import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sonamobi/models/cached_page.dart';
import 'package:sonamobi/providers/database.dart';
import 'package:sqflite/sqflite.dart';

final pageProvider = Provider((ref) => PageProvider(ref));

class FetchError implements Exception {
  final String message;
  final String path;
  final int code;
  final String body;
  final String? url;

  FetchError(this.message, this.path, [http.Response? response])
      : code = response?.statusCode ?? 0,
        body = response?.body ?? '',
        url = response?.request?.url.toString();

  @override
  String toString() => '$message for $path: $code $body';
}

class PageProvider {
  static const kCacheDuration = Duration(days: 30);
  static const kBaseUrl = 'sonaveeb.ee';

  static final _logger = Logger('PageProvider');

  String? _cookie;
  final Ref _ref;

  PageProvider(this._ref);

  _updateCookie() async {
    _logger.info('Updating cookie');
    final url = Uri.https(kBaseUrl);
    try {
      final response = await http.get(url).timeout(Duration(seconds: 2));
      if (response.statusCode != 200) {
        throw FetchError('Failed to get a cookie', '/', response);
      }
      final data =
          response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
      if (data != null) {
        _cookie = data.split(';')[0].trim();
      }
    } on Exception catch (e) {
      throw FetchError('Failed to get a cookie: $e', '/');
    }
  }

  Future<CachedPage?> _fetchFromCache(String path) async {
    final db = await _ref.read(databaseProvider).database;
    final rows = await db.query(
      CachedPage.kTableName,
      where: 'url = ?',
      whereArgs: [path],
    );
    return rows.map((row) => CachedPage.fromJson(row)).firstOrNull;
  }

  Future _saveToCache(String path, String content) async {
    final db = await _ref.read(databaseProvider).database;
    await db.insert(
      CachedPage.kTableName,
      CachedPage(path, content).toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future forgetPage(String path) async {
    final db = await _ref.read(databaseProvider).database;
    await db.delete(
      CachedPage.kTableName,
      where: 'url = ?',
      whereArgs: [path],
    );
  }

  Future<String> fetchPage(String path) async {
    final cached = await _fetchFromCache(path);
    if (cached != null &&
        DateTime.now().difference(cached.requestedAt) < kCacheDuration) {
      _logger.info('Got from cache: $path');
      return cached.content;
    }

    if (_cookie == null) await _updateCookie();

    final url = Uri.https(kBaseUrl, path);
    String body;
    try {
      http.Response response = await http.get(
        url,
        headers: {
          if (_cookie != null) 'Cookie': _cookie!,
          'Referer': 'https://sonaveeb.ee/',
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Sonamobi/0.1',
        },
      ).timeout(Duration(seconds: 2));

      // Check that cookie is fresh, i.e. we didn't get the default page.
      final cookieIsFresh = response.statusCode != 302 &&
          !response.headers.containsKey('Location');
      if (!cookieIsFresh) {
        _cookie = null;
        await _updateCookie();
        response = await http.get(
          url,
          headers: {
            if (_cookie != null) 'Cookie': _cookie!,
            'Referer': 'https://sonaveeb.ee/',
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Sonamobi/0.1',
          },
        ).timeout(Duration(seconds: 2));
      }

      if (response.statusCode != 200) {
        if (cached != null) return cached.content;
        throw FetchError('Error', path, response);
      }

      body = utf8.decode(response.bodyBytes);
    } on TimeoutException {
      if (cached != null) return cached.content;
      throw FetchError('Timeout', path);
    } on Exception catch (e) {
      if (cached != null) return cached.content;
      throw FetchError('Exception when downloading: $e', path);
    }
    if (body.length < 2) {
      throw FetchError('Empty page', path);
    }

    _saveToCache(path, body);
    return body;
  }
}

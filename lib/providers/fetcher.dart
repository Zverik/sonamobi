import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:sonamobi/models/cached_page.dart';
import 'package:sonamobi/providers/database.dart';
import 'package:sqflite/sqflite.dart';

final pageProvider = Provider((ref) => PageProvider(ref));

class FetchError implements Exception {
  final String message;
  final int code;
  final String body;
  final String? url;

  FetchError(this.message, http.Response? response)
      : code = response?.statusCode ?? 0,
        body = response?.body ?? '',
        url = response?.request?.url.toString();

  @override
  String toString() => '$message: $code $body';
}

class PageProvider {
  static const kCacheDuration = Duration(days: 30);
  static const kBaseUrl = 'sonaveeb.ee';

  static final _logger = Logger('PageProvider');

  String? _cookie;
  Ref _ref;

  PageProvider(this._ref);

  _updateCookie() async {
    final url = Uri.https(kBaseUrl);
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw FetchError('Failed to get a cookie', response);
    }
    final data =
        response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
    if (data != null) {
      _cookie = data.split(';')[0].trim();
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

  Future<String> fetchPage(String path) async {
    if (_cookie == null) await _updateCookie();

    final cached = await _fetchFromCache(path);
    if (cached != null &&
        DateTime.now().difference(cached.requestedAt) < kCacheDuration) {
      _logger.info('Got from cache: $path');
      return cached.content;
    }

    final url = Uri.https(kBaseUrl, path);
    String body;
    try {
      final response = await http.get(
        url,
        headers: {
          if (_cookie != null) 'Cookie': _cookie!,
          'Referer': 'https://sonaveeb.ee/',
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Sonamobi/0.1',
        },
      ).timeout(Duration(seconds: 2));

      if (response.statusCode != 200) {
        if (cached != null) return cached.content;
        throw FetchError('Error on $path', response);
      }

      body = utf8.decode(response.bodyBytes);
    } on TimeoutException {
      if (cached != null) return cached.content;
      throw FetchError('Timeout for $path', null);
    }

    _saveToCache(path, body);
    return body;
  }
}

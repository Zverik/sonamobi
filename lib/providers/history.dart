import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/models/history.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/providers/database.dart';
import 'package:sqflite/sqflite.dart';

final historyProvider = ChangeNotifierProvider((ref) => HistoryController(ref));

class HistoryController extends ChangeNotifier {
  final Ref _ref;
  List<HistoryEntry> history = const [];
  List<HistoryEntry> starred = const [];

  HistoryController(this._ref) {
    _load();
  }

  _load() async {
    history = await fetchHistory();
    starred = await fetchStarred();
    notifyListeners();
  }

  Future<List<HistoryEntry>> fetchHistory([int limit = 100]) async {
    final db = await _ref.read(databaseProvider).database;
    final rows = await db.query(
      HistoryEntry.kTableName,
      orderBy: 'accessed desc',
      limit: limit,
    );
    return rows.map((row) => HistoryEntry.fromJson(row)).toList();
  }

  Future<List<HistoryEntry>> fetchStarred() async {
    final db = await _ref.read(databaseProvider).database;
    final rows = await db.query(
      HistoryEntry.kTableName,
      where: 'starred = 1',
    );
    return rows.map((row) => HistoryEntry.fromJson(row)).toList();
  }

  Future addView(WordRef word, bool simple) async {
    final entry = HistoryEntry(word);
    final db = await _ref.read(databaseProvider).database;
    final rows = await db.query(
      HistoryEntry.kTableName,
      where: 'word = ?',
      whereArgs: [entry.databaseId],
    );
    final dbEntry =
        rows.map((row) => HistoryEntry.fromJson(row)).firstOrNull ?? entry;
    dbEntry.views += 1;
    dbEntry.lastAccessed = DateTime.now();
    await db.insert(
      HistoryEntry.kTableName,
      dbEntry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Update the cached history.
    history = await fetchHistory();
    notifyListeners();
  }

  Future star(WordRef word, bool starred) async {
    final entry = HistoryEntry(word);
    final db = await _ref.read(databaseProvider).database;
    final rows = await db.query(
      HistoryEntry.kTableName,
      where: 'word = ?',
      whereArgs: [entry.databaseId],
    );
    final dbEntry =
        rows.map((row) => HistoryEntry.fromJson(row)).firstOrNull ?? entry;
    dbEntry.starred = starred;
    await db.insert(
      HistoryEntry.kTableName,
      dbEntry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update the cached history and starred.
    await _load();
  }
}

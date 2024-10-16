import 'package:logging/logging.dart';
import 'package:sonamobi/models/cached_page.dart';
import 'package:sonamobi/models/history.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseProvider = Provider((_) => DatabaseHelper._());

class DatabaseHelper {
  static const kDatabaseName = 'sonamobi.db';
  static final _logger = Logger('DatabaseHelper');

  DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _createDatabase();
    _db = await _recreateDatabaseIfBroken(_db!);
    return _db!;
  }

  Future vacuum() async {
    final db = await database;
    await db.execute('vacuum');
  }

  Future<Database> _recreateDatabaseIfBroken(Database db) async {
    try {
      await db.query(HistoryEntry.kTableName, columns: ['count(*)']);
    } on DatabaseException catch (e) {
      _logger.severe('Database is broken!', e);
      await deleteDatabase(kDatabaseName);
      return await _createDatabase();
    }
    return db;
  }

  Future<Database> _createDatabase() async {
    return await openDatabase(
      kDatabaseName,
      version: 1,
      onCreate: _initDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  void _initDatabase(Database database, int version) async {
    await database.execute(
        "create table ${HistoryEntry.kTableName} (${HistoryEntry.kTableFields.join(', ')})");
    await database.execute(
        "create index ${HistoryEntry.kTableName}_ts on ${HistoryEntry.kTableName} (accessed)");
    await database.execute(
        "create index ${HistoryEntry.kTableName}_star on ${HistoryEntry.kTableName} (starred)");

    await database.execute(
        "create table ${CachedPage.kTableName} (${CachedPage.kTableFields.join(', ')})");
    await database.execute(
        "create index ${CachedPage.kTableName}_url on ${CachedPage.kTableName} (url)");
  }

  void _upgradeDatabase(
      Database database, int oldVersion, int newVersion) async {
    // Do nothing.
  }
}

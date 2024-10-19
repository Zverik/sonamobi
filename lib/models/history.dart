import 'package:sonamobi/models/wordref.dart';

class HistoryEntry {
  final WordRef word;
  DateTime lastAccessed;
  int views;
  bool starred;

  HistoryEntry(
    this.word, {
    DateTime? accessed,
    this.views = 0,
    this.starred = false,
  }) : lastAccessed = accessed ?? DateTime.now();

  String get databaseId => word.toUrl();

  static const kTableName = 'history';
  static const kTableFields = [
    'word text primary key',
    'accessed integer',
    'views integer',
    'starred integer',
  ];

  Map<String, dynamic> toJson() {
    return {
      'word': word.toUrl(),
      'accessed': lastAccessed.millisecondsSinceEpoch,
      'views': views,
      'starred': starred ? 1 : 0,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> data) {
    return HistoryEntry(
      WordRef.fromUrl(data['word']),
      accessed: DateTime.fromMillisecondsSinceEpoch(data['accessed']),
      views: data['views'],
      starred: data['starred'] == 1,
    );
  }
}

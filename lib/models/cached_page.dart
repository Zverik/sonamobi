import 'dart:io';

class CachedPage {
  final String url;
  final String content;
  final DateTime requestedAt;

  CachedPage(this.url, this.content, [DateTime? requestedAt])
      : requestedAt = requestedAt ?? DateTime.now();

  static const kTableName = 'cache';
  static const kTableFields = [
    'url text',
    'content text',
    'requested integer',
  ];

  Map<String, dynamic> toJson() {
    final codec = GZipCodec();
    return {
      'url': url,
      'content': content,
      'requested': requestedAt.millisecondsSinceEpoch,
    };
  }

  factory CachedPage.fromJson(Map<String, dynamic> data) {
    final codec = GZipCodec();
    return CachedPage(
      data['url'],
      data['content'],
      DateTime.fromMillisecondsSinceEpoch(data['requested']),
    );
  }
}

class WordRef {
  final String word;
  final int? homonym;
  final String? language;

  const WordRef(this.word, {this.homonym, this.language});

  static final kRegExp = RegExp(r'^(?:http.+?/)?([^/]+)(?:/(\d+)/([a-z]+))?$');

  factory WordRef.fromUrl(String url) {
    final match = kRegExp.matchAsPrefix(url);
    if (match == null) throw ArgumentError('Wrong url for WordRef: $url');
    final homonym = match.group(2);
    final lang = match.group(3);
    return WordRef(
      match.group(1) ?? '',
      homonym: homonym == null ? null : int.parse(homonym),
      language: lang,
    );
  }

  String toUrl() => homonym == null ? word : '$word/$homonym/$language';
}

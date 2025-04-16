import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Element;
import 'package:logging/logging.dart';

class Homonym {
  final int id;
  final int? homonymId;
  final String name;
  final String language;
  final String? matches;
  final String? intro;
  final String? url;

  const Homonym({
    required this.id,
    required this.name,
    required this.language,
    this.homonymId,
    this.matches,
    this.intro,
    this.url,
  });

  @override
  String toString() {
    return 'Homonym(id=$id, name=$name, lang=$language, hId=$homonymId, matches=$matches, intro=$intro)';
  }

  @override
  bool operator ==(Object other) =>
      other is Homonym &&
      other.id == id &&
      other.name == name &&
      other.language == language;

  @override
  int get hashCode => Object.hash(id, name, language);
}

class WordForm {
  final String word; // not splitting
  final String title;
  final String? spoken;

  const WordForm({required this.word, required this.title, this.spoken});
}

class SearchPageData {
  final String content;
  final List<WordForm> forms;
  final String formsRaw;
  final int? morphId;
  final String? language;

  const SearchPageData(
      {required this.forms,
      required this.formsRaw,
      required this.content,
      this.morphId,
      this.language});

  static const empty = SearchPageData(forms: [], formsRaw: '', content: '');
}

class SonaveebParsers {
  static final _logger = Logger('SonaveebParsers');

  static List<Homonym> extractHomonyms(String body) {
    final document = parse(body);
    // Now we need to find all homonyms
    final homonyms = <Homonym>[];
    for (final homonym
        in document.getElementsByClassName('homonym-list-item')) {
      int? wordId;
      String? lang;
      int? homonymId;
      String? url;
      for (final inputElement in homonym.getElementsByTagName('input')) {
        if (inputElement.attributes['name'] == 'word-id') {
          wordId = int.tryParse(inputElement.attributes['value']!);
        } else if (inputElement.attributes['name'] == 'word-select-url') {
          url = inputElement.attributes['value'];
          final urlMatch =
              RegExp(r'd?all/[^/]+/(\d+)/(\w+)$').firstMatch(url ?? '');
          if (urlMatch != null) {
            homonymId = int.tryParse(urlMatch.group(1) ?? '');
            lang = urlMatch.group(2);
          }
        }
      }

      final homonymBody =
          homonym.getElementsByClassName('homonym__body').firstOrNull;

      final wordNameElement = homonymBody
          ?.getElementsByClassName('text-body-two')
          .firstOrNull
          ?.getElementsByTagName('span')
          .firstOrNull;
      String? name = wordNameElement?.text;

      if (lang == null) {
        final langElement = homonym.getElementsByClassName('lang-code');
        lang = langElement.isEmpty ? null : langElement.first.text;
      }

      final matchesElement =
          homonymBody?.getElementsByClassName('homonym__matches').firstOrNull;
      String? matches = matchesElement?.text;

      final introElement = homonymBody
          ?.getElementsByClassName('homonym__text')
          .firstOrNull
          ?.getElementsByTagName('p')
          .firstOrNull;
      String? intro = introElement?.text;

      if (wordId != null && name != null && lang != null) {
        homonyms.add(Homonym(
          id: wordId,
          homonymId: homonymId,
          name: name,
          language: lang,
          matches: matches,
          intro: intro,
          url: url,
        ));
      } else {
        _logger.warning(
            'Could not parse homonym: id=$wordId, hId=$homonymId, name=$name, lang=$lang');
      }
    }
    return homonyms;
  }

  static List<WordForm> extractWordForms(Element table) {
    final reHtmlTag = RegExp(r'<[^>]+>');
    final List<WordForm> result = [];
    for (final td in table.getElementsByTagName('td')) {
      final spans = td.getElementsByTagName('span');
      if (spans.isEmpty) continue;
      final title = spans.first.attributes['title'] ?? '???';
      final word = spans.first.innerHtml.replaceAll(reHtmlTag, '');

      String? spoken;
      final btn = td.getElementsByTagName('button');
      if (btn.isNotEmpty) {
        spoken = btn.first.attributes['data-audio-url'];
      }

      result.add(WordForm(word: word, title: title, spoken: spoken));
    }
    return result;
  }

  static SearchPageData parseSearchPage(String body) {
    final document = parse(body);

    final morph = document.getElementsByClassName('morphology-paradigm');
    List<WordForm> forms = [];
    String formsRaw = '';
    if (morph.isNotEmpty) {
      final table = morph.first.getElementsByTagName('table');
      forms = extractWordForms(table.first);
      formsRaw = table.first.outerHtml;
    } else {
      _logger.warning(
          'Could not find word forms, ${morph.length} results for .morphology-paradigm.');
    }

    final paradigm = document.getElementById('morpho-modal-0');
    int? paradigmId;
    if (paradigm != null) {
      paradigmId = int.tryParse(paradigm.attributes['data-paradigm-id'] ?? '');
      // Use it as https://sonaveeb.ee/morpho/unif/1480786/est
    }

    final title = document.getElementsByClassName('word-results');
    String? language;
    if (title.isNotEmpty) {
      final langCode = title.first.getElementsByClassName('lang-code');
      if (langCode.isNotEmpty) {
        language = langCode.first.innerHtml.trim();
      }
    }

    return SearchPageData(
      content: body,
      forms: forms,
      formsRaw: formsRaw,
      morphId: paradigmId,
      language: language,
    );
  }

  static List<String> getWordSuggestions(String body) {
    final document = parse(body);
    final results = <String>[];
    final details = document.getElementsByClassName('word-details');
    if (details.isNotEmpty) {
      final forms = details.first.getElementsByClassName('word-form');
      for (final form in forms) {
        final attr = form.attributes['data-word'];
        if (attr != null) results.add(attr);
      }
    }
    return results;
  }
}

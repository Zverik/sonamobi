import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Document;

class Homonym {
  final int id;
  final int? homonymId;
  final String name;
  final String language;
  final String? matches;
  final String? intro;

  const Homonym(
      {required this.id,
      required this.name,
      required this.language,
      this.homonymId,
      this.matches,
      this.intro});
}

class WordForm {
  final String word; // not splitting
  final String title;
  final String? spoken;

  const WordForm({required this.word, required this.title, this.spoken});
}

class SearchPageData {
  final List<WordForm> forms;
  final int? morphId;

  const SearchPageData({required this.forms, this.morphId});

  static const empty = SearchPageData(forms: []);
}

class SonaveebParsers {
  static List<Homonym> extractHomonyms(String body) {
    final document = parse(body);
    // Now we need to find all homonyms
    final homonyms = <Homonym>[];
    for (final homonym
        in document.getElementsByClassName('homonym-list-item')) {
      int? wordId;
      String? lang;
      int? homonymId;
      for (final inputElement in homonym.getElementsByTagName('input')) {
        if (inputElement.attributes['name'] == 'word-id') {
          wordId = int.tryParse(inputElement.attributes['value']!);
        } else if (inputElement.attributes['name'] == 'word-select-url') {
          final url = inputElement.attributes['value'];
          final urlMatch =
              RegExp(r'd?all/[^/]+/(\d+)/(\w+)$').firstMatch(url ?? '');
          if (urlMatch != null) {
            homonymId = int.tryParse(urlMatch.group(1) ?? '');
            lang = urlMatch.group(2);
          }
        }
      }

      final wordNameElement = homonym.getElementsByClassName('homonym-name');
      String? name =
          wordNameElement.isEmpty ? null : wordNameElement.first.text;

      if (lang == null) {
        final langElement = homonym.getElementsByClassName('lang-code');
        lang = langElement.isEmpty ? null : langElement.first.text;
      }

      final matchesElement = homonym.getElementsByClassName('homonym-matches');
      String? matches =
          matchesElement.isEmpty ? null : matchesElement.first.text;

      final introElement = homonym.getElementsByClassName('homonym-intro');
      String? intro = introElement.isEmpty ? null : introElement.first.text;

      if (wordId != null && name != null && lang != null) {
        homonyms.add(Homonym(
          id: wordId,
          homonymId: homonymId,
          name: name,
          language: lang,
          matches: matches,
          intro: intro,
        ));
      }
    }
    return homonyms;
  }

  static List<WordForm> extractWordForms(Document document) {
    final reHtmlTag = RegExp(r'<[^>]+>');
    final List<WordForm> result = [];
    final morph = document.getElementsByClassName('morphology-paradigm');
    if (morph.isNotEmpty) {
      final table = morph.first.getElementsByTagName('table');
      for (final td in table.first.getElementsByTagName('td')) {
        final spans = td.getElementsByTagName('span');
        if (spans.isEmpty) continue;
        final title = spans.first.attributes['title'] ?? '???';
        final word = spans.first.innerHtml.replaceAll(reHtmlTag, '');

        String? spoken;
        final btn = td.getElementsByTagName('button');
        if (btn.isNotEmpty) {
          spoken = btn.first.attributes['data-url-to-audio'];
        }

        result.add(WordForm(word: word, title: title, spoken: spoken));
      }
    }
    return result;
  }

  static SearchPageData parseSearchPage(String body) {
    final document = parse(body);
    final forms = extractWordForms(document);

    final paradigm = document.getElementById('morpho-modal-0');
    int? paradigmId;
    if (paradigm != null) {
      paradigmId = int.tryParse(paradigm.attributes['data-paradigm-id'] ?? '');
      // Use it as https://sonaveeb.ee/morpho/unif/1480786/est
    }

    return SearchPageData(
      forms: forms,
      morphId: paradigmId,
    );
  }
}
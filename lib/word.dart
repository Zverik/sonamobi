import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:sonamobi/forms.dart';
import 'package:sonamobi/providers/html_frame.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/panel.dart' show WordPage;
import 'package:sonamobi/util/flags.dart';
import 'package:sonamobi/util/parsers.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WordView extends ConsumerStatefulWidget {
  final WordRef word;

  const WordView(this.word, {super.key});

  @override
  ConsumerState<WordView> createState() => _WordViewState();
}

class _WordViewState extends ConsumerState<WordView> {
  static final _logger = Logger('WordView');

  bool _loading = true;
  List<Homonym> _homonyms = const [];
  SearchPageData _pageData = SearchPageData.empty;
  int _chosenHomonym = 0;
  final WebViewController _webController = WebViewController();

  @override
  void initState() {
    super.initState();
    _initController();
    _updateMainPage();
  }

  _initController() {
    final kReWord = ref.read(linksProvider.notifier).searchRegExp;
    _webController.setJavaScriptMode(JavaScriptMode.disabled);
    _webController.setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: (request) {
      final match = kReWord.matchAsPrefix(request.url);
      if (match != null && match.groupCount > 0) {
        final word = Uri.decodeComponent(match.group(1) ?? '');
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WordPage(word: WordRef.fromUrl(word)),
        ));
      }
      return NavigationDecision.prevent;
    }));
  }

  _changeHomonym(int idx) async {
    _chosenHomonym = idx;
    String content;
    try {
      content = await ref.read(pageProvider).fetchPage(ref
          .read(linksProvider.notifier)
          .wordDetails(_homonyms[_chosenHomonym].id));
    } on FetchError catch (e) {
      // TODO
      _logger.severe('Failed to request homonyms', e);
      return;
    }
    _pageData = SonaveebParsers.parseSearchPage(content);

    if (!mounted) return;
    await _webController.loadHtmlString(
      ref.read(htmlFrameProvider).frame(content, context),
      baseUrl: 'https://sonaveeb.ee/',
    );
    setState(() {
      _loading = false;
    });
  }

  _updateMainPage() async {
    _homonyms = const [];
    try {
      final body = await ref
          .read(pageProvider)
          .fetchPage(ref.read(linksProvider.notifier).search(widget.word.word));
      _homonyms = SonaveebParsers.extractHomonyms(body);
    } on FetchError catch (e) {
      // TODO
      print(e.toString());
      return;
    }

    if (_homonyms.isEmpty) {
      // TODO
      print('No homonyms!');
      return;
    }

    int homonym = 0;
    if (widget.word.homonym != null) {
      for (int i = 0; i < _homonyms.length; i++) {
        if (_homonyms[i].homonymId == widget.word.homonym) {
          homonym = i;
          break;
        }
      }
    }

    await _changeHomonym(homonym);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Text('loading...');
    final homonym = _homonyms.isEmpty ? null : _homonyms[_chosenHomonym];

    if (homonym == null) {
      return Center(child: Text('No homonyms'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and buttons to choose a homonym.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < _homonyms.length; i++) ...[
                  if (i == _chosenHomonym)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        '${homonym.name} ${kCountryFlags[_homonyms[i].language] ?? ''}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (i != _chosenHomonym)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () {
                          _changeHomonym(i);
                        },
                        child: Text(
                            '${i + 1} ${kCountryFlags[_homonyms[i].language] ?? ''}'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),

        // Word forms.
        if (_pageData.forms.isNotEmpty)
          GestureDetector(
            onTap: _pageData.morphId == null
                ? null
                : () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          WordFormsPage(formId: _pageData.morphId ?? 1314487),
                    ));
                  },
            child: Container(
              color: Theme.of(context).highlightColor,
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  for (int i = 0; i < 2; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int j = 0; j < _pageData.forms.length / 2; j++)
                            if (j * 2 + i < _pageData.forms.length)
                              Text(
                                _pageData.forms[j * 2 + i].word,
                                style: TextStyle(fontSize: 20),
                              ),
                        ],
                      ),
                    ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: Icon(Icons.navigate_next),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // The rest of the page.
        Expanded(
          child: WebViewWidget(controller: _webController),
        ),
      ],
    );
  }
}

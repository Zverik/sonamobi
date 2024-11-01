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
  static const kBaseUrl = 'https://sonaveeb.ee/';

  bool _loading = true;
  String? _error;
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
        _logger.info('Tapped: "${request.url}"');
        if (request.url == 'https://word.forms/' && _pageData.morphId != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WordFormsPage(formId: _pageData.morphId ?? 1314487),
          ));
        }
        final match = kReWord.matchAsPrefix(request.url);
        if (match != null && match.groupCount > 0) {
          final word = Uri.decodeComponent(match.group(1) ?? '');
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WordPage(word: WordRef.fromUrl(word)),
          ));
        }
        if (request.url.toString() == kBaseUrl) {
          return NavigationDecision.navigate;
        }
        _logger.info('Prevented navigation.');
        return NavigationDecision.prevent;
      }),
    );
  }

  _changeHomonym(int idx) async {
    _error = null;
    _chosenHomonym = idx;
    String content;
    try {
      content = await ref.read(pageProvider).fetchPage(ref
          .read(linksProvider.notifier)
          .wordDetails(_homonyms[_chosenHomonym].id));
    } on FetchError catch (e) {
      _logger.severe('Failed to request homonyms', e);
      setState(() {
        _error = 'Failed to request homonyms.';
      });
      return;
    }
    _pageData = SonaveebParsers.parseSearchPage(content);

    if (!mounted) return;
    await _webController.loadHtmlString(
      ref.read(htmlFrameProvider).frame(
          id: 'wordpage',
          content: content,
          forms: _pageData.formsRaw,
          context: context),
      baseUrl: kBaseUrl,
    );
    setState(() {
      _loading = false;
    });
  }

  _updateMainPage() async {
    _error = null;
    _homonyms = const [];
    final path = ref.read(linksProvider.notifier).search(widget.word.word);
    try {
      final body = await ref.read(pageProvider).fetchPage(path);
      _homonyms = SonaveebParsers.extractHomonyms(body);
    } on FetchError catch (e) {
      _logger.severe('Failed to fetch the word page', e);
      setState(() {
        _error = 'Failed to fetch the word page.';
      });
      return;
    }

    if (_homonyms.isEmpty) {
      ref.read(pageProvider).forgetPage(path);
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

  Widget _messageWidget(String message, [bool red = false]) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 20,
          color: red ? Colors.red : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _messageWidget('Laen alla...');
    }

    if (_error != null) {
      return _messageWidget(_error ?? 'viga', true);
    }

    final homonym = _homonyms.isEmpty ? null : _homonyms[_chosenHomonym];

    if (homonym == null) {
      return _messageWidget('Pole homonüüme');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and buttons to choose a homonym.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

        Expanded(
          child: WebViewWidget(controller: _webController),
        ),
      ],
    );
  }
}

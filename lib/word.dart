import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:sonamobi/forms.dart';
import 'package:sonamobi/providers/html_frame.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/panel.dart' show WordPage;
import 'package:sonamobi/translate.dart';
import 'package:sonamobi/util/error.dart';
import 'package:sonamobi/util/homonym.dart';
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
  final _webControllers = <WebViewController>[];
  final _loaded = <bool>[];
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _updateMainPage();
  }

  void _initController(WebViewController controller) {
    final kReWord = ref.read(linksProvider.notifier).searchRegExp;
    controller.setJavaScriptMode(JavaScriptMode.disabled);
    controller.setNavigationDelegate(
      NavigationDelegate(onNavigationRequest: (request) {
        _logger.info('Nav request: "${request.url}"');
        if (request.url.toString() == kBaseUrl) {
          return NavigationDecision.navigate;
        }

        if (request.url == 'https://word.forms/' && _pageData.morphId != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WordFormsPage(formId: _pageData.morphId ?? 1314487),
          ));
        } else if (request.url.startsWith('https://need.translate/')) {
          final uri = Uri.parse(request.url);
          final text = uri.queryParameters['text'];
          if (text != null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TranslationPage(text, context: widget.word.word),
            ));
          }
        } else {
          final match = kReWord.matchAsPrefix(request.url);
          if (match != null && match.groupCount > 0) {
            final word = Uri.decodeComponent(match.group(1) ?? '');
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => WordPage(word: WordRef.fromUrl(word)),
            ));
          }
        }
        return NavigationDecision.prevent;
      }),
    );
  }

  _changeHomonym(int idx) async {
    _error = null;
    _chosenHomonym = idx;
    if (_loaded[idx]) {
      setState(() {});
      return;
    }

    String content;
    try {
      content = await ref.read(pageProvider).fetchPage(ref
          .read(linksProvider.notifier)
          .wordDetails(_homonyms[_chosenHomonym].id));
    } on FetchError catch (e) {
      _logger.severe('Failed to request homonyms', e);
      setState(() {
        _loading = false;
        _error = 'Failed to request homonyms.';
      });
      return;
    }
    _pageData = SonaveebParsers.parseSearchPage(content);

    if (!mounted) return;
    await _webControllers[idx].loadHtmlString(
      ref.read(htmlFrameProvider).frame(
          id: 'wordpage',
          content: content,
          forms: _pageData.language == 'et' ? _pageData.formsRaw : '',
          context: context),
      baseUrl: kBaseUrl,
    );
    _loaded[idx] = true;
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
        _loading = false;
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

    for (int i = 0; i < _homonyms.length; i++) {
      _webControllers.add(WebViewController());
      _loaded.add(false);
      _initController(_webControllers[i]);
    }

    _pageController = PageController(initialPage: homonym);
    await _changeHomonym(homonym);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MessagePanel('Laen alla...');
    }

    if (_error != null) {
      return MessagePanel(_error ?? 'viga', isError: true);
    }

    final homonym = _homonyms.isEmpty ? null : _homonyms[_chosenHomonym];

    if (homonym == null) {
      return MessagePanel('Pole homonüüme', isError: true);
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
                for (int i = 0; i < _homonyms.length; i++)
                  HomonymButton(
                    homonym: _homonyms[i],
                    isChosen: i == _chosenHomonym,
                    label: '${i + 1}',
                    onPressed: () {
                      _changeHomonym(i);
                      _pageController.jumpToPage(i);
                    },
                  ),
              ],
            ),
          ),
        ),

        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => _changeHomonym(idx),
            itemCount: _homonyms.length,
            itemBuilder: (context, idx) => WebViewWidget(
              controller: _webControllers[idx],
              gestureRecognizers: {
                Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer())
              },
            ),
          ),
        ),
      ],
    );
  }
}

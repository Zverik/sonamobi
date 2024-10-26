import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:sonamobi/providers/html_frame.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WordFormsPage extends ConsumerStatefulWidget {
  final int formId;
  final String language;

  const WordFormsPage({super.key, required this.formId, this.language = 'est'});

  @override
  ConsumerState<WordFormsPage> createState() => _WordFormsPageState();
}

class _WordFormsPageState extends ConsumerState<WordFormsPage> {
  static final _logger = Logger('WordFormsPage');
  static const kBaseUrl = 'https://sonaveeb.ee/';
  final WebViewController _webController = WebViewController();

  @override
  void initState() {
    super.initState();
    _webController.setJavaScriptMode(JavaScriptMode.disabled);
    _webController.setNavigationDelegate(
      NavigationDelegate(onNavigationRequest: (request) {
        _logger.info('Tapped: "${request.url}"');
if (request.url.toString() == kBaseUrl) return NavigationDecision.navigate;
_logger.info('Prevented navigation.');
return NavigationDecision.prevent;
      }),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _webController.setBackgroundColor(Theme.of(context).canvasColor);
    });
    _loadPage();
  }

  _loadPage() async {
    try {
      final body = await ref.read(pageProvider).fetchPage(ref
          .read(linksProvider.notifier)
          .morpho(widget.formId, widget.language));

      if (mounted) {
        String content = ref
            .read(htmlFrameProvider)
            .frame(id: 'wordforms', content: body, context: context);
        _webController.loadHtmlString(content, baseUrl: kBaseUrl);
      }
    } on FetchError catch (e) {
      _logger.severe('Failed to load word forms', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: WebViewWidget(controller: _webController)),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(textStyle: TextStyle(fontSize: 20)),
              label: Text('Sulge'),
              icon: Icon(
                Icons.close,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

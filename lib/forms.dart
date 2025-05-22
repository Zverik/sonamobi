import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:sonamobi/providers/html_frame.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/util/close_button.dart';
import 'package:sonamobi/util/error.dart';
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
  String? error;

  @override
  void initState() {
    super.initState();
    _webController.setJavaScriptMode(JavaScriptMode.disabled);
    _webController.setNavigationDelegate(
      NavigationDelegate(onNavigationRequest: (request) {
        _logger.info('Tapped: "${request.url}"');
        if (request.url.toString() == kBaseUrl) {
          return NavigationDecision.navigate;
        }
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
    error = null;
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
      setState(() {
        error = 'Failed to load word forms';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: error == null
                    ? WebViewWidget(controller: _webController)
                    : MessagePanel(error, isError: true, onReload: _loadPage)),
            SulgeButton(),
          ],
        ),
      ),
    );
  }
}

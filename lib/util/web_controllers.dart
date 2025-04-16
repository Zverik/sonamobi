import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/forms.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/panel.dart';
import 'package:sonamobi/translate.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebControllerData {
  final controller = WebViewController();
  bool loaded = false;
  String? title;

  WebControllerData();
}

class WebControllerArray {
  static final _logger = Logger('WebControllerArray');
  static const _kBaseUrl = 'https://sonaveeb.ee/';

  final _controllers = <WebControllerData>[];

  int get length => _controllers.length;
  bool isLoaded(int idx) =>
      idx <= _controllers.length ? _controllers[idx].loaded : false;

  WebViewController getController(int idx) => _controllers[idx].controller;

  void initAll(BuildContext context, int count) {
    _controllers.clear();
    for (int i = 0; i < count; i++) {
      _controllers.add(WebControllerData());
      _initController(Navigator.of(context), i);
    }
  }

  Future<void> loadHtml({
    required int idx,
    required String body,
    String? title,
  }) async {
    final ctrl = _controllers[idx];
    await ctrl.controller.loadHtmlString(body, baseUrl: _kBaseUrl);
    ctrl.loaded = true;
    ctrl.title = title;
  }

  void _initController(NavigatorState navigator, int idx) {
    final kReWord =
        RegExp(r'^https.+/search/(?:unif|lite)/dlall/(?:dsall/)?(.+)$');

    final controller = _controllers[idx].controller;
    controller.setJavaScriptMode(JavaScriptMode.disabled);
    controller.setNavigationDelegate(
      NavigationDelegate(onNavigationRequest: (request) {
        _logger.info('Nav request: "${request.url}"');
        if (request.url == _kBaseUrl) {
          return NavigationDecision.navigate;
        }

        if (request.url.startsWith('https://word.forms/')) {
          final morphId = int.tryParse(
              request.url.substring(request.url.lastIndexOf('/') + 1));
          if (morphId != null) {
            navigator.push(MaterialPageRoute(
              builder: (_) => WordFormsPage(formId: morphId),
            ));
          }
        } else if (request.url.startsWith('https://need.translate/')) {
          final uri = Uri.parse(request.url);
          final text = uri.queryParameters['text'];
          if (text != null) {
            navigator.push(MaterialPageRoute(
              builder: (_) => TranslationPage(text, context: _controllers[idx].title),
            ));
          }
        } else {
          final match = kReWord.matchAsPrefix(request.url);
          if (match != null && match.groupCount > 0) {
            final word = Uri.decodeComponent(match.group(1) ?? '');
            navigator.push(MaterialPageRoute(
              builder: (_) => WordPage(word: WordRef.fromUrl(word)),
            ));
          }
        }
        return NavigationDecision.prevent;
      }),
    );
  }
}

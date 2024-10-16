import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TestFocusPage extends StatefulWidget {
  const TestFocusPage({super.key});

  @override
  State<TestFocusPage> createState() => _TestFocusPageState();
}

class _TestFocusPageState extends State<TestFocusPage> {
  final _webController = WebViewController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    await _webController.loadHtmlString(
      '<html><title>Test</title><body>Test! Tap here!</body></html>',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: WebViewWidget(controller: _webController)),
            TextField(autofocus: true),
          ],
        ),
      ),
    );
  }
}

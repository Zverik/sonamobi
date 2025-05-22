import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/providers/homonyms.dart';
import 'package:sonamobi/providers/html_frame.dart';
import 'package:sonamobi/util/error.dart';
import 'package:sonamobi/util/parsers.dart';
import 'package:sonamobi/util/web_controllers.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WordView extends ConsumerStatefulWidget {
  final WordRef word;

  const WordView(this.word, {super.key});

  @override
  ConsumerState<WordView> createState() => _WordViewState();
}

class _WordViewState extends ConsumerState<WordView> {
  static final _logger = Logger('WordView');

  String? _error;
  final _webControllers = WebControllerArray();
  final PageController _pageController = PageController();

  _changeHomonym(int idx, Homonym homonym) async {
    _error = null;
    if (_webControllers.isLoaded(idx)) {
      setState(() {});
      return;
    }

    SearchPageData pageData;
    try {
      pageData = await ref.read(homonymPageProvider(homonym).future);
    } on Exception catch (e) {
      setState(() {
        _error = 'Failed to request homonyms.';
      });
      return;
    }

    if (!mounted) return;
    await _webControllers.loadHtml(
      idx: idx,
      title: widget.word.word,
      body: ref.read(htmlFrameProvider).frame(
          id: 'wordpage',
          content: pageData.content,
          morphId: pageData.morphId,
          forms: pageData.language == 'et' || pageData.language == null
              ? pageData.formsRaw
              : '',
          context: context),
    );
    setState(() {});
    _pageController.jumpToPage(idx);
  }

  @override
  void initState() {
    super.initState();
    _updateHomonyms();
  }

  void _updateHomonyms() {
    final homonyms = ref.read(homonymsProvider(widget.word));

    final count = homonyms.valueOrNull?.length ?? 0;
    if (count == 0) return;
    if (_webControllers.length != count) {
      _webControllers.initAll(context, count);
    }

    final idx = ref.read(chosenHomonymIndexProvider(widget.word));
    if (idx < count) _changeHomonym(idx, homonyms.valueOrNull![idx]);
  }

  void reload() {
    _error = null;
    ref.invalidate(homonymsProvider(widget.word));
  }

  @override
  Widget build(BuildContext context) {
    final homonyms = ref.watch(homonymsProvider(widget.word));
    ref.listen(homonymsProvider(widget.word), (o, n) {
      _updateHomonyms();
    });

    ref.listen(chosenHomonymIndexProvider(widget.word), (old, newIdx) {
      final homonymsList = homonyms.valueOrNull;
      if (homonymsList == null || newIdx >= homonymsList.length) return;
      _changeHomonym(newIdx, homonymsList[newIdx]);
    });

    if (homonyms.isLoading) {
      return MessagePanel('Laen alla...');
    }

    if (homonyms.hasError) {
      return MessagePanel(
        homonyms.error.toString(),
        isError: true,
        onReload: reload,
      );
    }

    if (_error != null) {
      return MessagePanel(
        _error ?? 'viga',
        isError: true,
        onReload: reload,
      );
    }

    if (homonyms.value?.isEmpty ?? true) {
      return MessagePanel(
        'Pole homonüüme',
        isError: true,
        onReload: reload,
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (idx) {
        ref.read(chosenHomonymIndexProvider(widget.word).notifier).set(idx);
      },
      itemCount: _webControllers.length,
      itemBuilder: (context, idx) => WebViewWidget(
        controller: _webControllers.getController(idx),
        gestureRecognizers: {
          Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer())
        },
      ),
    );
  }
}

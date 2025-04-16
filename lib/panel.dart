import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/autocomplete.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/providers/autocomplete.dart';
import 'package:sonamobi/providers/history.dart';
import 'package:sonamobi/providers/homonyms.dart';
import 'package:sonamobi/providers/night.dart';
import 'package:sonamobi/providers/translation.dart';
import 'package:sonamobi/empty.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/util/error.dart';
import 'package:sonamobi/util/search_bar.dart';
import 'package:sonamobi/util/word_title.dart';
import 'package:sonamobi/word.dart';
import 'package:url_launcher/url_launcher.dart';

class WordPage extends ConsumerStatefulWidget {
  final WordRef? word;
  final bool updateHistory;

  const WordPage({super.key, this.word, this.updateHistory = true});

  @override
  ConsumerState<WordPage> createState() => _WordPageState();
}

class _WordPageState extends ConsumerState<WordPage>
    with WidgetsBindingObserver {
  static final _logger = Logger('WordPage');

  bool _searching = true;
  String _lookingFor = '';
  AutocompleteResults? _lastResults;

  @override
  initState() {
    super.initState();
    _searching = widget.word == null;
    if (widget.word != null) {
      ref.read(historyProvider).addView(
            widget.word!,
            simple: ref.read(linksProvider),
            updateTime: widget.updateHistory,
          );

      // Also initialize the translations provider.
      ref.read(translationProvider.notifier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nightMode = ref.watch(nightModeProvider);

    Widget page;
    Widget appBarTitle;
    if (!_searching && widget.word != null) {
      page = WordView(widget.word!);
      appBarTitle = WordAppBarTitle(widget.word!);
    } else {
      final found = ref.watch(autocompleteProvider(_lookingFor));

      AutocompleteResults? results;
      if (found.isLoading && _searching && _lastResults != null) {
        results = _lastResults;
      } else {
        results = found.valueOrNull;
        _lastResults = results;
      }

      if (results == null) {
        appBarTitle = Text('Sõnamobi');
        page = const EmptyWordView();
      } else if (results.isEmpty) {
        appBarTitle = Text('Otsing');
        page = MessagePanel('Ei leidnud midagi');
      } else {
        appBarTitle = Text('Otsing');
        page = AutocompleteView(
          found: results,
          onTap: (value) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => WordPage(word: WordRef(value)),
            ));
          },
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: appBarTitle,
        actions: [
          if (_searching)
            IconButton(
              icon: Icon(nightModeIcon(nightMode)),
              onPressed: () {
                ref.read(nightModeProvider.notifier).next();
              },
            ),
          IconButton(
            icon: ImageIcon(AssetImage('assets/sonaveeb.png')),
            onPressed: () {
              String url = '';
              if (!_searching && widget.word != null) {
                final homonym = ref.read(chosenHomonymProvider(widget.word));
                url = homonym?.url ?? '';
                if (url.isEmpty) {
                  url = ref
                      .read(linksProvider.notifier)
                      .search(widget.word!.word);
                }
              }
              launchUrl(Uri.https('sonaveeb.ee', url));
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(child: page),
            WordSearchBar(
              onUpdateWord: (value) {
                setState(() {
                  _searching = true;
                  _lookingFor = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

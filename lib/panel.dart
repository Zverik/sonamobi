import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/autocomplete.dart';
import 'package:sonamobi/log.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/providers/history.dart';
import 'package:sonamobi/providers/translation.dart';
import 'package:sonamobi/util/debouncer.dart';
import 'package:sonamobi/empty.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/util/error.dart';
import 'package:sonamobi/util/parsers.dart';
import 'package:sonamobi/word.dart';

class WordPage extends ConsumerStatefulWidget {
  final WordRef? word;

  const WordPage({super.key, this.word});

  @override
  ConsumerState<WordPage> createState() => _WordPageState();
}

class _WordPageState extends ConsumerState<WordPage>
    with WidgetsBindingObserver {
  static final _logger = Logger('WordPage');

  bool _searching = true;
  final DebounceDelayer debouncer = DebounceDelayer();
  AutocompleteResults? found;
  String? _lookingFor;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  initState() {
    super.initState();
    _searching = widget.word == null;
    if (widget.word != null) {
      ref.read(historyProvider).addView(widget.word!, ref.read(linksProvider));
      // Also initialize the translations provider.
      ref.read(translationProvider.notifier);
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      Future.delayed(Duration(milliseconds: 200), () async {
        if (!mounted) return;
        if (_searchFocus.hasFocus) {
          _searchFocus.unfocus();
          Future.delayed(Duration(milliseconds: 1));
        }
        _searchFocus.requestFocus();
      });
    }
  }

  _autocomplete(String value) async {
    if (value.length < 2) {
      setState(() {
        found = null;
      });
      return;
    }

    _lookingFor = value;
    Map<String, dynamic> data;
    final pages = ref.read(pageProvider);
    final path = ref.read(linksProvider.notifier).autocomplete(value);
    AutocompleteResults result = AutocompleteResults.empty;
    try {
      final body = await pages.fetchPage(path);
      data = json.decode(body);
      if (_lookingFor != value) return;
      result = AutocompleteResults(
        found: (data['prefWords'] as List).whereType<String>().toList(),
        forms: (data['formWords'] as List).whereType<String>().toList(),
        searched: value,
      );

      if (result.isEmpty) {
        // Fetch the actual html page and check it for more options.
        final path2 = ref.read(linksProvider.notifier).search(value);
        final body2 = await ref.read(pageProvider).fetchPage(path2);
        if (_lookingFor != value) return;
        final suggestions = SonaveebParsers.getWordSuggestions(body2);
        result = AutocompleteResults(
          found: suggestions,
          forms: const [],
          searched: value,
        );
      }
    } on FetchError catch (e) {
      _logger.severe('Fetch error', e);
    } on FormatException catch (e) {
      _logger.severe('Json decoding error', e);
      pages.forgetPage(path);
    }
    _lookingFor = null;

    setState(() {
      found = result;
    });
  }

  _openWord(String word) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WordPage(word: WordRef(word)),
    ));

    if (widget.word != null) {
      setState(() {
        _searchController.clear();
        _searchFocus.requestFocus();
        _searching = false;
      });
    }
  }

  bool _checkSystem(String value) {
    if (value.replaceAll(' ', '') == '?log') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LogDisplayPage(),
      ));
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    if (!_searching && widget.word != null) {
      page = WordView(widget.word!);
    } else if (found == null) {
      page = const EmptyWordView();
    } else if (found?.isEmpty ?? true) {
      page = MessagePanel('Ei leidnud midagi');
    } else {
      page = AutocompleteView(
        found: found!,
        onTap: (value) {
          _openWord(value);
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(child: page),
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: () {
                      if (_searching) {
                        setState(() {
                          _searching = false;
                          found = null;
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Container(
                    // color: Theme.of(context).primaryColor,
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Otsi sõnade tähendusi ja tõlkeid',
                        hintStyle: TextStyle(color: Colors.grey),
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        value = value.trim();
                        if (_checkSystem(value)) {
                          _searchController.clear();
                          return;
                        }
                        setState(() {
                          _searching = value.isNotEmpty;
                        });
                        debouncer.delayed(
                          const Duration(milliseconds: 500),
                          () {
                            _autocomplete(value);
                          },
                        );
                      },
                      onSubmitted: (value) async {
                        value = value.trim();
                        if (value.isNotEmpty) {
                          debouncer.cancel();
                          await _autocomplete(value);
                          if (found?.found.isNotEmpty ?? false) {
                            // If the first result is exactly what's typed, go to the page.
                            final firstWord = found?.found.first ?? '';
                            if (firstWord == value) {
                              _openWord(firstWord);
                            }
                          }
                        } else {
                          setState(() {
                            _searching = false;
                          });
                        }
                        _searchFocus.requestFocus();
                      },
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchFocus.requestFocus();
                    setState(() {
                      found = null;
                      _searching = true;
                    });
                  },
                  child: const Text('X'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

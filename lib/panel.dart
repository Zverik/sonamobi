import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/autocomplete.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/util/debouncer.dart';
import 'package:sonamobi/empty.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/word.dart';

class WordPage extends ConsumerStatefulWidget {
  final WordRef? word;

  const WordPage({super.key, this.word});

  @override
  ConsumerState<WordPage> createState() => _WordPageState();
}

class _WordPageState extends ConsumerState<WordPage> {
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
  }

  _autocomplete(String value) async {
    setState(() {
      found = null;
    });
    if (value.length < 2) return;

    _lookingFor = value;
    Map<String, dynamic> data;
    try {
      final body = await ref
          .read(pageProvider)
          .fetchPage(ref.read(linksProvider.notifier).autocomplete(value));
      data = json.decode(body);
    } on FetchError catch (e) {
      _logger.severe('Fetch error', e);
      return;
    } on FormatException catch (e) {
      _logger.severe('Json decoding error', e);
      return;
    }
    if (_lookingFor != value) return;
    _lookingFor = null;

    setState(() {
      found = AutocompleteResults(
        found: (data['prefWords'] as List).whereType<String>().toList(),
        forms: (data['formWords'] as List).whereType<String>().toList(),
      );
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

  @override
  Widget build(BuildContext context) {
    Widget page;
    if (!_searching && widget.word != null) {
      page = WordView(widget.word!);
    } else if (found?.isEmpty ?? true) {
      page = const EmptyWordView();
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
                        setState(() {
                          _searching = value.isNotEmpty;
                        });
                        if (value.trim().length >= 2) {
                          debouncer.delayed(const Duration(milliseconds: 500),
                              () {
                            _autocomplete(value.trim());
                          });
                        }
                      },
                      onSubmitted: (value) async {
                        if (value.trim().isNotEmpty) {
                          debouncer.cancel();
                          await _autocomplete(value.trim());
                          if (found?.found.isNotEmpty ?? false) {
                            // If the first result is exactly what's typed, go to the page.
                            final firstWord = found?.found.first ?? '';
                            if (firstWord == _searchController.text.trim()) {
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

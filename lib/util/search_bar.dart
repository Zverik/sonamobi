import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/log.dart';

class WordSearchBar extends ConsumerStatefulWidget {
  final Function(String) onUpdateWord;
  
  const WordSearchBar({super.key, required this.onUpdateWord});

  @override
  ConsumerState<WordSearchBar> createState() => _WordSearchBarState();
}

class _WordSearchBarState extends ConsumerState<WordSearchBar>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
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
    return Row(
      children: [
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
                  value = '';
                }
                widget.onUpdateWord(value);
              },
              onSubmitted: (value) {
                value = value.trim();
                if (value.isEmpty) return;
                _searchFocus.requestFocus();
                widget.onUpdateWord(value);
              },
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _searchController.clear();
            _searchFocus.requestFocus();
            widget.onUpdateWord('');
          },
          child: const Text('X'),
        ),
      ],
    );
  }
}

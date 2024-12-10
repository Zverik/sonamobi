import 'package:flutter/material.dart';

class AutocompleteItem {
  final String word;
  final bool isForm;

  const AutocompleteItem(this.word, this.isForm);
}

class AutocompleteResults {
  final List<String> found;
  final List<String> forms;
  final String? searched;

  static const empty = AutocompleteResults(found: [], forms: []);

  const AutocompleteResults(
      {required this.found, required this.forms, this.searched});

  bool get isEmpty => found.isEmpty && forms.isEmpty;
  int length() => found.length + forms.length;
  bool get isSearchFound =>
      found.isNotEmpty &&
      searched != null &&
      found[0].toLowerCase().startsWith(searched?.toLowerCase() ?? '###') &&
      (found[0].toLowerCase() == searched?.toLowerCase() ||
          found.length == 1 ||
          !found[1].toLowerCase().startsWith(searched?.toLowerCase() ?? '###'));

  AutocompleteItem get(int i) {
    if (isSearchFound) {
      if (i == 0) return AutocompleteItem(found[0], false);
      i -= 1;
      return AutocompleteItem(
        i < forms.length ? forms[i] : found[i - forms.length + 1],
        i < forms.length,
      );
    } else {
      return AutocompleteItem(
        i < forms.length ? forms[i] : found[i - forms.length],
        i < forms.length,
      );
    }
  }
}

class AutocompleteView extends StatelessWidget {
  final Function(String) onTap;
  final AutocompleteResults found;

  const AutocompleteView({super.key, required this.found, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      reverse: true,
      itemCount: found.length(),
      itemBuilder: (context, index) {
        final item = found.get(index);
        return ListTile(
          title: Text(
            item.isForm ? '✳️ ${item.word}' : item.word,
            style: TextStyle(fontSize: 18),
          ),
          onTap: () {
            onTap(item.word);
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) => Divider(),
    );
  }
}

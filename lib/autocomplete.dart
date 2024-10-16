import 'package:flutter/material.dart';

class AutocompleteItem {
  final String word;
  final bool isForm;

  const AutocompleteItem(this.word, this.isForm);
}

class AutocompleteResults {
  final List<String> found;
  final List<String> forms;

  const AutocompleteResults({required this.found, required this.forms});

  bool get isEmpty => found.isEmpty && forms.isEmpty;
  int length() => found.length + forms.length;

  AutocompleteItem get(int i) => AutocompleteItem(
        i < forms.length ? forms[i] : found[i - forms.length],
        i < forms.length,
      );
}

class AutocompleteView extends StatelessWidget {
  final Function(String) onTap;
  final AutocompleteResults found;

  const AutocompleteView({super.key, required this.found, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // TODO: scroll from bottom
      reverse: true,
      itemCount: found.length(),
      itemBuilder: (context, index) {
        final item = found.get(index);
        return ListTile(
          title: Text(
            item.isForm ? 'form: ${item.word}' : item.word,
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
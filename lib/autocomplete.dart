import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool get isNotEmpty => found.isNotEmpty || forms.isNotEmpty;
  int get length => found.length + forms.length;
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
    final colorBackground1 = Theme.of(context).scaffoldBackgroundColor;
    final hslColor = HSLColor.fromColor(colorBackground1).withSaturation(0.0);
    final colorBackground2 = hslColor
        .withLightness(hslColor.lightness < 0.5
            ? hslColor.lightness + 0.08
            : hslColor.lightness - 0.03)
        .toColor();

    return ListView.builder(
      reverse: true,
      itemCount: found.length,
      itemBuilder: (context, index) {
        final item = found.get(index);
        return GestureDetector(
          child: Container(
            color: index.isEven ? colorBackground1 : colorBackground2,
            padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
            child: Row(
              children: [
                if (item.isForm)
                  Container(
                    decoration: BoxDecoration(
                      color: index.isOdd ? colorBackground1 : colorBackground2,
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    margin: EdgeInsets.only(right: 12.0),
                    child: Text('VORM', style: GoogleFonts.ptSansNarrow()),
                  ),
                Flexible(
                  child: Text(
                    item.word,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: index == 0 && found.isSearchFound
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            onTap(item.word);
          },
        );
      },
    );
  }
}

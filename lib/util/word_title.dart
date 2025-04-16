import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/providers/homonyms.dart';
import 'package:sonamobi/providers/night.dart';
import 'package:sonamobi/util/flags.dart';
import 'package:sonamobi/util/parsers.dart';

class WordAppBarTitle extends ConsumerWidget {
  final WordRef word;

  const WordAppBarTitle(this.word, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homonyms = ref.watch(homonymsProvider(word)).valueOrNull;
    final chosenHomonym = ref.watch(chosenHomonymIndexProvider(word));
    final homonymCount = homonyms?.length ?? 0;
    final Homonym? homonym = homonyms == null ? null : homonyms[chosenHomonym];

    final String flag = kCountryAbbrs[homonym?.language] ?? '';
    final isDark = ref.read(nightModeProvider.notifier).isDark(context);
    const kLangLight = Color(0xffecf0f2);
    const kLangDark = Color(0xff1f2c33);

    return Row(
      children: [
        if (homonymCount> 1)
          GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? kLangDark : kLangLight,
                borderRadius: BorderRadius.circular(3.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              margin: EdgeInsets.only(right: 12.0),
              child: Text(
                '${chosenHomonym + 1}/$homonymCount',
                style: GoogleFonts.ptSansNarrow(),
              ),
            ),
            onTap: () {
              int i = (chosenHomonym + 1) % homonymCount;
              ref.read(chosenHomonymIndexProvider(word).notifier).set(i);
            },
          ),
        Text(
          homonym?.name ?? word.word,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        if (flag.isNotEmpty)
          Container(
            margin: EdgeInsets.only(left: 8.0),
            padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: isDark ? kLangDark : kLangLight,
              borderRadius: BorderRadius.circular(3.0),
            ),
            child: Text(
              flag,
              style: TextStyle(),
            ),
          ),
      ],
    );
  }
}

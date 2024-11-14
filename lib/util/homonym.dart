import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/providers/night.dart';
import 'package:sonamobi/util/flags.dart';
import 'package:sonamobi/util/parsers.dart';

class HomonymButton extends ConsumerWidget {
  final Homonym homonym;
  final bool isChosen;
  final Function()? onPressed;
  final String? label;

  const HomonymButton({
    super.key,
    required this.homonym,
    required this.isChosen,
    this.onPressed,
    this.label,
  });

  static const kLangLight = Color(0xffecf0f2);
  static const kLangDark = Color(0xff1f2c33);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.read(nightModeProvider.notifier).isDark(context);

    Widget button;
    if (isChosen) {
      button = Text(
        homonym.name,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      button = Text(label ?? homonym.name);
    }

    final String flag = kCountryAbbrs[homonym.language] ?? '';
    if (flag.isNotEmpty) {
      button = Row(
        children: [
          button,
          SizedBox(width: 4.0),
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: isDark ? kLangDark : kLangLight,
              borderRadius: BorderRadius.circular(3.0),
            ),
            child: Text(
              flag,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: isChosen
          ? button
          : ElevatedButton(
        onPressed: onPressed,
        child: button,
      ),
    );
  }
}

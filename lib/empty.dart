import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/panel.dart' show WordPage;
import 'package:sonamobi/providers/history.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/providers/night.dart';
import 'package:url_launcher/url_launcher.dart';

class EmptyWordView extends ConsumerWidget {
  const EmptyWordView({super.key});

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final isDark = ref.read(nightModeProvider.notifier).isDark(context);
    return Column(
      children: [
        SizedBox(height: 10.0),
        ListTile(
          title: Text('Heledus'),
          trailing: AnimatedToggleSwitch<ThemeMode>.rolling(
            current: ref.watch(nightModeProvider),
            values: [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
            iconBuilder: (mode, current) => Icon(
              nightModeIcon(mode),
              color: nightModeColor(mode),
            ),
            height: 40.0,
            onChanged: (mode) {
              ref.read(nightModeProvider.notifier).set(mode);
            },
          ),
          onTap: () {
            ref.read(nightModeProvider.notifier).next();
          },
        ),
        SwitchListTile(
          value: ref.watch(linksProvider),
          title: Text('Keeleõppijale'),
          onChanged: (value) {
            ref.read(linksProvider.notifier).toggle();
          },
        ),
        if (history.history.length <= 3)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              child: Text.rich(
                TextSpan(
                  text: 'See on mitteametlik äpp ',
                  children: [
                    TextSpan(
                      text: 'Sõnaveebi',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue,
                        decorationThickness: 1.5,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' jaoks. Sisesta sõna või vajuta siia, et minna veebilehele.',
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 24,
                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                ),
              ),
              onTap: () {
                launchUrl(Uri.https('sonaveeb.ee'));
              },
            ),
          ),
        if (history.history.isNotEmpty)
          Expanded(
            child: ListView.separated(
              reverse: true,
              itemBuilder: (context, idx) {
                final entry = history.history[idx];
                final morning = DateTime.now()
                    .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

                String day;
                if (entry.lastAccessed.isAfter(morning)) {
                  day = 'täna';
                } else if (morning.difference(entry.lastAccessed) <=
                    Duration(hours: 24)) {
                  day = 'eile';
                } else {
                  day =
                      '${entry.lastAccessed.day}.${_pad2(entry.lastAccessed.month)}';
                }
                final hour =
                    '${_pad2(entry.lastAccessed.hour)}:${_pad2(entry.lastAccessed.minute)}';

                return ListTile(
                  title: Text(
                    entry.word,
                    style: TextStyle(fontSize: 18),
                  ),
                  subtitle: Text('👁 ${entry.views} 🕑 $day $hour'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WordPage(word: entry.wordRef),
                    ));
                  },
                );
              },
              separatorBuilder: (context, idx) => Divider(),
              itemCount: history.history.length,
            ),
          ),
      ],
    );
  }
}

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/panel.dart' show WordPage;
import 'package:sonamobi/providers/history.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/providers/night.dart';

class EmptyWordView extends ConsumerWidget {
  const EmptyWordView({super.key});

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return Column(
      children: [
        ListTile(
          title: Text('Heledus'),
          trailing: AnimatedToggleSwitch<ThemeMode>.rolling(
            current: ref.watch(nightModeProvider),
            values: [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
            iconBuilder: (mode, _) => Icon(nightModeIcon(mode)),
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
        if (history.history.isEmpty)
          Expanded(child: Center(child: Text('Type a word'))),
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
                    entry.word.word,
                    style: TextStyle(fontSize: 18),
                  ),
                  subtitle: Text('👁 ${entry.views} 🕑 $day $hour'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WordPage(word: entry.word),
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

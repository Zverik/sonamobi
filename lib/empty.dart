import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/providers/night.dart';

class EmptyWordView extends ConsumerWidget {
  const EmptyWordView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(nightModeIcon(ref.watch(nightModeProvider))),
              onPressed: () {
                ref.read(nightModeProvider.notifier).next();
              },
            ),
          ],
        ),
        SwitchListTile(
          value: ref.watch(linksProvider),
          title: Text('Keeleõppijale'),
          onChanged: (value) {
            ref.read(linksProvider.notifier).toggle();
          },
        ),
        Expanded(child: Center(child: Text('Type a word'))),
      ],
    );
  }
}

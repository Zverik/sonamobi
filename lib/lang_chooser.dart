import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/providers/translation.dart';
import 'package:sonamobi/util/close_button.dart';

class LanguageChooser extends ConsumerStatefulWidget {
  const LanguageChooser({super.key});

  @override
  ConsumerState<LanguageChooser> createState() => _LanguageChooserState();
}

class _LanguageChooserState extends ConsumerState<LanguageChooser> {
  List<TranslationConfig> _items = const [];

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  _initItems() async {
    final ni =
        await ref.read(translationProvider.notifier).getTranslationVariants();
    setState(() {
      _items = ni;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _items.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) return SizedBox(height: 100);
                  final item = _items[i - 1];
                  return ListTile(
                    leading: Image.asset(item.provider.image),
                    title: Text(item.targetName),
                    onTap: () {
                      ref.read(translationProvider.notifier).set(item);
                      Navigator.pop(context);
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    Divider(),
              ),
            ),
            SulgeButton(),
          ],
        ),
      ),
    );
  }
}

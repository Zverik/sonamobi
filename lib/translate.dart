import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/lang_chooser.dart';
import 'package:sonamobi/providers/translation.dart';
import 'package:sonamobi/util/close_button.dart';
import 'package:sonamobi/util/error.dart';

class TranslationPage extends ConsumerStatefulWidget {
  final String text;
  final String? context;

  const TranslationPage(this.text, {this.context, super.key});

  @override
  ConsumerState<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends ConsumerState<TranslationPage> {
  static final _logger = Logger('TranslationPage');
  String? translation;
  String? error;

  @override
  void initState() {
    super.initState();
    updateTranslation();
  }

  Future updateTranslation() async {
    try {
      final result =
          await ref.read(translationProvider.notifier).translate(widget.text);
      setState(() {
        error = null;
        translation = result;
      });
    } on Exception catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget panel;
    if (error != null) {
      panel = MessagePanel(
        error,
        isError: true,
        onReload: () {
          setState(() {
            error = null;
          });
          updateTranslation();
        },
      );
    } else {
      final textStyle = TextStyle(
        fontSize: 24,
      );
      panel = Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.context != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  widget.context ?? '',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(widget.text, style: textStyle),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            Text(
              translation ?? widget.text,
              style: textStyle.copyWith(
                color: translation == null ? Colors.grey : null,
              ),
            ),
          ],
        ),
      );
    }

    ref.listen(translationProvider, (o, n) {
      updateTranslation();
    });

    final tc = ref.watch(translationProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: panel,
              ),
            ),
            TextButton.icon(
              icon: Image.asset(tc.provider.image, width: 24.0),
              label: Text(
                '${tc.provider.title} → ${tc.targetName}',
                style: TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LanguageChooser(),
                    ));
              },
            ),
            SulgeButton(),
          ],
        ),
      ),
    );
  }
}

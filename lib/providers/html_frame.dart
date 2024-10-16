import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/providers/night.dart';

final htmlFrameProvider = Provider((ref) => HtmlFrameProvider(ref));

class HtmlFrameProvider {
  final Ref _ref;

  HtmlFrameProvider(this._ref) {
    // TODO: load assets?
  }

  String frame(String content, [BuildContext? context]) {
    final head = [
      '<title>page</title>',
      '<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">',
      '<style>${buildCss(context)}</style>',
    ];
    return '<html lang="en"><head>${head.join()}</head><body>$content</body></html>';
  }

  String buildCss(BuildContext? context) {
    final isDark = _ref.read(nightModeProvider.notifier).isDark(context);
    final css = <String>[];
    if (context != null) {
      final theme = Theme.of(context);
      css.add('body { background-color: ${theme.canvasColor.toHex()}; color: ${theme.textTheme.bodyMedium?.color?.toHex()} }');
    }
    css.add(isDark ? kCssDark : kCssLight);
    css.add(kCssCommon);
    return css.join('\n');
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true, bool outputAlpha = false}) =>
      '${leadingHashSign ? '#' : ''}'
          '${outputAlpha ? alpha.toRadixString(16).padLeft(2, '0') : ''}'
          '${red.toRadixString(16).padLeft(2, '0')}'
          '${green.toRadixString(16).padLeft(2, '0')}'
          '${blue.toRadixString(16).padLeft(2, '0')}';
}

const kCssCommon = '''
.highlight { font-size: 12px; color: #687887; }
eki-form { color: #20b900; }
body { font-size: 20px; }
''';

const kCssLight = '''
''';

const kCssDark = '''
a { color: #75FAF1; }
''';
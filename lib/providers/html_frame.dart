import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/providers/night.dart';

final htmlFrameProvider = Provider((ref) => HtmlFrameProvider(ref));

class HtmlFrameProvider {
  static final _logger = Logger('HtmlFrameProvider');
  static final _kReDefinition = RegExp(r'(<span class=".*(?:definition|example-text)-value[^>]+>)([^<]+)(</span>)');
  final Ref _ref;

  HtmlFrameProvider(this._ref);

  String frame({required String id, required String content, String? forms, BuildContext? context}) {
    final head = [
      '<title>page</title>',
      '<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">',
      '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">',
      '<style>${buildCss(context)}</style>',
    ];

    // Add a forms box with a link.
    String formsHtml;
    if (forms?.isEmpty ?? true) {
      formsHtml = '';
    } else {
      formsHtml = '<div id="forms-box"><a href="https://word.forms/"><table><tr><td>$forms</td><td id="forms-box-arrow">&#10749;</td></tr></table></a></div>';
    }

    // Replace descriptions and examples with links.
    content = content.replaceAllMapped(_kReDefinition, (match) {
      final text = match.group(2)!;
      return '${match.group(1)!}<a href="https://need.translate/?text=${Uri.encodeQueryComponent(text)}">${match.group(2)!}</a>${match.group(3)!}';
    });

    // All done, return the page.
    return '<html lang="en"><head>${head.join()}</head><body>$formsHtml<div id="$id">$content</div></body></html>';
  }

  String buildCss(BuildContext? context) {
    final isDark = _ref.read(nightModeProvider.notifier).isDark(context);
    final colors = isDark ? Map.of(kColorsDark) : Map.of(kColorsLight);
    if (context != null) {
      final theme = Theme.of(context);
      colors['background'] = theme.canvasColor.toHex();
      colors['text'] = theme.textTheme.bodyMedium?.color?.toHex() ??
          colors['text'] ??
          'black';
    }
    return kCssCommon.replaceAllMapped(RegExp(r'%([a-z0-9]+)%'), (match) {
      final k = match.group(1);
      if (!colors.containsKey(k)) _logger.severe('Missing color key: %$k%');
      return colors[match.group(1)] ?? 'black';
    });
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
body {
  font-size: 20px;
  background-color: %background%;
  color: %text%;
  margin: 0;
  font-family: "Inter", -apple-system, blinkmacsystemfont, "Segoe UI", roboto, "Helvetica Neue", arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
  font-weight: 400;
  line-height: 1.5;
  text-align: left;
}
a { color: %a%; }
div.word-details { margin: 8px; }
div.content-title { display: none !important; }
.level-2-panel h5.meaning-sub-heading:first-child { display: none !important; }
.btn-speaker { display: none !important; }
.corp-panel, #corp, #corpTrans { display: none !important; }
/* small (i) button */
.btn-icon.btn-sm { display: none !important; }
.see-less-content { display: none !important; }
/* another "näita vähem" button */
.colloc-inner-section .btn-link-muted { display: none !important; }
.definition-sources { display: none !important; }

#forms-box {
  background-color: %lightgray%;
  margin: 0;
  padding: 4px 8px;
}
#forms-box td {
  padding-right: 24px;
  font-size: 20px;
}
#forms-box > a > table { width: 100%; }
#forms-box eki-form { color: %text%; }
#forms-box #forms-box-arrow { text-alight: right; padding: 0; margin: 0; }

#wordforms .modal-header { display: none !important; }
#wordforms ul.nav { display: none !important; }
#wordforms .paradigm-text { display: none !important; }

.definition-value a, .example-text-value a {
  color: inherit;
  text-decoration: underline;
  text-decoration-style: dotted;
  text-decoration-color: %gray350%;
}

.collapse:not(.show) { display: none; }

.highlight { font-size: 12px; color: %gray350%; }
eki-form { color: #20b900; }
eki-highlight { font-weight: bold; }
a {
  -color: #2c6fb6;
  text-decoration: none;
  background-color: transparent;
}

eki-stress { position: relative; }
eki-stress::after {
  position: absolute;
  top: -2px;
  right: 25%;
  display: inline-block;
  content: "́ ";
}

.tag {
  padding: 0 8px;
  margin-right: .25rem;
  font-size: 1rem;
  font-weight: 400;
  color: #5d606e;
  border: 1px solid #8a98a5;
  border-radius: 3px;
}

.lang-code {
  display: inline-block;
  flex: 0 0 auto;
  min-width: 24px;
  height: 20px;
  padding: 2px 5px 3px;
  overflow: visible;
  font-size: 1rem;
  font-weight: 700;
  line-height: 1.4;
  color: %langtext%;
  text-align: center;
  cursor: default;
  background: %lang%;
  border-radius: 4px;
}

.level-2-panel {
  position: relative;
  padding-top: 0;
  margin: 0 -15px;
}

.level-3-panel {
  position: relative;
  padding: 1rem;
  border-bottom: 1px solid %lightgray%;
}

.meaning-sub-heading {
  padding: 10px 16px;
  margin-bottom: 0;
  text-transform: uppercase;
  background: %lightgray%;
  border-bottom: 1px solid %lightgray%;
}

.col-1, .col-2, .col-3, .col-4, .col-5, .col-6, .col-7, .col-8, .col-9, .col-10,
.col-11, .col-12, .col, .col-auto, .col-sm-1, .col-sm-2, .col-sm-3, .col-sm-4,
.col-sm-5, .col-sm-6, .col-sm-7, .col-sm-8, .col-sm-9, .col-sm-10, .col-sm-11,
.col-sm-12, .col-sm, .col-sm-auto, .col-md-1, .col-md-2, .col-md-3, .col-md-4,
.col-md-5, .col-md-6, .col-md-7, .col-md-8, .col-md-9, .col-md-10, .col-md-11,
.col-md-12, .col-md, .col-md-auto, .col-lg-1, .col-lg-2, .col-lg-3, .col-lg-4,
.col-lg-5, .col-lg-6, .col-lg-7, .col-lg-8, .col-lg-9, .col-lg-10, .col-lg-11,
.col-lg-12, .col-lg, .col-lg-auto, .col-xl-1, .col-xl-2, .col-xl-3, .col-xl-4,
.col-xl-5, .col-xl-6, .col-xl-7, .col-xl-8, .col-xl-9, .col-xl-10, .col-xl-11,
.col-xl-12, .col-xl, .col-xl-auto {
  position: relative;
  width: 100%;
  -padding-right: 15px;
  -padding-left: 15px;
}

.row {
  display: flex;
  flex-wrap: wrap;
  -margin-right: -15px;
  -margin-left: -15px;
}
.content-panel .word-details { flex: 1 1 auto; }
.col-6 { flex: 0 0 50%; max-width: 50%; }
.col-12 { flex: 0 0 100%; max-width: 100%; }

.m-0 { margin: 0 !important; }
.mr-2 { margin-right: 0.5rem !important; }
.mr-1 { margin-right: 0.25rem !important; }
.mb-3 { margin-bottom: 1rem !important; }
.mb-2 { margin-bottom: 0.5rem !important; }
.mb-1 { margin-bottom: 0.25rem !important; }
.mb-0 { margin-bottom: 0 !important; }
.pr-2 { padding-right: 0.5rem !important; }
.pl-2 { padding-left: 0.5rem !important; }
.pl-3 { padding-left: 1rem !important; }
.pb-1 { padding-bottom: 0.25rem !important; }
.pb-0 { padding-bottom: 0 !important; }
.ml-n1 { margin-left: -0.25rem !important; }
.ml-n2 { margin-left: -0.5rem !important; }

.list-unstyled { padding-left: 0; list-style: none; }
ol, ul, dl { margin-top: 0; margin-bottom: 1rem; }
b, strong { font-weight: bolder; }

.d-flex { display: flex !important; }
.flex-column { flex-direction: column !important; }
.flex-row { flex-direction: row !important; }
.flex-grow-1 { flex-grow: 1 !important; }
.flex-shrink-1 { flex-shrink: 1 !important; }
.flex-wrap { flex-wrap: wrap !important; }
.align-self-start { align-self: flex-start !important; }
.align-items-end { align-items: flex-end !important; }
.d-inline-flex { display: inline-flex !important; }

.w-100 { width: 100% !important; }
.h-100 { height: 100% !important; }
.dependencies { padding-bottom: 4px; }
.dependence-group { display: flex; flex-direction: column; }
.definition-row { line-height: 1.2; }
.definition-area, .matches { padding-bottom: 12px; }
.definition-area .domain { text-transform: uppercase; }
.meaning-meta { padding-bottom: 8px; }
.word-grouper-wrapper .word-options a { position: relative; line-height: 1.3; }

.word-grouper-wrapper .word-options:not(:last-child) a.is-homonym > span::after {
  margin-left: 5px;
}

.word-grouper-wrapper .word-options:not(:last-child) a > span::after {
  display: inline;
  margin-right: .5rem;
  color: #3f3f3f;
  text-decoration: none;
  content: ",";
}

.colloc-heading { font-size: 14px; color: %gray350%; }
.colloc-section { padding-left: 1rem; }
.colloc-inner-section { padding-left: 16px; margin-bottom: 4px; }
.colloc-row { display: flex; flex-flow: row wrap; margin-bottom: 2px; }

.colloc-member {
  position: relative;
  box-sizing: border-box;
  display: flex;
  flex-wrap: nowrap;
  padding: 2px 5px;
}

.colloc-member::after {
  position: absolute;
  top: 50%;
  right: 0;
  display: block;
  height: 20px;
  content: "";
  border-left: 1px solid #3f3f3f;
  transform: translateY(-50%);
}

.alert.bg-warning { font-size: 12px; color: %gray350%; }

.text-nowrap { white-space: nowrap !important; }
.font-weight-bold { font-weight: 700 !important; }
.text-small { font-size: 0.75rem !important; }
.text-uppercase { text-transform: uppercase !important; }
.font-italic { font-style: italic !important; }
.lexeme-level { line-height: 1.25; }

.text-gray-350 { color: %gray350%; }

.fa-ellipsis-h::before { content: "..."; }

.btn {
  display: inline-block;
  font-weight: 400;
  color: %button%;
  text-align: center;
  vertical-align: middle;
  cursor: pointer;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  background-color: transparent;
  border: 1px solid transparent;
  padding: 0.375rem 0.75rem;
  font-size: 1rem;
  line-height: 1.5;
  border-radius: 0.25rem;
  transition: color 0.15s ease-in-out, background-color 0.15s ease-in-out, border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
}

.btn-sm, .btn-group-sm > .btn {
  padding: 0.25rem 0.5rem;
    padding-bottom: 0.25rem;
  font-size: 0.875rem;
  line-height: 1.5;
  border-radius: 0.2rem;
}

.btn-link-muted {
  font-weight: 700;
  color: %gray350%;
  text-decoration: none;
}
button { background-color: %background%; color: %text%; }

#wordforms .modal-body {
  padding: 16px 25px;
}
#wordforms .uppercase {
  text-transform: uppercase;
  margin-bottom: -10px;
}
#wordforms h2 {
  margin: 26px 0 12px;
  font-size: 18px;
  font-weight: normal;
  text-transform: uppercase;
}
#wordforms .scrollable-table {
  position: relative;
  margin-left: -10px;
  margin-right: -10px;
}
#wordforms table th, #wordforms table td {
  padding: 10px 12px;
  border-bottom: 1px solid #ecf0f2;
}
th { text-align: inherit; }
#wordforms table th {
  font-size: 16px;
  font-weight: 700;
  line-height: 120%;
}
#wordforms table td {
  padding-top: 5px;
  padding-bottom: 5px;
}
.morphology-paradigm table td {
  line-height: 1.4;
  min-width: 30%;
  max-width: 60%;
  white-space: normal;
}
#wordforms table th[colspan="3"] {
  border: none;
  font-size: 18px;
  line-height: 22px;
  font-weight: normal;
}
#wordforms .subtitle {
  padding-top: 20px;
  padding-bottom: 0;
}
''';

const kColorsLight = {
  'a': '#2962FF',
  'gray350': '#687887',
  'lightgray': '#ccd9e0',
  'lang': '#ecf0f2',
  'langtext': '#5d606e',
  'button': '#3f3f3f',
};

const kColorsDark = {
  'a': '#75FAF1',
  'gray350': '#687887',
  'lightgray': '#1F2C33',
  'lang': '#1F2C33', // '#0D1113',
  'langtext': '#9194A2',
  'button': '#c0c0c0',
};

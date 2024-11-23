import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtranslate_v2/gtranslate_v2.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonamobi/keys.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show json, utf8;

final translationProvider =
    StateNotifierProvider<TranslationController, TranslationConfig>(
        (_) => TranslationController());

enum TranslationProvider {
  neurotolge,
  google;

  String get title => this == neurotolge ? 'Neurotõlge' : 'Google';
  String get image =>
      this == neurotolge ? 'assets/neurotolge.png' : 'assets/gtranslate.png';
}

class TranslationConfig {
  final TranslationProvider provider;
  final String target;
  final String targetName;

  const TranslationConfig(this.provider, this.target, this.targetName);
}

class TranslationController extends StateNotifier<TranslationConfig> {
  static final _prefsKey = 'translator';
  static final _logger = Logger('TranslationController');
  static final _neurotolgeVariants = <TranslationConfig>[
    TranslationConfig(TranslationProvider.neurotolge, 'rus', 'Русский'),
    TranslationConfig(TranslationProvider.neurotolge, 'eng', 'English'),
    TranslationConfig(TranslationProvider.neurotolge, 'fin', 'Suomi'),
    TranslationConfig(TranslationProvider.neurotolge, 'lav', 'Latviešu valoda'),
    TranslationConfig(TranslationProvider.neurotolge, 'lit', 'Lietuvių kalba'),
    TranslationConfig(TranslationProvider.neurotolge, 'ger', 'Deutsch'),
  ];
  static final _googleVariants = <TranslationConfig>[
    TranslationConfig(TranslationProvider.google, 'ru', 'Русский'),
    TranslationConfig(TranslationProvider.google, 'uk', 'Українська мова'),
    TranslationConfig(TranslationProvider.google, 'en', 'English'),
    TranslationConfig(TranslationProvider.google, 'lv', 'Latviešu valoda'),
    TranslationConfig(TranslationProvider.google, 'de', 'Deutsch'),
    TranslationConfig(TranslationProvider.google, 'fr', 'Français'),
    TranslationConfig(TranslationProvider.google, 'es', 'Español'),
    TranslationConfig(TranslationProvider.google, 'it', 'Italiano'),
    TranslationConfig(TranslationProvider.google, 'hi', 'हिन्दी'),
    TranslationConfig(TranslationProvider.google, 'ar', 'اَلْعَرَبِيَّةُ'),
  ];

  static final defaultConfig = _neurotolgeVariants[0];

  late final GTranslateV2 api;
  List<TranslationConfig> _cachedVariants = const [];

  TranslationController() : super(defaultConfig) {
    api = GTranslateV2(apiToken: kGoogleApiKey, client: http.Client());
    _read();
  }

  _read() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null && saved.length == 3) {
      TranslationProvider provider;
      switch (saved[0]) {
        case 'google':
          provider = TranslationProvider.google;
        default:
          provider = TranslationProvider.neurotolge;
      }
      state = TranslationConfig(provider, saved[1], saved[2]);
    }
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    String provider;
    switch (state.provider) {
      case TranslationProvider.neurotolge:
        provider = 'neurotolge';
      case TranslationProvider.google:
        provider = 'google';
    }
    await prefs
        .setStringList(_prefsKey, [provider, state.target, state.targetName]);
  }

  set(TranslationConfig config) {
    state = config;
    _save();
  }

  Future<String> translate(String text) async {
    final lang = state.target;
    switch (state.provider) {
      case TranslationProvider.neurotolge:
        return await translateWithNeurotolge(text, lang);
      case TranslationProvider.google:
        return await translateWithGoogle(text, lang);
    }
  }

  Future<String> translateWithNeurotolge(String text, String lang) async {
    final url = Uri.https('api.tartunlp.ai', '/translation/v2');
    final data = {
      'text': text,
      'src': 'est',
      'tgt': lang,
      'application': 'Sõnamobi App',
    };
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    String body;
    try {
      body = json.encode(data);
    } on FormatException catch (e) {
      _logger.severe('Could not encode body $data: $e');
      rethrow;
    }

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw FetchError('Failed to request a translation', text, response);
    }
    _logger
        .info('Remaining quota: ${response.headers['x-rate-limit-remaining']}');
    try {
      final respData = json.decode(utf8.decode(response.bodyBytes));
      return respData['result'];
    } on FormatException catch (e) {
      _logger.severe('Could not decode response ${response.body}: $e');
      rethrow;
    }
  }

  Future<String> translateWithGoogle(String text, String lang) async {
    final response = await api.translate(
      TranslateRequestModel(
        q: [text],
        source: 'et',
        target: lang,
        format: 'text',
      ),
    );
    return response.data?.translations?.first.translatedText ?? '(error)';
  }

  Future<List<TranslationConfig>> getTranslationVariants() async {
    if (_cachedVariants.isEmpty) {
      List<TranslationConfig> googleVariants = _googleVariants;
      try {
        final variants = await api.list(ListRequestModel(target: 'en'));
        final langs = variants.data?.languages;
        if (langs != null) {
          final newVariants = [
            for (final v in langs)
              if (v.language != null &&
                  _googleVariants.indexWhere((tc) => v.language == tc.target) ==
                      -1)
                TranslationConfig(TranslationProvider.google, v.language!,
                    v.name ?? v.language!)
          ];
          googleVariants += newVariants;
        }
      } on Exception catch (e) {
        _logger.warning('Could not get language variants from Google: $e');
      }
      _cachedVariants = _neurotolgeVariants + googleVariants;
    }
    return _cachedVariants;
  }
}

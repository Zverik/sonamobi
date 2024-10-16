import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final linksProvider =
    StateNotifierProvider<LinksNotifier, bool>((_) => LinksNotifier());

class LinksNotifier extends StateNotifier<bool> {
  static final _kPrefsKey = 'dictionary';

  LinksNotifier() : super(false) {
    _read();
  }

  _read() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kPrefsKey) ?? false;
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsKey, state);
  }

  toggle() {
    state = !state;
    _save();
  }

  bool get isLite => state;
  String get _dict => state ? 'lite' : 'unif';
  String get baseUrl => 'https://sonaveeb.ee';
  String autocomplete(String word) => '/searchwordfrag/$_dict/$word';
  String search(String word) =>
      isLite ? '/search/lite/dlall/$word' : '/search/unif/dlall/dsall/$word';
  String wordDetails(int wordId) => '/worddetails/$_dict/$wordId';
  String morpho(int formId, String language) => '/morpho/$_dict/$formId/$language';
  RegExp get searchRegExp => isLite ? kReLite : kReUnif;

  static final kReUnif = RegExp(r'^https.+/search/unif/dlall/dsall/(.+)$');
  static final kReLite = RegExp(r'^https.+/search/lite/dlall/(.+)$');
}

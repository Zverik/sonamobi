import 'dart:convert' show json;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonamobi/autocomplete.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/util/parsers.dart';

class AutocompleteError implements Exception {
  final String error;
  final Exception reason;

  const AutocompleteError(this.error, this.reason);

  @override
  String toString() => '$error: $reason';
}

final autocompleteProvider = FutureProvider.autoDispose
    .family<AutocompleteResults?, String>((ref, value) async {
  if (value.length < 2) {
    return null;
  }

  bool stop = false;
  ref.onDispose(() {
    stop = true;
  });

  await Future.delayed(Duration(milliseconds: 500));
  if (stop) return null;

  Map<String, dynamic> data;
  final pages = ref.read(pageProvider);
  final path = ref.read(linksProvider.notifier).autocomplete(value);
  AutocompleteResults result = AutocompleteResults.empty;
  try {
    final body = await pages.fetchPage(path);
    if (stop) return null;
    data = json.decode(body);
    result = AutocompleteResults(
      found: (data['prefWords'] as List).whereType<String>().toList(),
      forms: (data['formWords'] as List).whereType<String>().toList(),
      searched: value,
    );

    if (result.isEmpty) {
      // Fetch the actual html page and check it for more options.
      final path2 = ref.read(linksProvider.notifier).search(value);
      final body2 = await ref.read(pageProvider).fetchPage(path2);
      if (stop) return null;
      final suggestions = SonaveebParsers.getWordSuggestions(body2);
      result = AutocompleteResults(
        found: suggestions,
        forms: const [],
        searched: value,
      );
    }
  } on FetchError catch (e) {
    throw AutocompleteError('Fetch error', e);
  } on FormatException catch (e) {
    pages.forgetPage(path);
    throw AutocompleteError('Json decoding error', e);
  }

  return result;
});

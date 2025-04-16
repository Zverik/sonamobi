import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/models/wordref.dart';
import 'package:sonamobi/providers/fetcher.dart';
import 'package:sonamobi/providers/links.dart';
import 'package:sonamobi/util/parsers.dart';

class HomonymError implements Exception {
  final String error;
  const HomonymError(this.error);

  @override
  String toString() => error;
}

final homonymsProvider =
    FutureProvider.family<List<Homonym>, WordRef>((ref, word) async {
  List<Homonym> homonyms = const [];
  final path = ref.read(linksProvider.notifier).search(word.word);
  try {
    final body = await ref.read(pageProvider).fetchPage(path);
    homonyms = SonaveebParsers.extractHomonyms(body);
  } on FetchError catch (e) {
    final logger = Logger('HomonymsProvider');
    logger.severe('Failed to fetch the word page', e);
    throw HomonymError('Failed to fetch the word page.');
  }

  if (homonyms.isEmpty) {
    ref.read(pageProvider).forgetPage(path);
  }

  return homonyms;
});

final chosenHomonymIndexProvider = NotifierProvider.autoDispose
    .family<ChosenHomonymController, int, WordRef>(ChosenHomonymController.new);

class ChosenHomonymController extends AutoDisposeFamilyNotifier<int, WordRef> {
  @override
  int build(WordRef word) {
    final homonyms = ref.watch(homonymsProvider(word)).valueOrNull;
    if (word.homonym != null && homonyms != null) {
      for (int i = 0; i < homonyms.length; i++) {
        if (homonyms[i].homonymId == word.homonym) {
          return i;
        }
      }
    }
    return 0;
  }

  void set(int newValue) {
    state = newValue;
  }
}

final chosenHomonymProvider =
    Provider.autoDispose.family<Homonym?, WordRef?>((ref, word) {
  if (word == null) return null;
  final homonyms = ref.watch(homonymsProvider(word)).valueOrNull;
  final chosenHomonym = ref.watch(chosenHomonymIndexProvider(word));
  return homonyms == null || chosenHomonym >= homonyms.length
      ? null
      : homonyms[chosenHomonym];
});

final homonymPageProvider = FutureProvider.autoDispose
    .family<SearchPageData, Homonym?>((ref, homonym) async {
  if (homonym == null) return SearchPageData.empty;

  String content;
  try {
    content = await ref
        .read(pageProvider)
        .fetchPage(ref.read(linksProvider.notifier).wordDetails(homonym.id));
  } on FetchError catch (e) {
    final logger = Logger('HonomymPageProvider');
    logger.severe('Failed to request page', e);
    throw HomonymError('Failed to request page for $homonym');
  }
  return SonaveebParsers.parseSearchPage(content);
});

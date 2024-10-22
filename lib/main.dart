import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sonamobi/providers/night.dart';
import 'package:sonamobi/panel.dart';
import 'package:sonamobi/util/log_store.dart';

void main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((event) {
    logStore.addFromLogger(event);
  });
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logStore.addFromFlutter(details);
    };
    runApp(const ProviderScope(child: SonamobiApp()));
  }, (error, stack) {
    logStore.addFromZone(error, stack);
  });
}

class SonamobiApp extends ConsumerWidget {
  const SonamobiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sõnamobi',
      themeMode: ref.watch(nightModeProvider),
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WordPage(),
      // home: const TestFocusPage(),
    );
  }
}

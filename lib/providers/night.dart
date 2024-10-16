import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final nightModeProvider = StateNotifierProvider<NightModeNotifier, ThemeMode>(
    (_) => NightModeNotifier());

class NightModeNotifier extends StateNotifier<ThemeMode> {
  static final _kPrefsKey = 'night_mode';

  NightModeNotifier() : super(ThemeMode.system) {
    _read();
  }

  _read() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kPrefsKey);
    switch (saved) {
      case 0:
        state = ThemeMode.system;
      case 1:
        state = ThemeMode.light;
      case 2:
        state = ThemeMode.dark;
    }
  }

  _save() async {
    int value = 0;
    switch (state) {
      case ThemeMode.system:
        value = 0;
      case ThemeMode.light:
        value = 1;
      case ThemeMode.dark:
        value = 2;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefsKey, value);
  }

  next() {
    switch (state) {
      case ThemeMode.system:
        state = ThemeMode.light;
      case ThemeMode.light:
        state = ThemeMode.dark;
      case ThemeMode.dark:
        state = ThemeMode.system;
    }
    _save();
  }

  bool isDark(BuildContext? context) {
    switch (state) {
      case ThemeMode.system:
        return context == null
            ? false
            : MediaQuery.of(context).platformBrightness == Brightness.dark;
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
    }
  }
}

IconData nightModeIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return Icons.sunny_snowing;
    case ThemeMode.light:
      return Icons.sunny;
    case ThemeMode.dark:
      return Icons.dark_mode;
  }
}

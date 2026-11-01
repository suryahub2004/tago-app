import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.dark) {
    _init();
  }

  void _init() {
    if (Hive.isBoxOpen('settings')) {
      final isLight = Hive.box('settings').get('is_light_theme', defaultValue: false) as bool;
      state = isLight ? ThemeMode.light : ThemeMode.dark;
    }
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    if (Hive.isBoxOpen('settings')) {
      Hive.box('settings').put('is_light_theme', state == ThemeMode.light);
    }
  }
}

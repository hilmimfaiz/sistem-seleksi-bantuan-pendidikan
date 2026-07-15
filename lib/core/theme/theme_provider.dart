import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplikasi_finansialpendidikan/core/storage/secure_storage.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final themeString = await SecureStorageService.getThemeMode();
    if (themeString != null) {
      if (themeString == 'light') {
        state = ThemeMode.light;
      } else if (themeString == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    state = themeMode;
    String themeString = 'system';
    if (themeMode == ThemeMode.light) {
      themeString = 'light';
    } else if (themeMode == ThemeMode.dark) {
      themeString = 'dark';
    }
    await SecureStorageService.setThemeMode(themeString);
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else {
      await setTheme(ThemeMode.light);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

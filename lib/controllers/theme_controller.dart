import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const _themeModeKey = 'theme_mode';

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey);

    if (raw == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (raw == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    final nextMode = enabled ? ThemeMode.dark : ThemeMode.light;
    themeMode.value = nextMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, enabled ? 'dark' : 'light');
  }
}

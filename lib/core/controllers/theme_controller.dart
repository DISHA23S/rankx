import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final RxString language = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
    _loadLanguage();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode') ?? 'system';
      themeMode.value = _getThemeModeFromString(savedTheme);
      Get.changeThemeMode(themeMode.value);
    } catch (_) {
      // Use system default
      themeMode.value = ThemeMode.system;
    }
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      language.value = prefs.getString('language') ?? 'en';
    } catch (_) {
      language.value = 'en';
    }
  }

  ThemeMode _getThemeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', _getStringFromThemeMode(mode));
    } catch (_) {
      // Ignore error
    }
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setLanguage(String lang) async {
    language.value = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', lang);
    } catch (_) {
      // Ignore error
    }
  }

  bool get isDarkMode {
    if (themeMode.value == ThemeMode.system) {
      final context = Get.context;
      if (context == null) return false;
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return themeMode.value == ThemeMode.dark;
  }
}

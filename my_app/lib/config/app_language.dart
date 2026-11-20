import 'package:flutter/material.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('km');

  static String get current => languageNotifier.value;
  static bool get isKhmer => languageNotifier.value == 'km';
  static bool get isEnglish => languageNotifier.value == 'en';

  static Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final lang = sp.getString('APP_LANGUAGE') ?? 'km';
      languageNotifier.value = lang;
      MartService().getSettings().language = lang;
    } catch (_) {}
  }

  static Future<void> setLanguage(String lang) async {
    if (languageNotifier.value == lang) return;
    languageNotifier.value = lang;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('APP_LANGUAGE', lang);
      final settings = MartService().getSettings();
      settings.language = lang;
      await MartService().updateSettings(settings);
    } catch (_) {}
  }

  /// Dynamic greeting based on time of day and selected language
  static String greeting() {
    int hour = DateTime.now().hour;
    if (isEnglish) {
      if (hour < 12) return 'Good morning!';
      if (hour < 18) return 'Good afternoon!';
      return 'Good evening!';
    } else {
      if (hour < 12) return 'អរុណសួស្តី!';
      if (hour < 18) return 'ទិវាសួស្តី!';
      return 'សាយ័ណ្ហសួស្តី!';
    }
  }
}

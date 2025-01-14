import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;
  int _notificationTempo = 60;
  int get notifcationTempo => _notificationTempo;
  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String savedLocale = prefs.getString('selectedLanguage') ?? 'en';
    bool isDarkTheme = prefs.getBool('isDarkTheme') ?? false;

    _locale = Locale(savedLocale);
    _themeMode = isDarkTheme ? ThemeMode.dark : ThemeMode.light;
    _notificationTempo = prefs.getInt('notificationTempo') ?? 15;
    notifyListeners();
  }

  Future<void> updateLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', locale.languageCode);
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> updateNotificationTempo(int tempo) async {
    _notificationTempo = tempo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationTempo', _notificationTempo);
    notifyListeners();
  }
}

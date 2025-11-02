import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class AppStateManager extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.pastelYesil;
  bool _isDarkMode = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

  AppTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;

  AppStateManager() {
    _loadTheme();
    _loadDarkMode();
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? themeIndex = prefs.getInt('app_theme');
    if (themeIndex != null) {
      _currentTheme = AppTheme.values[themeIndex];
      notifyListeners();
    }
  }

  Future<void> _loadDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? savedDarkMode = prefs.getBool('is_dark_mode');
    if (savedDarkMode != null) {
      _isDarkMode = savedDarkMode;
      notifyListeners();
    }
  }

  Future<void> changeTheme(AppTheme theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme', theme.index);
    _currentTheme = theme;
    notifyListeners();
  }

  Future<void> changeDarkMode(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    _isDarkMode = isDark;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama geneli görünüm durumu. Tek palet var; yalnızca karanlık mod seçilir.
///
/// Eski sürümlerin kaydettiği `app_theme` (pastel tema) tercihi artık okunmaz.
class AppStateManager extends ChangeNotifier {
  bool _isDarkMode = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

  bool get isDarkMode => _isDarkMode;

  AppStateManager() {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? savedDarkMode = prefs.getBool('is_dark_mode');
    if (savedDarkMode != null) {
      _isDarkMode = savedDarkMode;
      notifyListeners();
    }
  }

  Future<void> changeDarkMode(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    _isDarkMode = isDark;
    notifyListeners();
  }
}

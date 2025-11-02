import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'managers/app_state_manager.dart';
import 'builders/app_theme_builder.dart';
import 'widgets/klasorler_with_theme.dart';
import 'screens/settings_page.dart';
 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateManager(),
      child: Consumer<AppStateManager>(
        builder: (context, appState, child) {
    return MaterialApp(
      title: 'Tarif Defteri',
      debugShowCheckedModeBanner: false,
            theme: AppThemeBuilder.buildLightTheme(appState.currentTheme),
            darkTheme: AppThemeBuilder.buildDarkTheme(appState.currentTheme),
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: KlasorlerWithTheme(
              onThemeChanged: appState.changeTheme,
              currentTheme: appState.currentTheme,
              isDarkMode: appState.isDarkMode,
              onDarkModeChanged: appState.changeDarkMode,
            ),
            routes: {
              '/settings': (context) => SettingsPage(
                onThemeChanged: appState.changeTheme,
                currentTheme: appState.currentTheme,
                isDarkMode: appState.isDarkMode,
                onDarkModeChanged: appState.changeDarkMode,
              ),
            },
          );
        },
      ),
    );
  }
}
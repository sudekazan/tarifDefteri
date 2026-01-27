import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'managers/app_state_manager.dart';
import 'builders/app_theme_builder.dart';
import 'widgets/klasorler_with_theme.dart';
import 'screens/settings_page.dart';

import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  
  // Reklamları yükle
  AdService.loadAppOpenAd();
  AdService.loadInterstitialAd();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
        Locale('pt'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('tr'),
      child: const MyApp(),
    ),
  );
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
            title: 'app_title'.tr(),
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
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          );
        },
      ),
    );
  }
}
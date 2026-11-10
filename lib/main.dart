import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'managers/app_state_manager.dart';
import 'builders/app_theme_builder.dart';
import 'sayfalar/ana_kabuk.dart';

import 'services/revenuecat_service.dart';
import 'services/review_service.dart';
import 'screens/update_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ekranlar dikey tasarlandı: telefon çevrilince yatay dönmesin. (iPad'de
  // çoklu görev desteği nedeniyle sistem bu kilidi uygulamaz; orada döner.)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await EasyLocalization.ensureInitialized();
  } catch (e) {
    debugPrint('EasyLocalization init error: $e');
  }

  // Değerlendirme isteğinin 7 günlük beklemesi ilk açılıştan sayılır.
  try {
    await ReviewService.ilkAcilisiKaydet();
  } catch (e) {
    debugPrint('İlk açılış tarihi kaydedilemedi: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    // serverClientId: Firebase Console'daki Web OAuth client ID'si.
    // Firebase idToken üretebilmesi için Android'de bu şart; Google
    // Sign-In SHA parmak izi eklendikten sonra google-services.json
    // yeniden indirilip buradan alındı.
    await GoogleSignIn.instance.initialize(
      serverClientId: '919442709959-k7ebgmegt80tccnqabphb3d0dd0coer4.apps.googleusercontent.com',
    );
  } catch (e) {
    debugPrint('GoogleSignIn init error: $e');
  }

  // Yavaş ağda açılış ekranında uzun süre takılı kalınmasın: RevenueCat en
  // fazla 6 sn beklenir; süre dolarsa kalan iş arka planda tamamlanır.
  try {
    await () async {
      await RevenueCatService.init();
      // Uygulama açılışında zaten giriş yapılmışsa RevenueCat kimliğini
      // Firebase UID'ye bağla (backend'in Pro durumunu kontrol edebilmesi için).
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await RevenueCatService.loginWithFirebaseUid(currentUser.uid);
      }
    }()
        .timeout(const Duration(seconds: 6));
  } catch (e) {
    debugPrint('RevenueCat init error/timeout: $e');
  }

  // Reklam SDK'sı, AB onay formu ve ATT izni artık ilk ekran çizildikten
  // sonra başlatılıyor (bkz. AdService.izinleriIsteVeReklamlariBaslat,
  // Klasorler.initState).

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
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Tek palet: temalar bir kez kurulur, karanlık mod değişince yeniden kurulmaz.
  static final ThemeData _acikTema = AppThemeBuilder.buildLightTheme();
  static final ThemeData _koyuTema = AppThemeBuilder.buildDarkTheme();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateManager(),
      child: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'app_title'.tr(),
            debugShowCheckedModeBanner: false,
            theme: _acikTema,
            darkTheme: _koyuTema,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: TarifDefteriUpgradeAlert(
              child: AnaKabuk(
                isDarkMode: appState.isDarkMode,
                onDarkModeChanged: appState.changeDarkMode,
              ),
            ),
            navigatorObservers: [AnaKabuk.rotaGozlemcisi],
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          );
        },
      ),
    );
  }
}
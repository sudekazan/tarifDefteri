// Mağaza ekran görüntüleri (App Store ve Google Play), Türkçe ve İngilizce.
//
// Gerçek sayfalar, gerçek tema ve fontlarla örnek verilerle çizilir; derleme
// ya da simülatör gerekmez. Normal `flutter test` bu klasörü çalıştırmaz:
//
//   flutter test test_driver/magaza_goruntuleri/magaza_goruntuleri_test.dart
//
// Görseller `build/magaza_goruntuleri/<dil>/<cihaz>/` altına yazılır.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Firebase'in kendi test taklidi (firebase_core ile birlikte gelir).
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/builders/app_theme_builder.dart';
import 'package:tarif_defteri/sayfalar/ana_kabuk.dart';
import 'package:tarif_defteri/sayfalar/klasor_ici.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';
import 'package:tarif_defteri/sayfalar/yemek_yapma_modu.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';
import 'package:tarif_defteri/utils/klasor_adi.dart';
import 'package:tarif_defteri/widgets/tarif_ekle_alt_sayfasi.dart';

import 'ornek_veriler.dart';

/// Mağaza cihaz boyutları (mantıksal nokta × ölçek = piksel).
class _Cihaz {
  const _Cihaz(this.ad, this.boyut, this.olcek, this.ustBosluk, this.altBosluk);
  final String ad;
  final Size boyut;
  final double olcek;
  final double ustBosluk;
  final double altBosluk;
}

// iPhone 6.9": 1320 × 2868. iPad 13": 2064 × 2752.
// Google Play telefon: 1080 × 2160 (en fazla 2:1).
const _iphone = _Cihaz('iphone_6.9', Size(440, 956), 3, 62, 34);
const _ipad = _Cihaz('ipad_13', Size(1032, 1376), 2, 24, 20);
const _android = _Cihaz('android', Size(360, 720), 3, 28, 16);

Future<void> _fontYukle(String aile, String yol) async {
  final yukleyici = FontLoader(aile)
    ..addFont(Future.value(ByteData.sublistView(File(yol).readAsBytesSync())));
  await yukleyici.load();
}

/// İkon fontu (Flutter SDK'dan), emoji ve durum çubuğu fontları (macOS'tan).
Future<void> _fontlariYukle() async {
  final kok = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final malzeme = '$kok/bin/cache/artifacts/material_fonts';
  await _fontYukle('MaterialIcons', '$malzeme/MaterialIcons-Regular.otf');
  await _fontYukle('Roboto', '$malzeme/Roboto-Medium.ttf');
  await _fontYukle('SFStatus', '/System/Library/Fonts/SFNS.ttf');
  await _fontYukle(
    'Apple Color Emoji',
    '/System/Library/Fonts/Apple Color Emoji.ttc',
  );
}

/// Telefonun üstündeki durum çubuğu (saat, sinyal, Wi-Fi, pil).
class _DurumCubugu extends StatelessWidget {
  const _DurumCubugu(this.cihaz);
  final _Cihaz cihaz;

  @override
  Widget build(BuildContext context) {
    // iPad'in durum çubuğu ince; Android'inki gibi ortalanır.
    final ios = cihaz != _android;
    final tablet = cihaz == _ipad;
    const renk = Color(0xFF1C1B1A);
    final yazi = TextStyle(
      fontFamily: ios ? 'SFStatus' : 'Roboto',
      fontSize: tablet ? 13 : (ios ? 17 : 14),
      fontWeight: FontWeight.w600,
      color: renk,
      decoration: TextDecoration.none,
    );
    return SizedBox(
      height: cihaz.ustBosluk,
      child: Padding(
        padding: tablet
            ? const EdgeInsets.symmetric(horizontal: 20)
            : EdgeInsets.fromLTRB(ios ? 52 : 18, ios ? 18 : 0, ios ? 36 : 14, 0),
        child: Row(
          crossAxisAlignment: ios && !tablet
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Text(ios ? '9:41' : '9:30', style: yazi),
            const Spacer(),
            if (!tablet) ...[
              Icon(Icons.signal_cellular_alt_rounded, size: ios ? 20 : 16, color: renk),
              const SizedBox(width: 5),
            ],
            Icon(Icons.wifi_rounded, size: tablet ? 16 : (ios ? 20 : 16), color: renk),
            const SizedBox(width: 5),
            Icon(
              ios ? Icons.battery_full_rounded : Icons.battery_full,
              size: tablet ? 20 : (ios ? 24 : 16),
              color: renk,
            ),
          ],
        ),
      ),
    );
  }
}

/// Firebase taklidi; depolama alanı adı verir ki `FirebaseStorage.instance`
/// hata vermesin. Hiçbir istek gerçekten gönderilmez (giriş yok).
class _SahteFirebase implements TestFirebaseCoreHostApi {
  CoreFirebaseOptions get _ayar => CoreFirebaseOptions(
        apiKey: 'test',
        projectId: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        storageBucket: 'test',
      );

  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async =>
      CoreInitializeResponse(
          name: appName, options: _ayar, pluginConstants: {});

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [
        CoreInitializeResponse(
          name: defaultFirebaseAppName,
          options: _ayar,
          pluginConstants: {},
        ),
      ];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async => _ayar;
}

/// Bir mağaza görseli: ana kabuk açılır, sonra [islem] ile istenen ekrana
/// gidilir (sekme seçilir ya da sayfa açılır).
class _Ekran {
  const _Ekran(this.ad, this.islem);
  final String ad;
  final Future<void> Function(
    WidgetTester tester,
    NavigatorState gezgin,
    OrnekVeriler veri,
  ) islem;
}

Future<void> _ac(NavigatorState gezgin, Widget sayfa) async {
  unawaited(gezgin.push(MaterialPageRoute<void>(builder: (_) => sayfa)));
}

Future<void> _sekme(WidgetTester tester, IconData ikon) async {
  await tester.tap(find.byIcon(ikon));
}

final _ekranlar = [
  _Ekran('01_defterim', (t, g, v) async {}),
  _Ekran('02_klasor', (t, g, v) => _ac(g, KlasorIci(klasorData: v.ilkKlasor))),
  _Ekran('03_tarif', (t, g, v) => _ac(g, TarifDetay(tarif: v.oneCikanTarif))),
  _Ekran('04_yemek_modu', (t, g, v) async {
    await _ac(g, YemekYapmaModu(tarif: v.oneCikanTarif));
    await _bekle(t);
    // İlk iki malzeme hazır işaretlensin.
    final malzemeler = v.klasorler.first.tarifler.first.malzemeler;
    for (final m in malzemeler.take(2)) {
      await t.tap(find.text(m).last);
      await t.pump();
    }
  }),
  _Ekran('05_ne_pisirsem', (t, g, v) async {
    await _sekme(t, Icons.soup_kitchen_outlined);
    await _bekle(t);
    // Birkaç popüler malzeme seçilsin.
    for (final anahtar in [
      'ingredient_egg',
      'ingredient_tomato',
      'ingredient_onion',
      'ingredient_cheese',
    ]) {
      final cip = find.text(anahtar.tr()).last;
      await t.ensureVisible(cip);
      await t.pump();
      await t.tap(cip, warnIfMissed: false);
      await t.pump();
    }
    // Sayfanın başına dön.
    await t.ensureVisible(find.text('what_to_cook_title'.tr()).first);
  }),
  _Ekran(
    '06_alisveris',
    (t, g, v) => _sekme(t, Icons.shopping_basket_outlined),
  ),
  // "Yeni tarif" alt sayfası: üç ekleme yolu. Giriş yapılmış gibi çizilir,
  // yoksa yapay zekâ seçeneği kilitli görünür.
  _Ekran('07_tarif_ekle', (t, g, v) async {
    unawaited(TarifEkleAltSayfasi.goster(
      t.element(find.byType(AnaKabuk)),
      klasorler: [for (final k in v.klasorler) v.klasorVerisi(k)],
      baslangicKlasoru: v.ilkKlasor,
      girisYapildi: true,
      klasorAdi: klasorGorunenAdi,
    ));
  }),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestFirebaseCoreHostApi.setUp(_SahteFirebase());
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await AppThemeBuilder.fontlariHazirla();
    await _fontlariYukle();
    RevenueCatService.proDurumuTest = true;
    _kanallariSustur();
  });

  for (final dil in OrnekVeriler.diller) {
    for (final cihaz in [_iphone, _ipad, _android]) {
      for (final ekran in _ekranlar) {
        testWidgets('$dil ${cihaz.ad} ${ekran.ad}', (tester) async {
          await _ciz(tester, dil, cihaz, ekran);
        });
      }
    }
  }
}

/// Sayfaların açılışta seslendiği yerel eklentiler (reklam onayı, link
/// dinleme, Firebase giriş dinleyicileri) testte yok; boş yanıt verilir.
void _kanallariSustur() {
  final m = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;
  for (final kanal in [
    'com.llfbandit.app_links/events',
    'com.llfbandit.app_links/messages',
    'plugins.flutter.io/google_mobile_ads/ump',
    'plugins.flutter.io/google_mobile_ads',
    'app_tracking_transparency',
    'sahte_dinleyici',
  ]) {
    // Bazı eklentilerin kendi kodlayıcısı var; ham "başarılı, boş" yanıtı
    // hepsinde aynı.
    m.setMockMessageHandler(
      kanal,
      (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
  }
  const pigeon = 'dev.flutter.pigeon.firebase_auth_platform_interface'
      '.FirebaseAuthHostApi';
  for (final ad in ['registerIdTokenListener', 'registerAuthStateListener']) {
    m.setMockMessageHandler(
      '$pigeon.$ad',
      (_) async => const StandardMessageCodec()
          .encodeMessage(<Object?>['sahte_dinleyici']),
    );
  }
  // Yemek modunda ekran açık tutulur; pigeon "boş, başarılı" yanıtı.
  m.setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (_) async => const StandardMessageCodec().encodeMessage(<Object?>[]),
  );
}

final _sinir = GlobalKey();

/// Uygulamanın teması; testte yedek font kendiliğinden seçilmediği için
/// emojiler Apple emoji fontuna yönlendirilir.
final _tema = () {
  final t = AppThemeBuilder.buildLightTheme();
  const yedek = ['Apple Color Emoji'];
  return t.copyWith(
    textTheme: t.textTheme.apply(fontFamilyFallback: yedek),
    primaryTextTheme: t.primaryTextTheme.apply(fontFamilyFallback: yedek),
  );
}();
final _gezgin = GlobalKey<NavigatorState>();

Future<void> _bekle(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}

Future<void> _ciz(
  WidgetTester tester,
  String dil,
  _Cihaz cihaz,
  _Ekran ekran,
) async {
  final veri = OrnekVeriler.dil(dil);
  SharedPreferences.setMockInitialValues(veri.tercihler());

  tester.view.physicalSize = cihaz.boyut * cihaz.olcek;
  tester.view.devicePixelRatio = cihaz.olcek;
  tester.view.padding = FakeViewPadding(
    top: cihaz.ustBosluk * cihaz.olcek,
    bottom: cihaz.altBosluk * cihaz.olcek,
  );
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: [for (final d in OrnekVeriler.diller) Locale(d)],
        path: 'assets/lang',
        fallbackLocale: const Locale('en'),
        startLocale: Locale(dil),
        saveLocale: false,
        child: Builder(
          builder: (context) => RepaintBoundary(
            key: _sinir,
            child: MaterialApp(
              navigatorKey: _gezgin,
              debugShowCheckedModeBanner: false,
              theme: _tema,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              builder: (context, cocuk) => Stack(
                children: [
                  cocuk!,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(child: _DurumCubugu(cihaz)),
                  ),
                ],
              ),
              home: AnaKabuk(isDarkMode: false, onDarkModeChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
  });
  await _bekle(tester);
  await ekran.islem(tester, _gezgin.currentState!, veri);
  await _bekle(tester);
  // Sayfa geçiş animasyonu bitsin.
  await tester.pump(const Duration(seconds: 1));
  await _bekle(tester);

  final sinir =
      _sinir.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final png = await tester.runAsync(() async {
    final goruntu = await sinir.toImage(pixelRatio: cihaz.olcek);
    final bayt = await goruntu.toByteData(format: ui.ImageByteFormat.png);
    return bayt!.buffer.asUint8List();
  });
  final dosya =
      File('build/magaza_goruntuleri/$dil/${cihaz.ad}/${ekran.ad}.png');
  dosya.parent.createSync(recursive: true);
  dosya.writeAsBytesSync(png!);

  // Zamanlayıcılar ve animasyonlar kapansın.
  await tester.pumpWidget(const SizedBox());
}

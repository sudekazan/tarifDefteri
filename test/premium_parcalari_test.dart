import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
// Çeviriyi EasyLocalization sarmalayıcısı olmadan yüklemek için.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tarif_defteri/sayfalar/premium_sayfasi.dart';
import 'package:tarif_defteri/services/analytics_service.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/premium_parcalari.dart';

void _ekran(WidgetTester tester, double genislik, [double yukseklik = 800]) {
  tester.view.physicalSize = Size(genislik, yukseklik);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _sar(
  Widget child, {
  double yaziOlcegi = 1,
  KilRenkleri renkler = KilRenkleri.acik,
}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: renkler.sertGolge ? Brightness.light : Brightness.dark,
      extensions: [renkler],
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(yaziOlcegi)),
      child: child!,
    ),
    home: child,
  );
}

// Test verisi: fiyatlar uygulamada RevenueCat'ten gelir; bunlar yalnızca
// testteki sahte paketler.
const _baglam = PresentedOfferingContext('test', null, null);

Package _paket(String id, PackageType tur, double fiyat) => Package(
      id,
      tur,
      StoreProduct('urun_$id', '', id, fiyat, '$fiyat TL', 'TRY'),
      _baglam,
    );

final _paketler = [
  _paket('omur', PackageType.lifetime, 250),
  _paket('yillik', PackageType.annual, 100),
  _paket('aylik', PackageType.monthly, 10),
];

Future<List<Offering>> _sahtePaketler() async =>
    [Offering('test', '', const {}, _paketler)];

void main() {
  late List<String> olaylar;

  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
    final tr = json.decode(File('assets/lang/tr.json').readAsStringSync())
        as Map<String, dynamic>;
    Localization.load(const Locale('tr'), translations: Translations(tr));
  });

  setUp(() {
    olaylar = [];
    AnalyticsService.testLogger = (name, params) async => olaylar.add(name);
    PremiumSayfasi.paketGetir = _sahtePaketler;
    // Testte mağaza yok: RevenueCat'e giden her çağrı hata döner.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('purchases_flutter'),
      (call) async => throw PlatformException(code: '2'),
    );
  });

  tearDown(() {
    AnalyticsService.testLogger = null;
    PremiumSayfasi.paketGetir = RevenueCatService.getOfferings;
    RevenueCatService.lastOfferingsError = null;
  });

  group('Plan kartı', () {
    testWidgets('en az 72 yükseklik, dokununca seçer, ekran okuyucu seçimi okur',
        (tester) async {
      final handle = tester.ensureSemantics();
      var dokunuldu = 0;
      await tester.pumpWidget(_sar(Scaffold(
        body: PremiumPlanKarti(
          baslik: 'Yıllık',
          aciklama: 'Açıklama',
          fiyat: '100 TL',
          secili: true,
          rozet: 'EN AVANTAJLI',
          onTap: () => dokunuldu++,
        ),
      )));

      final boy = tester.getSize(find.byType(PremiumPlanKarti));
      expect(boy.height, greaterThanOrEqualTo(PremiumPlanKarti.enKucukYukseklik));
      await tester.tap(find.byType(PremiumPlanKarti));
      expect(dokunuldu, 1);

      final anlam = tester.getSemantics(find.byType(PremiumPlanKarti));
      expect(
        anlam,
        matchesSemantics(
          label: 'Yıllık, EN AVANTAJLI, Açıklama, 100 TL',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('büyük yazıda fiyat başlığın altına iner', (tester) async {
      _ekran(tester, 320, 1600);
      await tester.pumpWidget(_sar(
        const Scaffold(
          body: SingleChildScrollView(
            child: PremiumPlanKarti(
              baslik: 'Yıllık',
              aciklama: 'Açıklama',
              fiyat: '100 TL',
              secili: false,
              onTap: null,
            ),
          ),
        ),
        yaziOlcegi: 3.2,
      ));
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('100 TL')).dy,
        greaterThan(tester.getBottomLeft(find.text('Yıllık')).dy),
      );
    });
  });

  testWidgets('üst satır ve yasal bağlantılar 48 dokunma alanlı',
      (tester) async {
    await tester.pumpWidget(_sar(Scaffold(
      body: ListView(
        children: [
          PremiumUstSatiri(
            kapatEtiketi: 'Kapat',
            onKapat: () {},
            geriYukleEtiketi: 'Geri Yükle',
            onGeriYukle: () {},
          ),
          PremiumKosullarKarti(
            baslik: 'Koşullar',
            metin: 'Metin',
            baglantilar: [
              PremiumBaglanti(etiket: 'Kullanım', onTap: () {}),
              PremiumBaglanti(etiket: 'Gizlilik', onTap: () {}),
            ],
          ),
        ],
      ),
    )));

    expect(
      tester.getSize(find.byType(KilYuvarlakDugme)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byType(KilDugme)).height,
      greaterThanOrEqualTo(48),
    );
    for (final ad in ['Kullanım', 'Gizlilik']) {
      final kutu = find.ancestor(of: find.text(ad), matching: find.byType(InkWell));
      expect(tester.getSize(kutu).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(kutu).width, greaterThanOrEqualTo(48));
    }
  });

  group('Pro\'ya geç kartı', () {
    testWidgets('dokununca açar, aktifken dokunulmaz', (tester) async {
      var dokunuldu = 0;
      await tester.pumpWidget(_sar(Scaffold(
        body: Column(
          children: [
            ProyaGecKarti(
              baslik: 'Premium\'a Geç',
              aciklama: 'Reklamsız',
              onTap: () => dokunuldu++,
            ),
            const ProyaGecKarti(
              baslik: 'Premium Aktif',
              aciklama: 'Kilidi açık',
              aktif: true,
            ),
          ],
        ),
      )));
      await tester.tap(find.text('Premium\'a Geç'));
      expect(dokunuldu, 1);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(
        find.ancestor(of: find.text('Premium Aktif'), matching: find.byType(InkWell)),
        findsNothing,
      );
    });
  });

  group('Premium sayfası', () {
    testWidgets('planlar aylık, yıllık, ömür boyu sırasında; yıllık seçili',
        (tester) async {
      _ekran(tester, 402, 3000);
      await tester.pumpWidget(_sar(const PremiumSayfasi(source: 'test')));
      await tester.pumpAndSettle();

      expect(olaylar, ['paywall_goruldu']);
      final kartlar = tester
          .widgetList<PremiumPlanKarti>(find.byType(PremiumPlanKarti))
          .toList();
      expect(kartlar.map((k) => k.baslik), [
        'premium_plan_monthly_title'.tr(),
        'premium_plan_annual_title'.tr(),
        'premium_plan_lifetime_title'.tr(),
      ]);
      expect(kartlar.map((k) => k.secili), [false, true, false]);
      expect(kartlar[1].rozet, 'premium_badge_most_popular'.tr());
      expect(
        kartlar[1].aciklama,
        'premium_plan_annual_desc_with_savings'.tr(args: ['17']),
      );
      // Fiyat metinleri mağazadan geldiği gibi.
      expect(kartlar.map((k) => k.fiyat), ['10.0 TL', '100.0 TL', '250.0 TL']);

      // Seçim değişince koşul metni de seçili plana geçer.
      expect(find.textContaining('100.0 TL / yıl'), findsOneWidget);
      await tester.tap(find.text('premium_plan_monthly_title'.tr()));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<PremiumPlanKarti>(find.byType(PremiumPlanKarti))
            .map((k) => k.secili),
        [true, false, false],
      );
      expect(find.textContaining('10.0 TL / ay'), findsOneWidget);
      expect(find.text('premium_cta_button'.tr()), findsOneWidget);
    });

    testWidgets('kapatınca paywall_kapatildi gider', (tester) async {
      _ekran(tester, 402, 1200);
      await tester.pumpWidget(_sar(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumSayfasi(source: 'test')),
            ),
            child: const Text('aç'),
          ),
        ),
      )));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(KilYuvarlakDugme));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumSayfasi), findsNothing);
      expect(olaylar, ['paywall_goruldu', 'paywall_kapatildi']);
    });

    testWidgets('paket yoksa yedek kart ve hata satırı çıkar', (tester) async {
      _ekran(tester, 402, 3000);
      PremiumSayfasi.paketGetir = () async {
        RevenueCatService.lastOfferingsError = 'Paket yok';
        return [];
      };
      await tester.pumpWidget(_sar(const PremiumSayfasi(source: 'test')));
      await tester.pumpAndSettle();

      expect(find.text('premium_fallback_package_title'.tr()), findsOneWidget);
      expect(find.text('premium_price_unavailable'.tr()), findsOneWidget);
      expect(find.byType(PremiumHataSatiri), findsOneWidget);
      await tester.tap(find.byType(PremiumHataSatiri));
      await tester.pumpAndSettle();
      expect(find.text('premium_package_error_title'.tr()), findsOneWidget);
      await tester.tap(find.text('common_ok'.tr()));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('geri yükleme bulunamazsa hata bildirimi çıkar', (tester) async {
      _ekran(tester, 402, 1200);
      await tester.pumpWidget(_sar(const PremiumSayfasi(source: 'test')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('premium_restore'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('premium_restore_failed'.tr()), findsOneWidget);
      expect(find.byType(PremiumSayfasi), findsOneWidget);
    });

    for (final koyu in [false, true]) {
      for (final olcek in [1.0, 3.2]) {
        for (final paketli in [true, false]) {
          final ad = '${koyu ? 'koyu' : 'açık'}, 320 genişlik, $olcek kat yazı, '
              '${paketli ? 'paketli' : 'paketsiz'}';
          testWidgets('taşma yok: $ad', (tester) async {
            _ekran(tester, 320, 640);
            if (!paketli) {
              PremiumSayfasi.paketGetir = () async {
                RevenueCatService.lastOfferingsError = 'Paket yok';
                return [];
              };
            }
            await tester.pumpWidget(_sar(
              const PremiumSayfasi(source: 'test'),
              yaziOlcegi: olcek,
              renkler: koyu ? KilRenkleri.koyu : KilRenkleri.acik,
            ));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            // Sona kadar kaydır; her parça kurulup çizilsin.
            await tester.scrollUntilVisible(
              find.text('premium_restore_purchases'.tr()),
              300,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  test('kullanılan metinler altı dilde var', () {
    const anahtarlar = [
      'premium_badge_pro',
      'premium_headline',
      'premium_subtitle',
      'premium_restore',
      'premium_cta_button',
      'premium_cancel_anytime',
      'premium_sub_terms_title',
      'premium_terms_of_use',
      'premium_privacy_policy',
      'premium_restore_purchases',
      'premium_badge_most_popular',
      'settings_premium_get_title',
      'settings_premium_get_subtitle',
      'settings_premium_active_title',
      'settings_premium_active_subtitle',
    ];
    for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      final m = json.decode(File('assets/lang/$dil.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final a in anahtarlar) {
        expect(m[a], isA<String>(), reason: '$dil: $a');
      }
    }
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
// Çeviriyi EasyLocalization sarmalayıcısı olmadan yüklemek için.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/sayfalar/bugun_ne_pisisem_sayfasi.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/widgets/ai_chef_loading_animation.dart';
import 'package:tarif_defteri/widgets/ai_hak_doldu_dialog.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/ne_pisirsem_parcalari.dart';

/// Test ekranını gerçekten [genislik] x [yukseklik] yapar.
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

/// Klasör listesini cihaz kaydına (SharedPreferences) yazar.
void _klasorler(List<KlasorData> klasorler) {
  SharedPreferences.setMockInitialValues({
    'klasorler': [for (final k in klasorler) json.encode(k.toMap())],
  });
}

void main() {
  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
    // Sayfa testlerinde gerçek Türkçe metinler (taşma denemesi gerçekçi olsun).
    final tr =
        json.decode(File('assets/lang/tr.json').readAsStringSync())
            as Map<String, dynamic>;
    Localization.load(const Locale('tr'), translations: Translations(tr));
  });

  group('Lottie renkleri', () {
    test('paletin dışındaki renkler kil renklerine eşlenir', () {
      const r = KilRenkleri.acik;
      final esleme = {0x58357C: r.birincilGolge, 0xF59798: r.vurgu};
      // Mor tava → terrakota, saydamlık korunur.
      expect(
        AiChefLoadingAnimation.eslenmisRenk(const Color(0x8058357C), esleme),
        r.birincilGolge.withValues(alpha: const Color(0x80000000).a),
      );
      // ±2 yuvarlama payı.
      expect(
        AiChefLoadingAnimation.eslenmisRenk(const Color(0xFFF69899), esleme),
        r.vurgu,
      );
      // Alev rengi (eşlemede yok) olduğu gibi kalır.
      expect(
        AiChefLoadingAnimation.eslenmisRenk(const Color(0xFFF46363), esleme),
        const Color(0xFFF46363),
      );
    });

    for (final koyu in [false, true]) {
      testWidgets(
        '${koyu ? 'koyu' : 'açık'} modda animasyon açılır, beyaz arka plan '
        'kart rengine boyanır',
        (tester) async {
          final r = koyu ? KilRenkleri.koyu : KilRenkleri.acik;
          final anahtar = GlobalKey();
          await tester.pumpWidget(
            _sar(
              Center(
                child: RepaintBoundary(
                  key: anahtar,
                  child: const SizedBox(
                    width: 375,
                    height: 216,
                    child: AiChefLoadingAnimation(
                      title: 'Şef hazırlıyor',
                      messages: ['Adım 1', 'Adım 2'],
                    ),
                  ),
                ),
              ),
              renkler: r,
            ),
          );
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(seconds: 2)),
          );
          await tester.pump();
          expect(
            find.byIcon(Icons.restaurant_rounded),
            findsNothing,
            reason: 'Animasyon açılamazsa yedek ikon gösterilir',
          );

          // Animasyonun sol üst köşesi (yalnızca arka plan) kart renginde.
          final sinir = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(anahtar),
          );
          final goruntu = await tester.runAsync(() => sinir.toImage());
          final veri = await tester.runAsync(() => goruntu!.toByteData());
          // Animasyon 220 genişlikte ortalı: x = 77..297, y = 0..127.
          final konum = (4 * 375 + 82) * 4;
          final piksel = Color.fromARGB(
            veri!.getUint8(konum + 3),
            veri.getUint8(konum),
            veri.getUint8(konum + 1),
            veri.getUint8(konum + 2),
          );
          expect(piksel, r.kart);

          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  });

  group('Parçalar', () {
    testWidgets('seçili malzeme çipi 48 yüksek, ekran okuyucuyla kaldırılır', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      var kaldirildi = 0;
      await tester.pumpWidget(
        _sar(
          Scaffold(
            body: Center(
              child: SeciliMalzemeCipi(
                malzeme: 'Yumurta',
                kaldirIpucu: 'Sil',
                onKaldir: () => kaldirildi++,
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(SeciliMalzemeCipi)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(find.byType(SeciliMalzemeCipi)),
        matchesSemantics(
          label: 'Yumurta',
          hint: 'Sil',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text('Yumurta'));
      expect(kaldirildi, 1);
      semantik.dispose();
    });

    testWidgets('hak kartının düğmesi en az 48x48', (tester) async {
      var acildi = false;
      await tester.pumpWidget(
        _sar(
          Scaffold(
            body: NePisirsemHakKarti(
              metin: 'Kalan Günlük Şef Hakkınız: 3 / 3',
              pro: false,
              eylemEtiketi: 'Daha Fazla Hak',
              onEylem: () => acildi = true,
            ),
          ),
        ),
      );
      final dugme = tester.getSize(find.byType(TextButton));
      expect(dugme.height, greaterThanOrEqualTo(48));
      expect(dugme.width, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Daha Fazla Hak'));
      expect(acildi, isTrue);
    });

    testWidgets('büyük yazıda ekleme düğmesi kutunun altına iner', (
      tester,
    ) async {
      _ekran(tester, 320);
      final kontrol = TextEditingController();
      addTearDown(kontrol.dispose);
      for (final olcek in [1.0, 3.2]) {
        await tester.pumpWidget(
          _sar(
            Scaffold(
              body: MalzemeEklemeSatiri(
                controller: kontrol,
                ipucu: 'Farklı malzeme ekle',
                ekleEtiketi: 'Ekle',
                onEkle: (_) {},
              ),
            ),
            yaziOlcegi: olcek,
          ),
        );
        final kutu = tester.getRect(find.byType(TextField));
        final dugme = tester.getRect(find.byType(KilDugme));
        if (olcek == 1) {
          expect(dugme.left, greaterThan(kutu.right));
        } else {
          expect(dugme.top, greaterThan(kutu.bottom));
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('bekleme katmanı alttaki sayfaya dokunmayı engeller', (
      tester,
    ) async {
      var dokunuldu = false;
      await tester.pumpWidget(
        _sar(
          Scaffold(
            body: Stack(
              children: [
                Center(
                  child: TextButton(
                    onPressed: () => dokunuldu = true,
                    child: const Text('alttaki'),
                  ),
                ),
                const Positioned.fill(
                  child: AiBeklemeKatmani(
                    baslik: 'Şef dolabı inceliyor',
                    mesajlar: ['Malzemeler taranıyor'],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('alttaki'), warnIfMissed: false);
      expect(dokunuldu, isFalse);
      expect(find.text('Şef dolabı inceliyor'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('+1 hak diyaloğu seçimi döndürür, düğmeler 48', (tester) async {
      AiHakDolduSecim? secim;
      await tester.pumpWidget(
        _sar(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async =>
                      secim = await aiHakDolduDialogGoster(context),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      for (final d in tester.widgetList<KilDugme>(find.byType(KilDugme))) {
        expect(
          tester.getSize(find.byWidget(d)).height,
          greaterThanOrEqualTo(48),
        );
      }
      await tester.tap(find.text('ai_limit_choice_watch_ad'.tr()));
      await tester.pumpAndSettle();
      expect(secim, AiHakDolduSecim.reklamIzle);
    });

    for (final koyu in [false, true]) {
      testWidgets(
        '+1 hak diyaloğu ${koyu ? 'koyu' : 'açık'} modda 320 genişlik ve '
        '3.2 kat yazıda taşmaz',
        (tester) async {
          _ekran(tester, 320, 640);
          await tester.pumpWidget(
            _sar(
              Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => aiHakDolduDialogGoster(context),
                      child: const Text('aç'),
                    ),
                  ),
                ),
              ),
              yaziOlcegi: 3.2,
              renkler: koyu ? KilRenkleri.koyu : KilRenkleri.acik,
            ),
          );
          await tester.tap(find.text('aç'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Sayfa', () {
    final klasorler = [
      KlasorData(klasor_id: 11, klasor_adi: 'Akşam yemekleri'),
      KlasorData(klasor_id: 12, klasor_adi: 'Pratik'),
    ];

    testWidgets('popüler malzeme seçilir, kaldırılır ve temizlenir', (
      tester,
    ) async {
      _klasorler(klasorler);
      await tester.pumpWidget(_sar(const BugunNePisisemSayfasi()));
      await tester.pumpAndSettle();

      expect(find.text('what_to_cook_selected_empty'.tr()), findsOneWidget);
      final yumurta = 'ingredient_egg'.tr();
      final cip = find.widgetWithText(KilCip, yumurta);
      await tester.ensureVisible(cip);
      await tester.tap(cip);
      await tester.pump();
      expect(find.widgetWithText(SeciliMalzemeCipi, yumurta), findsOneWidget);
      expect(
        find.text('what_to_cook_selected_ingredients_count'.tr(args: ['1'])),
        findsOneWidget,
      );

      // Seçili çipe dokununca çıkar.
      final secili = find.widgetWithText(SeciliMalzemeCipi, yumurta);
      await tester.ensureVisible(secili);
      await tester.tap(secili);
      await tester.pump();
      expect(find.byType(SeciliMalzemeCipi), findsNothing);

      // Elle ekleme ve temizle.
      await tester.enterText(find.byType(TextField), 'fesleğen');
      final ekle = find.text('what_to_cook_add_btn'.tr());
      await tester.ensureVisible(ekle);
      await tester.tap(ekle);
      await tester.pump();
      expect(
        find.widgetWithText(SeciliMalzemeCipi, 'fesleğen'),
        findsOneWidget,
      );
      final temizle = find.text('common_clear'.tr());
      await tester.ensureVisible(temizle);
      expect(
        tester
            .getSize(
              find.ancestor(of: temizle, matching: find.byType(TextButton)),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(temizle);
      await tester.pump();
      expect(find.byType(SeciliMalzemeCipi), findsNothing);
    });

    testWidgets('öğün tek seçilir, klasör alt sayfadan değişir', (
      tester,
    ) async {
      _klasorler(klasorler);
      await tester.pumpWidget(_sar(const BugunNePisisemSayfasi()));
      await tester.pumpAndSettle();

      final tatli = find.widgetWithText(
        KilCip,
        'what_to_cook_meal_dessert'.tr(),
      );
      await tester.ensureVisible(tatli);
      await tester.tap(tatli);
      await tester.pump();
      expect(tester.widget<KilCip>(tatli).secili, isTrue);
      expect(
        tester
            .widget<KilCip>(
              // "Fark Etmez" süre seçeneklerinde de var; ilki öğün.
              find.widgetWithText(KilCip, 'what_to_cook_meal_any'.tr()).first,
            )
            .secili,
        isFalse,
      );

      final kutu = find.byType(KlasorSecimKutusu);
      await tester.ensureVisible(kutu);
      expect(
        find.descendant(of: kutu, matching: find.text('Akşam yemekleri')),
        findsOneWidget,
      );
      await tester.tap(kutu);
      await tester.pumpAndSettle();
      expect(find.byType(KilSecimListesi), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(KilSecimListesi),
          matching: find.text('Pratik'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KilSecimListesi), findsNothing);
      expect(
        find.descendant(of: kutu, matching: find.text('Pratik')),
        findsOneWidget,
      );
    });

    testWidgets('malzeme seçmeden tarif istenince uyarı çıkar', (tester) async {
      _klasorler(klasorler);
      await tester.pumpWidget(_sar(const BugunNePisisemSayfasi()));
      await tester.pumpAndSettle();
      final dugme = find.text('what_to_cook_generate_btn'.tr());
      await tester.ensureVisible(dugme);
      await tester.tap(dugme);
      await tester.pump();
      expect(
        find.text('what_to_cook_no_ingredients_warning'.tr()),
        findsOneWidget,
      );
    });

    testWidgets('sekmedeyken geri düğmesi yok, başlık ekran okuyucuda başlık', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      _klasorler(const []);
      await tester.pumpWidget(_sar(const BugunNePisisemSayfasi()));
      await tester.pumpAndSettle();
      expect(find.byType(KilYuvarlakDugme), findsNothing);
      expect(
        tester.getSemantics(find.text('what_to_cook_title'.tr())),
        isSemantics(label: 'what_to_cook_title'.tr(), isHeader: true),
      );
      // Klasör yokken klasör seçici gösterilmez (eskisi gibi).
      expect(find.byType(KlasorSecimKutusu), findsNothing);
      semantik.dispose();
    });

    for (final koyu in [false, true]) {
      for (final olcek in [1.0, 3.2]) {
        testWidgets(
          '${koyu ? 'koyu' : 'açık'} modda 320 genişlik, $olcek kat yazıda '
          'taşma yok',
          (tester) async {
            _ekran(tester, 320, 640);
            _klasorler(klasorler);
            await tester.pumpWidget(
              _sar(
                const BugunNePisisemSayfasi(),
                yaziOlcegi: olcek,
                renkler: koyu ? KilRenkleri.koyu : KilRenkleri.acik,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            // Birkaç malzeme seçip sayfanın sonuna kadar kaydır.
            for (final m in ['ingredient_egg', 'ingredient_tomato_paste']) {
              final cip = find.widgetWithText(KilCip, m.tr());
              await tester.ensureVisible(cip);
              await tester.tap(cip);
              await tester.pump();
            }
            final dugme = find.text('what_to_cook_generate_btn'.tr());
            await tester.ensureVisible(dugme);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  test('kullanılan metinler altı dilde var', () {
    const anahtarlar = [
      'what_to_cook_title',
      'what_to_cook_subtitle',
      'what_to_cook_hero_badge',
      'what_to_cook_limit_badge_pro',
      'what_to_cook_limit_badge_free',
      'what_to_cook_make_unlimited',
      'what_to_cook_selected_ingredients_count',
      'what_to_cook_selected_empty',
      'what_to_cook_custom_hint',
      'what_to_cook_add_btn',
      'what_to_cook_popular_title',
      'what_to_cook_meal_type',
      'what_to_cook_time_type',
      'what_to_cook_select_folder',
      'what_to_cook_generate_btn',
      'what_to_cook_loading_title',
      'common_clear',
      'home_pro_badge',
      'premium_title',
      'ai_limit_choice_title',
      'ai_limit_choice_body',
      'ai_limit_choice_watch_ad',
      'ai_limit_choice_go_pro',
      'common_later',
    ];
    for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      final metinler =
          json.decode(File('assets/lang/$dil.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final a in anahtarlar) {
        expect(metinler[a], isA<String>(), reason: '$dil: $a eksik');
      }
    }
  });
}

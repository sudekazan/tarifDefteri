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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/sayfalar/yemek_yapma_modu.dart';
import 'package:tarif_defteri/services/analytics_service.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/yemek_modu_parcalari.dart';

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

/// Ekranı açık tutma eklentisinin (wakelock_plus) Pigeon kanalını taklit eder
/// ve gelen açma/kapama isteklerini sırayla [kayit]'a yazar.
class _WakelockKodlayici extends StandardMessageCodec {
  const _WakelockKodlayici();

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) =>
      type == 129 || type == 130
      ? readValue(buffer)
      : super.readValueOfType(type, buffer);
}

const _wakelockKanali =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

void _wakelockTaklidi(List<bool> kayit) {
  const kodlayici = _WakelockKodlayici();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(_wakelockKanali, (mesaj) async {
        final istek = kodlayici.decodeMessage(mesaj) as List<Object?>;
        final toggle = istek.first as List<Object?>;
        kayit.add(toggle.first as bool);
        return kodlayici.encodeMessage(<Object?>[]);
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(_wakelockKanali, null),
  );
}

TarifData _tarif({bool bos = false}) => TarifData(
  tarif_id: 3,
  tarif_adi: 'Fırında karnıyarık',
  tarif_aciklama: bos ? '' : 'x',
  tarif_aciklama_json: bos
      ? null
      : json.encode([
          {
            'type': 'malzemeler',
            'items': ['4 adet patlıcan', '250 gr kıyma', '1 adet soğan'],
          },
          {
            'type': 'yapilis',
            'items': [
              'Patlıcanları alacalı soyup tuzlu suda bekletin.',
              'Kıymayı soğanla kavurup patlıcanlara doldurun, fırında 25 dakika pişirin.',
            ],
          },
        ]),
  tarif_resimler: const [],
  klasor_id: 1,
);

void main() {
  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
  });

  /// Sayfa testlerinde gerçek Türkçe metinler (taşma denemesi gerçekçi olsun).
  void turkce() {
    final tr =
        json.decode(File('assets/lang/tr.json').readAsStringSync())
            as Map<String, dynamic>;
    Localization.load(const Locale('tr'), translations: Translations(tr));
  }

  group('Parçalar', () {
    testWidgets('malzeme satırı en az 64, dokununca işaretlenir', (
      tester,
    ) async {
      var secili = false;
      await tester.pumpWidget(
        _sar(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: YemekMalzemeSatiri(
                metin: '2 adet patlıcan',
                secili: secili,
                onTap: () => setState(() => secili = !secili),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(YemekMalzemeSatiri)).height,
        greaterThanOrEqualTo(yemekMalzemeSatirYuksekligi),
      );
      expect(
        tester.getSemantics(find.byType(YemekMalzemeSatiri)),
        matchesSemantics(
          label: '2 adet patlıcan',
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      await tester.tap(find.text('2 adet patlıcan'));
      await tester.pumpAndSettle();
      expect(secili, isTrue);
      final yazi = tester.widget<Text>(find.text('2 adet patlıcan'));
      expect(yazi.style?.decoration, TextDecoration.lineThrough);
      expect(yazi.style?.fontSize, yemekMalzemeYaziBoyutu);
    });

    testWidgets('özet: hepsi hazırsa onay işareti', (tester) async {
      await tester.pumpWidget(
        _sar(
          const Scaffold(
            body: YemekMalzemeOzeti(
              baslik: 'Malzemeler',
              hazirMetni: 'hazır',
              hazir: 3,
              toplam: 3,
            ),
          ),
        ),
      );
      expect(find.text('3 / 3 hazır'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('alt çubuk: düğmeler en az 56, ilk sayfada "Önceki" yok', (
      tester,
    ) async {
      var ileri = 0;
      var geri = 0;
      Widget cubuk({required bool ilk, required bool son}) => _sar(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: YemekModuAltCubuk(
              oncekiEtiketi: 'Önceki',
              ileriEtiketi: son ? 'Tamamla' : 'Sonraki Adım',
              sonSayfa: son,
              onOnceki: ilk ? null : () => geri++,
              onIleri: () => ileri++,
            ),
          ),
        ),
      );

      await tester.pumpWidget(cubuk(ilk: true, son: false));
      expect(find.text('Önceki'), findsNothing);
      await tester.tap(find.text('Sonraki Adım'));
      await tester.pumpAndSettle();
      expect(ileri, 1);

      await tester.pumpWidget(cubuk(ilk: false, son: true));
      await tester.pumpAndSettle();
      for (final d in tester.widgetList<KilDugme>(find.byType(KilDugme))) {
        expect(d.buyuk, isTrue);
      }
      for (final e in find.byType(KilDugme).evaluate()) {
        expect(
          e.size!.height,
          greaterThanOrEqualTo(
            KilDugme.buyukYukseklik + KilDugme.golgeYuksekligi,
          ),
        );
      }
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.tap(find.text('Önceki'));
      await tester.pumpAndSettle();
      expect(geri, 1);
    });

    testWidgets(
      'büyük yazıda "Malzemeler" yuvarlak düğme, alt düğmeler alt alta',
      (tester) async {
        _ekran(tester, 320);
        await tester.pumpWidget(
          _sar(
            yaziOlcegi: 3.2,
            Scaffold(
              body: Column(
                children: [
                  YemekModuBasligi(
                    baslik: 'Fırında karnıyarık',
                    malzemeEtiketi: 'Malzemeler',
                    onMalzemeler: () {},
                  ),
                  const Spacer(),
                  YemekModuAltCubuk(
                    oncekiEtiketi: 'Önceki',
                    ileriEtiketi: 'Sonraki Adım',
                    sonSayfa: false,
                    onOnceki: () {},
                    onIleri: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is KilYuvarlakDugme && w.etiket == 'Malzemeler',
          ),
          findsOneWidget,
        );
        final ileri = tester.getTopLeft(find.text('Sonraki Adım'));
        final onceki = tester.getTopLeft(find.text('Önceki'));
        expect(onceki.dy, greaterThan(ileri.dy));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('YemekYapmaModu', () {
    late List<String> olaylar;
    late List<bool> wakelock;

    setUp(() {
      turkce();
      olaylar = [];
      wakelock = [];
      AnalyticsService.testLogger = (ad, _) async => olaylar.add(ad);
      SharedPreferences.setMockInitialValues({});
    });
    tearDown(() => AnalyticsService.testLogger = null);

    Future<void> ac(WidgetTester tester, {TarifData? tarif}) async {
      _wakelockTaklidi(wakelock);
      await tester.pumpWidget(
        _sar(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => YemekYapmaModu(tarif: tarif ?? _tarif()),
                    ),
                  ),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
    }

    testWidgets('ekranı açık tutar, kapanınca bırakır; olay adları aynı', (
      tester,
    ) async {
      await ac(tester);
      expect(wakelock, [true]);
      expect(olaylar, ['yemek_modu_acildi']);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(YemekYapmaModu), findsNothing);
      expect(wakelock, [true, false]);
    });

    testWidgets('malzeme işaretlenir, adımlar gezilir, Tamamla kapatır', (
      tester,
    ) async {
      await ac(tester);
      expect(find.text('0 / 3 hazır'), findsOneWidget);
      await tester.tap(find.text('250 gr kıyma'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 hazır'), findsOneWidget);

      await tester.tap(find.text('Sonraki Adım'));
      await tester.pumpAndSettle();
      expect(find.text('Adım 1'), findsOneWidget);
      expect(find.text('Adım 1 / 2'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(
        find.text('Patlıcanları alacalı soyup tuzlu suda bekletin.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Önceki'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 hazır'), findsOneWidget);

      await tester.tap(find.text('Sonraki Adım'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sonraki Adım'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tamamla'));
      await tester.pumpAndSettle();
      expect(olaylar, ['yemek_modu_acildi', 'yemek_modu_tamamlandi']);
      expect(find.byType(YemekYapmaModu), findsNothing);
    });

    testWidgets('malzeme penceresindeki işaret sayfaya da yansır', (
      tester,
    ) async {
      await ac(tester);
      await tester.tap(find.text('Sonraki Adım'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Malzemeler').first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('1 adet soğan'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Önceki'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 hazır'), findsOneWidget);
    });

    testWidgets('boş tarifte boş yazıları görünür', (tester) async {
      await ac(tester, tarif: _tarif(bos: true));
      expect(find.text('Malzeme listesi bulunamadı.'), findsOneWidget);
      await tester.tap(find.text('Sonraki Adım'));
      await tester.pumpAndSettle();
      expect(find.text('Tarifin yapılış adımları bulunamadı.'), findsOneWidget);
      expect(find.text('Tamamla'), findsOneWidget);
    });

    for (final koyu in [false, true]) {
      for (final olcek in [1.0, 3.2]) {
        final mod = koyu ? 'koyu' : 'açık';
        testWidgets('$mod mod, 320 genişlik, $olcek kat yazıda taşma yok', (
          tester,
        ) async {
          _ekran(tester, 320, 640);
          _wakelockTaklidi(wakelock);
          await tester.pumpWidget(
            _sar(
              YemekYapmaModu(tarif: _tarif()),
              yaziOlcegi: olcek,
              renkler: koyu ? KilRenkleri.koyu : KilRenkleri.acik,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (var i = 0; i < 2; i++) {
            await tester.tap(find.text('Sonraki Adım'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(find.text('Tamamla'), findsOneWidget);
        });
      }
    }
  });

  test('kullanılan metinler altı dilde var', () {
    const anahtarlar = [
      'cooking_mode_ingredients',
      'cooking_mode_step',
      'cooking_mode_ready',
      'cooking_mode_previous',
      'cooking_mode_next_step',
      'cooking_mode_finish',
      'cooking_mode_no_ingredients_short',
      'cooking_mode_no_ingredients_list',
      'cooking_mode_no_steps',
    ];
    for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      final metinler =
          json.decode(File('assets/lang/$dil.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final a in anahtarlar) {
        expect(metinler[a], isA<String>(), reason: '$dil: $a');
      }
    }
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
// Çeviriyi EasyLocalization sarmalayıcısı olmadan yüklemek için.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/sayfalar/alisveris_listesi.dart';
import 'package:tarif_defteri/services/analytics_service.dart';
import 'package:tarif_defteri/widgets/alisveris_parcalari.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';

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

void _liste(List<String> alinacak, List<String> alinan) {
  SharedPreferences.setMockInitialValues({
    'shopping_list_todo': alinacak,
    'shopping_list_done': alinan,
  });
}

Future<List<String>> _kayit(String anahtar) async =>
    (await SharedPreferences.getInstance()).getStringList(anahtar) ?? [];

void main() {
  late List<String> olaylar;

  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
    final tr =
        json.decode(File('assets/lang/tr.json').readAsStringSync())
            as Map<String, dynamic>;
    Localization.load(const Locale('tr'), translations: Translations(tr));
  });

  setUp(() {
    olaylar = [];
    AnalyticsService.testLogger = (name, params) async => olaylar.add(name);
  });

  tearDown(() => AnalyticsService.testLogger = null);

  group('Alışveriş listesi sayfası', () {
    testWidgets('açılışta olay gider, kayıtlı liste görünür', (tester) async {
      _liste(['Süt', 'Un'], ['Yumurta']);
      await tester.pumpWidget(_sar(const AlisverisListesi()));
      await tester.pumpAndSettle();

      expect(olaylar, ['alisveris_listesi_acildi']);
      expect(find.text('Alışveriş Listesi'), findsOneWidget);
      expect(find.text('Alınacaklar'), findsOneWidget);
      expect(find.text('Alınanlar'), findsOneWidget);
      expect(find.text('Süt'), findsOneWidget);
      expect(find.text('Yumurta'), findsOneWidget);
      expect(find.text('Listen boş'), findsNothing);
    });

    testWidgets('boş listede boş durum kartı görünür', (tester) async {
      _liste([], []);
      await tester.pumpWidget(_sar(const AlisverisListesi()));
      await tester.pumpAndSettle();
      expect(find.text('Listen boş'), findsOneWidget);
      expect(find.text('Alınacaklar'), findsNothing);
      expect(find.text('Temizle'), findsNothing);
    });

    testWidgets('ekleme: başa eklenir, kaydedilir, olay gider', (tester) async {
      _liste(['Süt'], []);
      await tester.pumpWidget(_sar(const AlisverisListesi()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Domates ');
      await tester.tap(find.text('Ekle'));
      await tester.pumpAndSettle();

      expect(await _kayit('shopping_list_todo'), ['Domates', 'Süt']);
      expect(olaylar.last, 'alisveris_listesine_eklendi');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );

      // Boş metin eklenmez.
      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(await _kayit('shopping_list_todo'), ['Domates', 'Süt']);
    });

    testWidgets('işaretleme alınanlara taşır, geri almak geri taşır', (
      tester,
    ) async {
      _liste(['Süt', 'Un'], []);
      await tester.pumpWidget(_sar(const AlisverisListesi()));
      await tester.pumpAndSettle();

      // Ada dokunmak da işaretler.
      await tester.tap(find.text('Un'));
      await tester.pumpAndSettle();
      expect(await _kayit('shopping_list_todo'), ['Süt']);
      expect(await _kayit('shopping_list_done'), ['Un']);

      // Onay kutusuna dokunmak geri alır.
      final satir = find.widgetWithText(AlisverisMaddeSatiri, 'Un');
      await tester.tap(
        find.descendant(of: satir, matching: find.byType(KilOnayKutusu)),
      );
      await tester.pumpAndSettle();
      expect(await _kayit('shopping_list_todo'), ['Un', 'Süt']);
      expect(await _kayit('shopping_list_done'), isEmpty);
    });

    testWidgets('sil ve Temizle', (tester) async {
      _liste(['Süt', 'Un'], ['Yumurta', 'Tuz']);
      await tester.pumpWidget(_sar(const AlisverisListesi()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sil: Süt'));
      await tester.pumpAndSettle();
      expect(await _kayit('shopping_list_todo'), ['Un']);

      await tester.tap(find.text('Temizle'));
      await tester.pumpAndSettle();
      expect(await _kayit('shopping_list_done'), isEmpty);
      expect(await _kayit('shopping_list_todo'), ['Un']);
      expect(find.text('Alınanlar'), findsNothing);
    });

    testWidgets('sekme yeniden görününce olay gider ve liste tazelenir', (
      tester,
    ) async {
      _liste(['Süt'], []);
      final sinyal = ValueNotifier(0);
      await tester.pumpWidget(_sar(AlisverisListesi(gorunduSinyali: sinyal)));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('shopping_list_todo', ['Süt', 'Biber']);
      sinyal.value++;
      await tester.pumpAndSettle();

      expect(olaylar, ['alisveris_listesi_acildi', 'alisveris_listesi_acildi']);
      expect(find.text('Biber'), findsOneWidget);
    });

    testWidgets('dokunulan öğeler en az 48x48, ekran okuyucu satırı okur', (
      tester,
    ) async {
      final anlam = tester.ensureSemantics();
      _liste(['Süt'], ['Un']);
      await tester.pumpWidget(_sar(const AlisverisListesi()));
      await tester.pumpAndSettle();

      for (final bulucu in [
        find.byType(KilOnayKutusu),
        find.byType(IconButton),
        find.byType(KilDugme),
      ]) {
        for (final e in bulucu.evaluate()) {
          final boyut = tester.getSize(find.byWidget(e.widget));
          expect(boyut.width, greaterThanOrEqualTo(48));
          expect(boyut.height, greaterThanOrEqualTo(48));
        }
      }

      expect(
        tester.getSemantics(find.text('Un')),
        matchesSemantics(
          label: 'Un',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Alınacaklar'), findsOneWidget);
      anlam.dispose();
    });

    for (final koyu in [false, true]) {
      for (final olcek in [1.0, 3.2]) {
        testWidgets(
          '${koyu ? 'koyu' : 'açık'} modda 320 genişlik, $olcek kat yazıda '
          'taşma yok',
          (tester) async {
            _ekran(tester, 320, 640);
            _liste(
              ['Kırmızı mercimek', 'Zeytinyağı', 'Süt'],
              ['Yumurta', 'Toz şeker'],
            );
            await tester.pumpWidget(
              _sar(
                const AlisverisListesi(),
                yaziOlcegi: olcek,
                renkler: koyu ? KilRenkleri.koyu : KilRenkleri.acik,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            await tester.scrollUntilVisible(
              find.text('Temizle'),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('boş durum 320 genişlik ve 3.2 kat yazıda taşmaz', (
      tester,
    ) async {
      _ekran(tester, 320, 640);
      _liste([], []);
      await tester.pumpWidget(_sar(const AlisverisListesi(), yaziOlcegi: 3.2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  test('yeni metinler altı dilde var', () {
    const anahtarlar = [
      'shopping_list_add_button',
      'shopping_list_delete_item',
      'shopping_list_empty_title',
      'shopping_list_empty_subtitle',
      'common_clear',
    ];
    for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      final m =
          json.decode(File('assets/lang/$dil.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final a in anahtarlar) {
        expect((m[a] as String?)?.trim(), isNotEmpty, reason: '$dil: $a');
      }
    }
  });
}

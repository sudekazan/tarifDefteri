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
import 'package:tarif_defteri/sayfalar/arama_sayfasi.dart';
import 'package:tarif_defteri/services/analytics_service.dart';
import 'package:tarif_defteri/widgets/arama_parcalari.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/tarif_listesi_parcalari.dart';

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

Map<String, Object> _tarif(int id, String ad, {String aciklama = ''}) => {
  'tarif_id': id,
  'tarif_adi': ad,
  'tarif_aciklama': aciklama,
  'tarif_resimler': <String>[],
  'klasor_id': 1,
  'updatedAt': 0,
};

void _tarifler() {
  SharedPreferences.setMockInitialValues({
    'klasorler': [
      json.encode({'klasor_id': 1, 'klasor_adi': 'Çorbalar'}),
      'bozuk{',
    ],
    'tarifler_1': [
      json.encode(_tarif(1, 'Mercimek Çorbası')),
      json.encode(_tarif(2, 'Islak Kek', aciklama: 'Kakaolu')),
      json.encode(
        _tarif(3, 'Fırında Kırmızı Biberli ve Zeytinyağlı Patlıcan Musakkası'),
      ),
    ],
  });
}

void main() {
  late List<(String, Map<String, Object>?)> olaylar;

  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
    final tr =
        json.decode(File('assets/lang/tr.json').readAsStringSync())
            as Map<String, dynamic>;
    Localization.load(const Locale('tr'), translations: Translations(tr));
  });

  setUp(() {
    olaylar = [];
    AnalyticsService.testLogger = (name, params) async =>
        olaylar.add((name, params));
  });

  tearDown(() => AnalyticsService.testLogger = null);

  testWidgets('yazı yokken yönlendirme, eşleşenler, sonuç yok, temizle', (
    tester,
  ) async {
    _tarifler();
    await tester.pumpWidget(_sar(const AramaSayfasi()));
    await tester.pumpAndSettle();
    expect(find.text('Aramak istediğiniz tarifi yazın.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ıslak');
    await tester.pumpAndSettle();
    expect(find.byType(AramaSonucSatiri), findsOneWidget);
    expect(find.text('Islak Kek'), findsOneWidget);

    // Açıklamada da aranır.
    await tester.enterText(find.byType(TextField), 'kakao');
    await tester.pumpAndSettle();
    expect(find.text('Islak Kek'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pumpAndSettle();
    expect(find.byType(AramaSonucSatiri), findsNothing);
    expect(
      find.text('Aradığınız kritere uygun tarif bulunamadı.'),
      findsOneWidget,
    );

    final yerel = MaterialLocalizations.of(
      tester.element(find.byType(AramaSayfasi)),
    );
    await tester.tap(find.byTooltip(yerel.deleteButtonTooltip));
    await tester.pumpAndSettle();
    expect(find.text('Aramak istediğiniz tarifi yazın.'), findsOneWidget);
    expect(find.byTooltip(yerel.deleteButtonTooltip), findsNothing);
  });

  testWidgets('çıkarken son aramanın sonucu tek olay olarak gider', (
    tester,
  ) async {
    _tarifler();
    await tester.pumpWidget(_sar(const AramaSayfasi()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.enterText(find.byType(TextField), 'kek');
    await tester.pumpAndSettle();
    expect(olaylar, isEmpty);

    await tester.pumpWidget(_sar(const SizedBox()));
    expect(olaylar.single.$1, 'arama_yapildi');
    expect(olaylar.single.$2, {'sonuc_var': 'true'});
  });

  testWidgets('geri düğmesi sayfayı kapatır; dokunma alanları 48', (
    tester,
  ) async {
    _tarifler();
    await tester.pumpWidget(
      _sar(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AramaSayfasi()),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'çorba');
    await tester.pumpAndSettle();

    final geri = tester.getSize(find.byType(KilYuvarlakDugme));
    expect(geri.width, greaterThanOrEqualTo(48));
    expect(geri.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSize(find.byType(AramaSonucSatiri)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byType(KilYuvarlakDugme));
    await tester.pumpAndSettle();
    expect(find.byType(AramaSayfasi), findsNothing);
  });

  testWidgets('büyük yazıda görsel adın üstüne çıkar', (tester) async {
    await tester.pumpWidget(
      _sar(
        Scaffold(
          body: AramaSonucSatiri(ad: 'Mercimek Çorbası', onTap: () {}),
        ),
        yaziOlcegi: 2,
      ),
    );
    final gorsel = tester.getRect(find.byType(TarifKucukGorsel));
    final ad = tester.getRect(find.text('Mercimek Çorbası'));
    expect(ad.top, greaterThanOrEqualTo(gorsel.bottom));
  });

  for (final koyu in [false, true]) {
    for (final olcek in [1.0, 3.2]) {
      testWidgets(
        '${koyu ? 'koyu' : 'açık'} modda 320 genişlik, $olcek kat yazıda '
        'taşma yok',
        (tester) async {
          _ekran(tester, 320, 640);
          _tarifler();
          final renkler = koyu ? KilRenkleri.koyu : KilRenkleri.acik;
          await tester.pumpWidget(
            _sar(const AramaSayfasi(), yaziOlcegi: olcek, renkler: renkler),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.enterText(find.byType(TextField), 'a');
          await tester.pumpAndSettle();
          expect(find.byType(AramaSonucSatiri), findsWidgets);
          expect(tester.takeException(), isNull);

          await tester.enterText(find.byType(TextField), 'pizza');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

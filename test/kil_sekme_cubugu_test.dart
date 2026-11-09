import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';

const _diller = ['tr', 'en', 'de', 'es', 'fr', 'pt'];
const _sekmeAnahtarlari = [
  'tab_notebook',
  'tab_what_to_cook',
  'tab_shopping',
  'tab_profile',
];

Map<String, dynamic> _dilDosyasi(String dil) =>
    json.decode(File('assets/lang/$dil.json').readAsStringSync())
        as Map<String, dynamic>;

List<KilSekme> _sekmeler(List<String> etiketler) => [
      for (final e in etiketler)
        KilSekme(
          ikon: Icons.circle_outlined,
          seciliIkon: Icons.circle,
          etiket: e,
        ),
    ];

Widget _sar({
  required List<String> etiketler,
  int secili = 0,
  ValueChanged<int>? onSecildi,
  double genislik = 390,
  double yaziOlcegi = 1,
  KilRenkleri renkler = KilRenkleri.acik,
}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: renkler.sertGolge ? Brightness.light : Brightness.dark,
      extensions: [renkler],
    ),
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(genislik, 800),
        textScaler: TextScaler.linear(yaziOlcegi),
      ),
      child: Scaffold(
        bottomNavigationBar: KilSekmeCubugu(
          sekmeler: _sekmeler(etiketler),
          seciliIndeks: secili,
          onSecildi: onSecildi ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  test('sekme ve ana sayfa metinleri altı dilde de var', () {
    const anahtarlar = [
      ..._sekmeAnahtarlari,
      'home_pro_badge',
      'home_folders_title',
    ];
    for (final dil in _diller) {
      final metinler = _dilDosyasi(dil);
      for (final a in anahtarlar) {
        expect(metinler[a], isA<String>(), reason: '$dil: $a yok');
        expect((metinler[a] as String).trim(), isNotEmpty,
            reason: '$dil: $a boş');
      }
    }
  });

  testWidgets('dokunulan sekmenin indeksini bildirir', (tester) async {
    int? secilen;
    await tester.pumpWidget(_sar(
      etiketler: const ['Bir', 'İki', 'Üç', 'Dört'],
      onSecildi: (i) => secilen = i,
    ));
    await tester.tap(find.text('Üç'));
    expect(secilen, 2);
  });

  testWidgets('her sekmenin dokunma alanı en az 48x48', (tester) async {
    await tester.pumpWidget(_sar(
      etiketler: const ['Bir', 'İki', 'Üç', 'Dört'],
      genislik: 320,
    ));
    final hedefler = find.byType(NavigationDestination);
    expect(hedefler, findsNWidgets(4));
    for (final e in tester.widgetList(hedefler)) {
      final boyut = tester.getSize(find.byWidget(e));
      expect(boyut.width, greaterThanOrEqualTo(48));
      expect(boyut.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('üstte süs kenarı çizilir', (tester) async {
    await tester.pumpWidget(_sar(etiketler: const ['A', 'B', 'C', 'D']));
    final kutu = tester.widget<DecoratedBox>(find
        .ancestor(
          of: find.byType(NavigationBar),
          matching: find.byType(DecoratedBox),
        )
        .last);
    final kenar = (kutu.decoration as BoxDecoration).border as Border;
    expect(kenar.top.color, KilRenkleri.acik.kenar);
    expect(kenar.top.width, KilKart.kenarKalinligi);
  });

  testWidgets('etiketler en fazla 1.3 kat büyür', (tester) async {
    await tester.pumpWidget(_sar(
      etiketler: const ['Bir', 'İki', 'Üç', 'Dört'],
      yaziOlcegi: 3.2,
    ));
    final olcek =
        MediaQuery.textScalerOf(tester.element(find.text('Bir'))).scale(10) /
            10;
    expect(olcek, closeTo(KilSekmeCubugu.enBuyukYaziOlcegi, 0.001));
  });

  for (final dil in _diller) {
    for (final renkler in const [KilRenkleri.acik, KilRenkleri.koyu]) {
      testWidgets(
          '$dil, ${renkler.sertGolge ? 'açık' : 'koyu'}: dar ekranda ve en '
          'büyük yazıda taşmaz', (tester) async {
        final metinler = _dilDosyasi(dil);
        await tester.pumpWidget(_sar(
          etiketler: [for (final a in _sekmeAnahtarlari) metinler[a] as String],
          genislik: 320,
          yaziOlcegi: 3.2,
          renkler: renkler,
        ));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

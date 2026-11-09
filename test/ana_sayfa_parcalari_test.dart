import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/widgets/ana_sayfa_parcalari.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';

// Parçalar fontsuz, yalnızca KilRenkleri içeren bir temayla denenir;
// google_fonts testte font indirmeye çalışmasın. Test fontu gerçek fonttan
// geniş olduğu için taşma denemesi temkinlidir.
Widget _sar(
  Widget child, {
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
        size: Size(genislik, 900),
        textScaler: TextScaler.linear(yaziOlcegi),
      ),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [child],
        ),
      ),
    ),
  );
}

Widget _klasor(String ad, {VoidCallback? onTap, bool menulu = true}) =>
    KlasorKarti(
      ad: ad,
      ikon: Icons.cake_rounded,
      renk: KilRenkleri.acik.klasorTatli,
      onTap: onTap ?? () {},
      menu: menulu
          ? IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () {},
            )
          : null,
    );

Widget _anaSayfa() => Column(
      children: [
        ProRozeti(etiket: 'Pro', anlamEtiketi: 'Premium', onPressed: () {}),
        AramaKutusu(ipucu: 'Tarif ara...', onTap: () {}),
        NePisirsemKarti(
          rozet: 'SİHİRLİ ŞEF',
          baslik: 'Bugün Ne Pişirsem?',
          altBaslik: 'Elindeki malzemeleri seç, yapay zekâ sana tarif önersin.',
          onTap: () {},
        ),
        KlasorIzgarasi(kartlar: [
          _klasor('Favoriler', menulu: false),
          _klasor('Kahvaltılıklar ve hafta sonu brunch tarifleri'),
          _klasor('Çorbalar'),
        ]),
      ],
    );

void main() {
  testWidgets('Pro rozeti: dokunma alanı en az 48x48, dokununca çalışır',
      (tester) async {
    var sayac = 0;
    await tester.pumpWidget(_sar(
      Align(
        alignment: Alignment.centerLeft,
        child: ProRozeti(
          etiket: 'Pro',
          anlamEtiketi: "Premium'a Geç",
          onPressed: () => sayac++,
        ),
      ),
    ));
    final boyut = tester.getSize(find.byType(ProRozeti));
    expect(boyut.width, greaterThanOrEqualTo(48));
    expect(boyut.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(ProRozeti));
    await tester.pumpAndSettle();
    expect(sayac, 1);
    expect(find.bySemanticsLabel("Premium'a Geç"), findsOneWidget);
  });

  testWidgets('arama kutusu en az 48 yüksekliğinde, dokununca çalışır',
      (tester) async {
    var sayac = 0;
    await tester.pumpWidget(
        _sar(AramaKutusu(ipucu: 'Tarif ara...', onTap: () => sayac++)));
    expect(tester.getSize(find.byType(AramaKutusu)).height,
        greaterThanOrEqualTo(48));
    await tester.tap(find.text('Tarif ara...'));
    expect(sayac, 1);
  });

  testWidgets('Ne pişirsem kartına dokununca çalışır', (tester) async {
    var sayac = 0;
    await tester.pumpWidget(_sar(NePisirsemKarti(
      rozet: 'SİHİRLİ ŞEF',
      baslik: 'Bugün Ne Pişirsem?',
      altBaslik: 'Elindeki malzemeleri seç.',
      onTap: () => sayac++,
    )));
    await tester.tap(find.text('Bugün Ne Pişirsem?'));
    await tester.pumpAndSettle();
    expect(sayac, 1);
  });

  testWidgets('klasör izgarası iki sütun; aynı satırdaki kartlar aynı boyda',
      (tester) async {
    await tester.pumpWidget(_sar(KlasorIzgarasi(kartlar: [
      _klasor('Tatlılar'),
      _klasor('Hafta sonu kahvaltısı için uzun bir klasör adı'),
      _klasor('Çorbalar'),
    ])));
    final kartlar = find.byType(KlasorKarti);
    final birinci = tester.getRect(kartlar.at(0));
    final ikinci = tester.getRect(kartlar.at(1));
    final ucuncu = tester.getRect(kartlar.at(2));
    expect(birinci.top, ikinci.top);
    expect(birinci.height, ikinci.height);
    expect(ucuncu.top, greaterThan(birinci.bottom));
    expect(ucuncu.width, closeTo(birinci.width, 0.01));
  });

  testWidgets('büyük yazıda klasörler tek sütuna geçer', (tester) async {
    await tester.pumpWidget(_sar(
      KlasorIzgarasi(kartlar: [_klasor('Tatlılar'), _klasor('Çorbalar')]),
      yaziOlcegi: 2,
    ));
    final kartlar = find.byType(KlasorKarti);
    expect(tester.getRect(kartlar.at(1)).top,
        greaterThan(tester.getRect(kartlar.at(0)).bottom));
  });

  testWidgets('klasör kartı ve menüsü ayrı ayrı dokunulur', (tester) async {
    var kart = 0;
    var menu = 0;
    await tester.pumpWidget(_sar(KlasorKarti(
      ad: 'Tatlılar',
      ikon: Icons.cake_rounded,
      renk: KilRenkleri.acik.klasorTatli,
      onTap: () => kart++,
      menu: IconButton(
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: () => menu++,
      ),
    )));
    await tester.tap(find.text('Tatlılar'));
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    expect(kart, 1);
    expect(menu, 1);
    final menuBoyutu = tester.getSize(find.byType(IconButton));
    expect(menuBoyutu.width, greaterThanOrEqualTo(48));
    expect(menuBoyutu.height, greaterThanOrEqualTo(48));
  });

  for (final renkler in const [KilRenkleri.acik, KilRenkleri.koyu]) {
    final mod = renkler.sertGolge ? 'açık' : 'koyu';
    for (final olcek in const [1.0, 1.6, 3.2]) {
      testWidgets('$mod mod, yazı ${olcek}x, 320 genişlik: taşma yok',
          (tester) async {
        await tester.pumpWidget(_sar(
          _anaSayfa(),
          genislik: 320,
          yaziOlcegi: olcek,
          renkler: renkler,
        ));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

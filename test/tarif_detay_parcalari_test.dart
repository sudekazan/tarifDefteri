import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/tarif_detay_parcalari.dart';

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
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(yaziOlcegi)),
      child: child!,
    ),
    home: child,
  );
}

PorsiyonAyari _porsiyon({VoidCallback? onAzalt, VoidCallback? onArtir}) =>
    PorsiyonAyari(
      etiket: 'Porsiyon Çarpanı:',
      carpanMetni: '1.0x',
      azaltEtiketi: 'Porsiyonu azalt',
      artirEtiketi: 'Porsiyonu artır',
      onAzalt: onAzalt,
      onArtir: onArtir ?? () {},
    );

/// Tarif detayının tamamı (görsel olmadan): favori rozeti, porsiyon, üç bölüm.
Widget _detay({ValueChanged<int>? onSepeteEkle}) {
  return KilIcSayfa(
    baslik: 'Fırında karnıyarık ve pilav',
    eylemler: [
      KilYuvarlakDugme(
          ikon: Icons.ios_share_rounded, etiket: 'Paylaş', onPressed: () {}),
      KilYuvarlakDugme(
          ikon: Icons.drive_file_move_outline,
          etiket: 'Klasöre Taşı',
          onPressed: () {}),
      KilYuvarlakDugme(
          ikon: Icons.edit_rounded, etiket: 'Düzenle', onPressed: () {}),
    ],
    icerik: [
      const FavoriRozeti(etiket: 'Favoriler'),
      _porsiyon(onAzalt: () {}),
      TarifBolumKarti(
        tur: 'malzemeler',
        baslik: 'Malzemeler',
        maddeler: const ['2 adet patlıcan', '250 gr kıyma', '1 su bardağı su'],
        sepeteEkleEtiketi: 'Alışveriş Listesine Ekle',
        onSepeteEkle: onSepeteEkle ?? (_) {},
      ),
      const TarifBolumKarti(
        tur: 'yapilis',
        baslik: 'Yapılışı',
        maddeler: [
          'Patlıcanları alacalı soyup kızartın.',
          'Kıymayı soğanla kavurun, patlıcanlara doldurun.',
        ],
      ),
      TarifBolumKarti(
        tur: 'linkler',
        baslik: 'Linkler',
        maddeler: const ['https://ornek.com/karniyarik-tarifi'],
        onBaglantiAc: (_) {},
      ),
    ],
    altDugme: KilDugme.birincil(
      etiket: 'Yemek Yapma Modu',
      ikon: Icons.restaurant_rounded,
      onPressed: () {},
    ),
  );
}

void main() {
  test('Aşama 4 metinleri altı dilde de var ve boş değil', () {
    const anahtarlar = [
      'recipe_detail_portion_decrease',
      'recipe_detail_portion_increase',
      'recipe_edit_delete_photo',
      'recipe_edit_delete_section',
      'recipe_edit_delete_item',
      'recipe_edit_add_item',
    ];
    for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      final dosya = json.decode(
        File('assets/lang/$dil.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final anahtar in anahtarlar) {
        expect(dosya[anahtar], isA<String>(), reason: '$dil: $anahtar');
        expect((dosya[anahtar] as String).trim(), isNotEmpty,
            reason: '$dil: $anahtar');
      }
    }
  });

  test('bölüm ikonları ve malzeme türleri', () {
    expect(tarifBolumIkonu('yapilis'), Icons.format_list_numbered_rounded);
    expect(tarifBolumIkonu('bilinmeyen'), Icons.category_rounded);
    for (final tur in ['malzemeler', 'harc', 'hamur', 'serbet', 'sos']) {
      expect(tarifBolumuMalzemeMi(tur), isTrue, reason: tur);
    }
    for (final tur in ['yapilis', 'puf_noktasi', 'linkler']) {
      expect(tarifBolumuMalzemeMi(tur), isFalse, reason: tur);
    }
  });

  group('PorsiyonAyari', () {
    testWidgets('düğmeler 48x48, en küçük çarpanda "−" pasif',
        (tester) async {
      var artti = 0;
      await tester.pumpWidget(
        _sar(Scaffold(body: _porsiyon(onArtir: () => artti++))),
      );

      for (final etiket in ['Porsiyonu azalt', 'Porsiyonu artır']) {
        final boyut = tester.getSize(find.byTooltip(etiket));
        expect(boyut.width, greaterThanOrEqualTo(48), reason: etiket);
        expect(boyut.height, greaterThanOrEqualTo(48), reason: etiket);
      }

      final anlam = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Porsiyonu azalt')),
        matchesSemantics(isButton: true, hasEnabledState: true),
      );
      anlam.dispose();

      await tester.tap(find.byTooltip('Porsiyonu artır'));
      await tester.pumpAndSettle();
      expect(artti, 1);
    });
  });

  group('TarifBolumKarti', () {
    testWidgets('yapılışta numara, malzemede sepet düğmesi (48x48)',
        (tester) async {
      int? eklenen;
      await tester.pumpWidget(_sar(_detay(onSepeteEkle: (i) => eklenen = i)));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      final sepetler = find.byTooltip('Alışveriş Listesine Ekle');
      expect(sepetler, findsNWidgets(3));
      final boyut = tester.getSize(sepetler.at(1));
      expect(boyut.width, greaterThanOrEqualTo(48));
      expect(boyut.height, greaterThanOrEqualTo(48));

      await tester.tap(sepetler.at(1));
      expect(eklenen, 1);
    });

    testWidgets('bölüm başlığı ekran okuyucuda başlık', (tester) async {
      final anlam = tester.ensureSemantics();
      await tester.pumpWidget(_sar(_detay()));
      expect(
        tester.getSemantics(find.text('Malzemeler')),
        matchesSemantics(label: 'Malzemeler', isHeader: true),
      );
      anlam.dispose();
    });

    testWidgets('bağlantıya dokununca adres gelir', (tester) async {
      String? acilan;
      await tester.pumpWidget(_sar(Scaffold(
        body: TarifBolumKarti(
          tur: 'linkler',
          baslik: 'Linkler',
          maddeler: const ['https://ornek.com/tarif'],
          onBaglantiAc: (adres) => acilan = adres,
        ),
      )));
      await tester.tap(find.text('https://ornek.com/tarif'));
      expect(acilan, 'https://ornek.com/tarif');
    });
  });

  group('Büyük yazı', () {
    testWidgets('1.6 katın üstünde işaret ve sepet metnin üstüne çıkar',
        (tester) async {
      _ekran(tester, 320, 3000);
      Future<void> ciz(double olcek) => tester.pumpWidget(_sar(
            Scaffold(
              body: ListView(children: [
                TarifBolumKarti(
                  tur: 'malzemeler',
                  baslik: 'Malzemeler',
                  maddeler: const ['2 adet patlıcan'],
                  sepeteEkleEtiketi: 'Sepete ekle',
                  onSepeteEkle: (_) {},
                ),
              ]),
            ),
            yaziOlcegi: olcek,
          ));

      await ciz(1);
      expect(
        tester.getTopLeft(find.text('2 adet patlıcan')).dx,
        greaterThan(tester.getTopRight(find.byIcon(Icons.check_rounded)).dx),
      );

      await ciz(3.2);
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('2 adet patlıcan')).dy,
        greaterThanOrEqualTo(
            tester.getBottomLeft(find.byIcon(Icons.check_rounded)).dy),
      );
      expect(
        tester.getTopLeft(find.text('Malzemeler')).dy,
        greaterThanOrEqualTo(tester
            .getBottomLeft(find.byIcon(Icons.shopping_basket_rounded))
            .dy),
      );
    });
  });

  group('KilSecimListesi', () {
    testWidgets('satırlar en az 56 yüksekliğinde, dokununca seçer',
        (tester) async {
      var secilen = '';
      await tester.pumpWidget(_sar(Scaffold(
        body: KilSecimListesi(secenekler: [
          KilSecenek(
            ikon: Icons.folder_rounded,
            etiket: 'Tatlılar',
            onTap: () => secilen = 'Tatlılar',
          ),
          KilSecenek(
            ikon: Icons.folder_rounded,
            etiket: 'Çorbalar',
            onTap: () => secilen = 'Çorbalar',
          ),
        ]),
      )));
      final satir = find.ancestor(
        of: find.text('Çorbalar'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(satir).height, greaterThanOrEqualTo(56));
      await tester.tap(find.text('Çorbalar'));
      expect(secilen, 'Çorbalar');
    });
  });

  group('Tarif detayı taşmıyor', () {
    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      final mod = renkler.sertGolge ? 'açık' : 'koyu';
      for (final olcek in [1.0, 3.2]) {
        testWidgets('$mod mod, 320 genişlik, $olcek kat yazı', (tester) async {
          _ekran(tester, 320, 3000);
          await tester.pumpWidget(
            _sar(_detay(), yaziOlcegi: olcek, renkler: renkler),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Başlık kesilmez, alt satıra geçer.
          expect(find.text('Fırında karnıyarık ve pilav'), findsOneWidget);
        });
      }
    }
  });
}

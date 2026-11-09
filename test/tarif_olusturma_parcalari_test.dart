import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/tarif_detay_parcalari.dart';
import 'package:tarif_defteri/widgets/tarif_olusturma_parcalari.dart';

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

TarifBolumDuzenleKarti _kart({
  String tur = 'malzemeler',
  List<String> maddeler = const ['2 adet patlıcan', '250 gr kıyma'],
  TextEditingController? controller,
  VoidCallback? onBolumuSil,
  ValueChanged<int>? onMaddeDuzenle,
  ValueChanged<int>? onMaddeSil,
  ValueChanged<String>? onMaddeEkle,
}) {
  return TarifBolumDuzenleKarti(
    tur: tur,
    baslik: tur == 'yapilis' ? 'Yapılışı' : 'Malzemeler',
    maddeler: maddeler,
    controller: controller ?? TextEditingController(),
    ipucu: tur == 'yapilis' ? 'Adım ekle...' : 'Madde ekle...',
    bolumuSilEtiketi: 'Bölümü sil',
    maddeyiSilEtiketi: 'Maddeyi sil',
    maddeEkleEtiketi: 'Maddeyi ekle',
    onBolumuSil: onBolumuSil ?? () {},
    onMaddeDuzenle: onMaddeDuzenle ?? (_) {},
    onMaddeSil: onMaddeSil ?? (_) {},
    onMaddeEkle: onMaddeEkle ?? (_) {},
  );
}

/// Tarif oluşturma ekranının tamamı (fotoğrafsız).
Widget _olusturma() {
  return KilIcSayfa(
    baslik: 'Tarif Ekleme',
    eylemler: [
      KilYuvarlakDugme(
        ikon: Icons.photo_camera_rounded,
        etiket: 'Fotoğraf Ekle',
        onPressed: () {},
      ),
    ],
    icerik: [
      TarifFotoSeridi(
        yollar: const [],
        ekleEtiketi: 'Fotoğraf Ekle',
        silEtiketi: 'Fotoğrafı sil',
        yuklenemediMetni: 'Görsel yüklenemedi',
        bulunamadiMetni: 'Görsel bulunamadı',
        onEkle: () {},
        onSil: (_) {},
        onBuyut: (_) {},
      ),
      KilKart(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'Tarif Adı',
            hintText: 'Tarif Adı Giriniz',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          controller: TextEditingController(),
        ),
      ),
      TarifBolumlerBasligi(
        baslik: 'Tarif Bölümleri',
        ekleEtiketi: 'Bölüm Ekle',
        onEkle: () {},
      ),
      _kart(),
      _kart(tur: 'yapilis', maddeler: const [
        'Patlıcanları alacalı soyup kızartın.',
      ]),
      KilDugme.birincil(
        etiket: 'Kaydet',
        ikon: Icons.check_rounded,
        tamGenislik: true,
        onPressed: () {},
      ),
    ],
  );
}

void main() {
  group('TarifBolumDuzenleKarti', () {
    testWidgets('silme ve ekleme düğmeleri en az 48x48', (tester) async {
      await tester.pumpWidget(_sar(Scaffold(body: _kart())));
      for (final etiket in ['Bölümü sil', 'Maddeyi ekle']) {
        final boyut = tester.getSize(find.byTooltip(etiket));
        expect(boyut.width, greaterThanOrEqualTo(48), reason: etiket);
        expect(boyut.height, greaterThanOrEqualTo(48), reason: etiket);
      }
      final maddeSil = find.byTooltip('Maddeyi sil');
      expect(maddeSil, findsNWidgets(2));
      expect(tester.getSize(maddeSil.first).height, greaterThanOrEqualTo(48));
    });

    testWidgets('"+" kutudaki metni, Enter da aynı metni verir',
        (tester) async {
      final eklenenler = <String>[];
      final controller = TextEditingController();
      await tester.pumpWidget(_sar(Scaffold(
        body: _kart(controller: controller, onMaddeEkle: eklenenler.add),
      )));

      await tester.enterText(find.byType(TextField), '1 soğan');
      await tester.tap(find.byTooltip('Maddeyi ekle'));
      expect(eklenenler, ['1 soğan']);

      await tester.enterText(find.byType(TextField), '2 domates');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(eklenenler, ['1 soğan', '2 domates']);
    });

    testWidgets('maddeye dokununca düzenler, çarpıyla siler',
        (tester) async {
      int? duzenlenen;
      int? silinen;
      var bolumSilindi = false;
      await tester.pumpWidget(_sar(Scaffold(
        body: _kart(
          onMaddeDuzenle: (i) => duzenlenen = i,
          onMaddeSil: (i) => silinen = i,
          onBolumuSil: () => bolumSilindi = true,
        ),
      )));
      await tester.tap(find.text('250 gr kıyma'));
      expect(duzenlenen, 1);
      await tester.tap(find.byTooltip('Maddeyi sil').first);
      expect(silinen, 0);
      await tester.tap(find.byTooltip('Bölümü sil'));
      expect(bolumSilindi, isTrue);
    });

    testWidgets('yapılışta adımlar numaralı', (tester) async {
      await tester.pumpWidget(_sar(Scaffold(
        body: _kart(tur: 'yapilis', maddeler: const ['Bir', 'İki', 'Üç']),
      )));
      for (final n in ['1', '2', '3']) {
        expect(find.text(n), findsOneWidget);
      }
    });
  });

  group('TarifFotoSeridi', () {
    testWidgets('fotoğraf yokken yalnız düğme; varsa silme düğmesi 48x48',
        (tester) async {
      var eklendi = false;
      int? silinen;
      await tester.pumpWidget(_sar(Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => TarifFotoSeridi(
            yollar: eklendi ? const ['/yok/foto.jpg'] : const [],
            ekleEtiketi: 'Fotoğraf Ekle',
            silEtiketi: 'Fotoğrafı sil',
            yuklenemediMetni: 'Görsel yüklenemedi',
            bulunamadiMetni: 'Görsel bulunamadı',
            onEkle: () => setState(() => eklendi = true),
            onSil: (i) => silinen = i,
            onBuyut: (_) {},
          ),
        ),
      )));
      expect(find.byTooltip('Fotoğrafı sil'), findsNothing);

      await tester.tap(find.text('Fotoğraf Ekle'));
      await tester.pumpAndSettle();
      // Cihazda bulunamayan görsel yerine açıklama çıkar.
      expect(find.text('Görsel bulunamadı'), findsOneWidget);

      final sil = find.byTooltip('Fotoğrafı sil');
      final boyut = tester.getSize(sil);
      expect(boyut.width, greaterThanOrEqualTo(48));
      expect(boyut.height, greaterThanOrEqualTo(48));
      await tester.tap(sil);
      expect(silinen, 0);
    });
  });

  group('Tarif oluşturma taşmıyor', () {
    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      final mod = renkler.sertGolge ? 'açık' : 'koyu';
      for (final olcek in [1.0, 3.2]) {
        testWidgets('$mod mod, 320 genişlik, $olcek kat yazı', (tester) async {
          _ekran(tester, 320, 3000);
          await tester.pumpWidget(
            _sar(_olusturma(), yaziOlcegi: olcek, renkler: renkler),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Uzun sayfanın sonuna kadar kaydırırken de taşma olmamalı.
          await tester.scrollUntilVisible(
            find.text('Kaydet'),
            400,
            // Metin kutularının da kendi kaydırıcısı var; sayfanınki ilki.
            scrollable: find.byType(Scrollable).first,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Kaydet'), findsOneWidget);
        });
      }
    }
  });

  test('bölüm ikonu oluşturma ve detayda aynı', () {
    expect(tarifBolumIkonu('malzemeler'), Icons.shopping_basket_rounded);
  });
}

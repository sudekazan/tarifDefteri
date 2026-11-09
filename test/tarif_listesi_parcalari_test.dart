import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/tarif_listesi_parcalari.dart';

/// Test ekranını gerçekten [genislik] x [yukseklik] yapar (yalnızca
/// MediaQuery vermek yerleşimi daraltmaz).
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
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(yaziOlcegi)),
        child: child,
      ),
    ),
  );
}

TarifSatiri _satir({
  String ad = 'Fırında karnıyarık',
  bool favori = false,
  VoidCallback? onTap,
  VoidCallback? onFavori,
  VoidCallback? onSil,
  void Function(BuildContext)? onPaylas,
}) {
  return TarifSatiri(
    ad: ad,
    favori: favori,
    favoriEtiketi: favori ? 'Favorilerden çıkar' : 'Favorilere ekle',
    paylasEtiketi: 'Paylaş',
    silEtiketi: 'Tarif Sil',
    onTap: onTap ?? () {},
    onFavori: onFavori ?? () {},
    onPaylas: onPaylas ?? (_) {},
    onSil: onSil ?? () {},
  );
}

Widget _liste({
  required List<Widget> satirlar,
  bool aramaAcik = false,
  VoidCallback? onAramaAcKapat,
  Widget? yeniTarifDugmesi,
}) {
  return TarifListesiGorunumu(
    baslik: 'Tatlılar',
    satirlar: satirlar,
    bosDurum: const TarifBosDurum(
      ikon: Icons.menu_book_rounded,
      renk: KlasorRenk(zemin: Color(0xFFFFEDD5), ikon: Color(0xFF9A3412)),
      baslik: 'Henüz hiç tarif yok!',
      altBaslik: 'İlk tarifinizi oluşturun.',
    ),
    aramaAcik: aramaAcik,
    aramaController: TextEditingController(),
    aramaIpucu: 'Tarif ara...',
    onAramaAcKapat: onAramaAcKapat ?? () {},
    onAramaDegisti: (_) {},
    yeniTarifDugmesi: yeniTarifDugmesi,
  );
}

void main() {
  group('TarifSatiri', () {
    testWidgets('favori ve menü düğmeleri en az 48x48', (tester) async {
      await tester.pumpWidget(_sar(Scaffold(body: _satir())));

      final favori = tester.getSize(find.byTooltip('Favorilere ekle'));
      expect(favori.width, greaterThanOrEqualTo(48));
      expect(favori.height, greaterThanOrEqualTo(48));

      final menuKutusu = tester.getSize(
        find.ancestor(
          of: find.byIcon(Icons.more_vert_rounded),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(menuKutusu.width, greaterThanOrEqualTo(48));
      expect(menuKutusu.height, greaterThanOrEqualTo(48));
    });

    testWidgets('dokununca tarif açılır, kalbe basınca favori değişir',
        (tester) async {
      var acildi = 0;
      var favori = 0;
      await tester.pumpWidget(_sar(Scaffold(
        body: _satir(onTap: () => acildi++, onFavori: () => favori++),
      )));

      await tester.tap(find.text('Fırında karnıyarık'));
      await tester.tap(find.byTooltip('Favorilere ekle'));
      expect(acildi, 1);
      expect(favori, 1);
    });

    testWidgets('menüden paylaş ve sil çağrılır', (tester) async {
      var paylasildi = 0;
      var silindi = 0;
      await tester.pumpWidget(_sar(Scaffold(
        body: _satir(onPaylas: (_) => paylasildi++, onSil: () => silindi++),
      )));

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paylaş'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tarif Sil'));
      await tester.pumpAndSettle();

      expect(paylasildi, 1);
      expect(silindi, 1);
    });

    testWidgets('favoride dolu kalp ve "çıkar" etiketi', (tester) async {
      await tester.pumpWidget(_sar(Scaffold(body: _satir(favori: true))));
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byTooltip('Favorilerden çıkar'), findsOneWidget);
    });

    testWidgets('büyük yazıda ad düğmelerin altına iner', (tester) async {
      _ekran(tester, 390);
      await tester.pumpWidget(_sar(Scaffold(body: _satir()), yaziOlcegi: 2));

      final ad = tester.getTopLeft(find.text('Fırında karnıyarık'));
      final kalp = tester.getBottomLeft(find.byTooltip('Favorilere ekle'));
      expect(ad.dy, greaterThan(kalp.dy - 1));
    });
  });

  group('TarifListesiGorunumu', () {
    testWidgets('tarif yoksa boş durum kartı görünür', (tester) async {
      await tester.pumpWidget(_sar(_liste(satirlar: const [])));
      expect(find.text('Henüz hiç tarif yok!'), findsOneWidget);
    });

    testWidgets('arama açıkken kutu çıkar, düğme kapat olur', (tester) async {
      var degisti = 0;
      await tester.pumpWidget(_sar(_liste(
        satirlar: [_satir()],
        onAramaAcKapat: () => degisti++,
      )));
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byIcon(Icons.search_rounded));
      expect(degisti, 1);

      await tester.pumpWidget(_sar(_liste(satirlar: [_satir()], aramaAcik: true)));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('geri ve arama düğmeleri en az 48x48', (tester) async {
      await tester.pumpWidget(_sar(_liste(satirlar: [_satir()])));
      for (final ikon in [Icons.arrow_back_rounded, Icons.search_rounded]) {
        final kutu = tester.getSize(find.ancestor(
          of: find.byIcon(ikon),
          matching: find.byType(KilYuvarlakDugme),
        ));
        expect(kutu.width, greaterThanOrEqualTo(48));
        expect(kutu.height, greaterThanOrEqualTo(48));
      }
    });

    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      final mod = renkler.sertGolge ? 'açık' : 'koyu';
      testWidgets('$mod modda 320 genişlikte ve 3.2 kat yazıda taşma yok',
          (tester) async {
        _ekran(tester, 320, 700);
        await tester.pumpWidget(_sar(
          _liste(
            satirlar: [
              _satir(ad: 'Annemin fırında patlıcanlı kebabı ve pilavı'),
              _satir(favori: true),
            ],
            aramaAcik: true,
            yeniTarifDugmesi: KilDugme.birincil(
              etiket: 'Yeni tarif',
              ikon: Icons.add_rounded,
              onPressed: () {},
            ),
          ),
          yaziOlcegi: 3.2,
          renkler: renkler,
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });
}

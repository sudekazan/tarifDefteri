import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/utils/yemek_zamanlayici.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/yemek_zamanlayici_parcalari.dart';

Widget _sar(
  Widget child, {
  double yaziOlcegi = 1,
  KilRenkleri renkler = KilRenkleri.acik,
}) => MaterialApp(
  theme: ThemeData(
    brightness: renkler.sertGolge ? Brightness.light : Brightness.dark,
    extensions: [renkler],
  ),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(yaziOlcegi)),
    child: c!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);

Widget _serit(
  ZamanlayiciDurumu durum, {
  Duration kalan = const Duration(minutes: 4, seconds: 30),
  VoidCallback? onDuraklat,
  VoidCallback? onSifirla,
}) => YemekZamanlayiciSeridi(
  durum: durum,
  kalan: kalan,
  etiket: 'Zamanlayıcı',
  baslatEtiketi: 'Başlat',
  duraklatEtiketi: 'Duraklat',
  sifirlaEtiketi: 'Sıfırla',
  bittiMetni: 'Süre doldu!',
  onAc: () {},
  onDuraklat: onDuraklat ?? () {},
  onDevam: () {},
  onSifirla: onSifirla ?? () {},
);

void main() {
  group('YemekZamanlayici', () {
    late DateTime simdi;
    late YemekZamanlayici z;
    setUp(() {
      simdi = DateTime(2026, 11, 10, 12);
      z = YemekZamanlayici(saat: () => simdi);
    });

    test('başlayınca kalan süre saatle azalır, dolunca bir kez biter', () {
      z.baslat(const Duration(minutes: 5));
      expect(z.durum, ZamanlayiciDurumu.calisiyor);
      simdi = simdi.add(const Duration(minutes: 2));
      expect(z.kalan, const Duration(minutes: 3));
      expect(z.bittiMiKontrolEt(), isFalse);
      simdi = simdi.add(const Duration(minutes: 4)); // arka planda geçen süre
      expect(z.kalan, Duration.zero);
      expect(z.bittiMiKontrolEt(), isTrue);
      expect(z.bittiMiKontrolEt(), isFalse);
      expect(z.durum, ZamanlayiciDurumu.bitti);
    });

    test('duraklatınca süre durur, devam edince kaldığı yerden sürer', () {
      z.baslat(const Duration(minutes: 5));
      simdi = simdi.add(const Duration(minutes: 1));
      z.duraklat();
      simdi = simdi.add(const Duration(minutes: 10));
      expect(z.kalan, const Duration(minutes: 4));
      expect(z.bitis, isNull);
      z.devamEt();
      expect(z.bitis, simdi.add(const Duration(minutes: 4)));
    });

    test('sıfırla boş duruma döner; sıfır süre başlamaz', () {
      z.baslat(Duration.zero);
      expect(z.durum, ZamanlayiciDurumu.bos);
      z.baslat(const Duration(minutes: 1));
      z.sifirla();
      expect(z.durum, ZamanlayiciDurumu.bos);
      expect(z.kalan, Duration.zero);
    });

    test('metin biçimi', () {
      expect(zamanlayiciMetni(const Duration(minutes: 5)), '05:00');
      expect(zamanlayiciMetni(const Duration(milliseconds: 4200)), '00:05');
      expect(zamanlayiciMetni(const Duration(minutes: 75)), '1:15:00');
    });
  });

  group('YemekZamanlayiciSeridi', () {
    testWidgets('boşken yalnızca Zamanlayıcı düğmesi', (tester) async {
      await tester.pumpWidget(_sar(_serit(ZamanlayiciDurumu.bos)));
      expect(find.text('Zamanlayıcı'), findsOneWidget);
      expect(find.text('04:30'), findsNothing);
    });

    testWidgets('çalışırken kalan süre ve düğmeler çalışır', (tester) async {
      var duraklat = 0, sifirla = 0;
      await tester.pumpWidget(
        _sar(
          _serit(
            ZamanlayiciDurumu.calisiyor,
            onDuraklat: () => duraklat++,
            onSifirla: () => sifirla++,
          ),
        ),
      );
      expect(find.text('04:30'), findsOneWidget);
      await tester.tap(find.byTooltip('Duraklat'));
      await tester.tap(find.byTooltip('Sıfırla'));
      await tester.pump(const Duration(milliseconds: 300));
      expect((duraklat, sifirla), (1, 1));
    });

    testWidgets('bitince uyarı metni; büyük yazı ve koyu modda taşmaz', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final renk in [KilRenkleri.acik, KilRenkleri.koyu]) {
        await tester.pumpWidget(
          _sar(_serit(ZamanlayiciDurumu.bitti), yaziOlcegi: 2, renkler: renk),
        );
        expect(find.text('Süre doldu!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  testWidgets('seçici süre seçip Başlat ile döndürür', (tester) async {
    Duration? sonuc;
    await tester.pumpWidget(
      _sar(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => sonuc = await KilAltSayfa.goster<Duration>(
              context,
              builder: (_) => const YemekZamanlayiciSecici(
                baslik: 'Zamanlayıcı',
                baslatEtiketi: 'Başlat',
              ),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsWidgets);
    await tester.tap(find.text('10:00'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('+1:00'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Başlat'));
    await tester.pumpAndSettle();
    expect(sonuc, const Duration(minutes: 11));
  });
}

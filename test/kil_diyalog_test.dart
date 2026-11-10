import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(yaziOlcegi)),
      child: child!,
    ),
    home: Scaffold(body: child),
  );
}

/// Dokununca [ac]'ı çağıran düğme.
Widget _acici(void Function(BuildContext) ac) => Builder(
      builder: (context) => Center(
        child: TextButton(onPressed: () => ac(context), child: const Text('aç')),
      ),
    );

Color? _dugmeZemini(WidgetTester tester, String etiket) {
  final kutu = tester.widget<AnimatedContainer>(
    find.ancestor(of: find.text(etiket), matching: find.byType(AnimatedContainer)),
  );
  return (kutu.decoration as BoxDecoration?)?.color;
}

const _uzun = 'Bu çok uzun bir açıklama metnidir; dar ekranda ve büyük yazıda '
    'satırlara bölünmeli, düğmeler kesilmemelidir. Değişiklikler kaybolacak.';

void main() {
  group('KilDiyalog.onayIste', () {
    testWidgets('ana düğme true, vazgeç false döner', (tester) async {
      bool? sonuc;
      await tester.pumpWidget(_sar(_acici((c) async {
        sonuc = await KilDiyalog.onayIste(
          c,
          baslik: 'Sil?',
          mesaj: 'Emin misin?',
          onayEtiketi: 'Evet',
          vazgecEtiketi: 'Hayır',
        );
      })));

      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.text('Sil?'), findsOneWidget);
      expect(find.text('Emin misin?'), findsOneWidget);
      await tester.tap(find.text('Evet'));
      await tester.pumpAndSettle();
      expect(sonuc, isTrue);

      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hayır'));
      await tester.pumpAndSettle();
      expect(sonuc, isFalse);
    });

    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      final ad = renkler.sertGolge ? 'açık' : 'koyu';
      testWidgets('$ad: tehlikeli onayda düğme hata, ikon hata kutusu renginde',
          (tester) async {
        await tester.pumpWidget(_sar(
          _acici((c) => KilDiyalog.onayIste(
                c,
                baslik: 'Sil?',
                onayEtiketi: 'Sil',
                vazgecEtiketi: 'Vazgeç',
                ikon: Icons.delete_outline_rounded,
                tehlikeli: true,
              )),
          renkler: renkler,
        ));
        await tester.tap(find.text('aç'));
        await tester.pumpAndSettle();

        expect(_dugmeZemini(tester, 'Sil'), renkler.hata);
        final ikon = tester.widget<Icon>(find.byIcon(Icons.delete_outline_rounded));
        expect(ikon.color, renkler.hataZeminYazi);
        final diyalog = tester.widget<Dialog>(find.byType(Dialog));
        expect(diyalog.backgroundColor, renkler.kart);
      });
    }

    testWidgets('düğmeler en az 48 yüksekliğinde', (tester) async {
      await tester.pumpWidget(_sar(_acici((c) => KilDiyalog.onayIste(
            c,
            baslik: 'Sil?',
            onayEtiketi: 'Evet',
            vazgecEtiketi: 'Hayır',
          ))));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      for (final etiket in ['Evet', 'Hayır']) {
        final kutu = find.ancestor(
          of: find.text(etiket),
          matching: find.byWidgetPredicate(
            (w) => w is AnimatedContainer || w is TextButton,
          ),
        );
        expect(tester.getSize(kutu.first).height, greaterThanOrEqualTo(48),
            reason: etiket);
      }
    });
  });

  testWidgets('bilgiGoster tek düğmeyle kapanır', (tester) async {
    await tester.pumpWidget(_sar(_acici((c) => KilDiyalog.bilgiGoster(
          c,
          baslik: 'Hata',
          mesaj: 'Bir şey oldu',
          tamamEtiketi: 'Tamam',
        ))));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('Bir şey oldu'), findsOneWidget);
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('beklemeGoster dışına basınca kapanmaz', (tester) async {
    await tester.pumpWidget(_sar(_acici(KilDiyalog.beklemeGoster)));
    await tester.tap(find.text('aç'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(KilBeklemeKutusu), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(KilBeklemeKutusu), findsOneWidget);
  });

  testWidgets('KilBuyukFoto dokununca kapanır, zemin kart rengi',
      (tester) async {
    await tester.pumpWidget(_sar(_acici((c) => showDialog(
          context: c,
          builder: (_) =>
              const KilBuyukFoto(child: SizedBox(width: 100, height: 100)),
        ))));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
        KilRenkleri.acik.kart);
    await tester.tap(find.byType(KilBuyukFoto));
    await tester.pumpAndSettle();
    expect(find.byType(KilBuyukFoto), findsNothing);
  });

  group('taşma yok', () {
    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      for (final olcek in [1.0, 3.2]) {
        final ad = '${renkler.sertGolge ? 'açık' : 'koyu'} $olcek kat';
        testWidgets('$ad, 320 genişlik: metin kutulu diyalog', (tester) async {
          _ekran(tester, 320, 640);
          await tester.pumpWidget(_sar(
            _acici((c) => showDialog(
                  context: c,
                  builder: (ctx) => KilDiyalog(
                    ikon: Icons.warning_amber_rounded,
                    tur: KilDiyalogTuru.tehlike,
                    baslik: 'Değişiklikler kaybolacak',
                    mesaj: _uzun,
                    icerik: const TextField(
                      decoration: InputDecoration(labelText: 'Şifre'),
                    ),
                    eylemler: [
                      KilDugme.hata(
                        etiket: 'Çıkış Yap',
                        tamGenislik: true,
                        onPressed: () {},
                      ),
                      KilDiyalogMetinDugmesi(etiket: 'Vazgeç', onPressed: () {}),
                    ],
                  ),
                )),
            yaziOlcegi: olcek,
            renkler: renkler,
          ));
          await tester.tap(find.text('aç'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Uzun içerik kaydırılarak son düğmeye ulaşılır.
          await tester.scrollUntilVisible(find.text('Vazgeç'), 100,
              scrollable: find
                  .descendant(
                    of: find.byType(Dialog),
                    matching: find.byType(Scrollable),
                  )
                  .first);
          expect(find.text('Vazgeç').hitTestable(), findsOneWidget);
        });
      }
    }
  });

  group('KilBildirim', () {
    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      final ad = renkler.sertGolge ? 'açık' : 'koyu';
      testWidgets('$ad: türlere göre renkler', (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_sar(
          Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          }),
          renkler: renkler,
        ));

        final basari =
            KilBildirim.olustur(ctx, 'Kaydedildi', tur: KilBildirimTuru.basari);
        expect(basari.backgroundColor, renkler.vurgu);
        final hata =
            KilBildirim.olustur(ctx, 'Olmadı', tur: KilBildirimTuru.hata);
        expect(hata.backgroundColor, renkler.hata);
        final uyari =
            KilBildirim.olustur(ctx, 'Sınır', tur: KilBildirimTuru.uyari);
        expect(uyari.backgroundColor, renkler.oneCikanKart);
        final bilgi = KilBildirim.olustur(ctx, 'Bilgi');
        expect(bilgi.backgroundColor, isNull, reason: 'temanın rengi');
        // Koyu modda uyarı kenarla ayrılır.
        final kenar = (uyari.shape as RoundedRectangleBorder).side;
        expect(kenar == BorderSide.none, renkler.sertGolge);
      });
    }

    testWidgets('gösterilir, yazı ve ikon zemine uygun, eylem çalışır',
        (tester) async {
      var basildi = false;
      await tester.pumpWidget(_sar(_acici((c) => KilBildirim.goster(
            c,
            'Giriş gerekli',
            tur: KilBildirimTuru.hata,
            eylemEtiketi: 'Giriş Yap',
            onEylem: () => basildi = true,
          ))));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();

      final yazi = tester.widget<Text>(find.text('Giriş gerekli'));
      expect(yazi.style?.color, KilRenkleri.acik.hataUstuYazi);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();
      expect(basildi, isTrue);
    });

    testWidgets('320 genişlik, 3.2 kat yazıda taşma yok', (tester) async {
      _ekran(tester, 320, 640);
      await tester.pumpWidget(_sar(
        _acici((c) => KilBildirim.goster(c, _uzun, tur: KilBildirimTuru.basari)),
        yaziOlcegi: 3.2,
      ));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('KilSecenek emoji verilince ikon yerine bayrak gösterir',
      (tester) async {
    await tester.pumpWidget(_sar(KilSecimListesi(secenekler: [
      KilSecenek(
        ikon: Icons.language_rounded,
        emoji: '🇹🇷',
        etiket: 'Türkçe',
        secili: true,
        onTap: () {},
      ),
    ])));
    expect(find.text('🇹🇷'), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}

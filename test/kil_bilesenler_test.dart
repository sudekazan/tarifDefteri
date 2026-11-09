import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';

// Bileşenler fontsuz, yalnızca KilRenkleri içeren bir temayla denenir;
// google_fonts testte font indirmeye çalışmasın.
Widget sar(
  Widget child, {
  KilRenkleri renkler = KilRenkleri.acik,
  bool hareketiAzalt = false,
}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: renkler.sertGolge ? Brightness.light : Brightness.dark,
      extensions: [renkler],
    ),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: hareketiAzalt),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('KilDugme', () {
    testWidgets('dokununca çalışır, en az 48 yüksekliğinde', (tester) async {
      var sayac = 0;
      await tester.pumpWidget(
          sar(KilDugme.birincil(etiket: 'Kaydet', onPressed: () => sayac++)));
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      expect(sayac, 1);
      expect(tester.getSize(find.byType(KilDugme)).height,
          greaterThanOrEqualTo(48));
    });

    testWidgets('onPressed null ise dokunmak bir şey yapmaz', (tester) async {
      await tester.pumpWidget(
          sar(const KilDugme.ikincil(etiket: 'Pasif', onPressed: null)));
      await tester.tap(find.text('Pasif'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byType(KilDugme)),
          isSemantics(isButton: true, hasEnabledState: true, isEnabled: false));
    });

    testWidgets('hareketi azalt açıkken geçiş süresi sıfır', (tester) async {
      await tester.pumpWidget(sar(
        KilDugme.vurgu(etiket: 'Pişir', onPressed: () {}),
        hareketiAzalt: true,
      ));
      final kap = tester.widget<AnimatedContainer>(find.descendant(
        of: find.byType(KilDugme),
        matching: find.byType(AnimatedContainer),
      ));
      expect(kap.duration, Duration.zero);
    });

    testWidgets('hareketi azalt kapalıyken 150–200 ms', (tester) async {
      await tester
          .pumpWidget(sar(KilDugme.vurgu(etiket: 'Pişir', onPressed: () {})));
      final kap = tester.widget<AnimatedContainer>(find.descendant(
        of: find.byType(KilDugme),
        matching: find.byType(AnimatedContainer),
      ));
      expect(kap.duration.inMilliseconds, inInclusiveRange(150, 200));
    });

    testWidgets('açık modda sert gölge, koyu modda yok', (tester) async {
      BoxDecoration susleme() => tester
          .widget<AnimatedContainer>(find.descendant(
            of: find.byType(KilDugme),
            matching: find.byType(AnimatedContainer),
          ))
          .decoration! as BoxDecoration;

      await tester.pumpWidget(
          sar(KilDugme.birincil(etiket: 'A', onPressed: () {})));
      expect(susleme().boxShadow, isNotEmpty);
      expect(susleme().boxShadow!.first.blurRadius, 0);

      await tester.pumpWidget(sar(
        KilDugme.birincil(etiket: 'A', onPressed: () {}),
        renkler: KilRenkleri.koyu,
      ));
      await tester.pumpAndSettle();
      expect(susleme().boxShadow, isEmpty);
    });
  });

  group('KilYuvarlakDugme', () {
    testWidgets('dokunma alanı 48, etiket ekran okuyucuda', (tester) async {
      var basildi = false;
      await tester.pumpWidget(sar(KilYuvarlakDugme(
        ikon: Icons.close,
        etiket: 'Kapat',
        onPressed: () => basildi = true,
      )));
      expect(tester.getSize(find.byType(KilYuvarlakDugme)),
          const Size(48, 48));
      expect(find.bySemanticsLabel('Kapat'), findsOneWidget);
      await tester.tap(find.byType(KilYuvarlakDugme));
      await tester.pumpAndSettle();
      expect(basildi, isTrue);
    });
  });

  group('KilCip', () {
    testWidgets('dokununca seçim tersine döner, seçiliyken onay işareti var',
        (tester) async {
      bool? yeniDeger;
      await tester.pumpWidget(sar(KilCip(
        etiket: 'Tatlı',
        secili: false,
        onSelected: (d) => yeniDeger = d,
      )));
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(tester.getSize(find.byType(KilCip)).height,
          greaterThanOrEqualTo(48));
      await tester.tap(find.text('Tatlı'));
      expect(yeniDeger, isTrue);

      await tester.pumpWidget(sar(
          KilCip(etiket: 'Tatlı', secili: true, onSelected: (_) {})));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('KilOnayKutusu', () {
    testWidgets('etiketli satırın tamamı dokunulabilir', (tester) async {
      bool? yeniDeger;
      await tester.pumpWidget(sar(SizedBox(
        width: 300,
        child: KilOnayKutusu(
          deger: false,
          etiket: 'Un',
          onChanged: (d) => yeniDeger = d,
        ),
      )));
      await tester.tap(find.text('Un'));
      expect(yeniDeger, isTrue);
      expect(tester.getSize(find.byType(KilOnayKutusu)).height,
          greaterThanOrEqualTo(48));
    });

    testWidgets('etiketsiz kutu 48x48 ve işaretli bilgisi var',
        (tester) async {
      await tester.pumpWidget(
          sar(KilOnayKutusu(deger: true, onChanged: (_) {})));
      expect(tester.getSize(find.byType(KilOnayKutusu)), const Size(48, 48));
      expect(tester.getSemantics(find.byType(KilOnayKutusu)),
          isSemantics(hasCheckedState: true, isChecked: true));
    });
  });

  group('KilKart', () {
    testWidgets('koyu modda üst çizgi var, gölge yok', (tester) async {
      await tester.pumpWidget(sar(
        const KilKart(child: Text('Kart')),
        renkler: KilRenkleri.koyu,
      ));
      final kap = tester.widget<Container>(find
          .descendant(of: find.byType(KilKart), matching: find.byType(Container))
          .first);
      expect((kap.decoration! as BoxDecoration).boxShadow, isNull);
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('dokunulabilir kart çalışır', (tester) async {
      var sayac = 0;
      await tester.pumpWidget(
          sar(KilKart(onTap: () => sayac++, child: const Text('Çorba'))));
      await tester.tap(find.text('Çorba'));
      expect(sayac, 1);
    });
  });

  group('KilAltSayfa', () {
    testWidgets('başlık ve içerikle açılır', (tester) async {
      await tester.pumpWidget(sar(Builder(
        builder: (context) => TextButton(
          onPressed: () => KilAltSayfa.goster<void>(
            context,
            baslik: 'Yeni tarif',
            builder: (_) => const Text('İçerik'),
          ),
          child: const Text('Aç'),
        ),
      )));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(find.text('Yeni tarif'), findsOneWidget);
      expect(find.text('İçerik'), findsOneWidget);
    });
  });
}

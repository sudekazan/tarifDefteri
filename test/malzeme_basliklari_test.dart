import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/utils/malzeme_basliklari.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/yemek_modu_parcalari.dart';

void main() {
  group('malzemeBaslikIndeksleri', () {
    test('işaretli listede işaretsiz, rakamsız satırlar başlıktır', () {
      final satirlar = [
        'Kek İçin',
        '* 3 adet havuç (rendelenmiş)',
        '* 1 paket vanilin',
        'Üzeri İçin',
        '* 1 su bardağı pudra şekeri',
      ];
      expect(malzemeBaslikIndeksleri(satirlar), {0, 3});
    });

    test('":" ile biten rakamsız satır başlıktır', () {
      expect(malzemeBaslikIndeksleri(['Sos için:', '2 domates', 'tuz']), {0});
    });

    test('işaretsiz listede rakamsız malzeme başlık sayılmaz', () {
      expect(
        malzemeBaslikIndeksleri(['2 yumurta', 'tuz', 'karabiber']),
        isEmpty,
      );
    });

    test('rakam içeren satır başlık olmaz', () {
      expect(
        malzemeBaslikIndeksleri(['* 1 yumurta', '2 kişilik sos:', '½ limon']),
        isEmpty,
      );
    });
  });

  test('malzemeIsaretsiz baştaki madde işaretini atar', () {
    expect(malzemeIsaretsiz('* 3 adet yumurta'), '3 adet yumurta');
    expect(malzemeIsaretsiz('- tuz'), 'tuz');
    expect(malzemeIsaretsiz('1-2 diş sarımsak'), '1-2 diş sarımsak');
  });

  testWidgets('başlık satırı onay kutusu olmadan çizilir ve dokunulmaz', (
    tester,
  ) async {
    final dokunulan = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [KilRenkleri.acik]),
        home: Scaffold(
          body: YemekMalzemeListesi(
            malzemeler: const ['Kek İçin', '* 3 adet yumurta'],
            secililer: const {},
            basliklar: const {0},
            onDegistir: dokunulan.add,
            bosMetni: '',
          ),
        ),
      ),
    );

    expect(find.byType(YemekMalzemeSatiri), findsOneWidget);
    await tester.tap(find.text('Kek İçin'));
    await tester.tap(find.text('* 3 adet yumurta'));
    expect(dokunulan, [1]);
  });
}

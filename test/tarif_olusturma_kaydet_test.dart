import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/sayfalar/tarif_olusturma.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';

/// Sayfayı bir düğmeyle açar; "Kaydet" ile dönen tarifi [sonuc]'a yazar.
Widget _uygulama(TarifData tarif, ValueChanged<Object?> sonuc) {
  return MaterialApp(
    theme: ThemeData(extensions: const [KilRenkleri.acik]),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            sonuc(await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TarifOlusturma(tarifData: tarif),
              ),
            ));
          },
          child: const Text('aç'),
        ),
      ),
    ),
  );
}

TarifData _kayitliTarif(String bolumlerJson) => TarifData(
      tarif_id: 5,
      tarif_adi: 'Menemen',
      tarif_aciklama: 'Malzemeler\n* 2 yumurta',
      tarif_aciklama_json: bolumlerJson,
      tarif_resimler: [],
      klasor_id: 1,
    );

Future<void> _ac(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('kutuda bekleyen metin kaydederken maddeye çevrilir',
      (tester) async {
    Object? sonuc;
    await tester.pumpWidget(_uygulama(
      _kayitliTarif(
        '[{"title":"Malzemeler","type":"malzemeler","items":["2 yumurta"]},'
        '{"title":"Yapılışı","type":"yapilis","items":[]}]',
      ),
      (s) => sonuc = s,
    ));
    await _ac(tester);

    // 0: tarif adı, 1: Malzemeler kutusu, 2: Yapılışı kutusu
    await tester.enterText(find.byType(TextField).at(1), '1 domates');
    await tester.enterText(find.byType(TextField).at(2), 'Hepsini pişir');
    await tester.tap(find.text('recipe_edit_save_button'));
    await tester.pumpAndSettle();

    final tarif = sonuc as TarifData;
    expect(tarif.tarif_aciklama, contains('* 1 domates'));
    expect(tarif.tarif_aciklama, contains('1. Hepsini pişir'));
    expect(tarif.tarif_aciklama_json, contains('1 domates'));
  });

  testWidgets('tek madde kutuda bekliyorsa "madde ekleyin" hatası çıkmaz',
      (tester) async {
    Object? sonuc;
    await tester.pumpWidget(_uygulama(
      _kayitliTarif('[{"title":"Malzemeler","type":"malzemeler","items":[]}]'),
      (s) => sonuc = s,
    ));
    await _ac(tester);

    await tester.enterText(find.byType(TextField).at(1), '3 biber');
    await tester.tap(find.text('recipe_edit_save_button'));
    await tester.pumpAndSettle();

    expect((sonuc as TarifData).tarif_aciklama, contains('* 3 biber'));
  });

  testWidgets('silinen bölümün kutusundaki yazı alttaki bölüme geçmez',
      (tester) async {
    Object? sonuc;
    await tester.pumpWidget(_uygulama(
      _kayitliTarif(
        '[{"title":"Malzemeler","type":"malzemeler","items":["2 yumurta"]},'
        '{"title":"Yapılışı","type":"yapilis","items":["Pişir"]}]',
      ),
      (s) => sonuc = s,
    ));
    await _ac(tester);

    await tester.enterText(find.byType(TextField).at(1), 'yarım kalan');
    await tester.tap(find.byTooltip('recipe_edit_delete_section').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('recipe_edit_save_button'));
    await tester.pumpAndSettle();

    final tarif = sonuc as TarifData;
    expect(tarif.tarif_aciklama, isNot(contains('yarım kalan')));
    expect(tarif.tarif_aciklama, contains('1. Pişir'));
  });
}

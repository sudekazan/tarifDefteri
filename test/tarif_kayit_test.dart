import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:tarif_defteri/utils/tarif_kayit.dart';

TarifData _tarif({
  int id = 10,
  String ad = 'Menemen',
  int klasor = 7,
  List<String> resimler = const [],
}) {
  return TarifData(
    tarif_id: id,
    tarif_adi: ad,
    tarif_aciklama: 'Malzemeler\n* 2 yumurta',
    tarif_resimler: List.of(resimler),
    klasor_id: klasor,
  );
}

Future<List<TarifData>> _kayitlilar(int klasor) async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList('tarifler_$klasor') ?? [])
      .map((e) => TarifData.fromMap(json.decode(e)))
      .toList();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('tarifiCihazdaGuncelle', () {
    test('düzenlenen tarif kendi klasöründeki kaydın yerine yazılır',
        () async {
      await yeniTarifiCihazaYaz(_tarif(id: 10, ad: 'Menemen'));
      await yeniTarifiCihazaYaz(_tarif(id: 11, ad: 'Çorba'));

      final bulundu =
          await tarifiCihazdaGuncelle(_tarif(id: 10, ad: 'Soğanlı menemen'));

      expect(bulundu, isTrue);
      final kayitli = await _kayitlilar(7);
      expect(kayitli.map((t) => t.tarif_adi), ['Soğanlı menemen', 'Çorba']);
    });

    test('kaydı olmayan tarif eklenmez', () async {
      await yeniTarifiCihazaYaz(_tarif(id: 10));

      final bulundu = await tarifiCihazdaGuncelle(_tarif(id: 99, ad: 'Yok'));

      expect(bulundu, isFalse);
      expect((await _kayitlilar(7)).single.tarif_adi, 'Menemen');
    });
  });

  group('internet yokken kayıt', () {
    test('bulut yazması hiç bitmese de tarif cihazda durur', () async {
      final tarif = _tarif();
      final bitmeyen = Completer<List<String>>();

      await yeniTarifiCihazaYaz(tarif);
      unawaited(tarifiArkadanBulutaGonder(tarif, (_) => bitmeyen.future));

      expect((await _kayitlilar(7)).single.tarif_adi, 'Menemen');
    });

    test('fotoğraf sonradan yüklenince bulut adresi cihaza yazılır',
        () async {
      final tarif = _tarif(resimler: ['/yerel/a.jpg']);
      await yeniTarifiCihazaYaz(tarif);

      await tarifiArkadanBulutaGonder(
        tarif,
        (_) async => ['https://ornek.test/a.jpg'],
      );

      expect(
        (await _kayitlilar(7)).single.tarif_resimler,
        ['https://ornek.test/a.jpg'],
      );
    });

    test('fotoğraflar bu arada değiştiyse cihazdaki kayda dokunulmaz',
        () async {
      final tarif = _tarif(resimler: ['/yerel/a.jpg']);
      await yeniTarifiCihazaYaz(tarif);
      final yukleme = Completer<List<String>>();
      final gonderim = tarifiArkadanBulutaGonder(tarif, (_) => yukleme.future);

      await tarifiCihazdaGuncelle(_tarif(resimler: ['/yerel/b.jpg']));
      yukleme.complete(['https://ornek.test/a.jpg']);
      await gonderim;

      expect((await _kayitlilar(7)).single.tarif_resimler, ['/yerel/b.jpg']);
    });

    test('bulut hatası tarifi cihazdan silmez', () async {
      final tarif = _tarif();
      await yeniTarifiCihazaYaz(tarif);

      await tarifiArkadanBulutaGonder(
        tarif,
        (_) async => throw Exception('ağ yok'),
      );

      expect((await _kayitlilar(7)).single.tarif_adi, 'Menemen');
    });
  });

  test('tarifiCihazdanSil yalnızca o tarifi siler', () async {
    await yeniTarifiCihazaYaz(_tarif(id: 10));
    await yeniTarifiCihazaYaz(_tarif(id: 11, ad: 'Çorba'));

    await tarifiCihazdanSil(7, 10);

    expect((await _kayitlilar(7)).single.tarif_adi, 'Çorba');
  });
}

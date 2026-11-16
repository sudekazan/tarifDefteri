import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/services/tarif_paylasim_service.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:tarif_defteri/utils/tarif_bolumleri.dart';

const _resim = 'https://firebasestorage.googleapis.com/v0/b/x/o/a.jpg?alt=media';

TarifData _tarif({String aciklama = '', String? json}) => TarifData(
      tarif_id: 42,
      tarif_adi: 'Mercimek Çorbası',
      tarif_aciklama: aciklama,
      tarif_aciklama_json: json,
      tarif_resimler: const [],
      klasor_id: 2,
    );

void main() {
  group('linktenPaylasimKodu', () {
    test('geçerli linkten kodu okur', () {
      expect(linktenPaylasimKodu(Uri.parse('https://tarifly.web.app/t/AbCd2345')), 'AbCd2345');
      expect(linktenPaylasimKodu(Uri.parse('https://tarifly.web.app/t/AbCd2345/')), 'AbCd2345');
    });

    test('başka adres, yol ya da bozuk kod null', () {
      expect(linktenPaylasimKodu(Uri.parse('https://ornek.com/t/AbCd2345')), isNull);
      expect(linktenPaylasimKodu(Uri.parse('https://tarifly.web.app/x/AbCd2345')), isNull);
      expect(linktenPaylasimKodu(Uri.parse('https://tarifly.web.app/t/kisa')), isNull);
      expect(linktenPaylasimKodu(Uri.parse('https://tarifly.web.app/t/AbCd2345/ek')), isNull);
      expect(linktenPaylasimKodu(Uri.parse('https://tarifly.web.app/')), isNull);
      expect(linktenPaylasimKodu(Uri.parse('tarifly://t/AbCd2345')), isNull);
    });

    test('üretilen kod linkten geri okunur', () {
      final kod = yeniPaylasimKodu(Random(1));
      expect(kod.length, 8);
      expect(kod, isNot(matches(RegExp('[0O1lI]'))));
      expect(linktenPaylasimKodu(Uri.parse(paylasimLinki(kod))), kod);
    });
  });

  group('paylaşım belgesi', () {
    final bolumler = [
      {'title': 'Malzemeler', 'type': 'malzemeler', 'items': ['1 su bardağı mercimek'], 'isExpanded': true},
      {'title': 'Yapılışı', 'type': 'yapilis', 'items': ['Haşla', 'Blenderdan geçir']},
    ];

    test('yalnızca Storage fotoğrafları, en fazla 5 tane', () {
      final veri = paylasimBelgesi(
        tarif: _tarif(),
        bolumler: bolumler,
        sahipUid: 'u1',
        resimler: ['/cihaz/a.jpg', 'https://baska.com/b.jpg', for (var i = 0; i < 7; i++) _resim],
        dil: 'tr',
      );
      expect(veri['resimler'], List.filled(5, _resim));
      expect(veri['sahipUid'], 'u1');
      expect(veri['tarifId'], 42);
      expect((veri['bolumler'] as List).first, {
        'title': 'Malzemeler',
        'type': 'malzemeler',
        'items': ['1 su bardağı mercimek'],
      });
    });

    test('alıcının tarifi: yeni kimlik, seçilen klasör, bölümler JSON', () {
      final veri = paylasimBelgesi(
        tarif: _tarif(aciklama: 'ham metin'),
        bolumler: bolumler,
        sahipUid: 'u1',
        resimler: const [],
        dil: 'tr',
      );
      final tarif = paylasilandanTarif(veri, klasorId: 7, resimler: ['/yerel.jpg'], simdi: 1000);
      expect(tarif.tarif_id, 1000);
      expect(tarif.klasor_id, 7);
      expect(tarif.tarif_adi, 'Mercimek Çorbası');
      expect(tarif.tarif_aciklama, 'ham metin');
      expect(tarif.tarif_resimler, ['/yerel.jpg']);
      expect(tarif.isFavorite, isFalse);
      expect(json.decode(tarif.tarif_aciklama_json!), (veri['bolumler'] as List));
    });

    test('bozuk veri çökmez', () {
      final veri = <String, dynamic>{
        'ad': 'X',
        'bolumler': ['bozuk', {'title': 'A', 'items': 'liste değil'}],
        'resimler': [3, _resim, 'http://firebasestorage.googleapis.com/a'],
      };
      expect(paylasimBolumleri(veri), [
        {'title': 'A', 'type': '', 'items': <String>[]},
      ]);
      expect(paylasimResimleri(veri), [_resim]);
      expect(paylasimBolumleri({}), isEmpty);
      final tarif = paylasilandanTarif({}, klasorId: 1, resimler: const []);
      expect(tarif.tarif_adi, '');
      expect(tarif.tarif_aciklama_json, isNull);
    });
  });

  group('tarifBolumleriniCoz', () {
    test('JSON bölümleri okunur', () {
      final t = _tarif(json: jsonEncode([
        {'title': 'Sos', 'type': 'sos', 'items': ['salça']},
      ]));
      final b = tarifBolumleriniCoz(t, varsayilanBaslik: 'Malzemeler');
      expect(b.single['type'], 'sos');
      expect(b.single['items'], ['salça']);
    });

    test('eski düz metin bölümlere ayrılır', () {
      final t = _tarif(aciklama: '''
Malzemeler:
- 1 su bardağı mercimek
- 1 soğan
Yapılışı:
1. Soğanı kavur
2. Mercimeği ekle
   ve kaynat
''');
      final b = tarifBolumleriniCoz(t, varsayilanBaslik: 'Malzemeler');
      expect(b.map((e) => e['type']), ['malzemeler', 'yapilis']);
      expect(b[0]['items'], ['1 su bardağı mercimek', '1 soğan']);
      expect(b[1]['items'], ['Soğanı kavur', 'Mercimeği ekle ve kaynat']);
    });

    test('başlıksız maddeler varsayılan bölüme girer', () {
      final b = tarifBolumleriniCoz(_tarif(aciklama: '• tuz\n• biber'), varsayilanBaslik: 'Ingredients');
      expect(b.single['title'], 'Ingredients');
      expect(b.single['items'], ['tuz', 'biber']);
    });
  });

  test('tarifDuzMetni yapılışı numaralar, diğerlerini işaretler', () {
    final metin = tarifDuzMetni(_tarif(), [
      {'title': 'Malzemeler', 'type': 'malzemeler', 'items': ['mercimek']},
      {'title': 'Yapılışı', 'type': 'yapilis', 'items': ['haşla', 'karıştır']},
    ]);
    expect(metin, startsWith('📖 Mercimek Çorbası\n\n'));
    expect(metin, contains('• mercimek\n'));
    expect(metin, contains('1. haşla\n2. karıştır\n'));
  });
}

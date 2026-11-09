import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';

void main() {
  test('varsayılan ikon kodu gerçekten klasör ikonu', () {
    expect(KlasorData.varsayilanIkon, Icons.folder.codePoint);
    // Eski kod bugünkü fontta başka bir ikon; bu yüzden ekranda çevrilir.
    expect(KlasorData.eskiVarsayilanIkon, Icons.forward_5.codePoint);
  });

  test('yeni klasör ikon verilmezse klasör ikonuyla açılır', () {
    final k = KlasorData(klasor_id: 1, klasor_adi: 'Tariflerim');
    expect(k.iconCode, Icons.folder.codePoint);
    expect(k.icon.codePoint, Icons.folder.codePoint);
  });

  test('eski kayıtta klasör ikonu görünür, kayıtlı değer değişmez', () {
    final eski = KlasorData.fromMap({
      'klasor_id': 7,
      'klasor_adi': 'Tatlılar',
      'iconCode': 0xe2c7,
      'updatedAt': 1,
    });
    expect(eski.icon.codePoint, Icons.folder.codePoint);
    expect(eski.toMap()['iconCode'], 0xe2c7);

    final kodsuz = KlasorData.fromMap({
      'klasor_id': 8,
      'klasor_adi': 'Çorbalar',
      'updatedAt': 1,
    });
    expect(kodsuz.icon.codePoint, Icons.folder.codePoint);
    expect(kodsuz.toMap()['iconCode'], 0xe2c7);
  });

  test('seçilmiş diğer ikonlar olduğu gibi görünür', () {
    final k = KlasorData(
      klasor_id: 2,
      klasor_adi: 'Pastalar',
      iconCode: Icons.cake.codePoint,
    );
    expect(k.icon.codePoint, Icons.cake.codePoint);
  });
}

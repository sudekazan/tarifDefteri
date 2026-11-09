import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/utils/porsiyon_olcekleyici.dart';

void main() {
  test('çarpan 1 iken satır değişmez', () {
    expect(olcekleMalzeme('2 su bardağı un', 1.0), '2 su bardağı un');
  });

  test('tam sayı ölçeklenir', () {
    expect(olcekleMalzeme('2 su bardağı un', 2.0), '4 su bardağı un');
  });

  test('basit kesir ölçeklenir', () {
    expect(olcekleMalzeme('1/2 çay kaşığı tuz', 2.0), '1 çay kaşığı tuz');
  });

  test('karışık kesir ölçeklenir', () {
    expect(olcekleMalzeme('1 1/2 su bardağı un', 2.0), '3 su bardağı un');
  });

  test('birime bitişik sayı ölçeklenir', () {
    expect(olcekleMalzeme('200g un', 2.0), '400g un');
  });

  test('virgüllü ondalık virgülle yazılır', () {
    expect(olcekleMalzeme('1,5 kg et', 0.5), '0,75 kg et');
  });

  test('aralıklara dokunulmaz', () {
    expect(olcekleMalzeme('2-3 yemek kaşığı yağ', 2.0), '2-3 yemek kaşığı yağ');
  });

  test('virgüllü kesir çökmez', () {
    expect(() => olcekleMalzeme('1,5/2 su bardağı süt', 2.0), returnsNormally);
  });

  test('sıfır paydalı kesir çökmez ve satırı korur', () {
    expect(olcekleMalzeme('1/0 bardak', 2.0), '1/0 bardak');
  });

  test('sayı yoksa satır değişmez', () {
    expect(olcekleMalzeme('Bir tutam tuz', 2.0), 'Bir tutam tuz');
  });
}

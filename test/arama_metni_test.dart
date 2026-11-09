import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/utils/arama_metni.dart';

void main() {
  test('noktasız ı ile büyük I eşleşir', () {
    expect(aramaEslesir('Islak Kek', 'ıslak'), isTrue);
  });

  test('noktalı İ ile küçük i eşleşir', () {
    expect(aramaEslesir('İçli Köfte', 'içli'), isTrue);
  });

  test('büyük harfle yazılan arama bulunur', () {
    expect(aramaEslesir('mercimek çorbası', 'ÇORBASI'), isTrue);
  });

  test('alakasız metin eşleşmez', () {
    expect(aramaEslesir('Mercimek Çorbası', 'kek'), isFalse);
  });
}

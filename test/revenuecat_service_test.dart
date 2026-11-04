import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';

void main() {
  test('kullanıcı mağaza penceresinde vazgeçerse sonuç iptal olur', () {
    // RevenueCat'te 1 = purchaseCancelledError
    expect(RevenueCatService.sonucFromError(PlatformException(code: '1')), SatinAlmaSonucu.iptal);
  });

  test('diğer RevenueCat hataları hata sayılır', () {
    // 2 = storeProblemError
    expect(RevenueCatService.sonucFromError(PlatformException(code: '2')), SatinAlmaSonucu.hata);
  });

  test('sayı olmayan hata kodu çökmeden hata sayılır', () {
    expect(RevenueCatService.sonucFromError(PlatformException(code: 'abc')), SatinAlmaSonucu.hata);
  });
}

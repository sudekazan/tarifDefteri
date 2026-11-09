import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';

void main() {
  group('AI kalan hak sayacı', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('hiç senkronize edilmediyse ücretsiz günlük hak kadar', () async {
      expect(await RevenueCatService.getRemainingAiUses(), RevenueCatService.freeDailyAiLimit);
      expect(await RevenueCatService.canUseAi(), isTrue);
    });

    test('reklam bonusuyla 3ün üstündeki kalan hak kırpılmaz', () async {
      await RevenueCatService.syncRemainingFromServer(5);
      expect(await RevenueCatService.getRemainingAiUses(), 5);
    });

    test('hak bitince ön kontrol AI kullanımını engeller', () async {
      await RevenueCatService.syncRemainingFromServer(0);
      expect(await RevenueCatService.canUseAi(), isFalse);
    });

    test('önceki günlerin sayaçları temizlenir', () async {
      SharedPreferences.setMockInitialValues({
        'ai_usage_2026-01-01': 2,
        'ai_remaining_2026-01-01': 1,
        'tema': 'koyu',
      });
      await RevenueCatService.syncRemainingFromServer(2);
      final keys = (await SharedPreferences.getInstance()).getKeys();
      expect(keys.where((k) => k.startsWith('ai_')).length, 1);
      expect(keys, contains('tema'));
    });
  });

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

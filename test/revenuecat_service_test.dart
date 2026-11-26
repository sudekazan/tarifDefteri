import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';
import 'package:tarif_defteri/utils/ai_modu.dart';

void main() {
  group('AI kalan hak sayacı', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('hiç senkronize edilmediyse ücretsiz haftalık hak kadar', () async {
      expect(await RevenueCatService.getRemainingAiUses(mod: AiModu.malzeme),
          RevenueCatService.freeWeeklyAiLimit);
      expect(await RevenueCatService.canUseAi(mod: AiModu.malzeme), isTrue);
    });

    test('reklam bonusuyla 5in üstündeki kalan hak kırpılmaz', () async {
      await RevenueCatService.syncRemainingFromServer(7, mod: AiModu.malzeme);
      expect(await RevenueCatService.getRemainingAiUses(mod: AiModu.malzeme), 7);
    });

    test('hak bitince ön kontrol AI kullanımını engeller', () async {
      await RevenueCatService.syncRemainingFromServer(0, mod: AiModu.malzeme);
      expect(await RevenueCatService.canUseAi(mod: AiModu.malzeme), isFalse);
    });

    test('iki özelliğin hakkı ayrı sayılır', () async {
      await RevenueCatService.syncRemainingFromServer(0, mod: AiModu.malzeme);
      await RevenueCatService.syncRemainingFromServer(4, mod: AiModu.yemekAdi);
      expect(await RevenueCatService.canUseAi(mod: AiModu.malzeme), isFalse);
      expect(await RevenueCatService.getRemainingAiUses(mod: AiModu.yemekAdi), 4);
    });

    test('önceki haftaların ve eski günlük biçimin sayaçları temizlenir', () async {
      SharedPreferences.setMockInitialValues({
        'ai_usage_2026-01-01': 2,
        'ai_remaining_2026-01-01': 1,
        'ai_remaining_w_2026-01-05_ingredients': 3,
        'tema': 'koyu',
      });
      await RevenueCatService.syncRemainingFromServer(2, mod: AiModu.malzeme);
      await RevenueCatService.syncRemainingFromServer(5, mod: AiModu.yemekAdi);
      final keys = (await SharedPreferences.getInstance()).getKeys();
      expect(keys.where((k) => k.startsWith('ai_')).length, 2);
      expect(keys, contains('tema'));
    });

    test('hafta pazartesi 00:00 UTC başlar', () {
      expect(RevenueCatService.haftaBaslangici(DateTime.utc(2026, 11, 26, 12)), '2026-11-23');
      expect(RevenueCatService.haftaBaslangici(DateTime.utc(2026, 11, 23)), '2026-11-23');
      expect(RevenueCatService.haftaBaslangici(DateTime.utc(2026, 11, 22, 23, 59)), '2026-11-16');
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

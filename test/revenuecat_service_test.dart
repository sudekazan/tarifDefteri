import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/services/ai_recipe_service.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';

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

  group('reklam ek hakkı', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('haftada 3 ek hak kazanılınca reklam seçeneği kapanır', () async {
      expect(await RevenueCatService.bonusHakKaldiMi(), isTrue);
      for (var i = 0; i < RevenueCatService.maxWeeklyBonusUses; i++) {
        await RevenueCatService.bonusKazanildi();
      }
      expect(await RevenueCatService.bonusHakKaldiMi(), isFalse);
    });

    test('sunucu sınır doldu derse reklam seçeneği hemen kapanır', () async {
      await RevenueCatService.bonusHakkiniBitir();
      expect(await RevenueCatService.bonusHakKaldiMi(), isFalse);
    });

    test('önceki haftanın ek hak sayacı yeni haftayı etkilemez', () async {
      SharedPreferences.setMockInitialValues({'ai_bonus_w_2026-01-05': 3});
      expect(await RevenueCatService.bonusHakKaldiMi(), isTrue);
      await RevenueCatService.bonusKazanildi();
      final keys = (await SharedPreferences.getInstance()).getKeys();
      expect(keys.where((k) => k.startsWith('ai_bonus_w_')).length, 1);
    });
  });

  group('bonus yanıtı', () {
    test('200 ek hak verildi, kalan hak okunur', () {
      final s = AiRecipeService.bonusYanitiniCoz(200, '{"success":true,"remaining":2}');
      expect(s.durum, BonusDurumu.verildi);
      expect(s.kalan, 2);
    });

    test('429 haftalık ek hak sınırı', () {
      final s = AiRecipeService.bonusYanitiniCoz(
          429, '{"success":false,"message":"Weekly bonus ad limit reached."}');
      expect(s.durum, BonusDurumu.sinirDoldu);
    });

    test('429 saatlik istek sınırı ek hak sınırı sayılmaz', () {
      final s = AiRecipeService.bonusYanitiniCoz(
          429, '{"success":false,"rateLimited":true}');
      expect(s.durum, BonusDurumu.hata);
    });

    test('sunucu hatası', () {
      expect(AiRecipeService.bonusYanitiniCoz(503, '<html>').durum, BonusDurumu.hata);
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

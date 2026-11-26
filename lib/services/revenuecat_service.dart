import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// [RevenueCatService.purchasePackage] sonucu. [iptal], kullanıcının mağaza
/// penceresinde vazgeçtiğini belirtir; hata mesajı gösterilmemelidir.
enum SatinAlmaSonucu { basarili, iptal, hata }

class RevenueCatService {
  // Lütfen bu anahtarları kendi RevenueCat API anahtarlarınız ile değiştirin.
  static const _appleApiKey = 'appl_wzqpdBivjxBdcFMeuiwKdYiVWVW';
  static const _googleApiKey = 'goog_JBGkRQWPAQALDKKLXqiqwLNzmDr';

  // Entitlement ID (RevenueCat panelindeki kimlik)
  static const _entitlementID = 'recipe_keeper_custom_cookbook_pro';

  /// Ücretsiz kullanıcılar için klasör ve klasör başına tarif sınırları.
  /// Premium sayfasındaki "Sınırsız Klasör & Tarif" vaadinin karşılığı.
  static const int freeKlasorLimit = 3;
  static const int freeTarifPerKlasorLimit = 20;

  static bool _isPro = false;

  static bool get isProUser => _isPro;

  /// Yalnızca testler için (ör. mağaza görselleri reklamsız çizilsin).
  /// Analitiğe bildirmez.
  @visibleForTesting
  static set proDurumuTest(bool deger) => _isPro = deger;

  /// Pro durumunu günceller ve Firebase'e `is_pro` kullanıcı özelliği
  /// olarak bildirir.
  static void _setPro(bool isPro) {
    _isPro = isPro;
    AnalyticsService.setIsPro(isPro);
  }

  /// Son offering yükleme hatası / teşhis mesajı (UI'da göstermek için)
  static String? lastOfferingsError;
  static String? initError;

  static Future<void> init() async {
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      PurchasesConfiguration? configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey);
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
        await _firebaseKimliginiGonder();
        if (Platform.isIOS) await _appleAdsTokenToplamayiAc();
        await checkSubscriptionStatus();
      }
    } catch (e) {
      initError = e.toString();
      debugPrint('RevenueCat init error: $e');
    }
  }

  /// RevenueCat'in Firebase entegrasyonu için Firebase kurulum kimliğini
  /// müşteri özelliği olarak kaydeder; böylece yenileme, iptal ve deneme
  /// dönüşümü olayları Firebase'e düşer. Giriş yapınca tekrar çağrılır,
  /// çünkü kimlik o andaki RevenueCat kullanıcısına yazılır.
  static Future<void> _firebaseKimliginiGonder() async {
    try {
      final id = await AnalyticsService.appInstanceId();
      if (id != null && id.isNotEmpty) {
        await Purchases.setFirebaseAppInstanceId(id);
      }
    } catch (e) {
      debugPrint('RevenueCat Firebase kimliği hatası: $e');
    }
  }

  /// Aboneliklerin hangi Apple Ads kampanyasından geldiğini görmek için
  /// AdServices token'ını toplamaya başlar (yalnızca iOS). ATT izni gerektirmez.
  static Future<void> _appleAdsTokenToplamayiAc() async {
    try {
      await Purchases.enableAdServicesAttributionTokenCollection();
    } catch (e) {
      debugPrint('RevenueCat AdServices hatası: $e');
    }
  }

  /// RevenueCat kimliğini Firebase UID'ye bağlar.
  /// Bu bağlantı yapılmazsa backend, bir isteğin hangi kullanıcıya ait
  /// aboneliğe karşılık geldiğini bilemez (bkz. backend/server.js
  /// isProUserViaRevenueCat). Firebase girişi/kayıt başarılı olduğunda ve
  /// uygulama açılışında zaten giriş yapılmışsa çağrılmalıdır.
  static Future<void> loginWithFirebaseUid(String firebaseUid) async {
    try {
      final result = await Purchases.logIn(firebaseUid);
      _setPro(_isEntitlementActive(result.customerInfo));
      await _firebaseKimliginiGonder();
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  /// Kullanıcı çıkış yaptığında RevenueCat kimliğini anonim hale döndürür
  /// (aynı cihazda başka bir kullanıcı giriş yaparsa abonelikler karışmasın).
  static Future<void> logoutFromRevenueCat() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      // logOut anonim kullanıcıda ya da ağ hatasında hata fırlatabilir; yine
      // de çıkış yapan kullanıcı bu cihazda Pro görünmeye devam etmemeli.
      debugPrint('RevenueCat logOut error: $e');
    } finally {
      _setPro(false);
    }
  }

  static bool _isEntitlementActive(CustomerInfo customerInfo) {
    return (customerInfo.entitlements.all[_entitlementID]?.isActive ?? false) ||
        (customerInfo.entitlements.all['pro']?.isActive ?? false) ||
        (customerInfo.entitlements.all['premium']?.isActive ?? false);
  }

  static Future<bool> checkSubscriptionStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _setPro(_isEntitlementActive(customerInfo));
      return _isPro;
    } catch (e) {
      debugPrint('Check subscription error: $e');
      return false;
    }
  }

  static Future<SatinAlmaSonucu> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = (await Purchases.purchasePackage(package)).customerInfo;
      _setPro(_isEntitlementActive(customerInfo));
      return _isPro ? SatinAlmaSonucu.basarili : SatinAlmaSonucu.hata;
    } on PlatformException catch (e) {
      debugPrint('Purchase error: $e');
      return sonucFromError(e);
    } catch (e) {
      debugPrint('Purchase error: $e');
      return SatinAlmaSonucu.hata;
    }
  }

  /// RevenueCat hatasını satın alma sonucuna çevirir: kullanıcının mağaza
  /// penceresinde vazgeçmesi [SatinAlmaSonucu.iptal], geri kalanı hata.
  @visibleForTesting
  static SatinAlmaSonucu sonucFromError(PlatformException e) {
    try {
      return PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError
          ? SatinAlmaSonucu.iptal
          : SatinAlmaSonucu.hata;
    } catch (_) {
      return SatinAlmaSonucu.hata; // Kod sayı değilse
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _setPro(_isEntitlementActive(customerInfo));
      return _isPro;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
  
  static Future<List<Offering>> getOfferings() async {
    if (initError != null) {
      lastOfferingsError = 'RevenueCat başlatılamadı:\n$initError';
      return [];
    }
    try {
      lastOfferingsError = null;
      debugPrint('RevenueCat: paketler sorgulanıyor...');
      Offerings offerings = await Purchases.getOfferings();
      debugPrint('RevenueCat offerings: all=${offerings.all.keys.toList()}, current=${offerings.current?.identifier}');
      
      if (offerings.all.isEmpty) {
        lastOfferingsError = 'RevenueCat: Hiç offering bulunamadı.\n(RevenueCat panelinde Offering tanımlanmamış veya mağaza [App Store / Play Store] ürünleri eşleşmedi).';
      } else if (offerings.current == null) {
        lastOfferingsError = 'RevenueCat: Current (varsayılan) Offering seçilmemiş.\nPanelde bir offering\'i "Current / Default" yapın.\n(Mevcut offeringler: ${offerings.all.keys.join(", ")})';
      } else if (offerings.current!.availablePackages.isEmpty) {
        lastOfferingsError = 'RevenueCat: Current offering (${offerings.current!.identifier}) içinde paket bulunamadı veya App Store ürünleri henüz onaylanmamış/çekilemedi.';
      }
      
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return [offerings.current!];
      } else if (offerings.all.isNotEmpty) {
        final withPackages = offerings.all.values.where((o) => o.availablePackages.isNotEmpty);
        if (withPackages.isNotEmpty) {
          return [withPackages.first];
        }
        return [offerings.all.values.first];
      }
    } catch (e) {
      debugPrint('Get offerings error: $e');
      lastOfferingsError = 'RevenueCat İstek Hatası:\n$e';
    }
    return [];
  }

  /// Ücretsiz haftalık AI hakkı; iki özellik ayrı sayılır (yemek adıyla 5,
  /// malzemeden 5). backend/server.js FREE_WEEKLY_AI_LIMIT ile aynı.
  static const int freeWeeklyAiLimit = 5;

  /// Haftanın başlangıcı (pazartesi, UTC) YYYY-MM-DD biçiminde. Sunucu
  /// sayacı da bu tarihe göre tutar; haklar pazartesi 00:00 UTC'de yenilenir.
  @visibleForTesting
  static String haftaBaslangici([DateTime? simdi]) {
    final utc = (simdi ?? DateTime.now()).toUtc();
    final gun = DateTime.utc(utc.year, utc.month, utc.day);
    final pazartesi = gun.subtract(
      Duration(days: gun.weekday - DateTime.monday),
    );
    return pazartesi.toIso8601String().substring(0, 10);
  }

  static String _aiAnahtari(String mod) =>
      'ai_remaining_w_${haftaBaslangici()}_$mod';

  /// Yerel hızlı ön kontrol; asıl karar backend'indir.
  static Future<bool> canUseAi({required String mod}) async {
    if (_isPro) return true;
    return await getRemainingAiUses(mod: mod) > 0;
  }

  /// Backend'in döndürdüğü gerçek "kalan hak" sayısını yerelde saklar.
  /// Reklam bonuslarıyla kalan hak 5'in üstüne çıkabildiği için kırpılmaz.
  static Future<void> syncRemainingFromServer(
    int? remaining, {
    required String mod,
  }) async {
    if (remaining == null || _isPro) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_aiAnahtari(mod), remaining < 0 ? 0 : remaining);

    // Önceki haftaların ve eski günlük biçimin sayaçlarını temizle.
    final buHafta = 'ai_remaining_w_${haftaBaslangici()}_';
    for (final key in prefs.getKeys().toList()) {
      if ((key.startsWith('ai_remaining_') || key.startsWith('ai_usage_')) &&
          !key.startsWith(buHafta)) {
        await prefs.remove(key);
      }
    }
  }

  /// Reklamla haftada kazanılabilecek en fazla ek hak (iki tür toplamı).
  /// backend/server.js MAX_BONUS_USES_PER_WEEK ile aynı.
  static const int maxWeeklyBonusUses = 3;

  static String _bonusAnahtari() => 'ai_bonus_w_${haftaBaslangici()}';

  /// Bu hafta reklamla ek hak kazanılabilir mi? Değilse hak bitti
  /// penceresinde reklam seçeneği gösterilmez (izlenen reklam boşa gider).
  static Future<bool> bonusHakKaldiMi() async {
    if (_isPro) return false;
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_bonusAnahtari()) ?? 0) < maxWeeklyBonusUses;
  }

  /// Sunucu reklam ek hakkı verdiğinde sayılır.
  static Future<void> bonusKazanildi() =>
      _bonusSayaciniYaz((sayi) => sayi + 1);

  /// Sunucu bu haftanın ek hak sınırının dolduğunu söylediğinde çağrılır
  /// (ör. haklar başka cihazda kullanıldı).
  static Future<void> bonusHakkiniBitir() =>
      _bonusSayaciniYaz((_) => maxWeeklyBonusUses);

  static Future<void> _bonusSayaciniYaz(int Function(int) yeni) async {
    final prefs = await SharedPreferences.getInstance();
    final anahtar = _bonusAnahtari();
    await prefs.setInt(anahtar, yeni(prefs.getInt(anahtar) ?? 0));
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('ai_bonus_w_') && key != anahtar) {
        await prefs.remove(key);
      }
    }
  }

  static Future<int> getRemainingAiUses({required String mod}) async {
    if (_isPro) return 999;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_aiAnahtari(mod)) ?? freeWeeklyAiLimit;
  }
}

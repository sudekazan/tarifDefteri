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

  /// Ücretsiz günlük AI Şef hakkı (backend/server.js FREE_DAILY_AI_LIMIT ile aynı).
  static const int freeDailyAiLimit = 3;

  /// Backend günlük sayacı UTC tarihine göre tutar; yerel anahtar da UTC
  /// olmalı. Yerel tarih kullanılınca Türkiye'de 00:00-03:00 arasında hakkını
  /// bitiren kullanıcının ertesi günü yerelde 0 hakla başlıyor, sunucu izin
  /// verse bile uygulama AI Şef'i engelliyordu.
  static String _bugununAiAnahtari() =>
      'ai_remaining_${DateTime.now().toUtc().toIso8601String().substring(0, 10)}';

  /// Yerel hızlı ön kontrol; asıl karar backend'indir.
  static Future<bool> canUseAi() async {
    if (_isPro) return true;
    return await getRemainingAiUses() > 0;
  }

  /// Backend'in döndürdüğü gerçek "kalan hak" sayısını yerelde saklar.
  /// Reklam bonuslarıyla kalan hak 3'ün üstüne çıkabildiği için değer
  /// kırpılmaz (eskiden 3'e kırpılıyor, rozet yanlış sayı gösteriyordu).
  static Future<void> syncRemainingFromServer(int? remaining) async {
    if (remaining == null || _isPro) return;

    final prefs = await SharedPreferences.getInstance();
    final bugun = _bugununAiAnahtari();
    await prefs.setInt(bugun, remaining < 0 ? 0 : remaining);

    // Önceki günlerin sayaçlarını (eski 'ai_usage_' biçimi dahil) temizle.
    for (final key in prefs.getKeys().toList()) {
      if (key != bugun && (key.startsWith('ai_remaining_') || key.startsWith('ai_usage_'))) {
        await prefs.remove(key);
      }
    }
  }

  static Future<int> getRemainingAiUses() async {
    if (_isPro) return 999;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bugununAiAnahtari()) ?? freeDailyAiLimit;
  }
}

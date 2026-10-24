import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Son offering yükleme hatası / teşhis mesajı (UI'da göstermek için)
  static String? lastOfferingsError;
  static String? initError;

  static Future<void> init() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration? configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey);
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
        await checkSubscriptionStatus();
      }
    } catch (e) {
      initError = e.toString();
      debugPrint('RevenueCat init error: $e');
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
      _isPro = _isEntitlementActive(result.customerInfo);
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  /// Kullanıcı çıkış yaptığında RevenueCat kimliğini anonim hale döndürür
  /// (aynı cihazda başka bir kullanıcı giriş yaparsa abonelikler karışmasın).
  static Future<void> logoutFromRevenueCat() async {
    try {
      await Purchases.logOut();
      _isPro = false;
    } catch (e) {
      debugPrint('RevenueCat logOut error: $e');
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
      _isPro = _isEntitlementActive(customerInfo);
      return _isPro;
    } catch (e) {
      debugPrint('Check subscription error: $e');
      return false;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = (await Purchases.purchasePackage(package)).customerInfo;
      _isPro = _isEntitlementActive(customerInfo);
      return _isPro;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _isPro = _isEntitlementActive(customerInfo);
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

  // Ücretsiz AI Kullanım Hakkı Kontrolü
  static Future<bool> canUseAi() async {
    if (_isPro) return true; // Pro kullanıcılara sınırsız

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    int usageCount = prefs.getInt('ai_usage_$today') ?? 0;
    
    return usageCount < 3; // Günde maksimum 3 ücretsiz hak
  }

  /// Backend'in döndürdüğü gerçek "kalan hak" sayısıyla yerel sayacı eşitler.
  /// Yerel sayaç sadece hızlı bir ön kontrol için var (saat dilimi farkı veya
  /// uygulamanın yeniden kurulması gibi nedenlerle backend'deki Firestore
  /// sayacından sapabilir); backend her zaman otoritedir, bu metot her AI
  /// isteğinden sonra yerel değeri ona göre düzeltir.
  static Future<void> syncRemainingFromServer(int? remaining) async {
    if (remaining == null) return; // Pro kullanıcı / sınırsız, senkronize etmeye gerek yok

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(0, 10);
    final clampedRemaining = remaining.clamp(0, 3);
    await prefs.setInt('ai_usage_$today', 3 - clampedRemaining);
  }

  static Future<int> getRemainingAiUses() async {
    if (_isPro) return 999;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(0, 10);
    int usageCount = prefs.getInt('ai_usage_$today') ?? 0;
    
    return (3 - usageCount).clamp(0, 3);
  }
}

import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RevenueCatService {
  // Lütfen bu anahtarları kendi RevenueCat API anahtarlarınız ile değiştirin.
  static const _appleApiKey = 'appl_wzqpdBivjxBdcFMeuiwKdYiVWVW';
  static const _googleApiKey = 'goog_JBGkRQWPAQALDKKLXqiqwLNzmDr';

  // Entitlement ID (RevenueCat panelindeki kimlik)
  static const _entitlementID = 'recipe_keeper_custom_cookbook_pro';

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
      print('RevenueCat init error: $e');
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
      print('Check subscription error: $e');
      return false;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = (await Purchases.purchasePackage(package)).customerInfo;
      _isPro = _isEntitlementActive(customerInfo);
      return _isPro;
    } catch (e) {
      print('Purchase error: $e');
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _isPro = _isEntitlementActive(customerInfo);
      return _isPro;
    } catch (e) {
      print('Restore error: $e');
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
      print('RevenueCat: paketler sorgulanıyor...');
      Offerings offerings = await Purchases.getOfferings();
      print('RevenueCat offerings: all=${offerings.all.keys.toList()}, current=${offerings.current?.identifier}');
      
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
      print('Get offerings error: $e');
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

  static Future<void> incrementAiUsage() async {
    if (_isPro) return; // Pro ise saymaya gerek yok

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(0, 10);
    int usageCount = prefs.getInt('ai_usage_$today') ?? 0;
    
    await prefs.setInt('ai_usage_$today', usageCount + 1);
  }
  
  static Future<int> getRemainingAiUses() async {
    if (_isPro) return 999;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(0, 10);
    int usageCount = prefs.getInt('ai_usage_$today') ?? 0;
    
    return (3 - usageCount).clamp(0, 3);
  }
}

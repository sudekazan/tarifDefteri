import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RevenueCatService {
  // Lütfen bu anahtarları kendi RevenueCat API anahtarlarınız ile değiştirin.
  static const _appleApiKey = 'test_tDvTyPtPmVhNXJdXCJjMCLkBfWC';
  static const _googleApiKey = 'test_tDvTyPtPmVhNXJdXCJjMCLkBfWC';

  // Entitlement ID (RevenueCat panelinden ayarlanacak, örn: "pro")
  static const _entitlementID = 'pro';

  static bool _isPro = false;

  static bool get isProUser => _isPro;

  static Future<void> init() async {
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
  }

  static Future<bool> checkSubscriptionStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _isPro = customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
      return _isPro;
    } catch (e) {
      print('Check subscription error: $e');
      return false;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = await Purchases.purchaseStoreProduct(package.storeProduct);
      _isPro = customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
      return _isPro;
    } catch (e) {
      print('Purchase error: $e');
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _isPro = customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
      return _isPro;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }
  
  static Future<List<Offering>> getOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return [offerings.current!];
      }
    } catch (e) {
      print('Get offerings error: $e');
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

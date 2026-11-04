import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Gelir/büyüme kararları için gereken temel olayları Firebase Analytics'e
/// kaydeden ince bir sarmalayıcı. Her çağrı hataya karşı korumalı; analitik
/// hiçbir zaman asıl kullanıcı akışını kesmemeli.
///
/// Parametre değerleri yalnızca metin veya sayı olabilir (firebase_analytics
/// bool kabul etmez); bool'lar [_bool] ile 'true'/'false' metnine çevrilir.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Testlerde doluysa olaylar Firebase yerine buraya gider.
  @visibleForTesting
  static Future<void> Function(String name, Map<String, Object>? params)? testLogger;

  /// Testlerde doluysa kullanıcı özellikleri Firebase yerine buraya gider.
  @visibleForTesting
  static Future<void> Function(String name, String? value)? testUserPropertyLogger;

  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      if (testLogger != null) {
        await testLogger!(name, params);
      } else {
        await _analytics.logEvent(name: name, parameters: params);
      }
    } catch (e) {
      debugPrint('Analytics event error ($name): $e');
    }
  }

  static Future<void> _setUserProperty(String name, String? value) async {
    try {
      if (testUserPropertyLogger != null) {
        await testUserPropertyLogger!(name, value);
      } else {
        await _analytics.setUserProperty(name: name, value: value);
      }
    } catch (e) {
      debugPrint('Analytics user property error ($name): $e');
    }
  }

  static String _bool(bool value) => value ? 'true' : 'false';

  /// Firebase'in bu kurulum için ürettiği kimlik; RevenueCat'in Firebase
  /// entegrasyonu abonelik olaylarını bu kimlikle eşleştirir. Alınamazsa null.
  static Future<String?> appInstanceId() async {
    try {
      return await _analytics.appInstanceId;
    } catch (e) {
      debugPrint('Analytics appInstanceId error: $e');
      return null;
    }
  }

  /// Kullanıcının Pro olup olmadığını kullanıcı özelliği olarak kaydeder;
  /// böylece tüm olaylar Pro / ücretsiz diye ayrılabilir.
  static Future<void> setIsPro(bool isPro) => _setUserProperty('is_pro', _bool(isPro));

  /// Ödeme ekranı görüntülendiğinde. [source], ekranın hangi noktadan
  /// açıldığını belirtir (ör. "ai_limit", "klasor_limit", "settings").
  static Future<void> paywallGoruldu(String source) =>
      _log('paywall_goruldu', {'source': source});

  /// Ödeme ekranı satın alma yapılmadan kapatıldığında.
  static Future<void> paywallKapatildi(String source) =>
      _log('paywall_kapatildi', {'source': source});

  /// Bir abonelik/ürün satın alındığında. [source], satın almanın yapıldığı
  /// ödeme ekranının nereden açıldığıdır.
  static Future<void> satinAlma({String? packageId, String? priceString, required String source}) =>
      _log('satin_alma', {
        if (packageId != null) 'package_id': packageId,
        if (priceString != null) 'price': priceString,
        'source': source,
      });

  /// Satın alma tamamlanmadığında. [iptalEdildi], kullanıcının mağaza
  /// penceresinde vazgeçtiğini (hata değil) belirtir.
  static Future<void> satinAlmaBasarisiz({required String source, String? packageId, required bool iptalEdildi}) =>
      _log('satin_alma_basarisiz', {
        'source': source,
        if (packageId != null) 'package_id': packageId,
        'iptal_edildi': _bool(iptalEdildi),
      });

  /// AI Şef ile tarif üretimi başarıyla tamamlandığında. [kaynak]:
  /// "ne_pisirsem", "klasor_ai" veya "link".
  static Future<void> aiKullanildi({required bool isPro, required String kaynak}) =>
      _log('ai_kullanildi', {'is_pro': _bool(isPro), 'kaynak': kaynak});

  /// Günlük ücretsiz AI hakkı dolduğunda. [kaynak], [aiKullanildi] ile aynı.
  static Future<void> aiLimitDoldu({required String kaynak}) =>
      _log('ai_limit_doldu', {'kaynak': kaynak});

  /// Ödüllü reklam akışı bittiğinde. [sonuc]: "izlendi", "yarida_kapatildi"
  /// veya "yuklenemedi". [yer]: reklamın istendiği ekran.
  static Future<void> odulluReklam({required String sonuc, required String yer}) =>
      _log('odullu_reklam', {'sonuc': sonuc, 'yer': yer});

  /// Bir tarif kaydedildiğinde.
  static Future<void> tarifKaydedildi({required bool isAiGenerated}) =>
      _log('tarif_kaydedildi', {'is_ai_generated': _bool(isAiGenerated)});

  /// Bir tarif paylaşıldığında. [kaynak]: "tarif_detay", "klasor_ici" veya
  /// "klasorler".
  static Future<void> tarifPaylasildi({required String kaynak}) =>
      _log('tarif_paylasildi', {'kaynak': kaynak});

  /// Yemek yapma modu açıldığında.
  static Future<void> yemekModuAcildi() => _log('yemek_modu_acildi');

  /// Yemek yapma modunda son adım tamamlandığında.
  static Future<void> yemekModuTamamlandi() => _log('yemek_modu_tamamlandi');

  /// Alışveriş listesi açıldığında.
  static Future<void> alisverisListesiAcildi() => _log('alisveris_listesi_acildi');

  /// Alışveriş listesine bir madde eklendiğinde.
  static Future<void> alisverisListesineEklendi() => _log('alisveris_listesine_eklendi');

  /// Arama sayfasından metin girilmişken çıkıldığında (sayfa başına bir kez).
  static Future<void> aramaYapildi({required bool sonucVar}) =>
      _log('arama_yapildi', {'sonuc_var': _bool(sonucVar)});

  /// Yeni klasör oluşturulduğunda. [klasorSayisi], oluşturulduktan sonraki
  /// toplam klasör sayısıdır (ücretsiz sınıra ne kadar yaklaşıldığını gösterir).
  static Future<void> klasorOlusturuldu({required int klasorSayisi}) =>
      _log('klasor_olusturuldu', {'klasor_sayisi': klasorSayisi});
}

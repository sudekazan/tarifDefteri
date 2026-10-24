import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Gelir/büyüme kararları için gereken temel olayları Firebase Analytics'e
/// kaydeden ince bir sarmalayıcı. Her çağrı hataya karşı korumalı; analitik
/// hiçbir zaman asıl kullanıcı akışını kesmemeli.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics event error ($name): $e');
    }
  }

  /// Ödeme ekranı görüntülendiğinde. [source], ekranın hangi noktadan
  /// açıldığını belirtir (ör. "ai_limit", "klasor_limit", "ayarlar").
  static Future<void> paywallGoruldu(String source) =>
      _log('paywall_goruldu', {'source': source});

  /// Bir abonelik/ürün satın alındığında.
  static Future<void> satinAlma({String? packageId, String? priceString}) =>
      _log('satin_alma', {
        if (packageId != null) 'package_id': packageId,
        if (priceString != null) 'price': priceString,
      });

  /// AI Şef ile tarif üretimi başarıyla tamamlandığında.
  static Future<void> aiKullanildi({required bool isPro}) =>
      _log('ai_kullanildi', {'is_pro': isPro});

  /// Günlük ücretsiz AI hakkı dolduğunda.
  static Future<void> aiLimitDoldu() => _log('ai_limit_doldu');

  /// Bir tarif kaydedildiğinde.
  static Future<void> tarifKaydedildi({required bool isAiGenerated}) =>
      _log('tarif_kaydedildi', {'is_ai_generated': isAiGenerated});

  /// Bir tarif paylaşıldığında.
  static Future<void> tarifPaylasildi() => _log('tarif_paylasildi');
}

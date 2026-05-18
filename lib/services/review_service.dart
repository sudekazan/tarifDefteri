import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Akıllı uygulama değerlendirme servisi.
/// - İlk kullanımdan 7 gün sonra, sonrasında 30 günde bir sorar.
/// - Kullanıcı "Değerlendir" butonuna bastıysa bir daha sormaz.
/// - Zorunlu değil, kullanıcı isterse geçebilir.
class ReviewService {
  static const String _firstLaunchKey = 'review_first_launch_date';
  static const String _lastPromptKey = 'review_last_prompt_date';
  static const String _hasRatedKey = 'review_has_rated';

  static const int _daysBeforeFirstPrompt = 7;   // İlk soru: 7 gün sonra
  static const int _daysBetweenPrompts = 30;      // Tekrar soru: 30 günde bir

  /// Uygulama her açıldığında çağrılır. Uygunsa review ister.
  static Future<void> checkAndRequestReview(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Kullanıcı zaten değerlendirdiyse hiç sorma
    final hasRated = prefs.getBool(_hasRatedKey) ?? false;
    if (hasRated) return;

    final now = DateTime.now();

    // 2. İlk açılış tarihini kaydet
    if (!prefs.containsKey(_firstLaunchKey)) {
      await prefs.setString(_firstLaunchKey, now.toIso8601String());
      return; // İlk açılışta hemen sorma
    }

    final firstLaunch = DateTime.parse(prefs.getString(_firstLaunchKey)!);
    final daysSinceInstall = now.difference(firstLaunch).inDays;

    // 3. İlk 7 günü doldurmadıysa sorma
    if (daysSinceInstall < _daysBeforeFirstPrompt) return;

    // 4. Son sorma tarihini kontrol et
    if (prefs.containsKey(_lastPromptKey)) {
      final lastPrompt = DateTime.parse(prefs.getString(_lastPromptKey)!);
      final daysSinceLastPrompt = now.difference(lastPrompt).inDays;
      if (daysSinceLastPrompt < _daysBetweenPrompts) return;
    }

    // 5. Şartlar sağlandı → Son sorma tarihini güncelle ve sor
    await prefs.setString(_lastPromptKey, now.toIso8601String());
    await _showReviewPrompt();
  }

  /// Kullanıcı ayarlardan "Değerlendir" butonuna bastığında çağrılır.
  /// Bu durumda bir daha otomatik sormaz.
  static Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }

  /// Native review dialog'unu göster.
  static Future<void> _showReviewPrompt() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
    // Native dialog çıkmazsa sessizce geç (kullanıcıyı rahatsız etme)
  }

  /// Test/geliştirme için tüm review verilerini sıfırla.
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLaunchKey);
    await prefs.remove(_lastPromptKey);
    await prefs.remove(_hasRatedKey);
  }
}

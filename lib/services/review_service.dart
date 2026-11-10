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
  static const String _recipeSaveCountKey = 'review_recipe_save_count';

  static const int _daysBeforeFirstPrompt = 7;   // İlk soru: 7 gün sonra
  static const int _daysBetweenPrompts = 30;      // Tekrar soru: 30 günde bir

  /// Testlerde saati ve mağaza penceresini değiştirmek için.
  @visibleForTesting
  static DateTime Function() simdi = DateTime.now;
  @visibleForTesting
  static Future<void> Function() pencereyiGoster = _showReviewPrompt;

  /// Uygulama açılışında çağrılır: 7 günlük bekleme ilk açılıştan sayılsın
  /// diye ilk açılış tarihini bir kez kaydeder. (Eskiden tarih ilk
  /// tetiklemede yazılıyordu; o tetikleme boşa gidiyor, 7 gün de oradan
  /// başlıyordu.)
  static Future<void> ilkAcilisiKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_firstLaunchKey)) {
      await prefs.setString(_firstLaunchKey, simdi().toIso8601String());
    }
  }

  /// "Mutlu an"larda çağrılır (yemek modu bitti, tarif kaydedildi).
  /// Uygunsa değerlendirme ister.
  static Future<void> checkAndRequestReview(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Kullanıcı zaten değerlendirdiyse hiç sorma
    final hasRated = prefs.getBool(_hasRatedKey) ?? false;
    if (hasRated) return;

    final now = simdi();

    // 2. İlk açılış tarihi açılışta kaydedilir; yoksa (ör. eski sürümden
    // gelen kullanıcı) şimdi kaydet ve bekle.
    final ilkAcilisMetni = prefs.getString(_firstLaunchKey);
    if (ilkAcilisMetni == null) {
      await prefs.setString(_firstLaunchKey, now.toIso8601String());
      return;
    }

    final firstLaunch = DateTime.parse(ilkAcilisMetni);
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
    await pencereyiGoster();
  }

  /// Bir tarif kaydedildiğinde çağrılır (manuel veya AI ile). Toplam
  /// kaydedilen tarif sayısını artırır; AI ile üretilmiş bir tarifi
  /// kaydetmek veya en az 5 tarif kaydetmiş olmak, kullanıcının üründen
  /// memnun olduğu "mutlu an"lar olduğu için bu noktalarda değerlendirme
  /// istenir. 5. tarif ilk 7 günde kaydedilirse istek kaybolmaz; bekleme
  /// dolduktan sonraki ilk kayıtta sorulur.
  static Future<void> onRecipeSaved(BuildContext context, {bool isAiGenerated = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_recipeSaveCountKey) ?? 0) + 1;
    await prefs.setInt(_recipeSaveCountKey, count);

    if (isAiGenerated || count >= 5) {
      await checkAndRequestReview(context);
    }
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
    await prefs.remove(_recipeSaveCountKey);
  }
}

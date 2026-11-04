import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';
import 'analytics_service.dart';

class AdService {
  static AppOpenAd? _appOpenAd;
  static RewardedAd? _rewardedAd;
  static bool _isShowingAd = false;
  static bool _showAfterLoad = false;
  static bool _isLoadingAd = false;
  static bool _isLoadingRewarded = false;

  /// Onay (UMP) ve takip izni (ATT) adımları bitip reklam SDK'sı
  /// başlatıldığında true olur. Banner'lar bunu dinler ve ancak o zaman yüklenir.
  static final ValueNotifier<bool> reklamlarHazir = ValueNotifier(false);
  static Future<void>? _izinIslemi;

  /// Test and Real Ad Units
  static String get appOpenAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9257395924'
          : 'ca-app-pub-3940256099942544/5662855259';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-7331912696640483/9388360220'
          : 'ca-app-pub-7331912696640483/5884229487';
    }
  }

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-7331912696640483/8861660897'
          : 'ca-app-pub-7331912696640483/7346408402';
    }
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Test ID for Android Rewarded
          : 'ca-app-pub-3940256099942544/1712485313'; // Test ID for iOS Rewarded
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-7331912696640483/3790306779'
          : 'ca-app-pub-7331912696640483/8510392826';
    }
  }

  /// AB kullanıcıları için Google onay formunu (UMP), ardından iOS takip
  /// iznini (ATT) ister; reklam istenebiliyorsa SDK'yı başlatıp açılış ve
  /// ödüllü reklamları yükler. İlk ekran çizildikten sonra çağrılmalı (ATT
  /// penceresi yalnızca uygulama ekrandayken çıkar). Tekrar çağrılırsa aynı
  /// işlemi döndürür. Bir adım hata verirse sonrakine geçilir, akış takılmaz.
  static Future<void> izinleriIsteVeReklamlariBaslat() => _izinIslemi ??= _izinleriIste();

  static Future<void> _izinleriIste() async {
    await _onayBilgisiniGuncelle();
    await _onayFormunuGerekirseGoster();
    await requestTrackingAuthorization();

    bool reklamIstenebilir = false;
    try {
      reklamIstenebilir = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('canRequestAds error: $e');
    }
    if (!reklamIstenebilir) return;

    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds init error: $e');
    }
    reklamlarHazir.value = true;
    loadAppOpenAd();
    loadRewardedAd();
  }

  static Future<void> _onayBilgisiniGuncelle() {
    final tamamlandi = Completer<void>();
    void bitir() {
      if (!tamamlandi.isCompleted) tamamlandi.complete();
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        bitir,
        (error) {
          debugPrint('Consent info update error: ${error.message}');
          bitir();
        },
      );
    } catch (e) {
      debugPrint('Consent info update error: $e');
      bitir();
    }
    // Yerel SDK hiç yanıt vermezse reklamlar sonsuza kadar beklemesin.
    return tamamlandi.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  static Future<void> _onayFormunuGerekirseGoster() {
    final tamamlandi = Completer<void>();
    try {
      ConsentForm.loadAndShowConsentFormIfRequired((formError) {
        if (formError != null) debugPrint('Consent form error: ${formError.message}');
        if (!tamamlandi.isCompleted) tamamlandi.complete();
      });
    } catch (e) {
      debugPrint('Consent form error: $e');
      if (!tamamlandi.isCompleted) tamamlandi.complete();
    }
    return tamamlandi.future;
  }

  /// AB'de kullanıcının onay seçimini değiştirebileceği ayar satırı
  /// gösterilmeli mi? (Google bunu zorunlu tutuyor.)
  static Future<bool> gizlilikSecenekleriGerekli() async {
    try {
      await _izinIslemi;
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('Privacy options status error: $e');
      return false;
    }
  }

  /// Onay seçimini değiştirme formunu açar.
  static Future<void> gizlilikSecenekleriniGoster() {
    final tamamlandi = Completer<void>();
    try {
      ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) debugPrint('Privacy options form error: ${formError.message}');
        if (!tamamlandi.isCompleted) tamamlandi.complete();
      });
    } catch (e) {
      debugPrint('Privacy options form error: $e');
      if (!tamamlandi.isCompleted) tamamlandi.complete();
    }
    return tamamlandi.future;
  }

  /// Request Tracking Authorization for iOS
  static Future<void> requestTrackingAuthorization() async {
    if (Platform.isIOS) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          // Wait a bit to ensure the app is in foreground
          await Future.delayed(const Duration(milliseconds: 200));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (e) {
        debugPrint('Error requesting tracking authorization: $e');
      }
    }
  }

  /// Load an AppOpenAd.
  static void loadAppOpenAd() {
    if (RevenueCatService.isProUser || !reklamlarHazir.value) return;
    if (_isLoadingAd || _appOpenAd != null) {
      debugPrint('### AD_DEBUG: loadAppOpenAd called but skipped. isLoading: $_isLoadingAd, hasAd: ${_appOpenAd != null}');
      return;
    }
    
    _isLoadingAd = true;
    debugPrint('### AD_DEBUG: Loading AppOpenAd ($appOpenAdUnitId)...');
    
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoadingAd = false;
          debugPrint('### AD_DEBUG: AppOpenAd loaded successfully.');
          if (_showAfterLoad) {
            _showAfterLoad = false;
            debugPrint('### AD_DEBUG: showing ad because _showAfterLoad was true');
            showAdIfAvailable();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('### AD_DEBUG: AppOpenAd failed to load: ${error.message} (Code: ${error.code})');
          _isLoadingAd = false;
          _showAfterLoad = false;
        },
      ),
    );
  }

  /// Show the ad if available.
  static void showAdIfAvailable() {
    if (RevenueCatService.isProUser || !reklamlarHazir.value) return;
    if (_appOpenAd == null) {
      debugPrint('Ad not ready yet, set to show after load.');
      _showAfterLoad = true;
      loadAppOpenAd();
      return;
    }
    if (_isShowingAd) {
      debugPrint('Tried to show ad while already showing an ad.');
      return;
    }

    debugPrint('Showing AppOpenAd...');
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('Ad showed full screen content.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Ad failed to show full screen content: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Ad dismissed full screen content.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }

  /// Load Rewarded Ad.
  static void loadRewardedAd() {
    if (RevenueCatService.isProUser || !reklamlarHazir.value) return;
    if (_isLoadingRewarded || _rewardedAd != null) return;

    _isLoadingRewarded = true;
    debugPrint('Loading RewardedAd ($rewardedAdUnitId)...');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          debugPrint('RewardedAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  /// Show Rewarded Ad. [yer], reklamın istendiği ekrandır ("ne_pisirsem" veya
  /// "klasor_ici"); sonuç `odullu_reklam` olayıyla kaydedilir.
  static void showRewardedAd({required String yer, VoidCallback? onAdClosed, Function(RewardItem)? onUserEarnedReward}) {
    if (RevenueCatService.isProUser) {
      onUserEarnedReward?.call(RewardItem(1, 'premium_skip'));
      onAdClosed?.call();
      return;
    }
    if (_rewardedAd == null) {
      debugPrint('RewardedAd not ready yet (null). Attempting to load...');
      loadRewardedAd();
      // If ad is not ready, we proceed as if they watched it so the flow doesn't break
      AnalyticsService.odulluReklam(sonuc: 'yuklenemedi', yer: yer);
      onUserEarnedReward?.call(RewardItem(0, 'fallback'));
      onAdClosed?.call();
      return;
    }

    debugPrint('Attempting to show RewardedAd...');
    bool odulKazanildi = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('RewardedAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd dismissed.');
        AnalyticsService.odulluReklam(sonuc: odulKazanildi ? 'izlendi' : 'yarida_kapatildi', yer: yer);
        _isShowingAd = false;
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        // Even if it fails to show, we proceed so user isn't stuck
        AnalyticsService.odulluReklam(sonuc: 'yuklenemedi', yer: yer);
        onUserEarnedReward?.call(RewardItem(0, 'fallback_error'));
        onAdClosed?.call();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
      debugPrint('User earned reward: ${rewardItem.amount} ${rewardItem.type}');
      odulKazanildi = true;
      onUserEarnedReward?.call(rewardItem);
    });
  }
}
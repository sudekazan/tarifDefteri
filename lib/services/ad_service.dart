import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';


class AdService {
  static AppOpenAd? _appOpenAd;
  static InterstitialAd? _interstitialAd;
  static bool _isShowingAd = false;
  static bool _showAfterLoad = false;
  static bool _isLoadingAd = false;
  static bool _isLoadingInterstitial = false;

  /// Test and Real Ad Units
  static String get appOpenAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9257395924'
          : 'ca-app-pub-3940256099942544/5662855259';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-2127302088980655/9413134086'
          : 'ca-app-pub-2127302088980655/3694560082';
    }
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-2127302088980655/3542042807'
          : 'ca-app-pub-2127302088980655/5976634451';
    }
  }

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-2127302088980655/7429316929'
          : 'ca-app-pub-2127302088980655/9262656239';
    }
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
        print('Error requesting tracking authorization: $e');
      }
    }
  }

  /// Load an AppOpenAd.
  static void loadAppOpenAd() {
    if (_isLoadingAd || _appOpenAd != null) {
      print('### AD_DEBUG: loadAppOpenAd called but skipped. isLoading: $_isLoadingAd, hasAd: ${_appOpenAd != null}');
      return;
    }
    
    _isLoadingAd = true;
    print('### AD_DEBUG: Loading AppOpenAd ($appOpenAdUnitId)...');
    
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoadingAd = false;
          print('### AD_DEBUG: AppOpenAd loaded successfully.');
          if (_showAfterLoad) {
            _showAfterLoad = false;
            print('### AD_DEBUG: showing ad because _showAfterLoad was true');
            showAdIfAvailable();
          }
        },
        onAdFailedToLoad: (error) {
          print('### AD_DEBUG: AppOpenAd failed to load: ${error.message} (Code: ${error.code})');
          _isLoadingAd = false;
          _showAfterLoad = false;
        },
      ),
    );
  }

  /// Show the ad if available.
  static void showAdIfAvailable() {
    if (_appOpenAd == null) {
      print('Ad not ready yet, set to show after load.');
      _showAfterLoad = true;
      loadAppOpenAd();
      return;
    }
    if (_isShowingAd) {
      print('Tried to show ad while already showing an ad.');
      return;
    }

    print('Showing AppOpenAd...');
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('Ad showed full screen content.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Ad failed to show full screen content: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        print('Ad dismissed full screen content.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }

  /// Load Interstitial Ad.
  static void loadInterstitialAd() {
    if (_isLoadingInterstitial || _interstitialAd != null) return;

    _isLoadingInterstitial = true;
    print('Loading InterstitialAd ($interstitialAdUnitId)...');

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          print('InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd failed to load: $error');
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  /// Show Interstitial Ad.
  static void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_interstitialAd == null) {
      print('InterstitialAd not ready yet (null). Attempting to load...');
      loadInterstitialAd();
      onAdClosed?.call();
      return;
    }

    print('Attempting to show InterstitialAd...');
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('InterstitialAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('InterstitialAd dismissed.');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('InterstitialAd failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdClosed?.call();
      },
    );

    _interstitialAd!.show();
  }
}
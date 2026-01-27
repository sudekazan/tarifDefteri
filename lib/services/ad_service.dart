import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
          : 'ca-app-pub-2127302088980655/3542042807';
    }
  }

  /// Load an AppOpenAd.
  static void loadAppOpenAd() {
    if (_isLoadingAd || _appOpenAd != null) return;
    
    _isLoadingAd = true;
    print('Loading AppOpenAd ($appOpenAdUnitId)...');
    
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoadingAd = false;
          print('AppOpenAd loaded successfully.');
          if (_showAfterLoad) {
            _showAfterLoad = false;
            showAdIfAvailable();
          }
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: ${error.message} (Code: ${error.code})');
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




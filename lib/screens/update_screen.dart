import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// Güncelleme kontrol bileşeni:
/// - Kullanıcı en güncel sürümdeyse hiçbir mesaj göstermez.
/// - Alt sürümde ise kullanıcıyı rahatsız etmeden güncellemeye teşvik eden bir diyalog çıkarır.
/// - Kullanıcı "Daha Sonra" derse, belirlenen süre (varsayılan 1 gün) boyunca tekrar sormaz,
///   süre dolduktan sonra güncelleyene kadar belirli aralıklarla hatırlatmaya devam eder.
class TarifDefteriUpgradeAlert extends StatefulWidget {
  final Widget child;
  /// "Daha Sonra" denildikten ne kadar süre sonra tekrar hatırlatılsın (varsayılan: 1 gün)
  final Duration reminderInterval;
  /// Test amaçlı her açılışta göstermek için (canlıda false olmalı)
  final bool debugDisplayAlways;

  const TarifDefteriUpgradeAlert({
    super.key,
    required this.child,
    this.reminderInterval = const Duration(days: 1),
    this.debugDisplayAlways = false,
  });

  @override
  State<TarifDefteriUpgradeAlert> createState() =>
      _TarifDefteriUpgradeAlertState();
}

class _TarifDefteriUpgradeAlertState extends State<TarifDefteriUpgradeAlert> {
  late final Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(
      messages: TarifDefteriUpgraderMessages(),
      durationUntilAlertAgain: widget.reminderInterval, // Hatırlatma aralığı
      debugDisplayAlways: widget.debugDisplayAlways,
      debugLogging: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: _upgrader,
      dialogStyle: UpgradeDialogStyle.cupertino,
      barrierDismissible: true, // Diyalog dışına basarak kapatabilme
      showIgnore: false,        // "Yoksay" butonu YOK - kullanıcı güncellemeyi kalıcı olarak kapatamasın
      showLater: true,         // "Daha Sonra" butonu VAR - zorla kilitlemek yerine teşvik eder
      showReleaseNotes: true,   // Mağazadaki yenilikleri göster
      child: widget.child,
    );
  }
}

/// Türkçe ve İngilizce destekli, kullanıcıyı sıcak bir dille güncellemeye teşvik eden mesajlar
class TarifDefteriUpgraderMessages extends UpgraderMessages {
  TarifDefteriUpgraderMessages({super.code});

  @override
  String get title {
    if (languageCode == 'en') return '🎉 New Update Available!';
    return '🎉 Yeni Güncelleme Mevcut!';
  }

  @override
  String get body {
    if (languageCode == 'en') {
      return 'A new version of {{appName}} is available! Update now to enjoy the latest features and performance improvements.';
    }
    return '{{appName}} için yeni ve daha gelişmiş bir sürüm hazır! Yeni tarif özellikleri, performans iyileştirmeleri ve kesintisiz deneyim için lütfen uygulamanızı güncelleyin.';
  }

  @override
  String get prompt {
    if (languageCode == 'en') return 'Would you like to update now?';
    return 'Şimdi güncellemek ister misiniz?';
  }

  @override
  String get buttonTitleUpdate {
    if (languageCode == 'en') return '🚀 Update Now';
    return '🚀 Şimdi Güncelle';
  }

  @override
  String get buttonTitleLater {
    if (languageCode == 'en') return 'Later';
    return 'Daha Sonra';
  }

  @override
  String get buttonTitleIgnore {
    if (languageCode == 'en') return 'Ignore';
    return 'Yoksay';
  }

  @override
  String get releaseNotes {
    if (languageCode == 'en') return "What's New";
    return 'Yenilikler';
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

/// Güncelleme penceresi metinleri; uygulamada seçili dilde (6 dil) gösterilir.
/// Eskiden yalnızca Türkçe/İngilizce vardı ve cihaz diline bakılıyordu:
/// Almanca, İspanyolca, Fransızca, Portekizce kullanıcılar Türkçe görüyordu.
class TarifDefteriUpgraderMessages extends UpgraderMessages {
  TarifDefteriUpgraderMessages({super.code});

  @override
  String get title => 'update_dialog_title'.tr();

  @override
  String get body => 'update_dialog_body'.tr();

  @override
  String get prompt => 'update_dialog_prompt'.tr();

  @override
  String get buttonTitleUpdate => 'update_dialog_button_update'.tr();

  @override
  String get buttonTitleLater => 'update_dialog_button_later'.tr();

  @override
  String get buttonTitleIgnore => 'update_dialog_button_ignore'.tr();

  @override
  String get releaseNotes => 'update_dialog_release_notes'.tr();
}

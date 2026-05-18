import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:upgrader/upgrader.dart';

/// Güncelleme ekranı - eski sürümdeki kullanıcıları zorunlu olarak güncellemeye yönlendirir.
class TarifDefteriUpgradeAlert extends StatefulWidget {
  final Widget child;

  const TarifDefteriUpgradeAlert({super.key, required this.child});

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
      messages: _getLocalizedMessages(),
      durationUntilAlertAgain: Duration.zero, // Her açılışta kontrol et
      debugLogging: false,
    );
  }

  /// Kullanıcının diline göre doğru mesaj sınıfını döndürür.
  UpgraderMessages _getLocalizedMessages() {
    // Bu metod initState'de çağrıldığı için context yok,
    // Bu yüzden locale'yi Upgrader'ın kendi sistemine bırakıyoruz.
    // Kendi özel mesajlarımızı locale-agnostic bir şekilde veriyoruz.
    return LocalizedUpgraderMessages();
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: _upgrader,
      dialogStyle: UpgradeDialogStyle.cupertino,
      barrierDismissible: false,
      showIgnore: false,   // "Yoksay/Ignore" butonu YOK → zorunlu güncelleme
      showLater: false,    // "Sonra/Later" butonu YOK → zorunlu güncelleme
      child: widget.child,
    );
  }
}

/// Tüm dillere uygun, dinamik güncelleme mesajları.
class LocalizedUpgraderMessages extends UpgraderMessages {
  LocalizedUpgraderMessages() : super(code: 'en');

  @override
  String get body {
    return 'A new version is available! Please update to continue using the app.';
  }

  @override
  String get buttonTitleIgnore => 'Ignore';

  @override
  String get buttonTitleLater => 'Later';

  @override
  String get buttonTitleUpdate => '🚀 Update Now';

  @override
  String get prompt => 'Would you like to update?';

  @override
  String get releaseNotes => "What's New";

  @override
  String get title => '🎉 New Update Available!';

  @override
  String get updateAvailable => 'New version available!';
}

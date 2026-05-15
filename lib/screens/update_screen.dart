import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// Güncelleme ekranı - UpgradeAlert'i özel Türkçe mesajlarla saran widget.
/// main.dart'taki UpgradeAlert'in yerine ya da içine sarılarak kullanılır.
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
      messages: TurkishUpgraderMessages(),
      // Geliştirme sırasında her zaman kontrol etmek isterseniz:
      // durationUntilAlertAgain: Duration.zero,
      durationUntilAlertAgain: const Duration(days: 1),
      debugLogging: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: _upgrader,
      dialogStyle: UpgradeDialogStyle.cupertino,
      barrierDismissible: false,
      showIgnore: false,      // "Yoksay" butonu gizli
      showLater: true,        // "Sonra" butonu göster
      child: widget.child,
    );
  }
}

/// Türkçe mesajlar için özel Upgrader mesaj sınıfı.
class TurkishUpgraderMessages extends UpgraderMessages {
  TurkishUpgraderMessages() : super(code: 'tr');

  @override
  String get body =>
      'Tarif Defteri\'nin yeni bir sürümü mevcut! Daha iyi bir deneyim için lütfen güncelle.';

  @override
  String get buttonTitleIgnore => 'Yoksay';

  @override
  String get buttonTitleLater => 'Sonra';

  @override
  String get buttonTitleUpdate => '🚀 Güncelle';

  @override
  String get prompt => 'Güncellemek ister misin?';

  @override
  String get releaseNotes => 'Yenilikler';

  @override
  String get title => '🎉 Yeni Güncelleme Mevcut!';

  @override
  String get updateAvailable => 'Yeni sürüm mevcut!';
}

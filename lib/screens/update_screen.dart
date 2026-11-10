import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:upgrader/upgrader.dart';

import '../widgets/kil/kil.dart';

/// Güncelleme kontrol bileşeni:
/// - Kullanıcı en güncel sürümdeyse hiçbir mesaj göstermez.
/// - Alt sürümde ise kullanıcıyı rahatsız etmeden güncellemeye teşvik eden bir diyalog çıkarır.
/// - Kullanıcı "Daha Sonra" derse, belirlenen süre (varsayılan 1 gün) boyunca tekrar sormaz,
///   süre dolduktan sonra güncelleyene kadar belirli aralıklarla hatırlatmaya devam eder.
/// - iOS'ta sistem uyarısı gibi Cupertino diyaloğu (düğmeler kil renginde),
///   diğer platformlarda [KilDiyalog] (bkz. [KilGuncellemeUyarisi]).
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
    return KilGuncellemeUyarisi(
      upgrader: _upgrader,
      dialogStyle: guncellemeDiyalogStili(defaultTargetPlatform),
      barrierDismissible: true, // Diyalog dışına basarak kapatabilme
      showIgnore: false,        // "Yoksay" butonu YOK - kullanıcı güncellemeyi kalıcı olarak kapatamasın
      showLater: true,         // "Daha Sonra" butonu VAR - zorla kilitlemek yerine teşvik eder
      showReleaseNotes: true,   // Mağazadaki yenilikleri göster
      child: widget.child,
    );
  }
}

/// iOS ve macOS'ta Cupertino, diğerlerinde Material (kil) diyalog.
UpgradeDialogStyle guncellemeDiyalogStili(TargetPlatform platform) =>
    switch (platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => UpgradeDialogStyle.cupertino,
      _ => UpgradeDialogStyle.material,
    };

/// `UpgradeAlert`'in kil görünümlü hali. Davranış (ne zaman çıkacağı,
/// "Daha Sonra", engelleyici sürümde düğmelerin gizlenmesi) pakette kalır;
/// yalnızca diyaloğun görünümü değişir.
class KilGuncellemeUyarisi extends UpgradeAlert {
  KilGuncellemeUyarisi({
    super.key,
    super.upgrader,
    super.dialogStyle,
    super.barrierDismissible,
    super.showIgnore,
    super.showLater,
    super.showReleaseNotes,
    super.child,
  });

  @override
  UpgradeAlertState createState() => _KilGuncellemeUyarisiState();
}

class _KilGuncellemeUyarisiState extends UpgradeAlertState {
  @override
  Widget alertDialog(
    Key? key,
    String title,
    String message,
    String? releaseNotes,
    BuildContext context,
    bool cupertino,
    UpgraderMessages messages,
  ) {
    if (cupertino) {
      return super.alertDialog(
        key,
        title,
        message,
        releaseNotes,
        context,
        cupertino,
        messages,
      );
    }
    return guncellemeKilDiyalogu(
      key: key,
      baslik: title,
      mesaj: message,
      soru: messages.message(UpgraderMessage.prompt) ?? '',
      yenilikBasligi: messages.message(UpgraderMessage.releaseNotes) ?? '',
      yenilikler: releaseNotes,
      guncelleEtiketi:
          messages.message(UpgraderMessage.buttonTitleUpdate) ?? '',
      sonraEtiketi: messages.message(UpgraderMessage.buttonTitleLater) ?? '',
      yoksayEtiketi:
          messages.message(UpgraderMessage.buttonTitleIgnore) ?? '',
      engelli: widget.upgrader.blocked(),
      sonraGoster: widget.showLater,
      yoksayGoster: widget.showIgnore,
      onGuncelle: () => onUserUpdated(context, !widget.upgrader.blocked()),
      onSonra: () => onUserLater(context, true),
      onYoksay: () => onUserIgnored(context, true),
    );
  }

  /// Cupertino diyalogun düğmeleri: sistem mavisi yerine terrakota; ana
  /// eylem (Güncelle) kalın.
  @override
  Widget button(
    bool cupertino,
    String? text,
    BuildContext context,
    VoidCallback? onPressed,
  ) {
    if (!cupertino) return super.button(cupertino, text, context, onPressed);
    final r = context.kil;
    final anaEylem = text ==
        widget.upgrader.state.messages
            ?.message(UpgraderMessage.buttonTitleUpdate);
    return CupertinoDialogAction(
      isDefaultAction: anaEylem,
      textStyle: TextStyle(color: r.baslik),
      onPressed: onPressed,
      child: Text(text ?? ''),
    );
  }
}

/// Android'deki güncelleme diyaloğu. Engelleyici sürümde "Daha Sonra" ve
/// "Yoksay" çıkmaz (paketteki kural).
@visibleForTesting
Widget guncellemeKilDiyalogu({
  Key? key,
  required String baslik,
  required String mesaj,
  required String soru,
  required String yenilikBasligi,
  String? yenilikler,
  required String guncelleEtiketi,
  required String sonraEtiketi,
  required String yoksayEtiketi,
  required bool engelli,
  required bool sonraGoster,
  required bool yoksayGoster,
  required VoidCallback onGuncelle,
  required VoidCallback onSonra,
  required VoidCallback onYoksay,
}) {
  return Builder(
    key: key,
    builder: (context) {
      final r = context.kil;
      final yazi = Theme.of(context).textTheme;
      return KilDiyalog(
        ikon: Icons.system_update_rounded,
        baslik: baslik,
        mesaj: mesaj,
        icerik: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              soru,
              textAlign: TextAlign.center,
              style: yazi.bodyLarge?.copyWith(color: r.anaYazi),
            ),
            if (yenilikler != null && yenilikler.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: r.solukYuzey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      yenilikBasligi,
                      style: yazi.titleSmall?.copyWith(color: r.anaYazi),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      yenilikler,
                      style: yazi.bodyMedium?.copyWith(color: r.anaYazi),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        eylemler: [
          KilDugme.birincil(
            etiket: guncelleEtiketi,
            tamGenislik: true,
            onPressed: onGuncelle,
          ),
          if (!engelli && sonraGoster)
            KilDiyalogMetinDugmesi(etiket: sonraEtiketi, onPressed: onSonra),
          if (!engelli && yoksayGoster)
            KilDiyalogMetinDugmesi(etiket: yoksayEtiketi, onPressed: onYoksay),
        ],
      );
    },
  );
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

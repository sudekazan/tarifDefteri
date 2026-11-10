import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';

/// [KilBildirim]'in rengi ve ikonu.
enum KilBildirimTuru {
  /// Temanın koyu (koyu modda açık) snackbar'ı; ikon yok.
  bilgi,

  /// Adaçayı zemin, siyah yazı, onay ikonu.
  basari,

  /// Hata zemin, beyaz (koyu modda koyu) yazı, hata ikonu.
  hata,

  /// Kiremit öne çıkan kart renkleri; sınır ve "Pro'ya özel" uyarıları.
  uyari,
}

/// Uygulamanın ortak snackbar'ı. Renkler `KilRenkleri`'nden gelir; eskiden
/// her ekran kendi yeşil / kırmızı / turuncu rengini yazıyordu.
///
/// `KilBildirim.goster(context, 'mesaj', tur: KilBildirimTuru.basari)`.
class KilBildirim {
  const KilBildirim._();

  /// Snackbar'ı kurar (gösterilmeden test edilebilsin diye ayrı).
  static SnackBar olustur(
    BuildContext context,
    String mesaj, {
    KilBildirimTuru tur = KilBildirimTuru.bilgi,
    Duration sure = const Duration(seconds: 4),
    String? eylemEtiketi,
    VoidCallback? onEylem,
  }) {
    final r = context.kil;
    final tema = Theme.of(context).snackBarTheme;

    final (Color? zemin, Color? yazi, IconData? ikon) = switch (tur) {
      KilBildirimTuru.bilgi => (null, null, null),
      KilBildirimTuru.basari =>
        (r.vurgu, r.vurguUstuYazi, Icons.check_circle_rounded),
      KilBildirimTuru.hata => (r.hata, r.hataUstuYazi, Icons.error_rounded),
      KilBildirimTuru.uyari =>
        (r.oneCikanKart, r.oneCikanKartYazi, Icons.info_rounded),
    };
    final yaziStili = yazi == null
        ? tema.contentTextStyle
        : (tema.contentTextStyle ?? const TextStyle()).copyWith(color: yazi);

    // Koyu modda kiremit kart zemine çok yakın; kenarla ayrılır.
    final kenar = tur == KilBildirimTuru.uyari && !r.sertGolge
        ? BorderSide(color: r.birincilGolge, width: 1.5)
        : BorderSide.none;

    return SnackBar(
      backgroundColor: zemin,
      duration: sure,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: kenar,
      ),
      content: Row(
        children: [
          if (ikon != null) ...[
            ExcludeSemantics(child: Icon(ikon, color: yazi, size: 22)),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(mesaj, style: yaziStili)),
        ],
      ),
      action: eylemEtiketi == null
          ? null
          : SnackBarAction(
              label: eylemEtiketi,
              textColor: yazi ?? tema.actionTextColor,
              onPressed: onEylem ?? () {},
            ),
    );
  }

  /// Snackbar'ı gösterir.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> goster(
    BuildContext context,
    String mesaj, {
    KilBildirimTuru tur = KilBildirimTuru.bilgi,
    Duration sure = const Duration(seconds: 4),
    String? eylemEtiketi,
    VoidCallback? onEylem,
  }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      olustur(
        context,
        mesaj,
        tur: tur,
        sure: sure,
        eylemEtiketi: eylemEtiketi,
        onEylem: onEylem,
      ),
    );
  }
}

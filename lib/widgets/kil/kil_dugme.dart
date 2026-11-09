import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';
import 'kil_basilir.dart';

enum KilDugmeTuru { birincil, ikincil, vurgu }

/// Kil düğmesi: birincil (terrakota), ikincil (beyaz), vurgu (adaçayı).
///
/// Açık modda alttan sert gölge vardır; basınca birkaç piksel aşağı iner.
/// Koyu modda gölge yerine kenar vardır. "Hareketi azalt" açıksa geçiş
/// animasyonsuzdur. `onPressed` null ise pasif görünür.
class KilDugme extends StatelessWidget {
  const KilDugme({
    super.key,
    required this.etiket,
    required this.onPressed,
    this.tur = KilDugmeTuru.birincil,
    this.ikon,
    this.tamGenislik = false,
  });

  const KilDugme.birincil({
    super.key,
    required this.etiket,
    required this.onPressed,
    this.ikon,
    this.tamGenislik = false,
  }) : tur = KilDugmeTuru.birincil;

  const KilDugme.ikincil({
    super.key,
    required this.etiket,
    required this.onPressed,
    this.ikon,
    this.tamGenislik = false,
  }) : tur = KilDugmeTuru.ikincil;

  const KilDugme.vurgu({
    super.key,
    required this.etiket,
    required this.onPressed,
    this.ikon,
    this.tamGenislik = false,
  }) : tur = KilDugmeTuru.vurgu;

  final String etiket;
  final VoidCallback? onPressed;
  final KilDugmeTuru tur;
  final IconData? ikon;
  final bool tamGenislik;

  /// Açık moddaki sert gölgenin yüksekliği. Düğmenin altında bu kadar yer ayrılır.
  static const double golgeYuksekligi = 4;

  /// Görünen en küçük yükseklik (gölge payı hariç).
  static const double enKucukYukseklik = 48;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final etkin = onPressed != null;

    late final Color zemin;
    late final Color yazi;
    late final Color golge;
    late final Color kenar;
    switch (tur) {
      case KilDugmeTuru.birincil:
        zemin = r.birincil;
        yazi = r.birincilUstuYazi;
        golge = r.birincilGolge;
        kenar = r.sertGolge ? r.birincil : r.birincilGolge;
      case KilDugmeTuru.ikincil:
        zemin = r.kart;
        yazi = r.baslik;
        golge = r.kenar;
        kenar = r.kenar;
      case KilDugmeTuru.vurgu:
        zemin = r.vurgu;
        yazi = r.vurguUstuYazi;
        golge = r.vurguGolge;
        kenar = r.sertGolge ? r.vurgu : r.vurguGolge;
    }

    final zeminRengi = etkin ? zemin : r.solukYuzey;
    final yaziRengi = etkin ? yazi : r.solukYazi;
    final kenarRengi = etkin ? kenar : r.kenar;
    final yaziStili =
        Theme.of(context).textTheme.labelLarge?.copyWith(color: yaziRengi) ??
            TextStyle(color: yaziRengi);
    final sure = KilBasilir.sure(context);

    return Semantics(
      button: true,
      enabled: etkin,
      child: KilBasilir(
        onTap: onPressed,
        builder: (context, basili, odakli) {
          final golgeli = r.sertGolge && etkin;
          final inis = basili ? (golgeli ? golgeYuksekligi - 1 : 2.0) : 0.0;
          Widget icerik = AnimatedContainer(
            duration: sure,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, inis, 0),
            constraints: const BoxConstraints(
              minHeight: enKucukYukseklik,
              minWidth: enKucukYukseklik,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: zeminRengi,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: odakli ? r.anaYazi : kenarRengi,
                width: 2,
              ),
              boxShadow: golgeli
                  ? [
                      BoxShadow(
                        color: golge,
                        offset: Offset(0, basili ? 1 : golgeYuksekligi),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisSize: tamGenislik ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ikon != null) ...[
                  Icon(ikon, size: 20, color: yaziRengi),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    etiket,
                    style: yaziStili,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
          if (tamGenislik) {
            icerik = SizedBox(width: double.infinity, child: icerik);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: golgeYuksekligi),
            child: icerik,
          );
        },
      ),
    );
  }
}

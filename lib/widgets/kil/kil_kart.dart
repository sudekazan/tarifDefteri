import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';

/// Kil kartı: 2 px kenar, 20 köşe. Açık modda alttan `0 4 0` sert gölge;
/// koyu modda gölge yerine kenar ve üstte ince açık çizgi.
///
/// [oneCikan] true ise kiremit zeminli öne çıkan kart olur; içindeki yazı ve
/// ikonlar uygun renge geçer.
class KilKart extends StatelessWidget {
  const KilKart({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.oneCikan = false,
    this.anlamEtiketi,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool oneCikan;

  /// Dokunulabilir kartın ekran okuyucu etiketi (gerekirse).
  final String? anlamEtiketi;

  static const double koseYaricapi = 20;
  static const double kenarKalinligi = 2;
  static const double golgeYuksekligi = 4;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final zemin = oneCikan ? r.oneCikanKart : r.kart;
    final kenar = oneCikan && r.sertGolge ? r.oneCikanKart : r.kenar;
    final golge = oneCikan ? r.birincilGolge : r.kenar;
    final yazi = oneCikan ? r.oneCikanKartYazi : r.anaYazi;
    const disKose = BorderRadius.all(Radius.circular(koseYaricapi));
    const icKose =
        BorderRadius.all(Radius.circular(koseYaricapi - kenarKalinligi));

    Widget icerik = Padding(padding: padding, child: child);

    if (oneCikan) {
      icerik = DefaultTextStyle.merge(
        style: TextStyle(color: yazi),
        child: IconTheme.merge(
          data: IconThemeData(color: yazi),
          child: icerik,
        ),
      );
    }

    if (!r.sertGolge) {
      icerik = Stack(
        children: [
          icerik,
          Positioned(
            top: 0,
            left: koseYaricapi - kenarKalinligi,
            right: koseYaricapi - kenarKalinligi,
            child: ExcludeSemantics(
              child: Container(height: 1.5, color: r.ustCizgi),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      icerik = Semantics(
        button: true,
        label: anlamEtiketi,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: icKose,
            child: icerik,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: disKose,
        border: Border.all(color: kenar, width: kenarKalinligi),
        boxShadow: r.sertGolge
            ? [
                BoxShadow(
                  color: golge,
                  offset: const Offset(0, golgeYuksekligi),
                ),
              ]
            : null,
      ),
      child: ClipRRect(borderRadius: icKose, child: icerik),
    );
  }
}

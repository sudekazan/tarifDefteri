import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';
import 'kil_basilir.dart';

/// Geri, kapat ve ara gibi ikon düğmeleri. Görünen boyut 36, dokunma alanı 48.
///
/// [etiket] hem ekran okuyucuya hem uzun basınca çıkan ipucuna gider; boş
/// bırakılamaz.
class KilYuvarlakDugme extends StatelessWidget {
  const KilYuvarlakDugme({
    super.key,
    required this.ikon,
    required this.etiket,
    required this.onPressed,
  });

  final IconData ikon;
  final String etiket;
  final VoidCallback? onPressed;

  static const double gorunenBoyut = 36;
  static const double dokunmaBoyutu = 48;
  static const double golgeYuksekligi = 3;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final etkin = onPressed != null;
    final sure = KilBasilir.sure(context);

    return Tooltip(
      message: etiket,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: etkin,
        label: etiket,
        child: KilBasilir(
          onTap: onPressed,
          builder: (context, basili, odakli) {
            final golgeli = r.sertGolge && etkin;
            final inis = basili ? (golgeli ? golgeYuksekligi - 1 : 1.5) : 0.0;
            return SizedBox.square(
              dimension: dokunmaBoyutu,
              child: Center(
                child: AnimatedContainer(
                  duration: sure,
                  curve: Curves.easeOut,
                  width: gorunenBoyut,
                  height: gorunenBoyut,
                  transform: Matrix4.translationValues(0, inis, 0),
                  decoration: BoxDecoration(
                    color: r.kart,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: odakli ? r.anaYazi : r.kenar,
                      width: 2,
                    ),
                    boxShadow: golgeli
                        ? [
                            BoxShadow(
                              color: r.kenar,
                              offset: Offset(0, basili ? 1 : golgeYuksekligi),
                            ),
                          ]
                        : const [],
                  ),
                  child: Icon(
                    ikon,
                    size: 20,
                    color: etkin ? r.anaYazi : r.solukYazi,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

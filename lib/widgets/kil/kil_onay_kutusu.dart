import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';
import 'kil_basilir.dart';

/// Kil onay kutusu. Kutu 24, dokunma alanı en az 48.
///
/// İşaretsizken kenar `tanitanKenar` (en az 3:1), işaretliyken adaçayı zemin
/// ve onay işareti. [etiket] verilirse satırın tamamı dokunulabilir olur;
/// bu durumda genişliği sınırlı bir yerde (ör. liste) kullanılmalı.
class KilOnayKutusu extends StatelessWidget {
  const KilOnayKutusu({
    super.key,
    required this.deger,
    required this.onChanged,
    this.etiket,
  });

  final bool deger;

  /// Yeni değerle çağrılır. null ise kutu pasiftir.
  final ValueChanged<bool>? onChanged;
  final String? etiket;

  static const double kutuBoyutu = 24;
  static const double dokunmaBoyutu = 48;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final etkin = onChanged != null;
    final sure = KilBasilir.sure(context);
    final doluRenk = etkin ? r.vurgu : r.kenar;

    return Semantics(
      checked: deger,
      enabled: etkin,
      label: etiket,
      child: KilBasilir(
        onTap: etkin ? () => onChanged!(!deger) : null,
        builder: (context, basili, odakli) {
          final kutu = AnimatedContainer(
            duration: sure,
            curve: Curves.easeOut,
            width: kutuBoyutu,
            height: kutuBoyutu,
            decoration: BoxDecoration(
              color: deger ? doluRenk : r.kart,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: odakli
                    ? r.anaYazi
                    : deger
                        ? doluRenk
                        : (etkin ? r.tanitanKenar : r.kenar),
                width: 2,
              ),
            ),
            child: AnimatedScale(
              duration: sure,
              curve: Curves.easeOut,
              scale: deger ? 1 : 0,
              child: Icon(
                Icons.check_rounded,
                size: 18,
                color: r.vurguUstuYazi,
              ),
            ),
          );

          final kutuAlani = SizedBox.square(
            dimension: dokunmaBoyutu,
            child: Center(child: kutu),
          );
          if (etiket == null) return kutuAlani;

          final yaziStili = Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: etkin ? r.anaYazi : r.solukYazi);
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: dokunmaBoyutu),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                kutuAlani,
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(etiket!, style: yaziStili),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

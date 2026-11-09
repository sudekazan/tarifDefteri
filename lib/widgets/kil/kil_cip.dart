import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';
import 'kil_basilir.dart';

/// Kil çipi (filtre, etiket). Seçiliyken zemin ve yazı rengi değişir ve bir
/// onay işareti çıkar; seçim yalnızca renkle anlatılmaz.
///
/// Görünen yükseklik en az 40, dokunma alanı en az 48.
class KilCip extends StatelessWidget {
  const KilCip({
    super.key,
    required this.etiket,
    required this.secili,
    required this.onSelected,
    this.ikon,
    this.emoji,
  });

  final String etiket;
  final bool secili;

  /// Yeni seçim değeriyle çağrılır. null ise çip pasiftir.
  final ValueChanged<bool>? onSelected;

  /// Seçili değilken etiketin solunda görünen ikon (isteğe bağlı).
  final IconData? ikon;

  /// Seçili değilken etiketin solunda görünen emoji (isteğe bağlı). Ekran
  /// okuyucu okumaz; seçiliyken yerini onay işareti alır.
  final String? emoji;

  static const double gorunenYukseklik = 40;
  static const double dokunmaYuksekligi = 48;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final etkin = onSelected != null;
    final yaziRengi = !etkin
        ? r.solukYazi
        : secili
        ? r.seciliCipYazi
        : r.anaYazi;
    final yaziStili =
        Theme.of(context).textTheme.titleSmall?.copyWith(color: yaziRengi) ??
        TextStyle(color: yaziRengi);
    final solIkon = secili ? Icons.check_rounded : ikon;
    final sure = KilBasilir.sure(context);

    return Semantics(
      button: true,
      selected: secili,
      enabled: etkin,
      child: KilBasilir(
        onTap: etkin ? () => onSelected!(!secili) : null,
        builder: (context, basili, odakli) {
          final zemin = !etkin
              ? r.solukYuzey
              : secili
              ? r.seciliCipZemin
              : r.kart;
          final kenar = odakli
              ? r.anaYazi
              : secili
              ? r.seciliCipZemin
              : r.kenar;
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: (dokunmaYuksekligi - gorunenYukseklik) / 2,
            ),
            child: AnimatedContainer(
              duration: sure,
              curve: Curves.easeOut,
              constraints: const BoxConstraints(
                minHeight: gorunenYukseklik,
                minWidth: dokunmaYuksekligi,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: zemin,
                borderRadius: BorderRadius.circular(gorunenYukseklik),
                border: Border.all(color: kenar, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (solIkon != null) ...[
                    Icon(solIkon, size: 18, color: yaziRengi),
                    const SizedBox(width: 6),
                  ] else if (emoji != null) ...[
                    ExcludeSemantics(child: Text(emoji!, style: yaziStili)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(child: Text(etiket, style: yaziStili)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

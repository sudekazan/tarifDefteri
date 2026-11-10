import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';

/// [KilSecimListesi] içindeki bir seçenek.
class KilSecenek {
  const KilSecenek({
    required this.ikon,
    required this.etiket,
    required this.onTap,
    this.secili = false,
    this.renk,
    this.emoji,
  });

  final IconData ikon;
  final String etiket;
  final VoidCallback onTap;

  /// Seçili satırda sağda onay işareti çıkar; ekran okuyucu "seçili" der.
  final bool secili;

  /// İkon kutusunun rengi (ör. klasör rengi). Verilmezse seçili çip rengi.
  final KlasorRenk? renk;

  /// Verilirse ikon yerine kutuda gösterilir (ör. dil bayrağı).
  final String? emoji;
}

/// Alt sayfalardaki seçenek listesi (klasöre taşı, bölüm ekle). Her satır en
/// az 56 yüksekliğinde; solda renkli ikon kutusu, yanında ad. Uzun listede
/// kaydırılır.
class KilSecimListesi extends StatelessWidget {
  const KilSecimListesi({super.key, required this.secenekler});

  final List<KilSecenek> secenekler;

  static const double enKucukYukseklik = 56;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme.titleMedium;

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: secenekler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final s = secenekler[i];
        return Semantics(
          selected: s.secili,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: s.onTap,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: enKucukYukseklik),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: s.renk?.zemin ?? r.seciliCipZemin,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: s.emoji != null
                              ? Text(
                                  s.emoji!,
                                  style: const TextStyle(fontSize: 22),
                                  textScaler: TextScaler.noScaling,
                                )
                              : Icon(
                                  s.ikon,
                                  size: 22,
                                  color: s.renk?.ikon ?? r.seciliCipYazi,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(s.etiket, style: yazi)),
                      if (s.secili) ...[
                        const SizedBox(width: 8),
                        ExcludeSemantics(
                          child: Icon(Icons.check_rounded, color: r.baslik),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

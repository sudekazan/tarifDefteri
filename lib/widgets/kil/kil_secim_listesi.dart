import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';

/// [KilSecimListesi] içindeki bir seçenek.
class KilSecenek {
  const KilSecenek({
    required this.ikon,
    required this.etiket,
    required this.onTap,
  });

  final IconData ikon;
  final String etiket;
  final VoidCallback onTap;
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
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: s.onTap,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: enKucukYukseklik),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: r.seciliCipZemin,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s.ikon, size: 22, color: r.seciliCipYazi),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(s.etiket, style: yazi)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';
import 'kil_kart.dart';

/// Alt sekme çubuğundaki bir sekme.
@immutable
class KilSekme {
  const KilSekme({
    required this.ikon,
    required this.seciliIkon,
    required this.etiket,
  });

  final IconData ikon;
  final IconData seciliIkon;
  final String etiket;
}

/// Kil tasarımının alt sekme çubuğu: temadaki `NavigationBar` ve üstünde
/// süs kenarı (`NavigationBar`'ın kenar ayarı yok, çizgiyi bu bileşen çizer).
///
/// Sekme etiketleri en fazla [enBuyukYaziOlcegi] kadar büyür. Apple'ın sekme
/// çubukları da yazı boyutuyla büyümez; etiket uzun basınca ipucunda okunur.
class KilSekmeCubugu extends StatelessWidget {
  const KilSekmeCubugu({
    super.key,
    required this.sekmeler,
    required this.seciliIndeks,
    required this.onSecildi,
  });

  final List<KilSekme> sekmeler;
  final int seciliIndeks;
  final ValueChanged<int> onSecildi;

  static const double enBuyukYaziOlcegi = 1.3;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: r.kenar, width: KilKart.kenarKalinligi),
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: enBuyukYaziOlcegi,
        child: NavigationBar(
          selectedIndex: seciliIndeks,
          onDestinationSelected: onSecildi,
          destinations: [
            for (final s in sekmeler)
              NavigationDestination(
                icon: Icon(s.ikon),
                selectedIcon: Icon(s.seciliIkon),
                label: s.etiket,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'kil/kil.dart';

/// Klasör kaydı ekranındaki ikon seçici. Her kutu 56x56 (dokunma alanı en
/// az 48); seçili kutu renkle birlikte köşedeki onay işaretiyle de belli olur.
class KlasorIkonSecici extends StatelessWidget {
  const KlasorIkonSecici({
    super.key,
    required this.seciliKod,
    required this.onSecildi,
    required this.anlamEtiketi,
  });

  /// Seçili ikonun `codePoint` değeri.
  final int seciliKod;
  final ValueChanged<int> onSecildi;

  /// Ekran okuyucunun her kutu için okuyacağı ad (sıra numarasıyla çağrılır).
  final String Function(int sira) anlamEtiketi;

  static const double kutuBoyutu = 56;

  static const List<IconData> ikonlar = [
    Icons.folder, // Varsayılan
    Icons.favorite, // Favori
    Icons.cake, // Tatlı/muffin
    Icons.fastfood, // Poğaça/atıştırmalık
    Icons.restaurant, // Yemek
    Icons.local_drink, // İçecek
    Icons.soup_kitchen, // Sulu yemek
    Icons.icecream, // Tatlı/dondurma
    Icons.lunch_dining, // Yemek tabağı
    Icons.bakery_dining, // Fırın/tatlı
    Icons.emoji_food_beverage, // Çay/kahve
    Icons.set_meal,
    Icons.dinner_dining,
    Icons.brunch_dining,
    Icons.local_pizza,
    Icons.ramen_dining,
    Icons.rice_bowl,
  ];

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final sure = KilBasilir.sure(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < ikonlar.length; i++)
          Builder(builder: (context) {
            final ikon = ikonlar[i];
            final secili = ikon.codePoint == seciliKod;
            return Semantics(
              button: true,
              selected: secili,
              label: anlamEtiketi(i + 1),
              // excludeSemantics içteki dokunma eylemini de siler; eylem
              // burada ayrıca verilir.
              excludeSemantics: true,
              onTap: () => onSecildi(ikon.codePoint),
              child: KilBasilir(
                onTap: () => onSecildi(ikon.codePoint),
                builder: (context, basili, odakli) => AnimatedContainer(
                  duration: sure,
                  curve: Curves.easeOut,
                  width: kutuBoyutu,
                  height: kutuBoyutu,
                  transform: Matrix4.translationValues(0, basili ? 2 : 0, 0),
                  decoration: BoxDecoration(
                    color: secili ? r.seciliCipZemin : r.kart,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: odakli
                          ? r.anaYazi
                          : secili
                              ? r.birincil
                              : r.kenar,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        ikon,
                        size: 26,
                        color: secili ? r.seciliCipYazi : r.solukYazi,
                      ),
                      if (secili)
                        Positioned(
                          top: 3,
                          right: 3,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: r.vurgu,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: r.vurguUstuYazi,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

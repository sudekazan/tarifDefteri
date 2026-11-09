import 'package:flutter/material.dart';

import '../utils/recipe_link_helper.dart';
import 'kil/kil.dart';
import 'tarif_detay_parcalari.dart';

/// İkon düğmelerinin en küçük dokunma alanı (temanın ayarından bağımsız).
const BoxConstraints _dokunma = BoxConstraints(minWidth: 48, minHeight: 48);

// Tarif oluşturma ekranının kil parçaları. Metinleri çağıran sayfa çevirip
// verir; böylece parçalar çeviri ve Firebase olmadan da test edilebilir.

/// "Fotoğraf ekle" düğmesi ve altında eklenen fotoğrafların yatay şeridi.
class TarifFotoSeridi extends StatelessWidget {
  const TarifFotoSeridi({
    super.key,
    required this.yollar,
    required this.ekleEtiketi,
    required this.silEtiketi,
    required this.yuklenemediMetni,
    required this.bulunamadiMetni,
    required this.onEkle,
    required this.onSil,
    required this.onBuyut,
  });

  final List<String> yollar;
  final String ekleEtiketi;
  final String silEtiketi;
  final String yuklenemediMetni;
  final String bulunamadiMetni;
  final VoidCallback onEkle;
  final ValueChanged<int> onSil;
  final ValueChanged<int> onBuyut;

  static const double fotoGenislik = 120;
  static const double fotoYukseklik = 140;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KilDugme.ikincil(
          etiket: ekleEtiketi,
          ikon: Icons.add_a_photo_rounded,
          tamGenislik: true,
          onPressed: onEkle,
        ),
        if (yollar.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: fotoYukseklik,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: yollar.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: fotoGenislik,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () => onBuyut(i),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: r.kenar, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: TarifGorseli(
                            yol: yollar[i],
                            yuklenemediMetni: yuklenemediMetni,
                            bulunamadiMetni: bulunamadiMetni,
                          ),
                        ),
                      ),
                    ),
                    // Silme düğmesi (sağ üst). Dokunma alanı 48.
                    Positioned(
                      top: 0,
                      right: 0,
                      child: KilYuvarlakDugme(
                        ikon: Icons.close_rounded,
                        etiket: silEtiketi,
                        onPressed: () => onSil(i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tarif oluşturmadaki bir bölüm kartı: başlık ve silme düğmesi, maddeler
/// (dokununca düzenlenir, çarpıyla silinir) ve altta yeni madde kutusu.
class TarifBolumDuzenleKarti extends StatelessWidget {
  const TarifBolumDuzenleKarti({
    super.key,
    required this.tur,
    required this.baslik,
    required this.maddeler,
    required this.controller,
    required this.ipucu,
    required this.bolumuSilEtiketi,
    required this.maddeyiSilEtiketi,
    required this.maddeEkleEtiketi,
    required this.onBolumuSil,
    required this.onMaddeDuzenle,
    required this.onMaddeSil,
    required this.onMaddeEkle,
    this.onBaglantiAc,
  });

  final String tur;
  final String baslik;
  final List<String> maddeler;
  final TextEditingController controller;
  final String ipucu;
  final String bolumuSilEtiketi;
  final String maddeyiSilEtiketi;
  final String maddeEkleEtiketi;
  final VoidCallback onBolumuSil;
  final ValueChanged<int> onMaddeDuzenle;
  final ValueChanged<int> onMaddeSil;

  /// Yeni madde kutusundaki metinle çağrılır (Enter ya da "+" düğmesi).
  final ValueChanged<String> onMaddeEkle;
  final ValueChanged<String>? onBaglantiAc;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final metinStili = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: r.anaYazi);

    return KilKart(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarifBolumBasligi(
            ikon: tarifBolumIkonu(tur),
            baslik: baslik,
            sonda: IconButton(
              constraints: _dokunma,
              icon: const Icon(Icons.delete_outline_rounded),
              color: r.hata,
              tooltip: bolumuSilEtiketi,
              onPressed: onBolumuSil,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 2, color: r.kenar, endIndent: 8),
          const SizedBox(height: 4),
          for (var i = 0; i < maddeler.length; i++)
            TarifMaddeSatiri(
              isaretUstPayi: 10,
              isaret: TarifMaddeIsareti(
                numara: tur == 'yapilis' ? i + 1 : null,
                boyut: 28,
              ),
              metin:
                  tur == 'linkler' &&
                      onBaglantiAc != null &&
                      isValidRecipeUrl(maddeler[i])
                  ? TarifBaglantisi(
                      adres: maddeler[i],
                      onTap: () => onBaglantiAc!(maddeler[i]),
                      onLongPress: () => onMaddeDuzenle(i),
                    )
                  : InkWell(
                      onTap: () => onMaddeDuzenle(i),
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          child: Text(maddeler[i], style: metinStili),
                        ),
                      ),
                    ),
              sonda: IconButton(
                constraints: _dokunma,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: r.solukYazi,
                tooltip: maddeyiSilEtiketi,
                onPressed: () => onMaddeSil(i),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Builder(
              builder: (context) {
                final kutu = TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(hintText: ipucu),
                  onSubmitted: onMaddeEkle,
                );
                final ekle = KilYuvarlakDugme(
                  ikon: Icons.add_rounded,
                  etiket: maddeEkleEtiketi,
                  onPressed: () => onMaddeEkle(controller.text),
                );
                // Büyük yazıda kutu tam genişlik, "+" altında sağda.
                if (tarifUstUsteMi(context)) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      kutu,
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ekle,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: kutu),
                    const SizedBox(width: 4),
                    ekle,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Tarif bölümleri" başlığı ve "Bölüm ekle" düğmesi. Sığmazsa düğme alta
/// iner.
class TarifBolumlerBasligi extends StatelessWidget {
  const TarifBolumlerBasligi({
    super.key,
    required this.baslik,
    required this.ekleEtiketi,
    required this.onEkle,
  });

  final String baslik;
  final String ekleEtiketi;
  final VoidCallback onEkle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Semantics(
          header: true,
          container: true,
          // Caveat (headlineSmall, 26).
          child: Text(baslik, style: Theme.of(context).textTheme.headlineSmall),
        ),
        KilDugme.birincil(
          etiket: ekleEtiketi,
          ikon: Icons.add_rounded,
          onPressed: onEkle,
        ),
      ],
    );
  }
}

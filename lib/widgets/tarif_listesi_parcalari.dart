import 'dart:io';

import 'package:flutter/material.dart';

import 'kil/kil.dart';

// Tarif listelerinin (klasör içi, favoriler) kil parçaları. Metinleri çağıran
// sayfa çevirip verir; böylece parçalar çeviri olmadan da test edilebilir.

/// Tarifin küçük görseli: ağdan, cihazdan ya da (görsel yoksa) ikonlu kutu.
class TarifKucukGorsel extends StatelessWidget {
  const TarifKucukGorsel({super.key, this.yol, this.boyut = 60});

  /// İlk görselin adresi (`http...`) ya da cihazdaki yolu.
  final String? yol;
  final double boyut;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;

    Widget yerTutucu(IconData ikon) => Container(
          color: r.klasorTatli.zemin,
          alignment: Alignment.center,
          child: Icon(ikon, color: r.klasorTatli.ikon, size: boyut * 0.45),
        );

    final y = yol;
    late final Widget icerik;
    if (y == null || y.isEmpty) {
      icerik = yerTutucu(Icons.restaurant_menu_rounded);
    } else if (y.startsWith('http')) {
      icerik = Image.network(
        y,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, ilerleme) {
          if (ilerleme == null) return child;
          return Container(
            color: r.solukYuzey,
            alignment: Alignment.center,
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: r.birincil,
                value: ilerleme.expectedTotalBytes != null
                    ? ilerleme.cumulativeBytesLoaded /
                        ilerleme.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => yerTutucu(Icons.broken_image_rounded),
      );
    } else if (File(y).existsSync()) {
      icerik = Image.file(
        File(y),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => yerTutucu(Icons.broken_image_rounded),
      );
    } else {
      icerik = yerTutucu(Icons.image_not_supported_rounded);
    }

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.square(dimension: boyut, child: icerik),
      ),
    );
  }
}

enum _TarifEylemi { paylas, sil }

/// Tarif satırı: görsel, ad, favori düğmesi ve (paylaş / sil) menüsü.
///
/// Yazı [tekSutunOlcegi]'nin üstüne büyütülmüşse ad, görsel ve düğmelerin
/// altına iner; böylece dar ekranda ad sıkışmaz.
class TarifSatiri extends StatelessWidget {
  const TarifSatiri({
    super.key,
    required this.ad,
    this.resimYolu,
    required this.favori,
    required this.favoriEtiketi,
    required this.paylasEtiketi,
    required this.silEtiketi,
    required this.onTap,
    required this.onFavori,
    required this.onPaylas,
    required this.onSil,
  });

  final String ad;
  final String? resimYolu;
  final bool favori;

  /// Favori düğmesinin ekran okuyucu ve ipucu metni (ör. "Favorilere ekle").
  final String favoriEtiketi;
  final String paylasEtiketi;
  final String silEtiketi;

  final VoidCallback onTap;
  final VoidCallback onFavori;

  /// Menü düğmesinin context'iyle çağrılır (iPad'de paylaşım penceresi oraya
  /// bağlanır).
  final void Function(BuildContext dugmeContext) onPaylas;
  final VoidCallback onSil;

  static const double tekSutunOlcegi = 1.6;
  static const double dokunmaBoyutu = 48;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final olcek = MediaQuery.textScalerOf(context).scale(10) / 10;
    final buyukYazi = olcek > tekSutunOlcegi;

    final favoriDugmesi = SizedBox.square(
      dimension: dokunmaBoyutu,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: favoriEtiketi,
        isSelected: favori,
        onPressed: onFavori,
        icon: Icon(
          favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: r.klasorFavori.ikon,
          size: 24,
        ),
      ),
    );

    final menu = Builder(
      builder: (dugmeContext) => SizedBox.square(
        dimension: dokunmaBoyutu,
        child: PopupMenuButton<_TarifEylemi>(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_vert_rounded, color: r.solukYazi),
          onSelected: (eylem) {
            switch (eylem) {
              case _TarifEylemi.paylas:
                onPaylas(dugmeContext);
              case _TarifEylemi.sil:
                onSil();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _TarifEylemi.paylas,
              child: Row(
                children: [
                  Icon(Icons.ios_share_rounded, size: 20, color: r.baslik),
                  const SizedBox(width: 10),
                  Flexible(child: Text(paylasEtiketi)),
                ],
              ),
            ),
            PopupMenuItem(
              value: _TarifEylemi.sil,
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 20, color: r.hata),
                  const SizedBox(width: 10),
                  Flexible(child: Text(silEtiketi)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final adYazisi = Text(
      ad,
      style: Theme.of(context).textTheme.titleMedium,
      maxLines: buyukYazi ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );

    return KilKart(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: buyukYazi
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    TarifKucukGorsel(yol: resimYolu),
                    const Spacer(),
                    favoriDugmesi,
                    menu,
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: adYazisi,
                ),
              ],
            )
          : Row(
              children: [
                TarifKucukGorsel(yol: resimYolu),
                const SizedBox(width: 14),
                Expanded(child: adYazisi),
                const SizedBox(width: 4),
                favoriDugmesi,
                menu,
              ],
            ),
    );
  }
}

/// Tarif listesi sayfasının görünümü (klasör içi ve favoriler): geri ve arama
/// düğmeleri, Caveat başlık, isteğe bağlı arama kutusu, tarif satırları ya da
/// boş durum kartı.
///
/// Veri işleri çağıran sayfada kalır; bu parça yalnızca çizer. Böylece
/// Firebase olmadan da test edilebilir.
class TarifListesiGorunumu extends StatelessWidget {
  const TarifListesiGorunumu({
    super.key,
    required this.baslik,
    required this.satirlar,
    required this.bosDurum,
    required this.aramaAcik,
    required this.aramaController,
    required this.aramaIpucu,
    required this.onAramaAcKapat,
    required this.onAramaDegisti,
    this.yeniTarifDugmesi,
    this.altCubuk,
  });

  final String baslik;

  /// Tarif satırları (genellikle [TarifSatiri]). Boşsa [bosDurum] görünür.
  final List<Widget> satirlar;
  final Widget bosDurum;

  final bool aramaAcik;
  final TextEditingController aramaController;
  final String aramaIpucu;
  final VoidCallback onAramaAcKapat;
  final ValueChanged<String> onAramaDegisti;

  /// Sağ altta yüzen düğme (ör. "Yeni tarif").
  final Widget? yeniTarifDugmesi;

  /// En alttaki çubuk (ör. banner reklam).
  final Widget? altCubuk;

  static const double satirAraligi = 12;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yerel = MaterialLocalizations.of(context);

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              yeniTarifDugmesi != null ? 112 : 32,
            ),
            children: [
              KilSayfaBasligi(
                baslik: baslik,
                eylemler: [
                  KilYuvarlakDugme(
                    ikon: aramaAcik ? Icons.close_rounded : Icons.search_rounded,
                    etiket: aramaAcik
                        ? yerel.closeButtonTooltip
                        : yerel.searchFieldLabel,
                    onPressed: onAramaAcKapat,
                  ),
                ],
              ),
              if (aramaAcik) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: aramaController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: onAramaDegisti,
                  decoration: InputDecoration(
                    hintText: aramaIpucu,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (satirlar.isEmpty)
                bosDurum
              else
                for (var i = 0; i < satirlar.length; i++) ...[
                  if (i > 0) const SizedBox(height: satirAraligi),
                  satirlar[i],
                ],
            ],
          ),
        ),
        floatingActionButton: yeniTarifDugmesi,
        bottomNavigationBar: altCubuk,
      ),
    );
  }
}

/// Tarif listesi boşken gösterilen kart.
class TarifBosDurum extends StatelessWidget {
  const TarifBosDurum({
    super.key,
    required this.ikon,
    required this.renk,
    required this.baslik,
    this.altBaslik,
  });

  final IconData ikon;
  final KlasorRenk renk;
  final String baslik;
  final String? altBaslik;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;
    final alt = altBaslik;

    return KilKart(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: renk.zemin,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(ikon, size: 38, color: renk.ikon),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            baslik,
            style: yaziTemasi.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (alt != null) ...[
            const SizedBox(height: 6),
            Text(
              alt,
              style: yaziTemasi.bodyMedium?.copyWith(color: r.solukYazi),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

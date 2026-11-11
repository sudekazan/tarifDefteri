import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/recipe_link_helper.dart';
import 'kil/kil.dart';

// Tarif detayı ve tarif oluşturma ekranlarının ortak kil parçaları. Metinleri
// çağıran sayfa çevirip verir; böylece parçalar çeviri ve Firebase olmadan da
// test edilebilir.

/// Bölüm türünün ikonu (malzemeler, yapılış, sos...). Tür adları kayıtlı
/// tarif verisindeki adlardır, değişmez.
IconData tarifBolumIkonu(String tur) {
  switch (tur) {
    case 'malzemeler':
      return Icons.shopping_basket_rounded;
    case 'harc':
      return Icons.blender_rounded;
    case 'yapilis':
      return Icons.format_list_numbered_rounded;
    case 'hamur':
      return Icons.bakery_dining_rounded;
    case 'serbet':
      return Icons.water_drop_rounded;
    case 'sos':
      return Icons.soup_kitchen_rounded;
    case 'puf_noktasi':
      return Icons.lightbulb_rounded;
    case 'linkler':
      return Icons.link_rounded;
    default:
      return Icons.category_rounded;
  }
}

/// İkon düğmelerinin en küçük dokunma alanı (temanın ayarından bağımsız).
const BoxConstraints _dokunma = BoxConstraints(minWidth: 48, minHeight: 48);

/// Yazı bu kattan büyükse ikonlar ve düğmeler metnin üstüne çıkar; yoksa
/// 320 genişlikte kelimeler ortasından bölünür.
const double tarifUstUsteOlcegi = 1.6;

bool tarifUstUsteMi(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > tarifUstUsteOlcegi;

/// Bir madde satırı: solda işaret, ortada metin, sağda isteğe bağlı düğme.
/// Büyük yazıda işaret ve düğme metnin üstündeki satıra çıkar.
class TarifMaddeSatiri extends StatelessWidget {
  const TarifMaddeSatiri({
    super.key,
    required this.isaret,
    required this.metin,
    this.sonda,
    this.isaretUstPayi = 8,
  });

  final Widget isaret;
  final Widget metin;
  final Widget? sonda;

  /// Yan yana dururken işaretin metnin ilk satırıyla hizalanması için.
  final double isaretUstPayi;

  @override
  Widget build(BuildContext context) {
    if (tarifUstUsteMi(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(children: [isaret, const Spacer(), if (sonda != null) sonda!]),
          metin,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: isaretUstPayi),
          child: isaret,
        ),
        const SizedBox(width: 12),
        Expanded(child: metin),
        if (sonda != null) sonda!,
      ],
    );
  }
}

/// Malzeme gibi ölçeklenen ve alışveriş listesine eklenebilen bölüm türleri.
bool tarifBolumuMalzemeMi(String tur) =>
    tur == 'malzemeler' ||
    tur == 'harc' ||
    tur == 'hamur' ||
    tur == 'serbet' ||
    tur == 'sos';

/// Bölüm kartının başlığı: renkli ikon kutusu, Caveat bölüm başlığı ve
/// isteğe bağlı sağdaki düğme.
class TarifBolumBasligi extends StatelessWidget {
  const TarifBolumBasligi({
    super.key,
    required this.ikon,
    required this.baslik,
    this.sonda,
  });

  final IconData ikon;
  final String baslik;
  final Widget? sonda;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final kutu = ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: r.seciliCipZemin,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(ikon, color: r.seciliCipYazi, size: 24),
      ),
    );
    final yazi = Semantics(
      header: true,
      container: true,
      // Caveat (headlineSmall, 26).
      child: Text(baslik, style: Theme.of(context).textTheme.headlineSmall),
    );

    if (tarifUstUsteMi(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [kutu, const Spacer(), if (sonda != null) sonda!]),
          const SizedBox(height: 8),
          yazi,
        ],
      );
    }
    return Row(
      children: [
        kutu,
        const SizedBox(width: 12),
        Expanded(child: yazi),
        if (sonda != null) sonda!,
      ],
    );
  }
}

/// Madde başındaki daire: yapılışta sıra numarası, diğerlerinde işaret.
class TarifMaddeIsareti extends StatelessWidget {
  const TarifMaddeIsareti({super.key, this.numara, this.boyut = 32});

  /// Verilirse numara yazılır, yoksa onay işareti çizilir.
  final int? numara;
  final double boyut;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final n = numara;
    return ExcludeSemantics(
      excluding: n == null,
      child: Container(
        width: boyut,
        height: boyut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: r.seciliCipZemin,
          shape: BoxShape.circle,
        ),
        child: n != null
            ? FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '$n',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: r.seciliCipYazi),
                  ),
                ),
              )
            : Icon(Icons.check_rounded, size: 18, color: r.seciliCipYazi),
      ),
    );
  }
}

/// Bir bağlantı: birincil renkte, altı çizili. Dokununca açılır.
class TarifBaglantisi extends StatelessWidget {
  const TarifBaglantisi({
    super.key,
    required this.adres,
    required this.onTap,
    this.onLongPress,
  });

  final String adres;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: r.birincil),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  adres,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: r.baslik,
                    decoration: TextDecoration.underline,
                    decorationColor: r.baslik,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarif detayındaki bir bölüm kartı (malzemeler, yapılış, püf noktası...).
class TarifBolumKarti extends StatelessWidget {
  const TarifBolumKarti({
    super.key,
    required this.tur,
    required this.baslik,
    required this.maddeler,
    this.sepeteEkleEtiketi,
    this.onSepeteEkle,
    this.onBaglantiAc,
  });

  /// Bölüm türü (`malzemeler`, `yapilis`, `linkler`...).
  final String tur;
  final String baslik;

  /// Ekranda görünecek maddeler (malzemeler porsiyona göre ölçeklenmiş).
  final List<String> maddeler;

  /// Verilirse malzeme bölümlerinde her maddenin yanında sepet düğmesi olur.
  final String? sepeteEkleEtiketi;
  final ValueChanged<int>? onSepeteEkle;

  /// Bağlantılar bölümünde adrese dokununca.
  final ValueChanged<String>? onBaglantiAc;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final metinStili = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: r.anaYazi, height: 1.4);
    final sepet =
        tarifBolumuMalzemeMi(tur) &&
        sepeteEkleEtiketi != null &&
        onSepeteEkle != null;

    return KilKart(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TarifBolumBasligi(
              ikon: tarifBolumIkonu(tur),
              baslik: baslik,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 2, color: r.kenar, endIndent: 8),
          const SizedBox(height: 8),
          for (var i = 0; i < maddeler.length; i++)
            TarifMaddeSatiri(
              isaret: TarifMaddeIsareti(
                numara: tur == 'yapilis' ? i + 1 : null,
              ),
              metin:
                  tur == 'linkler' &&
                      onBaglantiAc != null &&
                      isValidRecipeUrl(maddeler[i])
                  ? TarifBaglantisi(
                      adres: maddeler[i],
                      onTap: () => onBaglantiAc!(maddeler[i]),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
                      child: Text(maddeler[i], style: metinStili),
                    ),
              sonda: sepet
                  ? IconButton(
                      constraints: _dokunma,
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 22,
                      ),
                      color: r.solukYazi,
                      tooltip: sepeteEkleEtiketi,
                      onPressed: () => onSepeteEkle!(i),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Eski biçimdeki (bölümsüz) tarifin açıklaması.
class TarifAciklamaKarti extends StatelessWidget {
  const TarifAciklamaKarti({
    super.key,
    required this.baslik,
    required this.metin,
  });

  final String baslik;
  final String metin;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return KilKart(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarifBolumBasligi(ikon: Icons.menu_book_rounded, baslik: baslik),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 2, color: r.kenar),
          const SizedBox(height: 12),
          Text(
            metin,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: r.anaYazi, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Porsiyon çarpanı: "−" ve "+" yuvarlak düğmeleri arasında çarpan.
/// Yazı büyüyünce düğmeler etiketin altına iner.
class PorsiyonAyari extends StatelessWidget {
  const PorsiyonAyari({
    super.key,
    required this.etiket,
    required this.carpanMetni,
    required this.azaltEtiketi,
    required this.artirEtiketi,
    required this.onAzalt,
    required this.onArtir,
  });

  final String etiket;
  final String carpanMetni;
  final String azaltEtiketi;
  final String artirEtiketi;

  /// `null` ise "−" pasif (en küçük çarpan).
  final VoidCallback? onAzalt;
  final VoidCallback? onArtir;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;
    final ayar = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KilYuvarlakDugme(
          ikon: Icons.remove_rounded,
          etiket: azaltEtiketi,
          onPressed: onAzalt,
        ),
        // Çok büyük yazıda çarpan, düğmeler sığsın diye küçülür.
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Semantics(
              liveRegion: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  carpanMetni,
                  textAlign: TextAlign.center,
                  style: yazi.titleMedium?.copyWith(color: r.baslik),
                ),
              ),
            ),
          ),
        ),
        KilYuvarlakDugme(
          ikon: Icons.add_rounded,
          etiket: artirEtiketi,
          onPressed: onArtir,
        ),
      ],
    );

    return KilKart(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(etiket, style: yazi.titleMedium),
          ),
          ayar,
        ],
      ),
    );
  }
}

/// Tarif görseli: ağdan ya da cihazdan. Yüklenemezse ikon ve açıklama.
class TarifGorseli extends StatelessWidget {
  const TarifGorseli({
    super.key,
    required this.yol,
    required this.yuklenemediMetni,
    required this.bulunamadiMetni,
  });

  final String yol;
  final String yuklenemediMetni;
  final String bulunamadiMetni;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;

    Widget hata(IconData ikon, String mesaj) => Container(
      color: r.klasorTatli.zemin,
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 48, color: r.klasorTatli.ikon),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              mesaj,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: r.klasorTatli.ikon),
            ),
          ),
        ],
      ),
    );

    if (yol.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: yol,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        progressIndicatorBuilder: (context, url, ilerleme) => Container(
          color: r.solukYuzey,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            color: r.birincil,
            value: ilerleme.progress,
          ),
        ),
        errorWidget: (_, __, ___) =>
            hata(Icons.broken_image_rounded, yuklenemediMetni),
      );
    }
    if (File(yol).existsSync()) {
      return Image.file(
        File(yol),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            hata(Icons.broken_image_rounded, yuklenemediMetni),
      );
    }
    return hata(Icons.image_not_supported_rounded, bulunamadiMetni);
  }
}

/// Tarif detayının üstündeki kaydırılabilir görseller. Birden çok görsel
/// varsa sağ altta "1 / 3" sayacı çıkar.
class TarifGorselGalerisi extends StatelessWidget {
  const TarifGorselGalerisi({
    super.key,
    required this.yollar,
    required this.onTap,
    required this.yuklenemediMetni,
    required this.bulunamadiMetni,
    this.yukseklik = 240,
  });

  final List<String> yollar;
  final ValueChanged<String> onTap;
  final String yuklenemediMetni;
  final String bulunamadiMetni;
  final double yukseklik;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return SizedBox(
      height: yukseklik,
      child: PageView.builder(
        itemCount: yollar.length,
        itemBuilder: (context, i) {
          final yol = yollar[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onTap(yol),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KilKart.koseYaricapi),
                  border: Border.all(
                    color: r.kenar,
                    width: KilKart.kenarKalinligi,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    KilKart.koseYaricapi - KilKart.kenarKalinligi,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TarifGorseli(
                        yol: yol,
                        yuklenemediMetni: yuklenemediMetni,
                        bulunamadiMetni: bulunamadiMetni,
                      ),
                      if (yollar.length > 1)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: r.kart,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: r.kenar, width: 2),
                            ),
                            child: Text(
                              '${i + 1} / ${yollar.length}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: r.anaYazi),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Favori tarifin başlığının altındaki küçük pembe rozet.
class FavoriRozeti extends StatelessWidget {
  const FavoriRozeti({super.key, required this.etiket});

  final String etiket;

  @override
  Widget build(BuildContext context) {
    final renk = context.kil.klasorFavori;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: renk.zemin,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_rounded, size: 18, color: renk.ikon),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                etiket,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: renk.ikon),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Üst çubuksuz iç sayfa iskeleti (tarif detayı, tarif oluşturma): yuvarlak
/// geri düğmesi, sağda eylem düğmeleri, altında Caveat başlık ve kaydırılan
/// içerik. [altDugme] verilirse sağ altta durur ve içerik onun altına kadar
/// kaydırılabilir.
class KilIcSayfa extends StatelessWidget {
  const KilIcSayfa({
    super.key,
    required this.baslik,
    required this.icerik,
    this.eylemler = const [],
    this.altDugme,
    this.altCubuk,
    this.kaydirma,
    this.onGeri,
  });

  final String baslik;
  final List<Widget> icerik;
  final List<Widget> eylemler;
  final Widget? altDugme;
  final Widget? altCubuk;
  final ScrollController? kaydirma;
  final VoidCallback? onGeri;

  /// Kartlar arası boşluk.
  static const double aralik = 16;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          bottom: false,
          child: ListView(
            controller: kaydirma,
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              altDugme != null ? 112 : 32,
            ),
            children: [
              KilSayfaBasligi(
                baslik: baslik,
                eylemler: eylemler,
                onGeri: onGeri,
              ),
              for (final parca in icerik) ...[
                const SizedBox(height: aralik),
                parca,
              ],
            ],
          ),
        ),
        floatingActionButton: altDugme,
        bottomNavigationBar: altCubuk,
      ),
    );
  }
}

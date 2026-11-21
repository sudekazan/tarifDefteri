import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kil/kil.dart';

// Ana sayfanın (Defterim) kil parçaları. Metinleri çağıran sayfa çevirip
// verir; böylece parçalar çeviri olmadan da test edilebilir.

/// Başlığın yanındaki küçük "Premium" rozeti. Görünen boyu küçük, dokunma
/// alanı en az 48x48. Yazısı büyük yazıda en fazla [yaziSiniri] kat büyür;
/// yoksa 320 genişlikte 3.2 katta "Premium" satıra sığmıyordu.
class ProRozeti extends StatelessWidget {
  const ProRozeti({
    super.key,
    required this.etiket,
    required this.anlamEtiketi,
    required this.onPressed,
  });

  final String etiket;

  /// Ekran okuyucunun okuyacağı tam ad (ör. "Premium'a Geç").
  final String anlamEtiketi;
  final VoidCallback onPressed;

  static const double dokunmaBoyutu = 48;
  static const double yaziSiniri = 2.0;

  // build'deki ölçüler: simge 16 + boşluk 4 + yatay iç boşluk 2x10 +
  // kenarlık 2x2. Değişirse [dogalGenislik] de değişmeli (testle korunur).
  static const double _yaziDisiGenislik = 16 + 4 + 2 * 10 + 2 * 2;

  /// Rozetin tek satırda kapladığı genişlik (dokunma alanı dahil). Başlığın
  /// yanına sığıp sığmadığına yerleşimden önce karar vermek için.
  static double dogalGenislik(BuildContext context, String etiket) {
    final tp = TextPainter(
      text: TextSpan(
        text: etiket,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(
        context,
      ).clamp(maxScaleFactor: yaziSiniri),
      maxLines: 1,
    )..layout();
    final genislik = tp.width + _yaziDisiGenislik;
    tp.dispose();
    return math.max(genislik, dokunmaBoyutu);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: r.seciliCipYazi);
    final sure = KilBasilir.sure(context);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: yaziSiniri,
      child: Semantics(
        button: true,
        label: anlamEtiketi,
        // excludeSemantics içteki dokunma eylemini de siler; eylem burada
        // ayrıca verilir, yoksa ekran okuyucu rozeti açamaz.
        excludeSemantics: true,
        onTap: onPressed,
        child: KilBasilir(
          onTap: onPressed,
          builder: (context, basili, odakli) => ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: dokunmaBoyutu,
              minHeight: dokunmaBoyutu,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: sure,
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, basili ? 2 : 0, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: r.seciliCipZemin,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: odakli ? r.anaYazi : r.seciliCipZemin,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: r.seciliCipYazi,
                    ),
                    const SizedBox(width: 4),
                    // Uzun metin ("Premium'a geç", "Passer à Premium") dar
                    // ekranda taşmasın: kısaltılmaz, alt satıra iner.
                    Flexible(child: Text(etiket, style: yazi)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ana sayfa başlığı: başlık solda, [proRozeti] sağ kenarda. Rozet sığmazsa
/// (büyük yazı) başlığın altına, sola yaslı iner; başlık kısalmaz.
/// Rozet başlığın hemen yanında dururken kullanıcılar onu "Premium'sunuz"
/// gibi bir durum bilgisi sanıyordu; sağ kenarda bir eylem olarak okunur.
class AnaSayfaBasligi extends StatelessWidget {
  const AnaSayfaBasligi({super.key, required this.baslik, this.proRozeti});

  final Widget baslik;

  /// Pro kullanıcıda null.
  final Widget? proRozeti;

  @override
  Widget build(BuildContext context) {
    final rozet = proRozeti;
    if (rozet == null) {
      return Align(alignment: AlignmentDirectional.centerStart, child: baslik);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // spaceBetween ancak Wrap tüm genişliği kaplarsa iki kenara dağıtır.
        final wrap = Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [baslik, rozet],
        );
        if (!constraints.hasBoundedWidth) return wrap;
        return SizedBox(width: constraints.maxWidth, child: wrap);
      },
    );
  }
}

/// Ana sayfadaki arama kutusu. Yazı yazılmaz; dokununca arama sayfası açılır.
class AramaKutusu extends StatelessWidget {
  const AramaKutusu({super.key, required this.ipucu, required this.onTap});

  final String ipucu;
  final VoidCallback onTap;

  static const double enKucukYukseklik = 52;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: r.solukYazi);

    return Semantics(
      button: true,
      label: ipucu,
      // excludeSemantics içteki dokunma eylemini de siler; eylem burada
      // ayrıca verilir, yoksa ekran okuyucu kutuyu açamaz.
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: r.kart,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Öğeyi tanıtan kenar (en az 3:1), metin kutusuyla aynı.
          side: BorderSide(color: r.tanitanKenar, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: enKucukYukseklik),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: r.solukYazi),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ipucu,
                      style: yazi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Bugün ne pişirsem" kahraman kartı: kiremit zeminli öne çıkan kil kartı.
class NePisirsemKarti extends StatelessWidget {
  const NePisirsemKarti({
    super.key,
    required this.rozet,
    required this.baslik,
    required this.altBaslik,
    required this.onTap,
  });

  final String rozet;
  final String baslik;
  final String altBaslik;
  final VoidCallback onTap;

  /// Yazı bu ölçeğin üstündeyse daire metnin üstüne çıkar; yoksa metin
  /// sıkışır ve kelimeler ortasından bölünür.
  static const double ustUsteOlcegi = 1.6;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;
    final yazi = r.oneCikanKartYazi;
    final olcek = MediaQuery.textScalerOf(context).scale(10) / 10;

    final metinler = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: yazi, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: yazi),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  rozet,
                  style: yaziTemasi.labelSmall?.copyWith(
                    color: yazi,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Caveat (headlineSmall, 26): yalnızca 22 pt ve üstü.
        Text(baslik, style: yaziTemasi.headlineSmall?.copyWith(color: yazi)),
        const SizedBox(height: 2),
        Text(altBaslik, style: yaziTemasi.bodyMedium?.copyWith(color: yazi)),
      ],
    );

    final daire = ExcludeSemantics(
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: r.seciliCipZemin,
          border: Border.all(color: yazi, width: 2),
        ),
        child: const Text(
          '🍳',
          style: TextStyle(fontSize: 30),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );

    return KilKart(
      oneCikan: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      child: olcek > ustUsteOlcegi
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [daire, const SizedBox(height: 12), metinler],
            )
          : Row(
              children: [
                Expanded(child: metinler),
                const SizedBox(width: 12),
                daire,
              ],
            ),
    );
  }
}

/// Klasör kartı: renkli ikon kutusu, sağ üstte isteğe bağlı menü, altta ad.
class KlasorKarti extends StatelessWidget {
  const KlasorKarti({
    super.key,
    required this.ad,
    required this.ikon,
    required this.renk,
    required this.onTap,
    this.menu,
  });

  final String ad;
  final IconData ikon;
  final KlasorRenk renk;
  final VoidCallback onTap;

  /// Sağ üstteki düğme (ör. yeniden adlandır / sil menüsü). En az 48x48.
  final Widget? menu;

  static const double ikonKutusu = 48;

  @override
  Widget build(BuildContext context) {
    return KilKart(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: ikonKutusu,
                  height: ikonKutusu,
                  decoration: BoxDecoration(
                    color: renk.zemin,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(ikon, color: renk.ikon, size: 26),
                ),
              ),
              const Spacer(),
              menu ?? const SizedBox(height: ikonKutusu),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              ad,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Klasör kartlarını iki sütunda dizer; bir satırdaki kartlar aynı boydadır.
/// Yazı [tekSutunOlcegi]'nin üstüne büyütülmüşse tek sütuna geçer.
class KlasorIzgarasi extends StatelessWidget {
  const KlasorIzgarasi({super.key, required this.kartlar});

  final List<Widget> kartlar;

  static const double tekSutunOlcegi = 1.6;
  static const double aralik = 14;

  @override
  Widget build(BuildContext context) {
    final olcek = MediaQuery.textScalerOf(context).scale(10) / 10;
    final satirlar = <Widget>[];
    if (olcek > tekSutunOlcegi) {
      satirlar.addAll(kartlar);
    } else {
      for (var i = 0; i < kartlar.length; i += 2) {
        satirlar.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: kartlar[i]),
                const SizedBox(width: aralik),
                Expanded(
                  child: i + 1 < kartlar.length
                      ? kartlar[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < satirlar.length; i++) ...[
          if (i > 0) const SizedBox(height: aralik),
          satirlar[i],
        ],
      ],
    );
  }
}

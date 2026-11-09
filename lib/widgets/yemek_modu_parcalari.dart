import 'package:flutter/material.dart';

import 'kil/kil.dart';
import 'tarif_detay_parcalari.dart';

// Yemek yapma modunun kil parçaları. Mutfakta uzaktan okunacağı için yazılar
// büyük (adım 26, malzeme 20), dokunma alanları geniş (satır en az 64, alt
// düğmeler 56). Metinleri sayfa çevirip verir; parçalar çeviri ve Firebase
// olmadan test edilebilir.

/// Adım metninin boyutu.
const double yemekAdimYaziBoyutu = 26;

/// Malzeme satırı metninin boyutu.
const double yemekMalzemeYaziBoyutu = 20;

/// Malzeme satırının en küçük yüksekliği.
const double yemekMalzemeSatirYuksekligi = 64;

/// Üst kısım, ilerleme ve alt düğmeler bu kattan fazla büyümez (sekme
/// etiketlerindeki 1.3 sınırı gibi); yoksa en büyük yazıda adıma yer
/// kalmaz. Adım ve malzeme yazıları sınırsız büyür.
const double yemekCubukYaziSiniri = 2.0;

/// [child]'ın yazısı en fazla [yemekCubukYaziSiniri] kat büyür. Üst ve alt
/// kısımlarda ve Caveat başlıklarda ("Adım 2", "Malzemeler") kullanılır.
Widget yemekYaziSiniri(Widget child) => MediaQuery.withClampedTextScaling(
  maxScaleFactor: yemekCubukYaziSiniri,
  child: child,
);

/// Üst kısım: solda geri, sağda "Malzemeler" düğmesi, altında Caveat başlık
/// (tarifin adı). Büyük yazıda tek satır olur: "Malzemeler" yuvarlak ikon
/// düğmesine döner, başlık ikisinin arasında tek satıra iner; böylece
/// adımlara yer kalır.
class YemekModuBasligi extends StatelessWidget {
  const YemekModuBasligi({
    super.key,
    required this.baslik,
    required this.malzemeEtiketi,
    required this.onMalzemeler,
    this.onGeri,
  });

  final String baslik;
  final String malzemeEtiketi;
  final VoidCallback onMalzemeler;

  /// Verilmezse sayfa kapanır (`Navigator.maybePop`).
  final VoidCallback? onGeri;

  static const double _icPay =
      (KilYuvarlakDugme.dokunmaBoyutu - KilYuvarlakDugme.gorunenBoyut) / 2;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final ustUste = tarifUstUsteMi(context);
    final ios = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

    final geri = Transform.translate(
      offset: const Offset(-_icPay, 0),
      child: KilYuvarlakDugme(
        ikon: ios ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded,
        etiket: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onGeri ?? () => Navigator.maybePop(context),
      ),
    );
    final yazi = Semantics(
      header: true,
      // Caveat (headlineMedium, 30).
      child: Text(
        baslik,
        maxLines: ustUste ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(color: r.baslik),
      ),
    );

    if (ustUste) {
      return Row(
        children: [
          geri,
          Expanded(child: yazi),
          Transform.translate(
            offset: const Offset(_icPay, 0),
            child: KilYuvarlakDugme(
              ikon: Icons.soup_kitchen_rounded,
              etiket: malzemeEtiketi,
              onPressed: onMalzemeler,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            geri,
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: KilDugme.ikincil(
                  etiket: malzemeEtiketi,
                  ikon: Icons.soup_kitchen_rounded,
                  onPressed: onMalzemeler,
                ),
              ),
            ),
          ],
        ),
        yazi,
      ],
    );
  }
}

/// Yuvarlak uçlu ilerleme çubuğu. [tamam] ise adaçayı, değilse terrakota.
/// Ekran okuyucuya kapalı; ilerleme yanındaki yazıyla okunur.
class YemekIlerlemeCubugu extends StatelessWidget {
  const YemekIlerlemeCubugu({
    super.key,
    required this.deger,
    this.tamam = false,
  });

  /// 0 ile 1 arası.
  final double deger;
  final bool tamam;

  static const double yukseklik = 10;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return ExcludeSemantics(
      child: Container(
        height: yukseklik,
        decoration: BoxDecoration(
          color: r.kenar,
          borderRadius: BorderRadius.circular(yukseklik / 2),
        ),
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedFractionallySizedBox(
          duration: KilBasilir.sure(context),
          curve: Curves.easeOut,
          widthFactor: deger.clamp(0.0, 1.0),
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: tamam ? r.vurgu : r.birincil,
              borderRadius: BorderRadius.circular(yukseklik / 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sayfaların üstündeki ilerleme: solda bulunulan yer ("Adım 2 / 5"), sağda
/// sayfa sayısı ("3 / 6"), altında çubuk. Büyük yazıda çubuk ve sayı tek
/// satırda.
class YemekSayfaIlerlemesi extends StatelessWidget {
  const YemekSayfaIlerlemesi({
    super.key,
    required this.konum,
    required this.sayfa,
    required this.toplamSayfa,
  });

  final String konum;

  /// 0'dan başlar.
  final int sayfa;
  final int toplamSayfa;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme.titleMedium;
    final sayac = Text(
      '${sayfa + 1} / $toplamSayfa',
      style: yazi?.copyWith(color: r.baslik),
    );
    final cubuk = YemekIlerlemeCubugu(
      deger: toplamSayfa == 0 ? 0 : (sayfa + 1) / toplamSayfa,
    );
    // Büyük yazıda konum yazısı gösterilmez; aynı bilgi sayfanın başlığında
    // ("Adım 2", "Malzemeler") zaten var.
    if (tarifUstUsteMi(context)) {
      return Row(
        children: [
          Expanded(child: cubuk),
          const SizedBox(width: 12),
          sayac,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                konum,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: yazi?.copyWith(color: r.solukYazi),
              ),
            ),
            const SizedBox(width: 12),
            sayac,
          ],
        ),
        const SizedBox(height: 8),
        cubuk,
      ],
    );
  }
}

/// Malzemeler sayfasının başındaki kart: ikon, Caveat başlık, "3 / 8 hazır"
/// hapı ve ilerleme çubuğu. Hepsi hazırsa hap ve çubuk adaçayına döner.
class YemekMalzemeOzeti extends StatelessWidget {
  const YemekMalzemeOzeti({
    super.key,
    required this.baslik,
    required this.hazirMetni,
    required this.hazir,
    required this.toplam,
  });

  final String baslik;

  /// "hazır" kelimesi (sayıların arkasına eklenir).
  final String hazirMetni;
  final int hazir;
  final int toplam;

  bool get tamam => toplam > 0 && hazir == toplam;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    // Özetin yazısı da üst kısım gibi en fazla 2 kat büyür; malzemelere yer
    // kalsın.
    return yemekYaziSiniri(
      KilKart(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TarifBolumBasligi(ikon: Icons.soup_kitchen_rounded, baslik: baslik),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tamam ? r.vurgu : r.seciliCipZemin,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tamam) ...[
                        Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: r.vurguUstuYazi,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          '$hazir / $toplam $hazirMetni',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: tamam
                                    ? r.vurguUstuYazi
                                    : r.seciliCipYazi,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            YemekIlerlemeCubugu(
              deger: toplam > 0 ? hazir / toplam : 0,
              tamam: tamam,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dokunulunca işaretlenen malzeme satırı. İşaretliyken soluk zemin, üstü
/// çizili soluk yazı ve adaçayı onay dairesi. Büyük yazıda daire metnin
/// üstüne çıkar.
class YemekMalzemeSatiri extends StatelessWidget {
  const YemekMalzemeSatiri({
    super.key,
    required this.metin,
    required this.secili,
    required this.onTap,
  });

  final String metin;
  final bool secili;
  final VoidCallback onTap;

  static const double daireBoyutu = 32;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final sure = KilBasilir.sure(context);
    final golgeli = r.sertGolge && !secili;

    final daire = ExcludeSemantics(
      child: AnimatedContainer(
        duration: sure,
        curve: Curves.easeOut,
        width: daireBoyutu,
        height: daireBoyutu,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: secili ? r.vurgu : r.kart,
          border: Border.all(
            color: secili ? r.vurgu : r.tanitanKenar,
            width: 2.5,
          ),
        ),
        child: secili
            ? Icon(Icons.check_rounded, size: 22, color: r.vurguUstuYazi)
            : null,
      ),
    );
    final yazi = Text(
      metin,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: yemekMalzemeYaziBoyutu,
        height: 1.35,
        color: secili ? r.solukYazi : r.anaYazi,
        decoration: secili ? TextDecoration.lineThrough : null,
        decorationColor: r.solukYazi,
        decorationThickness: 2,
      ),
    );

    final icerik = tarifUstUsteMi(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [daire, const SizedBox(height: 8), yazi],
          )
        : Row(
            children: [
              daire,
              const SizedBox(width: 16),
              Expanded(child: yazi),
            ],
          );

    return MergeSemantics(
      child: Semantics(
        checked: secili,
        child: AnimatedContainer(
          duration: sure,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: secili ? r.solukYuzey : r.kart,
            borderRadius: BorderRadius.circular(KilKart.koseYaricapi),
            border: Border.all(color: r.kenar, width: KilKart.kenarKalinligi),
            boxShadow: golgeli
                ? [
                    BoxShadow(
                      color: r.kenar,
                      offset: const Offset(0, KilKart.golgeYuksekligi),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(
                KilKart.koseYaricapi - KilKart.kenarKalinligi,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: yemekMalzemeSatirYuksekligi,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: icerik,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Malzemelerin tamamı: özet kartı ve satırlar (ya da boş liste yazısı).
/// Malzemeler sayfasında ve alttan açılan malzeme penceresinde kullanılır.
class YemekMalzemeListesi extends StatelessWidget {
  const YemekMalzemeListesi({
    super.key,
    required this.malzemeler,
    required this.secililer,
    required this.onDegistir,
    required this.bosMetni,
    this.ozet,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.shrinkWrap = false,
  });

  final List<String> malzemeler;
  final Set<int> secililer;
  final ValueChanged<int> onDegistir;
  final String bosMetni;
  final Widget? ozet;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return ListView(
      padding: padding,
      shrinkWrap: shrinkWrap,
      children: [
        if (ozet != null) ...[ozet!, const SizedBox(height: 16)],
        if (malzemeler.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              bosMetni,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: r.solukYazi),
            ),
          ),
        for (var i = 0; i < malzemeler.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          YemekMalzemeSatiri(
            metin: malzemeler[i],
            secili: secililer.contains(i),
            onTap: () => onDegistir(i),
          ),
        ],
      ],
    );
  }
}

/// Bir adım sayfası: numara dairesi ve Caveat "Adım 2" başlığı, altında
/// büyük yazılı, kaydırılan adım kartı. Büyük yazıda daire gösterilmez ve
/// başlık kartın içine, metinle birlikte kayan kısma girer.
class YemekAdimSayfasi extends StatelessWidget {
  const YemekAdimSayfasi({
    super.key,
    required this.numara,
    required this.adimEtiketi,
    required this.metin,
  });

  final int numara;

  /// "Adım" kelimesi; numara arkasına eklenir.
  final String adimEtiketi;
  final String metin;

  static const double daireBoyutu = 52;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazilar = Theme.of(context).textTheme;
    final ustUste = tarifUstUsteMi(context);
    final baslik = yemekYaziSiniri(
      Semantics(
        header: true,
        // Caveat (headlineLarge, 34).
        child: Text(
          '$adimEtiketi $numara',
          style: yazilar.headlineLarge?.copyWith(color: r.baslik),
        ),
      ),
    );
    final adim = Text(
      metin,
      style: yazilar.bodyLarge?.copyWith(
        fontSize: yemekAdimYaziBoyutu,
        height: 1.5,
        color: r.anaYazi,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!ustUste) ...[
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: daireBoyutu,
                    height: daireBoyutu,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: r.seciliCipZemin,
                      shape: BoxShape.circle,
                    ),
                    // Caveat 30; daireye sığmazsa küçülür.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          '$numara',
                          style: yazilar.headlineMedium?.copyWith(
                            color: r.seciliCipYazi,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: baslik),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: Padding(
              // Kartın sert gölgesi kesilmesin.
              padding: const EdgeInsets.only(bottom: KilKart.golgeYuksekligi),
              child: KilKart(
                padding: EdgeInsets.zero,
                child: SizedBox.expand(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ustUste
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [baslik, const SizedBox(height: 8), adim],
                          )
                        : adim,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alttaki gezinme: "Önceki" (ilk sayfada yok) ve "Sonraki Adım" ya da son
/// sayfada adaçayı "Tamamla". Düğmeler 56 yüksekliğinde. Etiketler yan yana
/// bölünmeden sığmıyorsa (dar ekran, uzun dil, büyük yazı) düğmeler alt
/// alta dizilir, ileri düğmesi üstte.
class YemekModuAltCubuk extends StatelessWidget {
  const YemekModuAltCubuk({
    super.key,
    required this.oncekiEtiketi,
    required this.ileriEtiketi,
    required this.sonSayfa,
    required this.onOnceki,
    required this.onIleri,
  });

  final String oncekiEtiketi;

  /// Son sayfada "Tamamla", diğerlerinde "Sonraki Adım".
  final String ileriEtiketi;
  final bool sonSayfa;

  /// `null` ise "Önceki" gösterilmez (ilk sayfa).
  final VoidCallback? onOnceki;

  /// `null` ise ileri düğmesi pasif (bitiriliyor).
  final VoidCallback? onIleri;

  @override
  Widget build(BuildContext context) {
    final ios = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    final ileri = sonSayfa
        ? KilDugme.vurgu(
            etiket: ileriEtiketi,
            ikon: Icons.check_circle_rounded,
            onPressed: onIleri,
            tamGenislik: true,
            buyuk: true,
          )
        : KilDugme.birincil(
            etiket: ileriEtiketi,
            ikon: ios
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_forward_rounded,
            onPressed: onIleri,
            tamGenislik: true,
            buyuk: true,
          );
    if (onOnceki == null) return ileri;

    return LayoutBuilder(
      builder: (context, sinir) {
        final yanYana =
            !tarifUstUsteMi(context) &&
            _gerekenGenislik(context, oncekiEtiketi) +
                    _aralik +
                    _gerekenGenislik(context, ileriEtiketi) <=
                sinir.maxWidth;
        final onceki = KilDugme.ikincil(
          etiket: oncekiEtiketi,
          ikon: ios
              ? Icons.arrow_back_ios_new_rounded
              : Icons.arrow_back_rounded,
          onPressed: onOnceki,
          tamGenislik: !yanYana,
          buyuk: true,
        );
        if (!yanYana) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ileri, const SizedBox(height: 8), onceki],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            onceki,
            const SizedBox(width: _aralik),
            Expanded(child: ileri),
          ],
        );
      },
    );
  }

  static const double _aralik = 12;

  /// Büyük [KilDugme]'nin etiketi bölünmeden sığması için gereken genişlik:
  /// yazı, ikon (24 + 8), iç boşluk (22 + 22) ve kenar (2 + 2).
  static double _gerekenGenislik(BuildContext context, String etiket) {
    final boyaci = TextPainter(
      text: TextSpan(
        text: etiket,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 18),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final genislik = boyaci.width;
    boyaci.dispose();
    return genislik + 24 + 8 + 44 + 4 + 1;
  }
}

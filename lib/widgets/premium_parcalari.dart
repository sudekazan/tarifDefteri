import 'package:flutter/material.dart';

import 'kil/kil.dart';

// Premium (satın alma) ekranının kil parçaları. Metinleri ve fiyatları çağıran
// sayfa verir (fiyatlar RevenueCat'ten gelir); parçalar yalnızca görünümdür,
// böylece çeviri ve mağaza olmadan test edilebilir.

/// Yazı bu kattan büyükse parçalar yan yana yerine üst üste dizilir.
const double premiumUstUsteOlcegi = 1.6;

bool premiumUstUsteMi(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) / 10 > premiumUstUsteOlcegi;

/// Caveat başlık, rozet ve üst satır en fazla bu kadar büyür (Aşama 5–7'deki
/// gibi); yoksa 320 genişlikte 3.2 kat yazıda başlık ekranı kaplıyor.
const double premiumBaslikSiniri = 2.0;

Widget premiumBaslikSinirla(Widget child) => MediaQuery.withClampedTextScaling(
      maxScaleFactor: premiumBaslikSiniri,
      child: child,
    );

/// Üst satır: solda kapat düğmesi, sağda "Geri Yükle".
class PremiumUstSatiri extends StatelessWidget {
  const PremiumUstSatiri({
    super.key,
    required this.kapatEtiketi,
    required this.onKapat,
    required this.geriYukleEtiketi,
    required this.onGeriYukle,
  });

  final String kapatEtiketi;
  final VoidCallback onKapat;
  final String geriYukleEtiketi;

  /// Satın alma sürerken null (pasif).
  final VoidCallback? onGeriYukle;

  static const double _icPay =
      (KilYuvarlakDugme.dokunmaBoyutu - KilYuvarlakDugme.gorunenBoyut) / 2;

  @override
  Widget build(BuildContext context) {
    return premiumBaslikSinirla(
      Row(
        children: [
          Transform.translate(
            offset: const Offset(-_icPay, 0),
            child: KilYuvarlakDugme(
              ikon: Icons.close_rounded,
              etiket: kapatEtiketi,
              onPressed: onKapat,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: KilDugme.ikincil(
                etiket: geriYukleEtiketi,
                ikon: Icons.restore_rounded,
                onPressed: onGeriYukle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ekranın tepesi: "Pro" hapı, şef dairesi, Caveat başlık ve alt yazı.
class PremiumTanitim extends StatelessWidget {
  const PremiumTanitim({
    super.key,
    required this.rozet,
    required this.baslik,
    required this.altBaslik,
  });

  final String rozet;
  final String baslik;
  final String altBaslik;

  static const double sefBoyutu = 88;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final metin = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: premiumBaslikSinirla(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: r.seciliCipZemin,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 16,
                    color: r.seciliCipYazi,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      rozet,
                      style: metin.labelMedium?.copyWith(
                        color: r.seciliCipYazi,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ExcludeSemantics(
            child: Container(
              width: sefBoyutu,
              height: sefBoyutu,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: r.seciliCipZemin,
                border: Border.all(color: r.kenar, width: 2),
                boxShadow: r.sertGolge
                    ? [BoxShadow(color: r.kenar, offset: const Offset(0, 4))]
                    : null,
              ),
              alignment: Alignment.center,
              child: const Text(
                '🧑‍🍳',
                style: TextStyle(fontSize: 44),
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: premiumBaslikSinirla(
            Text(
              baslik,
              textAlign: TextAlign.center,
              // Caveat (headlineLarge, 34).
              style: metin.headlineLarge?.copyWith(color: r.baslik),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          altBaslik,
          textAlign: TextAlign.center,
          style: metin.bodyLarge?.copyWith(color: r.solukYazi, height: 1.4),
        ),
      ],
    );
  }
}

/// Özellik listesindeki bir satırın verisi.
class PremiumOzellik {
  const PremiumOzellik({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
  });

  final IconData ikon;
  final String baslik;
  final String aciklama;
}

/// Pro'nun özelliklerini sıralayan kil kartı. İkon kutuları klasör renkleri
/// arasında sırayla döner (tatlı, çorba, kahvaltı, favori).
class PremiumOzellikKarti extends StatelessWidget {
  const PremiumOzellikKarti({super.key, required this.ozellikler});

  final List<PremiumOzellik> ozellikler;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final renkler = [
      r.klasorTatli,
      r.klasorCorba,
      r.klasorKahvalti,
      r.klasorFavori,
    ];
    return KilKart(
      // Büyük yazıda uzun kelimeler bölünmesin diye kenar boşluğu daralır.
      padding: EdgeInsets.all(premiumUstUsteMi(context) ? 12 : 16),
      child: Column(
        children: [
          for (var i = 0; i < ozellikler.length; i++) ...[
            if (i > 0) Divider(height: 24, thickness: 1.5, color: r.kenar),
            PremiumOzellikSatiri(
              ozellik: ozellikler[i],
              renk: renkler[i % renkler.length],
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumOzellikSatiri extends StatelessWidget {
  const PremiumOzellikSatiri({
    super.key,
    required this.ozellik,
    required this.renk,
  });

  final PremiumOzellik ozellik;
  final KlasorRenk renk;

  static const double ikonKutusu = 44;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final metin = Theme.of(context).textTheme;

    final ikon = ExcludeSemantics(
      child: Container(
        width: ikonKutusu,
        height: ikonKutusu,
        decoration: BoxDecoration(
          color: renk.zemin,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(ozellik.ikon, color: renk.ikon, size: 22),
      ),
    );
    final onay = ExcludeSemantics(
      child: Icon(Icons.check_circle_rounded, color: r.vurgu, size: 22),
    );
    final yazilar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ozellik.baslik, style: metin.titleMedium),
        const SizedBox(height: 2),
        Text(
          ozellik.aciklama,
          style: metin.bodyMedium?.copyWith(color: r.solukYazi),
        ),
      ],
    );

    return MergeSemantics(
      child: premiumUstUsteMi(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [ikon, const Spacer(), onay]),
                const SizedBox(height: 8),
                yazilar,
              ],
            )
          : Row(
              children: [
                ikon,
                const SizedBox(width: 14),
                Expanded(child: yazilar),
                const SizedBox(width: 8),
                onay,
              ],
            ),
    );
  }
}

/// Bir satın alma planı kartı (aylık, yıllık, ömür boyu). Seçili kart
/// terrakota kenarlı ve açık turuncu zeminlidir; solda seçim dairesi.
class PremiumPlanKarti extends StatelessWidget {
  const PremiumPlanKarti({
    super.key,
    required this.baslik,
    required this.aciklama,
    required this.fiyat,
    required this.secili,
    required this.onTap,
    this.rozet,
    this.fiyatAltta = false,
  });

  final String baslik;
  final String aciklama;

  /// true ise fiyat yanda değil, açıklamanın altında durur (ör. uzun
  /// "Fiyat bilgisi yüklenemedi" metni). Büyük yazıda hep alttadır.
  final bool fiyatAltta;

  /// Mağazadan gelen fiyat metni; burada değiştirilmez.
  final String fiyat;
  final bool secili;

  /// Satın alma sürerken null (pasif).
  final VoidCallback? onTap;

  /// Ör. "EN AVANTAJLI"; yalnızca yıllık planda.
  final String? rozet;

  static const double enKucukYukseklik = 72;
  static const double daireBoyutu = 26;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final metin = Theme.of(context).textTheme;
    final zemin = secili ? r.seciliCipZemin : r.kart;
    final kenar = secili ? r.birincil : r.kenar;
    final golge = secili ? r.birincilGolge : r.kenar;
    const kose = BorderRadius.all(Radius.circular(KilKart.koseYaricapi));

    final daire = ExcludeSemantics(
      child: Container(
        width: daireBoyutu,
        height: daireBoyutu,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: secili ? r.birincil : r.kart,
          border: Border.all(
            color: secili ? r.birincil : r.tanitanKenar,
            width: 2,
          ),
        ),
        child: secili
            ? Icon(Icons.check_rounded, size: 18, color: r.birincilUstuYazi)
            : null,
      ),
    );

    final rozetHapi = rozet == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: r.vurgu,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rozet!,
              style: metin.labelSmall?.copyWith(
                color: r.vurguUstuYazi,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          );

    final ad = Text(baslik, style: metin.titleMedium);
    final aciklamaYazisi = aciklama.isEmpty
        ? null
        : Text(
            aciklama,
            style: metin.bodyMedium?.copyWith(color: r.solukYazi),
          );
    final ustUste = premiumUstUsteMi(context);
    final fiyatYazisi = Text(
      fiyat,
      textAlign: ustUste || fiyatAltta ? TextAlign.start : TextAlign.end,
      style: metin.titleLarge?.copyWith(
        color: r.baslik,
        fontWeight: FontWeight.w700,
      ),
    );

    final Widget icerik;
    if (ustUste) {
      icerik = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              daire,
              const SizedBox(width: 12),
              if (rozetHapi != null) Flexible(child: rozetHapi),
            ],
          ),
          const SizedBox(height: 8),
          ad,
          if (aciklamaYazisi != null) ...[
            const SizedBox(height: 2),
            aciklamaYazisi,
          ],
          const SizedBox(height: 6),
          fiyatYazisi,
        ],
      );
    } else {
      icerik = Row(
        children: [
          daire,
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [ad, ?rozetHapi],
                ),
                if (aciklamaYazisi != null) ...[
                  const SizedBox(height: 3),
                  aciklamaYazisi,
                ],
                if (fiyatAltta) ...[
                  const SizedBox(height: 6),
                  fiyatYazisi,
                ],
              ],
            ),
          ),
          if (!fiyatAltta) ...[
            const SizedBox(width: 10),
            // Fiyat mağazadan gelir; uzunsa satıra sığsın diye alt satıra
            // geçebilir.
            Flexible(flex: 2, child: fiyatYazisi),
          ],
        ],
      );
    }

    final etiket = [
      baslik,
      ?rozet,
      if (aciklama.isNotEmpty) aciklama,
      fiyat,
    ].join(', ');

    return Semantics(
      button: true,
      selected: secili,
      inMutuallyExclusiveGroup: true,
      enabled: onTap != null,
      label: etiket,
      excludeSemantics: true,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: zemin,
          borderRadius: kose,
          border: Border.all(color: kenar, width: KilKart.kenarKalinligi),
          boxShadow: r.sertGolge
              ? [
                  BoxShadow(
                    color: golge,
                    offset: const Offset(0, KilKart.golgeYuksekligi),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: kose,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: enKucukYukseklik),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: icerik,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paketler yüklenemediğinde çıkan, dokununca ayrıntıyı açan hata satırı.
class PremiumHataSatiri extends StatelessWidget {
  const PremiumHataSatiri({super.key, required this.metin, required this.onTap});

  final String metin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: r.hataZeminYazi, fontWeight: FontWeight.w600);
    const kose = BorderRadius.all(Radius.circular(14));

    return Semantics(
      button: true,
      child: Material(
        color: r.hataZemin,
        borderRadius: kose,
        child: InkWell(
          onTap: onTap,
          borderRadius: kose,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: r.hataZeminYazi,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metin,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: yazi,
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: r.hataZeminYazi,
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

/// Bir yasal bağlantı (kullanım koşulları, gizlilik, geri yükleme).
class PremiumBaglanti {
  const PremiumBaglanti({required this.etiket, required this.onTap});

  final String etiket;

  /// Satın alma sürerken null olabilir.
  final VoidCallback? onTap;
}

/// Abonelik koşulları (Apple kural 3.1.2) ve yasal bağlantılar. Soluk
/// yüzeyli, gölgesiz kart; bağlantılar 48'lik dokunma alanlı.
class PremiumKosullarKarti extends StatelessWidget {
  const PremiumKosullarKarti({
    super.key,
    required this.baslik,
    required this.metin,
    required this.baglantilar,
  });

  final String baslik;
  final String metin;
  final List<PremiumBaglanti> baglantilar;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: r.solukYuzey,
        borderRadius: BorderRadius.circular(KilKart.koseYaricapi),
        border: Border.all(color: r.kenar, width: KilKart.kenarKalinligi),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            baslik,
            textAlign: TextAlign.center,
            style: yazi.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            metin,
            style: yazi.bodySmall?.copyWith(color: r.solukYazi, height: 1.5),
          ),
          Divider(height: 24, thickness: 1.5, color: r.kenar),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < baglantilar.length; i++) ...[
                if (i > 0)
                  ExcludeSemantics(
                    child: Text(
                      '•',
                      style: yazi.bodySmall?.copyWith(color: r.solukYazi),
                    ),
                  ),
                _BaglantiDugmesi(baglanti: baglantilar[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BaglantiDugmesi extends StatelessWidget {
  const _BaglantiDugmesi({required this.baglanti});

  final PremiumBaglanti baglanti;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final etkin = baglanti.onTap != null;
    final renk = etkin ? r.baslik : r.solukYazi;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: baglanti.onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              widthFactor: 1,
              child: Text(
                baglanti.etiket,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: renk,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: renk,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Satın alma ya da geri yükleme sürerken sayfayı kapatan katman.
class PremiumBeklemeKatmani extends StatelessWidget {
  const PremiumBeklemeKatmani({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final scrim = Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5);
    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(dismissible: false, color: scrim),
        Center(
          child: Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: r.kart,
              shape: BoxShape.circle,
              border: Border.all(color: r.kenar, width: 2),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(r.birincil),
            ),
          ),
        ),
      ],
    );
  }
}

/// Profil/Ayarlar'daki "Premium'a Geç" kartı: kiremit öne çıkan kil kartı.
/// Pro kullanıcıda [aktif] true olur; kart sade kil kartına döner ve
/// dokunulmaz.
class ProyaGecKarti extends StatelessWidget {
  const ProyaGecKarti({
    super.key,
    required this.baslik,
    required this.aciklama,
    this.onTap,
    this.aktif = false,
  });

  final String baslik;
  final String aciklama;
  final VoidCallback? onTap;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final metin = Theme.of(context).textTheme;
    final oneCikan = !aktif;
    final yaziRengi = oneCikan ? r.oneCikanKartYazi : r.anaYazi;
    final solukRenk = oneCikan ? r.oneCikanKartYazi : r.solukYazi;
    final ustUste = premiumUstUsteMi(context);

    final ikon = ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: aktif ? r.klasorCorba.zemin : r.seciliCipZemin,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          aktif ? Icons.verified_rounded : Icons.workspace_premium_rounded,
          color: aktif ? r.klasorCorba.ikon : r.seciliCipYazi,
          size: 24,
        ),
      ),
    );
    final yazilar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: metin.titleMedium?.copyWith(color: yaziRengi)),
        const SizedBox(height: 2),
        Text(aciklama, style: metin.bodyMedium?.copyWith(color: solukRenk)),
      ],
    );
    final ok = onTap == null
        ? null
        : ExcludeSemantics(
            child: Icon(Icons.chevron_right_rounded, color: yaziRengi),
          );

    return KilKart(
      oneCikan: oneCikan,
      onTap: onTap,
      anlamEtiketi: onTap == null ? null : '$baslik, $aciklama',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: ustUste
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [ikon, const Spacer(), ?ok]),
                  const SizedBox(height: 8),
                  onTap == null ? yazilar : ExcludeSemantics(child: yazilar),
                ],
              )
            : Row(
                children: [
                  ikon,
                  const SizedBox(width: 14),
                  Expanded(
                    child: onTap == null
                        ? yazilar
                        : ExcludeSemantics(child: yazilar),
                  ),
                  if (ok != null) ...[const SizedBox(width: 8), ok],
                ],
              ),
      ),
    );
  }
}

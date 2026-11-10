import 'package:flutter/material.dart';

import 'kil/kil.dart';

/// Giriş ekranındaki Caveat başlık en fazla bu kadar büyür (diğer
/// ekranlardaki gibi); daha büyükte form ekrana sığmıyor.
const double girisBaslikSiniri = 2;

/// Giriş ekranının üstü: uygulama ikonu dairesi, Caveat uygulama adı ve
/// soluk alt yazı.
class GirisTanitim extends StatelessWidget {
  const GirisTanitim({super.key, required this.baslik, required this.altYazi});

  final String baslik;
  final String altYazi;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;

    return Column(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: r.seciliCipZemin,
              shape: BoxShape.circle,
              border: Border.all(color: r.kenar, width: KilKart.kenarKalinligi),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 40,
              color: r.seciliCipYazi,
            ),
          ),
        ),
        const SizedBox(height: 12),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: girisBaslikSiniri,
          child: Semantics(
            header: true,
            child: Text(
              baslik,
              textAlign: TextAlign.center,
              style: yazi.headlineLarge?.copyWith(color: r.baslik),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          altYazi,
          textAlign: TextAlign.center,
          style: yazi.bodyLarge?.copyWith(color: r.solukYazi),
        ),
      ],
    );
  }
}

/// "Giriş Yap / Kayıt Ol" seçici. Seçili parça terrakota zemin, beyaz yazı;
/// diğeri soluk yüzeyin üstünde soluk yazı. Her parça en az 48 yüksekliğinde;
/// etiketler yan yana sığmazsa alt satıra kayar.
class GirisSekmeSecici extends StatelessWidget {
  const GirisSekmeSecici({
    super.key,
    required this.girisSecili,
    required this.girisEtiketi,
    required this.kayitEtiketi,
    required this.onDegisti,
  });

  final bool girisSecili;
  final String girisEtiketi;
  final String kayitEtiketi;

  /// `true`: giriş, `false`: kayıt seçildi.
  final ValueChanged<bool> onDegisti;

  static const double enKucukYukseklik = 48;

  /// Yazı bu kattan büyükse parçalar alt alta dizilir.
  static const double altAltaOlcegi = 1.6;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final giris = _Parca(
      etiket: girisEtiketi,
      secili: girisSecili,
      onTap: () => onDegisti(true),
    );
    final kayit = _Parca(
      etiket: kayitEtiketi,
      secili: !girisSecili,
      onTap: () => onDegisti(false),
    );
    // Büyük yazıda yan yana sığmıyor, kelimeler bölünüyor: alt alta dizilir.
    final altAlta =
        MediaQuery.textScalerOf(context).scale(10) / 10 > altAltaOlcegi;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: r.solukYuzey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: r.kenar, width: 1.5),
      ),
      child: altAlta
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [giris, const SizedBox(height: 4), kayit],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: giris),
                  const SizedBox(width: 4),
                  Expanded(child: kayit),
                ],
              ),
            ),
    );
  }
}

class _Parca extends StatelessWidget {
  const _Parca({
    required this.etiket,
    required this.secili,
    required this.onTap,
  });

  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final stil = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: secili ? r.birincilUstuYazi : r.solukYazi,
    );
    final sure = KilBasilir.sure(context);

    return Semantics(
      button: true,
      selected: secili,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: secili ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: sure,
            constraints: const BoxConstraints(
              minHeight: GirisSekmeSecici.enKucukYukseklik,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: secili ? r.birincil : r.solukYuzey,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(etiket, textAlign: TextAlign.center, style: stil),
          ),
        ),
      ),
    );
  }
}

/// Formdaki hata mesajı: hata kutusu renkleri, ikon ve metin. Ekran okuyucu
/// mesaj çıkınca okur.
class GirisHataKutusu extends StatelessWidget {
  const GirisHataKutusu({super.key, required this.mesaj});

  final String mesaj;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: r.hataZemin,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.error_outline_rounded,
                color: r.hataZeminYazi,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mesaj,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: r.hataZeminYazi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "veya" ayracı: iki yanda süs çizgisi, ortada soluk yazı.
class GirisAyirici extends StatelessWidget {
  const GirisAyirici({super.key, required this.metin});

  final String metin;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return Row(
      children: [
        Expanded(child: Divider(color: r.kenar, thickness: 1.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            metin,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: r.solukYazi),
          ),
        ),
        Expanded(child: Divider(color: r.kenar, thickness: 1.5)),
      ],
    );
  }
}

/// İşlem sürerken ana düğmenin yerine çıkan gösterge (düğmeyle aynı yükseklik).
class GirisBekleme extends StatelessWidget {
  const GirisBekleme({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: KilDugme.buyukYukseklik + KilDugme.golgeYuksekligi,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: context.kil.birincil,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

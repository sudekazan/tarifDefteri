import 'package:flutter/material.dart';

import 'kil/kil.dart';

// Alışveriş listesi sekmesinin kil parçaları. Metinleri çağıran sayfa çevirip
// verir; böylece parçalar çeviri olmadan da test edilebilir.

/// Yazı bu ölçeğin üstündeyse bölüm başlığının yanındaki düğme alta iner.
const double alisverisUstUsteOlcegi = 1.6;

bool alisverisUstUsteMi(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) / 10 > alisverisUstUsteOlcegi;

/// Caveat başlıklar en fazla bu kadar büyür (Aşama 5–6'daki sınır gibi);
/// yoksa 320 genişlikte 3.2 kat yazıda tek kelimeler bile satıra sığmıyor.
const double alisverisBaslikSiniri = 2.0;

Widget _baslikSinirla(Widget child) => MediaQuery.withClampedTextScaling(
  maxScaleFactor: alisverisBaslikSiniri,
  child: child,
);

/// Sekmenin Caveat ekran başlığı (34). Sekmede geri düğmesi yok.
class AlisverisBasligi extends StatelessWidget {
  const AlisverisBasligi({super.key, required this.baslik});

  final String baslik;

  @override
  Widget build(BuildContext context) {
    return _baslikSinirla(
      Semantics(
        header: true,
        child: Text(
          baslik,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: context.kil.baslik),
        ),
      ),
    );
  }
}

/// Bir malzeme satırı: onay kutusu, ad ve sil düğmesi.
///
/// Onay kutusuna ya da ada dokununca durum değişir; ekran okuyucu ikisini tek
/// öğe olarak ("Süt, işaretli") okur. Alınan malzemenin adı soluk ve üstü
/// çizili.
class AlisverisMaddeSatiri extends StatelessWidget {
  const AlisverisMaddeSatiri({
    super.key,
    required this.madde,
    required this.alindi,
    required this.silEtiketi,
    required this.onDegistir,
    required this.onSil,
  });

  final String madde;
  final bool alindi;
  final String silEtiketi;
  final VoidCallback onDegistir;
  final VoidCallback onSil;

  static const double enKucukYukseklik = 56;
  static const double dokunmaBoyutu = 48;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final stil = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: alindi ? r.solukYazi : r.anaYazi,
      decoration: alindi ? TextDecoration.lineThrough : null,
      decorationColor: r.solukYazi,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: enKucukYukseklik),
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(
              child: InkWell(
                onTap: onDegistir,
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: enKucukYukseklik,
                  ),
                  child: Row(
                    children: [
                      KilOnayKutusu(
                        deger: alindi,
                        onChanged: (_) => onDegistir(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(madde, style: stil),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox.square(
            dimension: dokunmaBoyutu,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: '$silEtiketi: $madde',
              onPressed: onSil,
              icon: Icon(Icons.close_rounded, color: r.solukYazi, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Alınacaklar" ya da "Alınanlar" bölümü: Caveat başlık (26), isteğe bağlı
/// başlık düğmesi ve malzemelerin durduğu kart.
///
/// Alınanlar ([alindi]) soluk yüzeyli, gölgesiz kartta durur; böylece
/// alınacaklar öne çıkar.
class AlisverisBolumu extends StatelessWidget {
  const AlisverisBolumu({
    super.key,
    required this.baslik,
    required this.satirlar,
    this.alindi = false,
    this.eylem,
  });

  final String baslik;
  final List<Widget> satirlar;
  final bool alindi;

  /// Başlığın yanındaki düğme (ör. "Temizle"). Büyük yazıda başlığın altına
  /// iner.
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final baslikYazisi = _baslikSinirla(
      Semantics(
        header: true,
        child: Text(
          baslik,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: alindi ? r.solukYazi : r.baslik,
          ),
        ),
      ),
    );

    final Widget ust;
    final e = eylem;
    if (e == null) {
      ust = baslikYazisi;
    } else if (alisverisUstUsteMi(context)) {
      ust = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [baslikYazisi, const SizedBox(height: 6), e],
      );
    } else {
      ust = Row(
        children: [
          Expanded(child: baslikYazisi),
          const SizedBox(width: 8),
          e,
        ],
      );
    }

    final liste = Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (var i = 0; i < satirlar.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: r.kenar),
            satirlar[i],
          ],
        ],
      ),
    );
    const ic = EdgeInsets.fromLTRB(4, 4, 4, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ust,
        const SizedBox(height: 8),
        if (alindi)
          Container(
            decoration: BoxDecoration(
              color: r.solukYuzey,
              borderRadius: BorderRadius.circular(KilKart.koseYaricapi),
              border: Border.all(color: r.kenar, width: KilKart.kenarKalinligi),
            ),
            padding: ic,
            child: liste,
          )
        else
          KilKart(padding: ic, child: liste),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'kil/kil.dart';
import 'tarif_listesi_parcalari.dart' show TarifKucukGorsel;

// Tarif arama ekranının kil parçaları. Metinleri çağıran sayfa çevirip verir;
// böylece parçalar çeviri olmadan da test edilebilir.

/// Yazı bu ölçeğin üstündeyse sonuç satırında görsel adın üstüne çıkar.
const double aramaUstUsteOlcegi = 1.6;

/// Üst kısım: yuvarlak geri düğmesi ve yanında arama kutusu. Kutuda yazı
/// varken sağında temizle düğmesi çıkar.
class AramaUstSatiri extends StatelessWidget {
  const AramaUstSatiri({
    super.key,
    required this.controller,
    required this.ipucu,
    required this.onDegisti,
    required this.onTemizle,
    this.onGeri,
  });

  final TextEditingController controller;
  final String ipucu;
  final ValueChanged<String> onDegisti;
  final VoidCallback onTemizle;

  /// Verilmezse sayfa kapanır (`Navigator.maybePop`).
  final VoidCallback? onGeri;

  /// Geri düğmesinin dairesi kenarla aynı hizaya gelsin diye
  /// ([KilSayfaBasligi] gibi).
  static const double _icPay =
      (KilYuvarlakDugme.dokunmaBoyutu - KilYuvarlakDugme.gorunenBoyut) / 2;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yerel = MaterialLocalizations.of(context);
    final ios = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

    return Row(
      children: [
        Transform.translate(
          offset: const Offset(-_icPay, 0),
          child: KilYuvarlakDugme(
            ikon: ios
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_back_rounded,
            etiket: yerel.backButtonTooltip,
            onPressed: onGeri ?? () => Navigator.maybePop(context),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, deger, _) => TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: onDegisti,
              decoration: InputDecoration(
                hintText: ipucu,
                prefixIcon: Icon(Icons.search_rounded, color: r.solukYazi),
                suffixIcon: deger.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: yerel.deleteButtonTooltip,
                        icon: Icon(Icons.close_rounded, color: r.solukYazi),
                        onPressed: onTemizle,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bir arama sonucu: görsel, tarif adı ve ok. Dokununca tarif açılır.
class AramaSonucSatiri extends StatelessWidget {
  const AramaSonucSatiri({
    super.key,
    required this.ad,
    this.resimYolu,
    required this.onTap,
  });

  final String ad;
  final String? resimYolu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final olcek = MediaQuery.textScalerOf(context).scale(10) / 10;
    final buyukYazi = olcek > aramaUstUsteOlcegi;

    final adYazisi = Text(
      ad,
      style: Theme.of(context).textTheme.titleMedium,
      maxLines: buyukYazi ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );
    final ok = ExcludeSemantics(
      child: Icon(Icons.chevron_right_rounded, color: r.solukYazi),
    );

    return KilKart(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: buyukYazi
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      TarifKucukGorsel(yol: resimYolu),
                      const Spacer(),
                      ok,
                    ],
                  ),
                  const SizedBox(height: 10),
                  adYazisi,
                ],
              )
            : Row(
                children: [
                  TarifKucukGorsel(yol: resimYolu),
                  const SizedBox(width: 14),
                  Expanded(child: adYazisi),
                  const SizedBox(width: 4),
                  ok,
                ],
              ),
      ),
    );
  }
}

/// Henüz yazı yokken ya da sonuç çıkmayınca gösterilen kart. Metin bir
/// cümle olduğu için başlık değil gövde yazısıyla çizilir.
class AramaBilgiKarti extends StatelessWidget {
  const AramaBilgiKarti({
    super.key,
    required this.metin,
    this.sonucYok = false,
  });

  final String metin;
  final bool sonucYok;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final renk = sonucYok ? r.klasorKahvalti : r.klasorTatli;
    return KilKart(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: renk.zemin,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                sonucYok
                    ? Icons.search_off_rounded
                    : Icons.manage_search_rounded,
                size: 34,
                color: renk.ikon,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            metin,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: r.anaYazi),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';
import 'kil_dugme.dart';
import 'kil_kart.dart';

/// [KilDiyalog]'un ikon dairesinin rengi.
enum KilDiyalogTuru {
  /// Seçili çip renkleri (açık turuncu zemin, terrakota ikon).
  normal,

  /// Hata kutusu renkleri; geri alınamayan işlemler (sil, çıkış yap).
  tehlike,
}

/// Uygulamanın ortak diyaloğu: kil kartı gibi kenarlı yüzey, isteğe bağlı ikon
/// dairesi, Quicksand başlık, mesaj ya da özel içerik ve alt alta tam
/// genişlik düğmeler.
///
/// Düğmeler alt alta durduğu için büyük yazıda ve dar ekranda bölünmez;
/// içerik sığmazsa diyalog kaydırılır. Hazır kalıplar: [onayIste],
/// [bilgiGoster], [beklemeGoster].
///
/// Uygulamadaki diyaloglar eskiden de iOS'ta Material'dı; bu davranış
/// korunur. Yalnızca güncelleme uyarısı iOS'ta Cupertino'dur
/// (`lib/screens/update_screen.dart`).
class KilDiyalog extends StatelessWidget {
  const KilDiyalog({
    super.key,
    required this.baslik,
    this.mesaj,
    this.icerik,
    this.ikon,
    this.tur = KilDiyalogTuru.normal,
    this.eylemler = const [],
  });

  final String baslik;
  final String? mesaj;

  /// Mesajın altına konan özel içerik (ör. metin kutusu).
  final Widget? icerik;

  /// Verilirse başlığın üstünde renkli daire içinde gösterilir ve başlık ile
  /// mesaj ortalanır.
  final IconData? ikon;
  final KilDiyalogTuru tur;

  /// Alt alta dizilen düğmeler; ilki ana eylem. Genelde [KilDugme] ve en
  /// altta [KilDiyalogMetinDugmesi] (Vazgeç).
  final List<Widget> eylemler;

  static const double koseYaricapi = 24;

  /// Başlık yazısının en fazla büyüme katı.
  static const double baslikSiniri = 2;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;
    final ortali = ikon != null;
    final hizala = ortali ? TextAlign.center : TextAlign.start;
    final tehlike = tur == KilDiyalogTuru.tehlike;

    return Dialog(
      backgroundColor: r.kart,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(koseYaricapi),
        side: BorderSide(color: r.kenar, width: KilKart.kenarKalinligi),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ikon != null) ...[
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: tehlike ? r.hataZemin : r.seciliCipZemin,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ikon,
                      size: 34,
                      color: tehlike ? r.hataZeminYazi : r.seciliCipYazi,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Başlık en fazla 2 kat büyür (diğer ekranlardaki başlıklar gibi);
            // yoksa 320 genişlikte 3.2 katta kelimeler ortadan bölünüyor.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: baslikSiniri,
              child: Semantics(
                header: true,
                child: Text(
                  baslik,
                  textAlign: hizala,
                  style: yazi.titleLarge?.copyWith(color: r.anaYazi),
                ),
              ),
            ),
            if (mesaj != null) ...[
              const SizedBox(height: 10),
              Text(
                mesaj!,
                textAlign: hizala,
                style: yazi.bodyLarge?.copyWith(
                  color: r.solukYazi,
                  height: 1.45,
                ),
              ),
            ],
            if (icerik != null) ...[
              const SizedBox(height: 16),
              icerik!,
            ],
            if (eylemler.isNotEmpty) ...[
              const SizedBox(height: 24),
              for (var i = 0; i < eylemler.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                eylemler[i],
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Onay ister. Ana düğmeye basılırsa `true`, vazgeçilirse `false`, dışına
  /// basıp kapatılırsa `null` döner. [tehlikeli] ise ana düğme hata rengidir.
  static Future<bool?> onayIste(
    BuildContext context, {
    required String baslik,
    String? mesaj,
    Widget? icerik,
    required String onayEtiketi,
    required String vazgecEtiketi,
    IconData? ikon,
    bool tehlikeli = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => KilDiyalog(
        baslik: baslik,
        mesaj: mesaj,
        icerik: icerik,
        ikon: ikon,
        tur: tehlikeli ? KilDiyalogTuru.tehlike : KilDiyalogTuru.normal,
        eylemler: [
          if (tehlikeli)
            KilDugme.hata(
              etiket: onayEtiketi,
              tamGenislik: true,
              onPressed: () => Navigator.pop(ctx, true),
            )
          else
            KilDugme.birincil(
              etiket: onayEtiketi,
              tamGenislik: true,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          KilDiyalogMetinDugmesi(
            etiket: vazgecEtiketi,
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );
  }

  /// Tek düğmeli bilgi ya da hata diyaloğu.
  static Future<void> bilgiGoster(
    BuildContext context, {
    required String baslik,
    String? mesaj,
    required String tamamEtiketi,
    IconData? ikon,
    KilDiyalogTuru tur = KilDiyalogTuru.normal,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => KilDiyalog(
        baslik: baslik,
        mesaj: mesaj,
        ikon: ikon,
        tur: tur,
        eylemler: [
          KilDugme.birincil(
            etiket: tamamEtiketi,
            tamGenislik: true,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  /// İşlem sürerken ekranı kapatan bekleme göstergesi. Dışına basılarak
  /// kapanmaz; işlem bitince çağıran `Navigator.pop` ile kapatır.
  static Future<void> beklemeGoster(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const KilBeklemeKutusu(),
    );
  }
}

/// Diyalogun en altındaki sade metin düğmesi (Vazgeç, Daha sonra). En az 48
/// yükseklik, soluk yazı.
class KilDiyalogMetinDugmesi extends StatelessWidget {
  const KilDiyalogMetinDugmesi({
    super.key,
    required this.etiket,
    required this.onPressed,
  });

  final String etiket;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.kil.solukYazi,
        minimumSize: const Size(double.infinity, 48),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: Text(etiket, textAlign: TextAlign.center),
    );
  }
}

/// Ortada kil kartı içinde dönen gösterge. [KilDiyalog.beklemeGoster] açar.
class KilBeklemeKutusu extends StatelessWidget {
  const KilBeklemeKutusu({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: r.kart,
          borderRadius: BorderRadius.circular(KilDiyalog.koseYaricapi),
          border: Border.all(color: r.kenar, width: KilKart.kenarKalinligi),
        ),
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: r.birincil),
      ),
    );
  }
}

/// Fotoğrafı büyük gösteren diyalog: kil kartı çerçevesi, dokununca kapanır.
/// Eskiden siyah zeminliydi.
class KilBuyukFoto extends StatelessWidget {
  const KilBuyukFoto({super.key, required this.child});

  /// Genelde `Image.file` ya da `Image.network` (`BoxFit.contain`).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return Dialog(
      backgroundColor: r.kart,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KilKart.koseYaricapi),
        side: BorderSide(color: r.kenar, width: KilKart.kenarKalinligi),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(KilKart.koseYaricapi - 8),
            child: child,
          ),
        ),
      ),
    );
  }
}

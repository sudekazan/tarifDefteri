import 'package:flutter/material.dart';

import 'ai_chef_loading_animation.dart';
import 'kil/kil.dart';

// "Bugün ne pişirsem" sekmesinin kil parçaları. Metinleri çağıran sayfa
// çevirip verir; böylece parçalar çeviri olmadan da test edilebilir.

/// Yazı bu ölçeğin üstündeyse yan yana öğeler üst üste dizilir; yoksa metin
/// sıkışır ve kelimeler ortasından bölünür.
const double nePisirsemUstUsteOlcegi = 1.6;

bool nePisirsemUstUsteMi(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) / 10 > nePisirsemUstUsteOlcegi;

/// Caveat başlıklar ve bekleme kartı en fazla bu kadar büyür (yemek yapma
/// modundaki `yemekCubukYaziSiniri` gibi). Yoksa 320 genişlikte 3.2 kat
/// yazıda "Pişirsem?" gibi tek kelimeler bile satıra sığmıyor, ortasından
/// bölünüyordu.
const double nePisirsemBaslikSiniri = 2.0;

Widget nePisirsemBaslikSinirla(Widget child) =>
    MediaQuery.withClampedTextScaling(
      maxScaleFactor: nePisirsemBaslikSiniri,
      child: child,
    );

/// Sayfanın üst kısmı. Sekmedeyken yalnızca Caveat başlık ve "Pro" rozeti;
/// üstüne açıldıysa (geri gidilebiliyorsa) [KilSayfaBasligi] gibi geri
/// düğmesi de vardır.
class NePisirsemBasligi extends StatelessWidget {
  const NePisirsemBasligi({
    super.key,
    required this.baslik,
    required this.geriVar,
    this.proRozeti,
  });

  final String baslik;
  final bool geriVar;

  /// Başlığın yanındaki rozet (Pro kullanıcıda verilmez).
  final Widget? proRozeti;

  @override
  Widget build(BuildContext context) {
    if (geriVar) {
      return nePisirsemBaslikSinirla(
        KilSayfaBasligi(
          baslik: baslik,
          eylemler: [if (proRozeti != null) proRozeti!],
        ),
      );
    }
    final r = context.kil;
    final ustUste = nePisirsemUstUsteMi(context);
    final yazi = nePisirsemBaslikSinirla(
      Semantics(
        header: true,
        // Caveat (headlineLarge, 34). Büyük yazıda kesilmez, alt satıra geçer.
        child: Text(
          baslik,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: r.baslik),
        ),
      ),
    );
    if (proRozeti == null) return yazi;
    // Büyük yazıda rozet başlığın altına iner; yanında başlığa yer kalmıyordu.
    if (ustUste) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [yazi, proRozeti!],
      );
    }
    return Row(
      children: [
        Flexible(child: yazi),
        const SizedBox(width: 8),
        proRozeti!,
      ],
    );
  }
}

/// Üstteki tanıtım kartı: kiremit zeminli öne çıkan kil kartı, rozet ve
/// açıklama. Dokunulmaz.
class NePisirsemTanitimKarti extends StatelessWidget {
  const NePisirsemTanitimKarti({
    super.key,
    required this.rozet,
    required this.aciklama,
  });

  final String rozet;
  final String aciklama;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;
    final yazi = r.oneCikanKartYazi;

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
        const SizedBox(height: 10),
        Text(aciklama, style: yaziTemasi.bodyLarge?.copyWith(color: yazi)),
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
          '🧑‍🍳',
          style: TextStyle(fontSize: 30),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );

    return KilKart(
      oneCikan: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      child: nePisirsemUstUsteMi(context)
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

/// Kalan günlük şef hakkı. Ücretsiz kullanıcıda yanında "Daha fazla hak"
/// düğmesi (Premium'u açar) vardır.
class NePisirsemHakKarti extends StatelessWidget {
  const NePisirsemHakKarti({
    super.key,
    required this.metin,
    required this.pro,
    this.eylemEtiketi,
    this.onEylem,
  });

  final String metin;
  final bool pro;
  final String? eylemEtiketi;
  final VoidCallback? onEylem;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;
    final ustUste = nePisirsemUstUsteMi(context);

    final ikon = ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: r.seciliCipZemin,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          pro ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
          size: 22,
          color: r.seciliCipYazi,
        ),
      ),
    );
    final yazi = Text(
      metin,
      style: yaziTemasi.titleSmall?.copyWith(color: r.anaYazi),
    );
    final eylem = eylemEtiketi == null
        ? null
        : TextButton(
            onPressed: onEylem,
            style: TextButton.styleFrom(
              foregroundColor: r.baslik,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: yaziTemasi.labelLarge,
            ),
            child: Text(eylemEtiketi!, textAlign: TextAlign.center),
          );

    return KilKart(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: ustUste
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ikon,
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.only(right: 6), child: yazi),
                if (eylem != null)
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: eylem,
                  ),
              ],
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  ikon,
                  const SizedBox(width: 12),
                  Expanded(child: yazi),
                  if (eylem != null) ...[
                    const SizedBox(width: 4),
                    Flexible(child: eylem),
                  ],
                ],
              ),
            ),
    );
  }
}

/// Bölüm başlığı (Caveat 26) ve sağda isteğe bağlı bir düğme.
class NePisirsemBolumBasligi extends StatelessWidget {
  const NePisirsemBolumBasligi({super.key, required this.metin, this.eylem});

  final String metin;
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final baslik = nePisirsemBaslikSinirla(
      Semantics(
        header: true,
        // Caveat (headlineSmall, 26): yalnızca 22 pt ve üstü.
        child: Text(
          metin,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: r.baslik),
        ),
      ),
    );
    if (eylem == null) return baslik;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [baslik, eylem!],
    );
  }
}

/// Seçilen bir malzeme. Dokununca listeden çıkar; sağdaki çarpı bunu anlatır.
/// Görünen yükseklik 40, dokunma alanı 48.
class SeciliMalzemeCipi extends StatelessWidget {
  const SeciliMalzemeCipi({
    super.key,
    required this.malzeme,
    required this.kaldirIpucu,
    required this.onKaldir,
  });

  final String malzeme;

  /// Ekran okuyucunun eylem ipucu (ör. "Sil").
  final String kaldirIpucu;
  final VoidCallback onKaldir;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: r.seciliCipYazi);
    final sure = KilBasilir.sure(context);

    return Semantics(
      button: true,
      label: malzeme,
      hint: kaldirIpucu,
      excludeSemantics: true,
      onTap: onKaldir,
      child: KilBasilir(
        onTap: onKaldir,
        builder: (context, basili, odakli) => Padding(
          padding: const EdgeInsets.symmetric(
            vertical: (KilCip.dokunmaYuksekligi - KilCip.gorunenYukseklik) / 2,
          ),
          child: AnimatedContainer(
            duration: sure,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, basili ? 2 : 0, 0),
            constraints: const BoxConstraints(
              minHeight: KilCip.gorunenYukseklik,
              minWidth: KilCip.dokunmaYuksekligi,
            ),
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            decoration: BoxDecoration(
              color: r.seciliCipZemin,
              borderRadius: BorderRadius.circular(KilCip.gorunenYukseklik),
              border: Border.all(
                color: odakli ? r.anaYazi : r.seciliCipZemin,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(malzeme, style: yazi)),
                const SizedBox(width: 6),
                Icon(Icons.close_rounded, size: 18, color: r.seciliCipYazi),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seçilen malzemelerin kutusu. Boşken yönlendiren bir metin gösterir.
class SeciliMalzemelerKutusu extends StatelessWidget {
  const SeciliMalzemelerKutusu({
    super.key,
    required this.cipler,
    required this.bosMetin,
  });

  final List<Widget> cipler;
  final String bosMetin;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return SizedBox(
      width: double.infinity,
      child: KilKart(
        padding: const EdgeInsets.all(12),
        child: cipler.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  bosMetin,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: r.solukYazi),
                ),
              )
            : Wrap(spacing: 8, children: cipler),
      ),
    );
  }
}

/// Elle malzeme yazma kutusu ve "Ekle" düğmesi. Büyük yazıda düğme alta iner.
class MalzemeEklemeSatiri extends StatelessWidget {
  const MalzemeEklemeSatiri({
    super.key,
    required this.controller,
    required this.ipucu,
    required this.ekleEtiketi,
    required this.onEkle,
  });

  final TextEditingController controller;
  final String ipucu;
  final String ekleEtiketi;
  final ValueChanged<String> onEkle;

  @override
  Widget build(BuildContext context) {
    final kutu = TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(hintText: ipucu, hintMaxLines: 3),
      onSubmitted: onEkle,
    );
    final dugme = KilDugme.birincil(
      etiket: ekleEtiketi,
      ikon: Icons.add_rounded,
      onPressed: () => onEkle(controller.text),
    );

    if (nePisirsemUstUsteMi(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [kutu, const SizedBox(height: 10), dugme],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: kutu),
        const SizedBox(width: 10),
        Padding(padding: const EdgeInsets.only(top: 4), child: dugme),
      ],
    );
  }
}

/// Tarifin kaydedileceği klasör. Dokununca klasör listesi açılır.
class KlasorSecimKutusu extends StatelessWidget {
  const KlasorSecimKutusu({
    super.key,
    required this.ad,
    required this.ikon,
    required this.renk,
    required this.degistirIpucu,
    required this.onTap,
  });

  final String ad;
  final IconData ikon;
  final KlasorRenk renk;

  /// Ekran okuyucunun eylem ipucu.
  final String degistirIpucu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return Semantics(
      button: true,
      label: ad,
      hint: degistirIpucu,
      excludeSemantics: true,
      onTap: onTap,
      child: KilKart(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Flex(
            // Büyük yazıda ikon adın üstüne çıkar; yoksa ad sıkışıp bölünüyordu.
            direction: nePisirsemUstUsteMi(context)
                ? Axis.vertical
                : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: renk.zemin,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, size: 22, color: renk.ikon),
              ),
              const SizedBox(width: 12, height: 8),
              if (nePisirsemUstUsteMi(context))
                Text(ad, style: Theme.of(context).textTheme.titleMedium)
              else ...[
                Expanded(
                  child: Text(
                    ad,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.unfold_more_rounded, color: r.solukYazi),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Yapay zekâ tarifi hazırlarken sayfanın üstünü örten katman: karartılmış
/// zemin ve ortada şef animasyonlu kil kartı. Alttaki sayfaya dokunulamaz,
/// ekran okuyucu da yalnızca kartı okur.
class AiBeklemeKatmani extends StatelessWidget {
  const AiBeklemeKatmani({
    super.key,
    required this.baslik,
    required this.mesajlar,
  });

  final String baslik;
  final List<String> mesajlar;

  @override
  Widget build(BuildContext context) {
    final scrim = Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6);
    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(dismissible: false, color: scrim),
        BlockSemantics(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: KilKart(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    // Kısa süreli durum metni; en fazla 2 kat büyür.
                    child: nePisirsemBaslikSinirla(
                      AiChefLoadingAnimation(title: baslik, messages: mesajlar),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

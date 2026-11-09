import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../tarifler_data/klasor_data.dart';
import 'kil/kil.dart';

/// Tarif eklemenin üç yolu.
enum TarifEklemeYolu { kendim, sef, link }

/// Alt sayfada yapılan seçim: yol ve tarifin gideceği klasör.
@immutable
class TarifEklemeSecimi {
  const TarifEklemeSecimi(this.yol, this.klasor);

  final TarifEklemeYolu yol;
  final KlasorData klasor;
}

/// Alt sayfanın metinleri. Uygulamada [TarifEkleMetinleri.ceviri] kullanılır;
/// testler düz metin verir.
@immutable
class TarifEkleMetinleri {
  const TarifEkleMetinleri({
    required this.baslik,
    required this.klasorSorusu,
    required this.kendim,
    required this.kendimAciklama,
    required this.sef,
    required this.sefAciklama,
    required this.link,
    required this.linkAciklama,
    required this.girisGerekli,
  });

  factory TarifEkleMetinleri.ceviri() => TarifEkleMetinleri(
        baslik: 'home_new_recipe'.tr(),
        klasorSorusu: 'recipe_add_folder_label'.tr(),
        kendim: 'add_option_manual'.tr(),
        kendimAciklama: 'add_option_manual_desc'.tr(),
        sef: 'add_option_ai'.tr(),
        sefAciklama: 'add_option_ai_desc'.tr(),
        link: 'add_option_link'.tr(),
        linkAciklama: 'add_option_link_desc'.tr(),
        girisGerekli: 'ai_login_required'.tr(),
      );

  final String baslik;
  final String klasorSorusu;
  final String kendim;
  final String kendimAciklama;
  final String sef;
  final String sefAciklama;
  final String link;
  final String linkAciklama;
  final String girisGerekli;
}

/// "Yeni tarif" alt sayfası: önce tarifin gideceği klasör, sonra üç yol
/// (kendim yazacağım, Şefe sor, linkten tarif).
///
/// Sayfa yalnızca seçimi döndürür; akışları `TarifEklemeAkisi` yürütür.
class TarifEkleAltSayfasi extends StatefulWidget {
  const TarifEkleAltSayfasi({
    super.key,
    required this.klasorler,
    required this.baslangicKlasoru,
    required this.girisYapildi,
    required this.klasorAdi,
    required this.metinler,
    required this.onSecildi,
  });

  final List<KlasorData> klasorler;
  final KlasorData baslangicKlasoru;

  /// Şefe sor ve linkten tarif giriş ister; giriş yoksa kilitli görünürler.
  final bool girisYapildi;
  final String Function(KlasorData klasor) klasorAdi;
  final TarifEkleMetinleri metinler;
  final ValueChanged<TarifEklemeSecimi> onSecildi;

  /// Alt sayfayı açar; bir yol seçilirse seçimi, kapatılırsa null döndürür.
  static Future<TarifEklemeSecimi?> goster(
    BuildContext context, {
    required List<KlasorData> klasorler,
    required KlasorData baslangicKlasoru,
    required bool girisYapildi,
    required String Function(KlasorData klasor) klasorAdi,
  }) {
    final metinler = TarifEkleMetinleri.ceviri();
    return KilAltSayfa.goster<TarifEklemeSecimi>(
      context,
      baslik: metinler.baslik,
      builder: (sayfaContext) => TarifEkleAltSayfasi(
        klasorler: klasorler,
        baslangicKlasoru: baslangicKlasoru,
        girisYapildi: girisYapildi,
        klasorAdi: klasorAdi,
        metinler: metinler,
        onSecildi: (secim) => Navigator.pop(sayfaContext, secim),
      ),
    );
  }

  @override
  State<TarifEkleAltSayfasi> createState() => _TarifEkleAltSayfasiState();
}

class _TarifEkleAltSayfasiState extends State<TarifEkleAltSayfasi> {
  late KlasorData _secili = widget.baslangicKlasoru;
  final _ilkSeciliAnahtar = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Klasör çok ve seçili olan sağda kalmışsa görünür yere kaydır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _ilkSeciliAnahtar.currentContext;
      if (c != null && c.mounted) {
        Scrollable.ensureVisible(c, alignment: 0.5);
      }
    });
  }

  void _sec(TarifEklemeYolu yol) =>
      widget.onSecildi(TarifEklemeSecimi(yol, _secili));

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final m = widget.metinler;
    final kilitli = !widget.girisYapildi;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            m.klasorSorusu,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: r.solukYazi),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final k in widget.klasorler)
                  Padding(
                    key: k.klasor_id == widget.baslangicKlasoru.klasor_id
                        ? _ilkSeciliAnahtar
                        : null,
                    padding: const EdgeInsets.only(right: 8),
                    child: KilCip(
                      etiket: widget.klasorAdi(k),
                      ikon: k.icon,
                      secili: k.klasor_id == _secili.klasor_id,
                      onSelected: (_) => setState(() => _secili = k),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TarifEkleSecenegi(
            ikon: Icons.edit_note_rounded,
            renk: r.klasorTatli,
            baslik: m.kendim,
            aciklama: m.kendimAciklama,
            onTap: () => _sec(TarifEklemeYolu.kendim),
          ),
          const SizedBox(height: 12),
          TarifEkleSecenegi(
            ikon: Icons.auto_awesome_rounded,
            renk: r.klasorCorba,
            baslik: m.sef,
            aciklama: kilitli ? m.girisGerekli : m.sefAciklama,
            kilitli: kilitli,
            onTap: () => _sec(TarifEklemeYolu.sef),
          ),
          const SizedBox(height: 12),
          TarifEkleSecenegi(
            ikon: Icons.link_rounded,
            renk: r.klasorKahvalti,
            baslik: m.link,
            aciklama: kilitli ? m.girisGerekli : m.linkAciklama,
            kilitli: kilitli,
            onTap: () => _sec(TarifEklemeYolu.link),
          ),
        ],
      ),
    );
  }
}

/// Alt sayfadaki bir yol: renkli ikon kutusu, ad, açıklama ve sağda ok.
/// [kilitli] ise ok yerine kilit çıkar (giriş gerekli); yine de dokunulur,
/// akış giriş gerektiğini söyler.
class TarifEkleSecenegi extends StatelessWidget {
  const TarifEkleSecenegi({
    super.key,
    required this.ikon,
    required this.renk,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
    this.kilitli = false,
  });

  final IconData ikon;
  final KlasorRenk renk;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;
  final bool kilitli;

  /// Yazı bu ölçeğin üstündeyse ikon metnin üstüne çıkar (metin sıkışmasın).
  static const double ustUsteOlcegi = 1.6;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;
    final olcek = MediaQuery.textScalerOf(context).scale(10) / 10;

    final ikonKutusu = ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: kilitli ? r.solukYuzey : renk.zemin,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          ikon,
          color: kilitli ? r.solukYazi : renk.ikon,
          size: 26,
        ),
      ),
    );
    final sagIkon = ExcludeSemantics(
      child: Icon(
        kilitli ? Icons.lock_rounded : Icons.chevron_right_rounded,
        color: r.solukYazi,
      ),
    );
    final metinler = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: yaziTemasi.titleMedium),
        const SizedBox(height: 2),
        Text(
          aciklama,
          style: yaziTemasi.bodyMedium?.copyWith(color: r.solukYazi),
        ),
      ],
    );

    return KilKart(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: olcek > ustUsteOlcegi
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [ikonKutusu, const Spacer(), sagIkon]),
                const SizedBox(height: 10),
                metinler,
              ],
            )
          : Row(
              children: [
                ikonKutusu,
                const SizedBox(width: 14),
                Expanded(child: metinler),
                const SizedBox(width: 8),
                sagIkon,
              ],
            ),
    );
  }
}

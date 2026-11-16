import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../services/revenuecat_service.dart';
import '../services/tarif_paylasim_service.dart';
import '../tarifler_data/klasor_data.dart';
import '../utils/klasor_adi.dart';
import '../utils/recipe_link_helper.dart';
import '../utils/tarif_kayit.dart';
import '../widgets/kil/kil.dart';
import '../widgets/tarif_detay_parcalari.dart';
import 'klasor_ici.dart';
import 'premium_sayfasi.dart';

enum _Durum { yukleniyor, hazir, bulunamadi, hata }

/// Tarifly paylaşım linkiyle açılan tarif. Tarif önizlenir; "Defterime
/// ekle" ile klasör seçilip kullanıcının defterine kopyalanır. Eklemek için
/// giriş gerekmez (tarif önce cihaza yazılır, girişliyse buluta da gider).
class PaylasilanTarifSayfasi extends StatefulWidget {
  const PaylasilanTarifSayfasi({
    super.key,
    required this.kod,
    this.eklenince,
  });

  /// Linkteki paylaşım kodu.
  final String kod;

  /// Tarif deftere eklenince (Defterim listesini tazelemek için).
  final VoidCallback? eklenince;

  @override
  State<PaylasilanTarifSayfasi> createState() => _PaylasilanTarifSayfasiState();
}

class _PaylasilanTarifSayfasiState extends State<PaylasilanTarifSayfasi> {
  final _servis = TarifPaylasimService();
  _Durum _durum = _Durum.yukleniyor;
  Map<String, dynamic>? _veri;
  bool _ekleniyor = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _durum = _Durum.yukleniyor);
    try {
      final veri = await _servis
          .getir(widget.kod)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      AnalyticsService.paylasilanTarifAcildi(bulundu: veri != null);
      setState(() {
        _veri = veri;
        _durum = veri == null ? _Durum.bulunamadi : _Durum.hazir;
      });
    } catch (e) {
      debugPrint('Paylaşılan tarif yüklenemedi: $e');
      if (mounted) setState(() => _durum = _Durum.hata);
    }
  }

  Future<List<KlasorData>> _klasorler() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('klasorler') ?? [])
        .map((j) => KlasorData.fromMap(json.decode(j)))
        .where((k) => k.klasor_id != -1) // Favoriler gerçek klasör değil
        .toList();
  }

  Future<void> _klasorSec() async {
    final klasorler = await _klasorler();
    if (!mounted) return;
    if (klasorler.isEmpty) {
      KilBildirim.goster(context, 'shared_recipe_no_folder'.tr());
      return;
    }
    KilAltSayfa.goster<void>(
      context,
      baslik: 'shared_recipe_select_folder'.tr(),
      builder: (sayfaContext) => KilSecimListesi(
        secenekler: [
          for (final k in klasorler)
            KilSecenek(
              ikon: k.icon,
              etiket: klasorGorunenAdi(k),
              onTap: () {
                Navigator.pop(sayfaContext);
                _klasoreEkle(k);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _klasoreEkle(KlasorData klasor) async {
    final veri = _veri;
    if (veri == null || _ekleniyor) return;

    if (await klasorTarifSiniriDolduMu(klasor.klasor_id)) {
      if (!mounted) return;
      KilBildirim.goster(
        context,
        'tarif_limit_reached'.tr(args: ['${RevenueCatService.freeTarifPerKlasorLimit}']),
        tur: KilBildirimTuru.uyari,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumSayfasi(source: 'tarif_limit')),
      );
      return;
    }

    setState(() => _ekleniyor = true);
    try {
      final resimler = await _servis.resimleriIndir(paylasimResimleri(veri));
      final tarif = paylasilandanTarif(
        veri,
        klasorId: klasor.klasor_id,
        resimler: resimler,
      );
      // Önce cihaza yazılır; bulut arkadan (bkz. tarif_kayit.dart).
      await yeniTarifiCihazaYaz(tarif);
      unawaited(tarifiArkadanBulutaGonder(
        tarif,
        FirebaseService().saveTarifToFirebase,
      ));
      AnalyticsService.paylasilanTarifEklendi();
      widget.eklenince?.call();
      if (!mounted) return;
      KilBildirim.goster(context, 'shared_recipe_added'.tr(), tur: KilBildirimTuru.basari);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => KlasorIci(klasorData: klasor)),
      );
    } catch (e) {
      debugPrint('Paylaşılan tarif eklenemedi: $e');
      if (!mounted) return;
      setState(() => _ekleniyor = false);
      KilBildirim.goster(context, 'shared_recipe_add_error'.tr(), tur: KilBildirimTuru.hata);
    }
  }

  void _buyukFoto(String adres) {
    showDialog(
      context: context,
      builder: (_) => KilBuyukFoto(
        child: CachedNetworkImage(
          imageUrl: adres,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final veri = _veri;
    if (_durum != _Durum.hazir || veri == null) {
      return KilIcSayfa(
        baslik: 'shared_recipe_title'.tr(),
        icerik: [
          if (_durum == _Durum.yukleniyor)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else
            _DurumKarti(
              mesaj: _durum == _Durum.bulunamadi
                  ? 'shared_recipe_not_found'.tr()
                  : 'shared_recipe_load_error'.tr(),
              dugmeEtiketi:
                  _durum == _Durum.hata ? 'shared_recipe_retry'.tr() : null,
              onDugme: _yukle,
            ),
        ],
      );
    }

    final bolumler = paylasimBolumleri(veri);
    final resimler = paylasimResimleri(veri);
    final aciklama = '${veri['aciklama'] ?? ''}';

    return KilIcSayfa(
      baslik: '${veri['ad'] ?? ''}',
      icerik: [
        if (resimler.isNotEmpty)
          TarifGorselGalerisi(
            yollar: resimler,
            onTap: _buyukFoto,
            yuklenemediMetni: 'image_load_error'.tr(),
            bulunamadiMetni: 'image_not_found'.tr(),
          ),
        for (final b in bolumler)
          TarifBolumKarti(
            tur: b['type'],
            baslik: b['title'],
            maddeler: b['items'],
            onBaglantiAc: (adres) => launchRecipeUrl(context, adres),
          ),
        if (bolumler.isEmpty && aciklama.isNotEmpty)
          TarifAciklamaKarti(
            baslik: 'recipe_detail_description_title'.tr(),
            metin: aciklama,
          ),
      ],
      altDugme: KilDugme.birincil(
        etiket: 'shared_recipe_add'.tr(),
        ikon: Icons.bookmark_add_rounded,
        onPressed: _ekleniyor ? null : _klasorSec,
      ),
    );
  }
}

class _DurumKarti extends StatelessWidget {
  const _DurumKarti({
    required this.mesaj,
    required this.dugmeEtiketi,
    required this.onDugme,
  });

  final String mesaj;
  final String? dugmeEtiketi;
  final VoidCallback onDugme;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return KilKart(
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, size: 40, color: r.solukYazi),
          const SizedBox(height: 12),
          Text(
            mesaj,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: r.anaYazi),
          ),
          if (dugmeEtiketi != null) ...[
            const SizedBox(height: 16),
            KilDugme.birincil(
              etiket: dugmeEtiketi!,
              ikon: Icons.refresh_rounded,
              onPressed: onDugme,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../utils/tarif_paylas.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/arama_metni.dart';
import '../utils/klasor_adi.dart';
import '../utils/tarif_kayit.dart';
import '../widgets/kil/kil.dart';
import '../widgets/tarif_ekle_alt_sayfasi.dart';
import '../widgets/tarif_listesi_parcalari.dart';
import 'tarif_ekleme_akisi.dart';

/// Klasör içi: klasördeki tarifler, arama ve "Yeni tarif" düğmesi.
class KlasorIci extends StatefulWidget {
  final KlasorData klasorData;
  const KlasorIci({super.key, required this.klasorData});

  @override
  State<KlasorIci> createState() => _KlasorIciState();
}

class _KlasorIciState extends State<KlasorIci> {
  List<TarifData> tarifListesi = [];
  List<TarifData> filtreliTarifler = [];
  bool aramaYapiliyorMu = false;
  TextEditingController aramaController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tarifleriYukle();
    AdService.loadRewardedAd();
  }

  @override
  void dispose() {
    aramaController.dispose();
    super.dispose();
  }

  Future<void> _tarifleriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];

    // 1. Önce SharedPreferences'tan hızlıca göster
    final localList = tariflerJson.map((e) {
      return TarifData.fromMap(json.decode(e));
    }).toList();

    if (mounted) {
      setState(() {
        tarifListesi = localList;
        filtreliTarifler = List.from(tarifListesi);
      });
    }

    // 2. Giriş yapıldıysa Firebase'den çek ve bozuk yerel yolları düzelt
    if (_firebaseService.isUserLoggedIn) {
      try {
        final cloudTarifler = await _firebaseService
            .loadTariflerFromFirebase(widget.klasorData.klasor_id);

        if (cloudTarifler.isEmpty || !mounted) return;

        // Cloud verilerinden tarif_id → tarif eşlemesi oluştur
        final cloudMap = {for (var t in cloudTarifler) t.tarif_id: t};

        bool herhangiGuncellendi = false;
        final yeniJson = tariflerJson.map((e) {
          var map = json.decode(e) as Map<String, dynamic>;
          final int tid = map['tarif_id'];
          final List<String> mevcutResimler = map['tarif_resimler'] != null
              ? List<String>.from(map['tarif_resimler'])
              : [];

          // Bozuk yol (bulut adresi değil ve dosyası cihazda yok) varsa
          // cloud'dan al. Dosyası duran yerel fotoğraf henüz yüklenmemiş
          // olabilir; ona dokunulmaz.
          final bool bozukYolVar = mevcutResimler
              .any((p) => !p.startsWith('http') && !File(p).existsSync());
          final cloudTarif = cloudMap[tid];
          if (bozukYolVar && cloudTarif != null && cloudTarif.tarif_resimler.isNotEmpty) {
            final cloudResimler = cloudTarif.tarif_resimler
                .where((p) => p.startsWith('http'))
                .toList();
            if (cloudResimler.isNotEmpty) {
              map['tarif_resimler'] = cloudResimler;
              herhangiGuncellendi = true;
            }
          }
          return json.encode(map);
        }).toList();

        // Ayrıca cloud'da olup yerel'de olmayan tarifleri ekle
        final localIds = localList.map((t) => t.tarif_id).toSet();
        for (var ct in cloudTarifler) {
          if (!localIds.contains(ct.tarif_id)) {
            yeniJson.add(json.encode(ct.toMap()));
            herhangiGuncellendi = true;
          }
        }

        if (herhangiGuncellendi) {
          await prefs.setStringList(key, yeniJson);
          // Güncel listeyi tekrar yükle
          final guncelList = yeniJson.map((e) {
            return TarifData.fromMap(json.decode(e));
          }).toList();
          if (mounted) {
            setState(() {
              tarifListesi = guncelList;
              filtreliTarifler = List.from(tarifListesi);
            });
          }
        }
      } catch (e) {
        debugPrint('Firebase\'den görsel güncelleme hatası: $e');
      }
    }
  }

  void _filtreleTarifler(String arama) {
    setState(() {
      if (arama.isEmpty) {
        filtreliTarifler = List.from(tarifListesi);
      } else {
        filtreliTarifler = tarifListesi.where((tarif) =>
          aramaEslesir(tarif.tarif_adi, arama) ||
          aramaEslesir(tarif.tarif_aciklama, arama)
        ).toList();
      }
    });
  }

  Future<void> _tarifGuncelle(TarifData guncelTarif) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    int index = tariflerJson.indexWhere((e) => json.decode(e)['tarif_id'] == guncelTarif.tarif_id);
    if (index != -1) {
      // Güncellemeden önce artık kullanılmayan (silinmiş) eski fotoğrafları temizle
      final eskiTarif = TarifData.fromMap(json.decode(tariflerJson[index]));
      final kaldirilanResimler = eskiTarif.tarif_resimler
          .where((p) => !guncelTarif.tarif_resimler.contains(p))
          .toList();
      // Önce cihaza yaz ve listeyi yenile; Firebase beklenmez (internet
      // yokken yazma bitmez, düzenleme kaydedilmemiş gibi görünürdü).
      guncelTarif.updatedAt = DateTime.now().millisecondsSinceEpoch;
      tariflerJson[index] = json.encode(guncelTarif.toMap());
      await prefs.setStringList(key, tariflerJson);

      // Yerel fotoğrafları yükler, bulut adreslerini cihazdaki kayda yazar.
      unawaited(tarifiArkadanBulutaGonder(
        guncelTarif,
        _firebaseService.updateTarifInFirebase,
      ));
      if (kaldirilanResimler.isNotEmpty) {
        unawaited(_firebaseService.deleteImagesForTarif(
          TarifData(
            tarif_id: eskiTarif.tarif_id,
            tarif_adi: eskiTarif.tarif_adi,
            tarif_aciklama: '',
            tarif_resimler: kaldirilanResimler,
            klasor_id: eskiTarif.klasor_id,
          ),
        ));
      }

      _tarifleriYukle();
    }
  }

  Future<void> _tarifSil(TarifData tarif) async {
    await tarifiCihazdanSil(widget.klasorData.klasor_id, tarif.tarif_id);

    // Firebase'den ve görsellerden (yerel + bulut) de sil; beklenmez.
    unawaited(_firebaseService.deleteTarifFromFirebase(
        widget.klasorData.klasor_id, tarif.tarif_id));
    unawaited(_firebaseService.deleteImagesForTarif(tarif));

    _tarifleriYukle();
  }

  Future<void> _favoriDegistir(TarifData tarif) async {
    setState(() {
      tarif.isFavorite = !tarif.isFavorite;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    int idx = tariflerJson.indexWhere((e) => (json.decode(e)['tarif_id'] == tarif.tarif_id));
    if (idx != -1) {
      var map = json.decode(tariflerJson[idx]);
      map['isFavorite'] = tarif.isFavorite;
      tariflerJson[idx] = json.encode(map);
      await prefs.setStringList(key, tariflerJson);
    }
    await _firebaseService.updateTarifInFirebase(tarif);
  }

  Future<void> _tarifPaylas(BuildContext dugmeContext, TarifData tarif) => tarifiPaylas(
        context: context,
        dugmeContext: dugmeContext,
        tarif: tarif,
        kaynak: 'klasor_ici',
      );

  void _silmeOnayi(TarifData tarif) {
    KilDiyalog.onayIste(
      context,
      ikon: Icons.delete_outline_rounded,
      tehlikeli: true,
      baslik: 'recipes_delete_title'.tr(),
      mesaj: '${tarif.tarif_adi}${'recipes_delete_confirm_suffix'.tr()}',
      onayEtiketi: 'common_yes'.tr(),
      vazgecEtiketi: 'common_no'.tr(),
    ).then((onay) {
      if (onay == true) _tarifSil(tarif);
    });
  }

  Future<void> _tarifiAc(TarifData tarif) async {
    final guncelTarif = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TarifDetay(tarif: tarif),
      ),
    );
    if (guncelTarif == true) {
      _tarifleriYukle();
    } else if (guncelTarif != null && guncelTarif is TarifData) {
      _tarifGuncelle(guncelTarif);
    }
  }

  /// "Yeni tarif" alt sayfası: bu klasör seçili gelir, istenirse değişir.
  Future<void> _yeniTarif() async {
    final klasorler = await kayitliKlasorleriOku();
    if (!klasorler.any((k) => k.klasor_id == widget.klasorData.klasor_id)) {
      klasorler.insert(0, widget.klasorData);
    }
    if (!mounted) return;
    final secim = await TarifEkleAltSayfasi.goster(
      context,
      klasorler: klasorler,
      baslangicKlasoru: widget.klasorData,
      girisYapildi: _firebaseService.isUserLoggedIn,
      klasorAdi: klasorGorunenAdi,
    );
    if (secim == null || !mounted) return;
    final buKlasor = secim.klasor.klasor_id == widget.klasorData.klasor_id;
    TarifEklemeAkisi(
      context: context,
      klasor: secim.klasor,
      yenile: () => setState(() {}),
      kaydedilince: (_) {
        if (buKlasor) {
          _tarifleriYukle();
        } else if (mounted) {
          // Tarif başka klasöre gitti: o klasör açılır.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KlasorIci(klasorData: secim.klasor),
            ),
          );
        }
      },
    ).baslat(secim.yol);
  }

  void _aramayiAcKapat() {
    setState(() {
      if (aramaYapiliyorMu) {
        aramaYapiliyorMu = false;
        aramaController.clear();
        filtreliTarifler = List.from(tarifListesi);
      } else {
        aramaYapiliyorMu = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;

    return TarifListesiGorunumu(
      baslik: klasorGorunenAdi(widget.klasorData),
      aramaAcik: aramaYapiliyorMu,
      aramaController: aramaController,
      aramaIpucu: 'recipes_search_hint'.tr(),
      onAramaAcKapat: _aramayiAcKapat,
      onAramaDegisti: (arama) {
        if (mounted) _filtreleTarifler(arama);
      },
      satirlar: [
        for (final tarif in filtreliTarifler)
          TarifSatiri(
            ad: tarif.tarif_adi,
            resimYolu: tarif.tarif_resimler.isNotEmpty
                ? tarif.tarif_resimler.first
                : null,
            favori: tarif.isFavorite,
            favoriEtiketi: tarif.isFavorite
                ? 'recipe_favorite_remove'.tr()
                : 'recipe_favorite_add'.tr(),
            paylasEtiketi: 'recipe_detail_share_tooltip'.tr(),
            silEtiketi: 'recipes_delete_title'.tr(),
            onTap: () => _tarifiAc(tarif),
            onFavori: () => _favoriDegistir(tarif),
            onPaylas: (dugmeContext) => _tarifPaylas(dugmeContext, tarif),
            onSil: () => _silmeOnayi(tarif),
          ),
      ],
      bosDurum: TarifBosDurum(
        ikon: Icons.menu_book_rounded,
        renk: r.klasorTatli,
        baslik: 'recipes_empty_title'.tr(),
        altBaslik: 'recipes_empty_subtitle'.tr(),
      ),
      yeniTarifDugmesi: KilDugme.birincil(
        etiket: 'home_new_recipe'.tr(),
        ikon: Icons.add_rounded,
        onPressed: _yeniTarif,
      ),
      altCubuk: const BannerAdWidget(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/services/firebase_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:tarif_defteri/sayfalar/tarif_olusturma.dart';
import 'package:tarif_defteri/sayfalar/yemek_yapma_modu.dart';
import '../utils/tarif_paylas.dart';
import '../utils/tarif_bolumleri.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/revenuecat_service.dart';
import '../utils/tarif_kayit.dart';
import '../widgets/kil/kil.dart';
import '../widgets/tarif_detay_parcalari.dart';
import '../utils/recipe_link_helper.dart';
import '../utils/porsiyon_olcekleyici.dart';

class TarifDetay extends StatefulWidget {
  final TarifData tarif;

  const TarifDetay({super.key, required this.tarif});

  @override
  State<TarifDetay> createState() => _TarifDetayState();
}

class _TarifDetayState extends State<TarifDetay> {
  List<Map<String, dynamic>> sections = [];
  double _portionMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _parseTarifAciklama();
  }

  Future<void> _addToShoppingList(String ingredient) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('shopping_list_todo') ?? [];
    if (!list.contains(ingredient)) {
      list.insert(0, ingredient);
      await prefs.setStringList('shopping_list_todo', list);
      
      if (mounted) {
        KilBildirim.goster(
          context,
          'recipe_detail_add_to_cart'.tr(),
          tur: KilBildirimTuru.basari,
          sure: const Duration(seconds: 2),
        );
      }
    }
  }

  void _parseTarifAciklama() {
    sections = tarifBolumleriniCoz(
      widget.tarif,
      varsayilanBaslik: 'recipe_section_ingredients'.tr(),
    );
  }

  void _showBigPhoto(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => KilBuyukFoto(
        child: imagePath.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: imagePath,
                fit: BoxFit.contain,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
              )
            : Image.file(File(imagePath), fit: BoxFit.contain),
      ),
    );
  }

  Future<void> _paylas(BuildContext dugmeContext) => tarifiPaylas(
        context: context,
        dugmeContext: dugmeContext,
        tarif: widget.tarif,
        kaynak: 'tarif_detay',
      );

  Future<void> _duzenle() async {
    final guncelTarif = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TarifOlusturma(tarifData: widget.tarif),
      ),
    );
    if (guncelTarif != null && guncelTarif is TarifData && mounted) {
      Navigator.pop(context, guncelTarif);
    }
  }

  @override
  Widget build(BuildContext context) {
    final porsiyonVar =
        sections.any((s) => s['type'] == 'malzemeler' || s['type'] == 'harc' || s['type'] == 'hamur');

    return KilIcSayfa(
      baslik: widget.tarif.tarif_adi,
      eylemler: [
        // Paylaş düğmesi (iOS'ta paylaşım penceresi bu düğmenin konumundan açılır)
        Builder(
          builder: (dugmeContext) => KilYuvarlakDugme(
            ikon: Icons.ios_share_rounded,
            etiket: 'recipe_detail_share_tooltip'.tr(),
            onPressed: () => _paylas(dugmeContext),
          ),
        ),
        KilYuvarlakDugme(
          ikon: Icons.drive_file_move_outline,
          etiket: 'folders_move'.tr(),
          onPressed: () => _showMoveDialog(context),
        ),
        KilYuvarlakDugme(
          ikon: Icons.edit_rounded,
          etiket: 'recipe_detail_edit_tooltip'.tr(),
          onPressed: _duzenle,
        ),
      ],
      icerik: [
        if (widget.tarif.isFavorite)
          FavoriRozeti(etiket: 'folders_favorites'.tr()),

        // Görseller
        if (widget.tarif.tarif_resimler.isNotEmpty)
          TarifGorselGalerisi(
            yollar: widget.tarif.tarif_resimler,
            onTap: _showBigPhoto,
            yuklenemediMetni: 'image_load_error'.tr(),
            bulunamadiMetni: 'image_not_found'.tr(),
          ),

        // Porsiyon ayarlama
        if (porsiyonVar)
          PorsiyonAyari(
            etiket: 'recipe_detail_portions'.tr(),
            carpanMetni: '${_portionMultiplier}x',
            azaltEtiketi: 'recipe_detail_portion_decrease'.tr(),
            artirEtiketi: 'recipe_detail_portion_increase'.tr(),
            onAzalt: _portionMultiplier > 0.5
                ? () => setState(() => _portionMultiplier -= 0.5)
                : null,
            onArtir: () => setState(() => _portionMultiplier += 0.5),
          ),

        // Bölümler
        for (final section in sections)
          TarifBolumKarti(
            tur: section['type'] ?? '',
            baslik: section['title'] ?? '',
            maddeler: [
              for (final String madde in section['items'])
                tarifBolumuMalzemeMi(section['type'] ?? '')
                    ? olcekleMalzeme(madde, _portionMultiplier)
                    : madde,
            ],
            sepeteEkleEtiketi: 'recipe_detail_add_to_cart'.tr(),
            onSepeteEkle: (i) {
              String scaled = olcekleMalzeme(section['items'][i], _portionMultiplier);
              _addToShoppingList(scaled);
            },
            onBaglantiAc: (adres) => launchRecipeUrl(context, adres),
          ),

        // Eğer section yoksa (eski format) açıklamayı göster
        if (sections.isEmpty && widget.tarif.tarif_aciklama.isNotEmpty)
          TarifAciklamaKarti(
            baslik: 'recipe_detail_description_title'.tr(),
            metin: widget.tarif.tarif_aciklama,
          ),
      ],
      altDugme: KilDugme.birincil(
        etiket: 'recipe_detail_cooking_mode'.tr(),
        ikon: Icons.restaurant_rounded,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YemekYapmaModu(tarif: widget.tarif, portionMultiplier: _portionMultiplier),
            ),
          );
        },
      ),
      altCubuk: const BannerAdWidget(),
    );
  }

  void _showMoveDialog(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? [];
    List<Map<String, dynamic>> klasorler = [];
    for (String j in klasorJsonList) {
      klasorler.add(json.decode(j));
    }

    if (!mounted) return;

    // Bu tarifin zaten bulunduğu klasör listede gösterilmez.
    final secenekler = <({int id, String ad})>[];
    for (var index = 0; index < klasorler.length; index++) {
      final klasorMap = klasorler[index];
      int kId = klasorMap['klasor_id'] ?? (index + 1);
      if (kId == widget.tarif.klasor_id) continue; // Zaten bu klasörde

      String displayName = klasorMap['klasor_adi'] ?? '';
      if (kId == 1 && (displayName == 'default_folder_desserts'.tr() || displayName == 'Tatlılar' || displayName == 'Desserts')) {
        displayName = 'default_folder_desserts'.tr();
      } else if (kId == 2 && (displayName == 'default_folder_soups'.tr() || displayName == 'Çorbalar' || displayName == 'Soups')) {
        displayName = 'default_folder_soups'.tr();
      } else if (kId == 3 && (displayName == 'default_folder_main_dishes'.tr() || displayName == 'Ana Yemekler' || displayName == 'Main Dishes')) {
        displayName = 'default_folder_main_dishes'.tr();
      } else if (kId == 4 && (displayName == 'default_folder_breakfast'.tr() || displayName == 'Kahvaltılıklar' || displayName == 'Breakfast')) {
        displayName = 'default_folder_breakfast'.tr();
      }
      secenekler.add((id: kId, ad: displayName));
    }

    if (!context.mounted) return;

    KilAltSayfa.goster<void>(
      context,
      baslik: 'folders_select_move'.tr(),
      builder: (sayfaContext) => KilSecimListesi(
        secenekler: [
          for (final s in secenekler)
            KilSecenek(
              ikon: Icons.folder_rounded,
              etiket: s.ad,
              onTap: () async {
                Navigator.pop(sayfaContext);
                if (await klasorTarifSiniriDolduMu(s.id)) {
                  if (!context.mounted) return;
                  KilBildirim.goster(
                    context,
                    'tarif_limit_reached'.tr(args: ['${RevenueCatService.freeTarifPerKlasorLimit}']),
                    tur: KilBildirimTuru.uyari,
                  );
                  return;
                }
                await _moveTarif(s.id);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _moveTarif(int newKlasorId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Eski klasörden çıkar
    String oldKey = 'tarifler_${widget.tarif.klasor_id}';
    List<String> oldList = prefs.getStringList(oldKey) ?? [];
    oldList.removeWhere((t) {
      var map = json.decode(t);
      return map['tarif_id'] == widget.tarif.tarif_id;
    });
    await prefs.setStringList(oldKey, oldList);
    
    // Firebase'den eski doc'u sil
    FirebaseService fs = FirebaseService();
    await fs.deleteTarifFromFirebase(widget.tarif.klasor_id, widget.tarif.tarif_id);
    
    // Yeni klasöre ekle
    widget.tarif.klasor_id = newKlasorId;
    widget.tarif.updatedAt = DateTime.now().millisecondsSinceEpoch;
    String newKey = 'tarifler_$newKlasorId';
    List<String> newList = prefs.getStringList(newKey) ?? [];
    newList.add(json.encode(widget.tarif.toMap()));
    await prefs.setStringList(newKey, newList);
    
    // Firebase'e yeni doc olarak ekle
    await fs.saveTarifToFirebase(widget.tarif);
    
    if (!mounted) return;
    
    KilBildirim.goster(
      context,
      'folders_move_success'.tr(),
      tur: KilBildirimTuru.basari,
    );
    
    Navigator.pop(context, true); // Pop the screen and return true to indicate change
  }
}

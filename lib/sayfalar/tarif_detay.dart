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
import 'package:share_plus/share_plus.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/revenuecat_service.dart';
import '../utils/tarif_kayit.dart';
import '../widgets/kil/kil.dart';
import '../widgets/tarif_detay_parcalari.dart';
import '../utils/magaza_linki.dart';
import '../utils/recipe_link_helper.dart';
import '../utils/porsiyon_olcekleyici.dart';
import '../services/analytics_service.dart';

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
    if (widget.tarif.tarif_aciklama_json != null && widget.tarif.tarif_aciklama_json!.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(widget.tarif.tarif_aciklama_json!);
        sections = decoded.map((e) {
          // Geri dönen öğelerin listeler olduğundan emin olalım
          return {
            'title': e['title'],
            'type': e['type'],
            'items': List<String>.from(e['items'] ?? []),
            'isExpanded': e['isExpanded'] ?? true
          };
        }).toList();
        return;
      } catch (e) {
        debugPrint('JSON parsing error in tarif_detay: $e');
      }
    }

    String tarifAciklama = widget.tarif.tarif_aciklama;
    if (tarifAciklama.isEmpty) return;
    
    final lines = tarifAciklama.split('\n');
    String currentSection = '';
    String currentType = '';
    List<String> currentItems = [];
    
    // Helper to check headers (Improved)
    bool isHeader(String line, List<String> keywords) {
      String lower = line.replaceAll(':', '').trim().toLowerCase();
      
      // Ignore numbered items or bullets (prevent false positives like "2. İç malzemelerini karıştırın")
      if (RegExp(r'^\d+').hasMatch(lower)) return false;
      if (lower.startsWith('*') || lower.startsWith('-') || lower.startsWith('•')) return false;

      // Çok uzun satırları başlık olarak kabul etme (Yanlış pozitifleri önle)
      if (lower.length > 40) return false; 
      
      for (var k in keywords) {
         if (lower.contains(k.toLowerCase())) return true;
      }
      return false;
    }
    
    for (String line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Başlık kontrolü (Çok dilli ve esnek)
      if (isHeader(trimmed, ['malzemeler', 'ingredients', 'içindekiler'])) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed.replaceAll(':', '');
        currentType = 'malzemeler';
        currentItems = [];
      } else if (isHeader(trimmed, ['harç', 'filling', 'iç harcı'])) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed.replaceAll(':', '');
        currentType = 'harc';
        currentItems = [];
      } else if (isHeader(trimmed, ['hamuru', 'dough', 'hamur'])) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed.replaceAll(':', '');
        currentType = 'hamur';
        currentItems = [];
      } else if (isHeader(trimmed, ['şerbeti', 'syrup', 'şerbet', 'serbet'])) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed.replaceAll(':', '');
        currentType = 'serbet';
        currentItems = [];
      } else if (isHeader(trimmed, ['sosu', 'sauce', 'sos'])) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed.replaceAll(':', '');
        currentType = 'sos';
        currentItems = [];
      } else if (isHeader(trimmed, ['püf noktası', 'tips', 'puf noktasi', 'chef notes'])) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed.replaceAll(':', '');
        currentType = 'puf_noktasi';
        currentItems = [];
      } else if (isHeader(trimmed, ['yapılışı', 'instructions', 'steps', 'hazırlanışı', 'tarif', 'yapilis'])) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed.replaceAll(':', '');
        currentType = 'yapilis';
        currentItems = [];
      } else if (isHeader(trimmed, ['linkler', 'links'])) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed.replaceAll(':', '');
        currentType = 'linkler';
        currentItems = [];
      } else if (trimmed.startsWith('*') || trimmed.startsWith('•') || trimmed.startsWith('-') || RegExp(r'^\d+\.').hasMatch(trimmed) || trimmed.startsWith('🔗')) {
        // Madde ekle
        String item = trimmed;
        if (trimmed.startsWith('*') || trimmed.startsWith('•') || trimmed.startsWith('-')) {
          item = trimmed.substring(1).trim();
        } else if (trimmed.startsWith('🔗')) {
          item = trimmed.replaceFirst('🔗', '').trim();
        } else {
          item = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        }
        
        if (item.isNotEmpty) {
           // Eğer madde geldi ama henüz bir başlık yoksa, varsayılan olarak 'Malzemeler' başlat
           if (currentSection.isEmpty) {
             currentSection = 'recipe_section_ingredients'.tr();
             currentType = 'malzemeler';
           }
           currentItems.add(item);
        }
      } else {
        // Başlık değil, madde işareti yok. Düz metin.
        // Eğer kısa ve kalınsa başlık olabilir ama yukarıdaki kelimelere uymamış
        // Veya bir önceki maddenin devamı.
        
        if (currentSection.isEmpty && currentItems.isEmpty) {
           // Belki de "Genel" bir başlık? Veya AI sadece "Malzemeler İçin:" dedi ama split yüzünden ayrı kaldı?
           // Şimdilik görmezden gel veya Description'a ekle.
           // Ancak üstteki 'isHeader' zaten çoğu şeyi yakalar.
        } else if (currentItems.isNotEmpty) {
           // Bir önceki maddeye ekle (multiline support)
           currentItems[currentItems.length - 1] += ' $trimmed';
        } else {
            // Section var ama madde yok. Description gibi ekle.
            currentItems.add(trimmed);
        }
      }
    }
    
    // Son section'ı ekle
    _addSectionIfNotEmpty(currentSection, currentType, currentItems);
  }
  
  void _addSectionIfNotEmpty(String title, String type, List<String> items) {
    // items boş olsa bile eğer title varsa ekle (nadiren başlık olup içerik olmayabilir ama başlık kaybolmasın)
    // Ancak usually title ve items lazım. Fakat veri kaybını önlemek için title varsa ekleyelim.
    if (title.isNotEmpty && items.isNotEmpty) {
      sections.add({
        'title': title,
        'type': type,
        'items': List.from(items),
      });
    }
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

  Future<void> _paylas(BuildContext dugmeContext) async {
    try {
      // Tarif bilgilerini düzenli formatta hazırla
      String shareText = '📖 ${widget.tarif.tarif_adi}\n\n';

      // Sections varsa onları kullan, yoksa ham açıklamayı kullan
      if (sections.isNotEmpty) {
        for (var section in sections) {
          shareText += '${section['title']}\n';
          shareText += '${'─' * 20}\n';
          for (int i = 0; i < section['items'].length; i++) {
            if (section['type'] == 'yapilis') {
              shareText += '${i + 1}. ${section['items'][i]}\n';
            } else {
              shareText += '• ${section['items'][i]}\n';
            }
          }
          shareText += '\n';
        }
      } else {
        shareText += widget.tarif.tarif_aciklama;
      }

      shareText += '\n━━━━━━━━━━━━━━━━━━\n';
      shareText += 'share_from_app'.tr();
      shareText += '\n${'share_download_cta'.tr()} $magazaLinki';

      // iOS için butonun konumunu al
      final box = dugmeContext.findRenderObject() as RenderBox?;
      final sharePositionOrigin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await Share.share(
        shareText,
        subject: widget.tarif.tarif_adi,
        sharePositionOrigin: sharePositionOrigin,
      );
      AnalyticsService.tarifPaylasildi(kaynak: 'tarif_detay');
    } catch (e) {
      debugPrint('Tarif paylaşma hatası: $e');
      if (mounted) {
        KilBildirim.goster(
          context,
          'share_error_generic'.tr(),
          tur: KilBildirimTuru.hata,
        );
      }
    }
  }

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

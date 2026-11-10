import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/banner_ad_widget.dart';
import '../widgets/kil/kil.dart';
import '../widgets/tarif_detay_parcalari.dart';
import '../widgets/tarif_olusturma_parcalari.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/recipe_link_helper.dart';

class TarifOlusturma extends StatefulWidget {
  @override
  State<TarifOlusturma> createState() => _TarifOlusturmaState();
  final TarifData tarifData;
  final Map<String, dynamic>? aiResultMap;
  final bool isManual;

  const TarifOlusturma({
    super.key,
    required this.tarifData,
    this.aiResultMap,
    this.isManual = false,
  });
}

class _TarifOlusturmaState extends State<TarifOlusturma> {
  var tfTaridAdi = TextEditingController();
  final FocusNode _aciklamaFocus = FocusNode();
  List<Map<String, dynamic>> sections = [];
  List<XFile> photos = [];
  final ImagePicker _picker = ImagePicker();

  // Her section için TextField controller'ı
  Map<int, TextEditingController> sectionControllers = {};
  final ScrollController _scrollController = ScrollController();

  bool isAiGenerated = false;

  // Görseli kalıcı klasöre kopyala
  Future<String> _copyImageToPermanentLocation(String sourcePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'tarif_images');

      // Eğer dosya zaten kalıcı klasördeyse, tekrar kopyalama
      if (sourcePath.contains('tarif_images')) {
        debugPrint('Görsel zaten kalıcı klasörde: $sourcePath');
        // Dosyanın hala var olduğunu kontrol et
        if (await File(sourcePath).exists()) {
          return sourcePath;
        }
        // Dosya yoksa devam et (tekrar kopyalamaya çalış)
      }

      // Klasör yoksa oluştur
      if (!await Directory(imagesDir).exists()) {
        await Directory(imagesDir).create(recursive: true);
      }

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourcePath)}';
      final String destinationPath = path.join(imagesDir, fileName);
      final File destinationFile = File(destinationPath);

      await File(sourcePath).copy(destinationPath);
      // Kopyalanan dosyanın var olduğunu doğrula
      if (await destinationFile.exists()) {
        debugPrint('Görsel başarıyla kopyalandı: $destinationPath');
        return destinationFile.path;
      } else {
        throw Exception('Dosya kopyalanamadı');
      }
    } catch (e) {
      debugPrint('HATA - Görsel kopyalama hatası: $e');
      debugPrint('HATA - Kaynak yol: $sourcePath');
      // Hata durumunda boş string döndür (çarpı işareti yerine görsel gösterme)
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    var tarifData = widget.tarifData;
    tfTaridAdi.text = tarifData.tarif_adi;

    // Check if we have AI result data
    if (widget.aiResultMap != null) {
      isAiGenerated = true;
      _parseAiResult(widget.aiResultMap!);
    }
    // Otherwise check for existing string description
    else if (tarifData.tarif_aciklama.isNotEmpty) {
      _parseExistingTarif(tarifData.tarif_aciklama);
    }
    // New recipe, add default empty ingredient section
    else if (sections.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          sections.add({
            'title': 'recipe_section_ingredients'.tr(),
            'type': 'malzemeler',
            'items': [],
          });
        });
      });
    }

    // Mevcut görselleri yükle
    _loadExistingImages(tarifData.tarif_resimler);
  }

  void _parseAiResult(Map<String, dynamic> aiData) {
    if (aiData.containsKey('icindekiler')) {
      var icindekiler = aiData['icindekiler'];
      if (icindekiler is List) {
        for (var grup in icindekiler) {
          if (grup is Map) {
            String? bolumAdi = grup['bolum_adi'];
            List<dynamic>? malzemeler = grup['malzemeler'];

            String sectionType = 'malzemeler';
            // Auto-detect type from AI title
            if (bolumAdi != null) {
              String lower = bolumAdi.toLowerCase();
              if (lower.contains('sos')) {
                sectionType = 'sos';
              } else if (lower.contains('hamur')) {
                sectionType = 'hamur';
              } else if (lower.contains('iç') || lower.contains('harç')) {
                sectionType = 'harc';
              } else if (lower.contains('şerbet') || lower.contains('serbet')) {
                sectionType = 'serbet';
              } else if (lower.contains('püf') || lower.contains('ipucu')) {
                sectionType = 'puf_noktasi';
              }
            }

            if (malzemeler != null) {
              sections.add({
                'title': bolumAdi ?? 'recipe_section_ingredients'.tr(),
                'type': sectionType,
                'items': List<String>.from(malzemeler.map((e) => e.toString())),
                'isExpanded': true,
              });
            }
          }
        }
      }
    }

    if (aiData.containsKey('adimlar')) {
      var adimlar = aiData['adimlar'];
      if (adimlar is List) {
        sections.add({
          'title': 'recipe_section_instructions'.tr(),
          'type': 'yapilis',
          'items': List<String>.from(adimlar.map((e) => e.toString())),
          'isExpanded': true,
        });
      }
    }

    if (aiData.containsKey('puf_noktasi')) {
      var puf = aiData['puf_noktasi'];
      if (puf != null && puf.toString().isNotEmpty) {
        sections.add({
          'title': 'recipe_section_tips'.tr(),
          'type': 'puf_noktasi',
          'items': [puf.toString()],
          'isExpanded': true,
        });
      }
    }

    // Refresh UI
    if (mounted) setState(() {});
  }

  // Mevcut görselleri yükle
  void _loadExistingImages(List<String> existingImagePaths) {
    if (existingImagePaths.isNotEmpty) {
      setState(() {
        photos = existingImagePaths.map((path) => XFile(path)).toList();
      });
    }
  }

  bool _isNetworkUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  void dispose() {
    _aciklamaFocus.dispose();
    _scrollController.dispose();
    // Section controller'larını temizle
    for (var controller in sectionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _parseExistingTarif(String tarifAciklama) {
    if (widget.tarifData.tarif_aciklama_json != null &&
        widget.tarifData.tarif_aciklama_json!.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(
          widget.tarifData.tarif_aciklama_json!,
        );
        sections = decoded.map((e) {
          return {
            'title': e['title'],
            'type': e['type'],
            'items': List<String>.from(e['items'] ?? []),
            'isExpanded': e['isExpanded'] ?? true,
          };
        }).toList();
        return;
      } catch (e) {
        debugPrint('JSON parsing error in tarif_olusturma: $e');
      }
    }

    if (tarifAciklama.isEmpty) return;

    final lines = tarifAciklama.split('\n');
    String currentSection = '';
    String currentType = '';
    List<String> currentItems = [];

    // Tüm dillerde bölüm başlıklarını tanımla
    final ingredientTitles = [
      'malzemeler',
      'ingredients',
      'zutaten',
      'ingredientes',
      'ingrédients',
    ];
    final fillingTitles = [
      'harç',
      'filling',
      'füllung',
      'relleno',
      'garniture',
      'recheio',
    ];
    final doughTitles = ['hamuru', 'dough', 'teig', 'masa', 'pâte'];
    final syrupTitles = [
      'şerbeti',
      'syrup',
      'sirup',
      'almíbar',
      'sirop',
      'calda',
    ];
    final instructionTitles = [
      'yapılışı',
      'instructions',
      'anleitung',
      'instrucciones',
    ];
    final linkTitles = ['linkler', 'links', 'enlaces', 'liens'];
    final sauceTitles = ['sosu', 'sos', 'sauce', 'soße', 'salsa', 'molho'];
    final tipTitles = [
      'püf noktası',
      'püf noktalari',
      'püf noktaları',
      'tips',
      'tipps',
      'consejos',
      'astuces',
      'dicas',
    ];

    for (String line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final lowerTrimmed = trimmed.toLowerCase();

      // Başlık kontrolü - tüm diller
      if (ingredientTitles.contains(lowerTrimmed)) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed;
        currentType = 'malzemeler';
        currentItems = [];
      } else if (fillingTitles.contains(lowerTrimmed)) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed;
        currentType = 'harc';
        currentItems = [];
      } else if (doughTitles.contains(lowerTrimmed)) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed;
        currentType = 'hamur';
        currentItems = [];
      } else if (syrupTitles.contains(lowerTrimmed)) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed;
        currentType = 'serbet';
        currentItems = [];
      } else if (instructionTitles.contains(lowerTrimmed)) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed;
        currentType = 'yapilis';
        currentItems = [];
      } else if (linkTitles.contains(lowerTrimmed)) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed;
        currentType = 'linkler';
        currentItems = [];
      } else if (sauceTitles.contains(lowerTrimmed)) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed;
        currentType = 'sos';
        currentItems = [];
      } else if (tipTitles.contains(lowerTrimmed)) {
        _addSectionIfNotEmpty(currentSection, currentType, currentItems);
        currentSection = trimmed;
        currentType = 'puf_noktasi';
        currentItems = [];
      } else if (trimmed.startsWith('*') ||
          trimmed.startsWith('•') ||
          trimmed.startsWith('🔗') ||
          RegExp(r'^\d+\.').hasMatch(trimmed)) {
        // Madde ekle
        String item = trimmed;
        if (trimmed.startsWith('*') || trimmed.startsWith('•')) {
          item = trimmed.substring(1).trim();
        } else if (trimmed.startsWith('🔗')) {
          // Emoji'yi güvenli şekilde kaldır
          item = trimmed.replaceFirst('🔗', '').trim();
        } else {
          item = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        }
        if (item.isNotEmpty) {
          currentItems.add(item);
        }
      }
    }

    // Son section'ı ekle
    _addSectionIfNotEmpty(currentSection, currentType, currentItems);
  }

  void _addSectionIfNotEmpty(String title, String type, List<String> items) {
    if (title.isNotEmpty && items.isNotEmpty) {
      sections.add({'title': title, 'type': type, 'items': List.from(items)});
    }
  }

  void _editSectionItem(int sectionIndex, int itemIndex) {
    TextEditingController editController = TextEditingController(
      text: sections[sectionIndex]['items'][itemIndex],
    );
    showDialog(
      context: context,
      builder: (context) => KilDiyalog(
        baslik: 'recipe_edit_edit_item'.tr(),
        icerik: TextField(
          controller: editController,
          autofocus: true,
          maxLines: null,
        ),
        eylemler: [
          KilDugme.birincil(
            etiket: 'common_save'.tr(),
            tamGenislik: true,
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                setState(() {
                  sections[sectionIndex]['items'][itemIndex] = editController
                      .text
                      .trim();
                });
              }
              Navigator.pop(context);
            },
          ),
          KilDiyalogMetinDugmesi(
            etiket: 'common_cancel'.tr(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showBigPhoto(File file) {
    showDialog(
      context: context,
      builder: (context) => KilBuyukFoto(
        child: Image.file(file, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnsavedChanges =
        tfTaridAdi.text.isNotEmpty || sections.isNotEmpty || photos.isNotEmpty;
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Geri tuşuna basıldığında uyarı göster (yalnızca kaydedilmemiş veri varken buraya düşer)
        final confirmDiscard = await KilDiyalog.onayIste(
          context,
          ikon: Icons.warning_amber_rounded,
          tehlikeli: true,
          baslik: 'recipe_edit_discard_title'.tr(),
          mesaj: 'recipe_edit_discard_message'.tr(),
          onayEtiketi: 'recipe_edit_discard_exit'.tr(),
          vazgecEtiketi: 'recipe_edit_discard_keep'.tr(),
        );
        if (confirmDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: KilIcSayfa(
        baslik: widget.tarifData.tarif_id > 0
            ? 'recipe_edit_appbar_edit'.tr()
            : 'recipe_edit_appbar_add'.tr(),
        kaydirma: _scrollController,
        eylemler: [
          KilYuvarlakDugme(
            ikon: Icons.photo_camera_rounded,
            etiket: 'recipe_edit_add_photo_tooltip'.tr(),
            onPressed: _fotografSec,
          ),
        ],
        icerik: [
          // Fotoğraf ekle düğmesi ve eklenen fotoğraflar
          TarifFotoSeridi(
            yollar: [for (final photo in photos) photo.path],
            ekleEtiketi: 'recipe_edit_add_photo_tooltip'.tr(),
            silEtiketi: 'recipe_edit_delete_photo'.tr(),
            yuklenemediMetni: 'image_load_error'.tr(),
            bulunamadiMetni: 'image_not_found'.tr(),
            onEkle: _fotografSec,
            onSil: (i) {
              setState(() {
                photos.removeAt(i);
              });
            },
            onBuyut: (i) {
              if (File(photos[i].path).existsSync()) {
                _showBigPhoto(File(photos[i].path));
              }
            },
          ),

          // Tarif adı
          KilKart(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: tfTaridAdi,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'recipe_edit_name_label'.tr(),
                hintText: 'recipe_edit_name_hint'.tr(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),

          TarifBolumlerBasligi(
            baslik: 'recipe_edit_sections_label'.tr(),
            ekleEtiketi: 'recipe_edit_add_section_button'.tr(),
            onEkle: _showSectionMenu,
          ),

          for (var secIndex = 0; secIndex < sections.length; secIndex++)
            TarifBolumDuzenleKarti(
              tur: sections[secIndex]['type'] ?? '',
              baslik: sections[secIndex]['title'] ?? '',
              maddeler: [
                for (final madde in sections[secIndex]['items']) '$madde',
              ],
              controller: sectionControllers[secIndex] ??=
                  TextEditingController(),
              ipucu: sections[secIndex]['type'] == 'yapilis'
                  ? 'recipe_edit_step_placeholder'.tr()
                  : 'recipe_edit_item_placeholder'.tr(),
              bolumuSilEtiketi: 'recipe_edit_delete_section'.tr(),
              maddeyiSilEtiketi: 'recipe_edit_delete_item'.tr(),
              maddeEkleEtiketi: 'recipe_edit_add_item'.tr(),
              onBolumuSil: () {
                setState(() {
                  sections.removeAt(secIndex);
                });
              },
              onMaddeDuzenle: (i) => _editSectionItem(secIndex, i),
              onMaddeSil: (i) {
                setState(() {
                  sections[secIndex]['items'].removeAt(i);
                });
              },
              onMaddeEkle: (val) => _maddeEkle(secIndex, val),
              onBaglantiAc: (adres) => launchRecipeUrl(context, adres),
            ),

          const SizedBox(height: 8),
          KilDugme.birincil(
            etiket: 'recipe_edit_save_button'.tr(),
            ikon: Icons.check_rounded,
            tamGenislik: true,
            onPressed: _kaydet,
          ),
        ],
        altCubuk: const BannerAdWidget(),
      ),
    );
  }

  Future<void> _fotografSec() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked.isNotEmpty) {
      setState(() {
        photos.addAll(picked);
      });
    }
  }

  /// Enter'a ya da "+" düğmesine basınca maddeyi ekler ve kutuyu temizler
  /// (klavye açık kalırsa art arda madde eklenebilir).
  void _maddeEkle(int secIndex, String val) {
    if (val.trim().isEmpty) return;
    setState(() {
      sections[secIndex]['items'].add(val.trim());
    });
    sectionControllers[secIndex]?.clear();
  }

  Future<void> _kaydet() async {
    // Tarif adı kontrolü
    if (tfTaridAdi.text.trim().isEmpty) {
      KilBildirim.goster(
        context,
        'recipe_edit_error_no_name'.tr(),
        tur: KilBildirimTuru.hata,
      );
      return;
    }

    // En az bir section olmalı
    if (sections.isEmpty) {
      KilBildirim.goster(
        context,
        'recipe_edit_error_no_section'.tr(),
        tur: KilBildirimTuru.hata,
      );
      return;
    }

    // En az bir madde olmalı
    bool hasItems = false;
    for (var section in sections) {
      if (section['items'].isNotEmpty) {
        hasItems = true;
        break;
      }
    }

    if (!hasItems) {
      KilBildirim.goster(
        context,
        'recipe_edit_error_no_item'.tr(),
        tur: KilBildirimTuru.hata,
      );
      return;
    }

    // Sections verilerini tarif açıklamasına dönüştür
    String tarifAciklama = '';
    for (var section in sections) {
      tarifAciklama += '\n${section['title']}\n';
      if (section['type'] == 'yapilis') {
        for (int i = 0; i < section['items'].length; i++) {
          tarifAciklama += '${i + 1}. ${section['items'][i]}\n';
        }
      } else if (section['type'] == 'linkler') {
        for (String item in section['items']) {
          tarifAciklama += '🔗 $item\n';
        }
      } else {
        for (String item in section['items']) {
          tarifAciklama += '* $item\n';
        }
      }
    }

    // Görselleri işle ve kaydet
    List<String> resimYollari = [];

    // Fotoğraflar yalnızca cihazdaki kalıcı klasöre kopyalanır. Buluta
    // yükleme burada beklenmez; tarifi kaydeden sayfa arkadan yükler
    // (bkz. tarifiArkadanBulutaGonder). Böylece internet yokken ya da
    // yavaşken kaydetme takılmaz.
    for (var photo in photos) {
      if (_isNetworkUrl(photo.path)) {
        resimYollari.add(photo.path);
      } else {
        resimYollari.add(await _copyImageToPermanentLocation(photo.path));
      }
    }

    debugPrint('Kaydedilecek görsel sayısı: ${resimYollari.length}');
    debugPrint('Görsel yolları: $resimYollari');

    String tarifAciklamaJson = '';
    try {
      tarifAciklamaJson = json.encode(sections);
    } catch (e) {
      debugPrint('Error encoding JSON: $e');
    }

    if (mounted) {
      Navigator.pop(
        context,
        TarifData(
          tarif_id: widget.tarifData.tarif_id,
          tarif_adi: tfTaridAdi.text.trim(),
          tarif_aciklama: tarifAciklama.trim(),
          tarif_aciklama_json: tarifAciklamaJson,
          tarif_resimler: resimYollari,
          klasor_id: widget.tarifData.klasor_id,
          // Düzenleme sırasında favori durumu korunmalı;
          // aksi halde her düzenleme favori işaretini
          // sessizce sıfırlıyordu.
          isFavorite: widget.tarifData.isFavorite,
        ),
      );
    }
  }

  void _showSectionMenu() {
    KilAltSayfa.goster<void>(
      context,
      baslik: 'recipe_edit_select_section_title'.tr(),
      builder: (sayfaContext) => KilSecimListesi(
        secenekler: [
          for (final section in _getAvailableSections())
            KilSecenek(
              ikon: tarifBolumIkonu(section['type']),
              etiket: section['title'],
              onTap: () {
                Navigator.pop(sayfaContext);
                _addSection(section['type']);
              },
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableSections() {
    List<Map<String, dynamic>> allSections = [
      {'type': 'malzemeler', 'title': 'recipe_section_ingredients'.tr()},
      {'type': 'harc', 'title': 'recipe_section_filling'.tr()},
      {'type': 'yapilis', 'title': 'recipe_section_instructions'.tr()},
      {'type': 'hamur', 'title': 'recipe_section_dough'.tr()},
      {'type': 'serbet', 'title': 'recipe_section_syrup'.tr()},
      {'type': 'sos', 'title': 'recipe_section_sauce'.tr()},
      {'type': 'puf_noktasi', 'title': 'recipe_section_tips'.tr()},
      {'type': 'linkler', 'title': 'recipe_section_links'.tr()},
    ];

    // Mevcut section'ları filtrele
    return allSections.where((section) {
      return !sections.any(
        (existingSection) => existingSection['type'] == section['type'],
      );
    }).toList();
  }

  void _addSection(String type) {
    // Eğer bu türde section yoksa ekle
    bool sectionExists = sections.any((section) => section['type'] == type);
    if (!sectionExists) {
      Map<String, dynamic> yeniSection = {
        'title': _getSectionTitle(type),
        'type': type,
        'items': [],
      };
      setState(() {
        sections.add(yeniSection);
      });

      // Yeni bölüm eklendikten sonra ekranı o bölüme (en alta) kaydır
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  String _getSectionTitle(String type) {
    switch (type) {
      case 'malzemeler':
        return 'recipe_section_ingredients'.tr();
      case 'harc':
        return 'recipe_section_filling'.tr();
      case 'yapilis':
        return 'recipe_section_instructions'.tr();
      case 'hamur':
        return 'recipe_section_dough'.tr();
      case 'serbet':
        return 'recipe_section_syrup'.tr();
      case 'linkler':
        return 'recipe_section_links'.tr();
      case 'sos':
        return 'recipe_section_sauce'.tr();
      case 'puf_noktasi':
        return 'recipe_section_tips'.tr();
      default:
        return '';
    }
  }
}

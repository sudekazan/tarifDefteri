import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/banner_ad_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/ai_recipe_service.dart';
import '../services/firebase_service.dart';
import '../utils/error_helper.dart';

class TarifOlusturma extends StatefulWidget {
  @override
  State<TarifOlusturma> createState() => _TarifOlusturmaState();
  TarifData tarifData;
  final Map<String, dynamic>? aiResultMap;
  final bool isManual;

  TarifOlusturma({required this.tarifData, this.aiResultMap, this.isManual = false});
}

class _TarifOlusturmaState extends State<TarifOlusturma> {
  var tfTaridAdi = TextEditingController();
  final FocusNode _aciklamaFocus = FocusNode();
  List<Map<String, dynamic>> sections = [];
  List<XFile> photos = [];
  final ImagePicker _picker = ImagePicker();
  
  // Her section için TextField controller'ı
  Map<int, TextEditingController> sectionControllers = {};
  
  bool isAiGenerated = false;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isUploading = false;

  // Görseli kalıcı klasöre kopyala
  Future<String> _copyImageToPermanentLocation(String sourcePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'tarif_images');
      
      // Eğer dosya zaten kalıcı klasördeyse, tekrar kopyalama
      if (sourcePath.contains('tarif_images')) {
        print('Görsel zaten kalıcı klasörde: $sourcePath');
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

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourcePath)}';
      final String destinationPath = path.join(imagesDir, fileName);
      final File destinationFile = File(destinationPath);

      await File(sourcePath).copy(destinationPath);
      // Kopyalanan dosyanın var olduğunu doğrula
      if (await destinationFile.exists()) {
        print('Görsel başarıyla kopyalandı: $destinationPath');
        return destinationFile.path;
      } else {
        throw Exception('Dosya kopyalanamadı');
      }
    } catch (e) {
      print('HATA - Görsel kopyalama hatası: $e');
      print('HATA - Kaynak yol: $sourcePath');
      // Hata durumunda boş string döndür (çarpı işareti yerine görsel gösterme)
      return '';
    }
  }

  Future<void> tarifiKaydet(String tarif_adi, String tarif_aciklama) async {
    print("Tarif Kayıt Edildi: ${tarif_adi} - ${tarif_aciklama}");
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
            'items': []
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
                if (lower.contains('sos')) sectionType = 'sos';
                else if (lower.contains('hamur')) sectionType = 'hamur';
                else if (lower.contains('iç') || lower.contains('harç')) sectionType = 'harc';
                else if (lower.contains('şerbet') || lower.contains('serbet')) sectionType = 'serbet';
                else if (lower.contains('püf') || lower.contains('ipucu')) sectionType = 'puf_noktasi';
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
           'title': 'Püf Noktası',
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
    // Section controller'larını temizle
    for (var controller in sectionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  void _parseExistingTarif(String tarifAciklama) {
    if (tarifAciklama.isEmpty) return;
    
    final lines = tarifAciklama.split('\n');
    String currentSection = '';
    String currentType = '';
    List<String> currentItems = [];
    
    // Tüm dillerde bölüm başlıklarını tanımla
    final ingredientTitles = ['malzemeler', 'ingredients', 'zutaten', 'ingredientes', 'ingrédients'];
    final fillingTitles = ['harç', 'filling', 'füllung', 'relleno', 'garniture', 'recheio'];
    final doughTitles = ['hamuru', 'dough', 'teig', 'masa', 'pâte'];
    final syrupTitles = ['şerbeti', 'syrup', 'sirup', 'almíbar', 'sirop', 'calda'];
    final instructionTitles = ['yapılışı', 'instructions', 'anleitung', 'instrucciones'];
    final linkTitles = ['linkler', 'links', 'enlaces', 'liens'];
    final sauceTitles = ['sosu', 'sos', 'sauce', 'soße', 'salsa', 'molho'];
    final tipTitles = ['püf noktası', 'püf noktalari', 'püf noktaları', 'tips', 'tipps', 'consejos', 'astuces', 'dicas'];
    
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
      } else if (trimmed.startsWith('*') || trimmed.startsWith('•') || trimmed.startsWith('🔗') || RegExp(r'^\d+\.').hasMatch(trimmed)) {
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
      sections.add({
        'title': title,
        'type': type,
        'items': List.from(items),
      });
    }
  }

  // Yapay Zeka ile Tarif Oluştur
  Future<void> _generateRecipeWithAI() async {
    // Yemek adı boşsa uyarı ver
    if (tfTaridAdi.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ai_name_warning'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Yükleniyor dialogu göster - İyileştirilmiş UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
             color: Theme.of(context).cardColor,
             borderRadius: BorderRadius.circular(24),
             boxShadow: [
               BoxShadow(
                 color: Colors.black26,
                 blurRadius: 16,
                 offset: Offset(0, 4),
               )
             ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Özel bir animasyonlu ikon yerine şimdilik renkli progress indicator
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'ai_generating_title'.tr(),
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'ai_generating_message'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final aiService = AiRecipeService();
      final recipeData = await aiService.generateRecipe(tfTaridAdi.text.trim());
      
      // Dialogu kapat
      Navigator.pop(context);

      // Gelen veriyi form alanlarına doldur
      setState(() {
        // Mevcut bölümleri temizle
        sections.clear();
        
        // --- MALZEMELER PARSING ---
        var icindekilerData = recipeData['icindekiler'] ?? recipeData['ingredients'];
        
        // 1. Durum: icindekiler bir liste (Beklenen format)
        if (icindekilerData != null && icindekilerData is List) {
          for (var bolum in icindekilerData) {
             if (bolum is! Map) continue; // Hatalı format koruması

             String bolumAdi = bolum['bolum_adi'] ?? bolum['section_name'] ?? bolum['title'] ?? 'Genel';
             var mData = bolum['malzemeler'] ?? bolum['ingredients'] ?? [];
             List<String> malzemeler = [];
             
             if (mData is List) {
               malzemeler = List<String>.from(mData.map((e) => e.toString()));
             } else if (mData is String) {
               malzemeler = mData.split('\n').where((e) => e.trim().isNotEmpty).toList();
             }
             
             String title = bolumAdi == 'Genel' ? 'recipe_section_ingredients'.tr() : bolumAdi;
             
             // Tip belirle
             String type = 'malzemeler';
             String lowerTitle = title.toLowerCase();
             
             if (lowerTitle.contains('sos') || lowerTitle.contains('sauce')) type = 'sos'; 
             else if (lowerTitle.contains('hamur') || lowerTitle.contains('dough')) type = 'hamur';
             else if (lowerTitle.contains('şerbet') || lowerTitle.contains('serbet') || lowerTitle.contains('syrup')) type = 'serbet';
             else if (lowerTitle.contains('harç') || lowerTitle.contains('harc') || lowerTitle.contains('filling')) type = 'harc';
             
             _addSectionIfNotEmpty(title, type, malzemeler);
          }
        } 
        // 2. Durum: icindekiler yerine direkt üst seviyede malzemeler var (Tekdüze format)
        else {
           var flatMalzemeler = recipeData['malzemeler'] ?? recipeData['ingredients'];
           if (flatMalzemeler != null) {
              List<String> list = [];
              if (flatMalzemeler is List) {
                list = List<String>.from(flatMalzemeler.map((e) => e.toString()));
              } else if (flatMalzemeler is String) {
                list = flatMalzemeler.split('\n').where((e) => e.trim().isNotEmpty).toList();
              }
              _addSectionIfNotEmpty('recipe_section_ingredients'.tr(), 'malzemeler', list);
           }
        }

        // --- ADIMLAR PARSING ---
        var adimlarData = recipeData['adimlar'] ?? recipeData['steps'] ?? recipeData['instructions'];
        if (adimlarData != null) {
          List<String> adimlar = [];
          if (adimlarData is List) {
             adimlar = List<String>.from(adimlarData.map((e) => e.toString()));
          } else if (adimlarData is String) {
             adimlar = adimlarData.split('\n').where((e) => e.trim().isNotEmpty).toList();
          }
          
          _addSectionIfNotEmpty(
            'recipe_section_instructions'.tr(), 
            'yapilis', 
            adimlar
          );
        }

        // --- PÜF NOKTASI PARSING ---
        var pufData = recipeData['puf_noktasi'] ?? recipeData['tips'] ?? recipeData['tip'] ?? recipeData['chef_notes'];
        if (pufData != null && pufData.toString().isNotEmpty) {
           _addSectionIfNotEmpty(
            'Püf Noktası', 
            'puf_noktasi', 
            [pufData.toString()]
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ai_success_message'.tr()), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      setState(() {
        isAiGenerated = true;
      });


    } catch (e) {
      // Dialogu kapat
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'ai_error_title'.tr()}: ${ErrorHelper.getFriendlyErrorMessage(e)}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  


  void _showBigPhoto(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Geri tuşuna basıldığında uyarı göster
        if (tfTaridAdi.text.isNotEmpty || sections.isNotEmpty || photos.isNotEmpty) {
          // İlk kez oluşturuyor mu yoksa düzenliyor mu kontrol et
          bool isEditing = widget.tarifData.tarif_adi.isNotEmpty;
          
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İkon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Başlık
                  Text(
                    'recipe_edit_discard_title'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Açıklama
                  Text(
                    'recipe_edit_discard_message'.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'recipe_edit_discard_keep'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'recipe_edit_discard_exit'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          return result ?? false;
        }
        return true; // Hiçbir veri yoksa direkt çık
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tarifData.tarif_id > 0 ? 'recipe_edit_appbar_edit'.tr() : 'recipe_edit_appbar_add'.tr()),
          actions: [
            IconButton(
              icon: Icon(Icons.photo_camera, color: Theme.of(context).iconTheme.color),
              onPressed: () async {
                final picked = await _picker.pickMultiImage();
                if (picked != null && picked.isNotEmpty) {
                  setState(() {
                    photos.addAll(picked);
                  });
                }
              },
              tooltip: 'recipe_edit_add_photo_tooltip'.tr(),
            ),
          ],
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Görsel Önizleme Carousel (Yatay Liste)
                    Container(
                      height: 140,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Fotoğraf Ekle Butonu (Kart şeklinde)
                          GestureDetector(
                            onTap: () async {
                              final picked = await _picker.pickMultiImage();
                              if (picked != null && picked.isNotEmpty) {
                                setState(() {
                                  photos.addAll(picked);
                                });
                              }
                            },
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, 
                                    size: 32, 
                                    color: Theme.of(context).primaryColor
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'recipe_edit_add_photo_tooltip'.tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Eklenen Fotoğraflar
                          ...photos.map((photo) => Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                // Fotoğraf Kartı
                                Card(
                                  elevation: 4,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (File(photo.path).existsSync()) {
                                          _showBigPhoto(File(photo.path));
                                        }
                                      },
                                      child: _isNetworkUrl(photo.path)
                                        ? Image.network(
                                            photo.path,
                                            width: 120,
                                            height: 140,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Icon(Icons.broken_image, color: Colors.grey[400]),
                                              );
                                            },
                                          )
                                        : File(photo.path).existsSync()
                                          ? Image.file(
                                              File(photo.path),
                                              width: 120,
                                              height: 140,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(Icons.broken_image, color: Colors.grey[400]),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                            ),
                                    ),
                                  ),
                                ),
                                // Silme Butonu (Sağ Üst)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        photos.remove(photo);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'recipe_edit_name_label'.tr(),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: tfTaridAdi,
                            decoration: InputDecoration(
                              hintText: 'recipe_edit_name_hint'.tr(),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'recipe_edit_sections_label'.tr(),
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                  
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showSectionMenu();
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: Text('recipe_edit_add_section_button'.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                   // Dinamik başlık ve içerik ekleme alanları açıklama kutusunun ALTINA taşındı
                   ...sections.asMap().entries.map((entry) {
                      int secIndex = entry.key;
                      var section = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        color: Theme.of(context).cardColor,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık ve silme butonu
                              Row(
                                children: [
                                  Icon(
                                    _getSectionIcon(section['type']),
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      section['title'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Theme.of(context).textTheme.bodyLarge?.color
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        sections.removeAt(secIndex);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              // İçerik listesi - daha kompakt tasarım
                              if (section['items'].isNotEmpty) ...[
                                ...List.generate(section['items'].length, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        // Numaralandırma veya bullet point
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: section['type'] == 'yapilis'
                                                ? Text(
                                                    "${i + 1}",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).primaryColor,
                                                      fontSize: 14,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.circle,
                                                    size: 10,
                                                    color: Theme.of(context).primaryColor.withOpacity(0.6),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Madde metni
                                        Expanded(
                                          child: section['type'] == 'linkler' && _isValidUrl(section['items'][i])
                                              ? InkWell(
                                                  onTap: () => _launchUrl(section['items'][i]),
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.link,
                                                          size: 16,
                                                          color: Theme.of(context).primaryColor,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            section['items'][i],
                                                            style: TextStyle(
                                                              color: Theme.of(context).primaryColor,
                                                              fontSize: 16,
                                                              decoration: TextDecoration.underline,
                                                              decorationColor: Theme.of(context).primaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  section['items'][i],
                                                  style: TextStyle(
                                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                        ),
                                        // Silme butonu
                                        IconButton(
                                          icon: Icon(Icons.clear, size: 20, color: Theme.of(context).primaryColor),
                                          onPressed: () {
                                            setState(() {
                                              section['items'].removeAt(i);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                              // Tek TextField
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: sectionControllers[secIndex] ??= TextEditingController(),
                                        decoration: InputDecoration(
                                          hintText: section['type'] == 'yapilis' ? 'recipe_edit_step_placeholder'.tr() : 'recipe_edit_item_placeholder'.tr(),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.all(16),
                                        ),
                                        onSubmitted: (val) {
                                          // Enter'a basınca malzeme ekle
                                          if (val.trim().isNotEmpty) {
                                            setState(() {
                                              section['items'].add(val.trim());
                                            });
                                            // TextField'ı temizle
                                            final controller = sectionControllers[secIndex];
                                            if (controller != null) {
                                              controller.clear();
                                              // Focus'u koru
                                              Future.delayed(const Duration(milliseconds: 50), () {
                                                if (mounted) {
                                                  // TextField'a tekrar focus ver
                                                  FocusScope.of(context).requestFocus(
                                                    FocusNode()..requestFocus()
                                                  );
                                                }
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.add_circle,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        onPressed: () {
                                          // + butonuna basarak malzeme ekle
                                          final controller = sectionControllers[secIndex];
                                          if (controller != null && controller.text.trim().isNotEmpty) {
                                            setState(() {
                                              section['items'].add(controller.text.trim());
                                            });
                                            // TextField'ı temizle
                                            controller.clear();
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          // Tarif adı kontrolü
                          if (tfTaridAdi.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('recipe_edit_error_no_name'.tr()),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          // En az bir section olmalı
                          if (sections.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('recipe_edit_error_no_section'.tr()),
                                backgroundColor: Colors.red,
                              ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('recipe_edit_error_no_item'.tr()),
                                backgroundColor: Colors.red,
                              ),
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
                          
                          if (photos.isNotEmpty) {
                            // Loading göster
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              for (var photo in photos) {
                                if (_isNetworkUrl(photo.path)) {
                                  // Zaten bulutta olan görsel
                                  resimYollari.add(photo.path);
                                } else {
                                  // Yeni yerel görsel - önce yerel hafızaya kopyala
                                  String localPath = await _copyImageToPermanentLocation(photo.path);
                                  
                                  // Eğer kullanıcı giriş yapmışsa buluta yükle
                                  if (_firebaseService.isUserLoggedIn && localPath.isNotEmpty) {
                                    String? cloudUrl = await _firebaseService.uploadImage(File(localPath));
                                    if (cloudUrl != null) {
                                      resimYollari.add(cloudUrl);
                                    } else {
                                      resimYollari.add(localPath); // Yükleme başarısızsa yerel yolu tut
                                    }
                                  } else {
                                    resimYollari.add(localPath);
                                  }
                                }
                              }
                            } catch (e) {
                              print('Görsel işleme hatası: $e');
                            } finally {
                              // Loading kapat
                              if (mounted) Navigator.pop(context);
                            }
                          }
                          
                          print('Kaydedilecek görsel sayısı: ${resimYollari.length}');
                          print('Görsel yolları: $resimYollari');
                          
                          if (mounted) {
                            Navigator.pop(context, TarifData(
                              tarif_id: widget.tarifData.tarif_id,
                              tarif_adi: tfTaridAdi.text.trim(),
                              tarif_aciklama: tarifAciklama.trim(),
                              tarif_resimler: resimYollari,
                              klasor_id: widget.tarifData.klasor_id,
                            ));
                          }
                        },
                        child: Text(
                          'recipe_edit_save_button'.tr(),
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }

  void _showSectionMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'recipe_edit_select_section_title'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _getAvailableSections().map((section) => ListTile(
                  leading: Icon(
                    _getSectionIcon(section['type']),
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(section['title']),
                  onTap: () {
                    Navigator.pop(context);
                    _addSection(section['type']);
                  },
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
      {'type': 'sos', 'title': 'Sosu'},
      {'type': 'puf_noktasi', 'title': 'Püf Noktası'},
      {'type': 'linkler', 'title': 'recipe_section_links'.tr()},
    ];

    // Mevcut section'ları filtrele
    return allSections.where((section) {
      return !sections.any((existingSection) => existingSection['type'] == section['type']);
    }).toList();
  }

  void _addSection(String type) {
    // Eğer bu türde section yoksa ekle
    bool sectionExists = sections.any((section) => section['type'] == type);
    if (!sectionExists) {
      Map<String, dynamic> yeniSection = {
        'title': _getSectionTitle(type),
        'type': type,
        'items': []
      };
      setState(() {
        sections.add(yeniSection);
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
        return 'Sosu';
      case 'puf_noktasi':
        return 'Püf Noktası';
      default:
        return '';
    }
  }

  IconData _getSectionIcon(String type) {
    switch (type) {
      case 'malzemeler':
        return Icons.shopping_basket;
      case 'harc':
        return Icons.blender;
      case 'yapilis':
        return Icons.format_list_numbered;
      case 'hamur':
        return Icons.circle;
      case 'serbet':
        return Icons.water_drop;
      case 'linkler':
        return Icons.link;
      case 'sos':
        return Icons.soup_kitchen;
      case 'puf_noktasi':
        return Icons.lightbulb;
      default:
        return Icons.category;
    }
  }

  // Link mi kontrol eder
  bool _isValidUrl(String text) {
    // URL veya domain içeriyorsa link olarak kabul et
    final urlPattern = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$',
      caseSensitive: false,
    );
    // Daha basit kontrol: nokta içeriyor ve boşluk yok
    bool hasValidFormat = text.contains('.') && !text.contains(' ') && text.length > 3;
    return urlPattern.hasMatch(text) || (hasValidFormat && (text.startsWith('http') || text.startsWith('www') || text.contains('.com') || text.contains('.net') || text.contains('.org') || text.contains('.tr')));
  }

  // Linki açar
  Future<void> _launchUrl(String url) async {
    try {
      // Eğer URL http/https ile başlamıyorsa ekle
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Eğer açılmazsa kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'link_cannot_open_prefix'.tr()}$url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'link_invalid_prefix'.tr()}$url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

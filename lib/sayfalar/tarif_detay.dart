import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/services/firebase_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:tarif_defteri/sayfalar/tarif_olusturma.dart';
import 'package:tarif_defteri/sayfalar/yemek_yapma_modu.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/banner_ad_widget.dart';

class TarifDetay extends StatefulWidget {
  final TarifData tarif;

  const TarifDetay({super.key, required this.tarif});

  @override
  State<TarifDetay> createState() => _TarifDetayState();
}

class _TarifDetayState extends State<TarifDetay> {
  List<Map<String, dynamic>> sections = [];
  double _portionMultiplier = 1.0;

  String _scaleIngredient(String ingredient, double multiplier) {
    if (multiplier == 1.0) return ingredient;
    
    // İlk rakamı veya kesri eşleştir
    final regExp = RegExp(r'(?:^|\s)(\d+(?:[.,]\d+)?(?:\/\d+)?)(?=\s|$)');
    
    var match = regExp.firstMatch(ingredient);
    if (match != null) {
      String numStr = match.group(1)!;
      double? val;
      if (numStr.contains('/')) {
        var parts = numStr.split('/');
        val = double.parse(parts[0]) / double.parse(parts[1]);
      } else {
        val = double.tryParse(numStr.replaceAll(',', '.'));
      }
      
      if (val != null) {
        double scaled = val * multiplier;
        String result = scaled.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
        return ingredient.replaceFirst(numStr, result, match.start);
      }
    }
    return ingredient;
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('recipe_detail_add_to_cart'.tr()),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
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
        print('JSON parsing error in tarif_detay: $e');
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
      case 'sos':
        return Icons.soup_kitchen;
      case 'puf_noktasi':
        return Icons.lightbulb;
      case 'linkler':
        return Icons.link;
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

  void _showBigPhoto(String imagePath) {
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
              child: imagePath.startsWith('http')
                  ? Image.network(imagePath, fit: BoxFit.contain)
                  : Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(IconData icon, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tarif.tarif_adi,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          // Paylaş butonu
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.share, color: Theme.of(context).iconTheme.color),
                onPressed: () async {
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
                    
                    // iOS için butonun konumunu al
                    final box = context.findRenderObject() as RenderBox?;
                    final sharePositionOrigin = box!.localToGlobal(Offset.zero) & box.size;
                    
                    await Share.share(
                      shareText,
                      subject: widget.tarif.tarif_adi,
                      sharePositionOrigin: sharePositionOrigin,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${'share_error_with_message_prefix'.tr()}$e',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                tooltip: 'recipe_detail_share_tooltip'.tr(),
              );
            },
          ),
          // Taşı Butonu
          IconButton(
            icon: Icon(Icons.drive_file_move_outline, color: Theme.of(context).iconTheme.color),
            onPressed: () => _showMoveDialog(context),
            tooltip: 'folders_move'.tr,
          ),
          // Düzenle butonu
          IconButton(
            icon: Icon(Icons.edit, color: Theme.of(context).iconTheme.color),
            onPressed: () async {
              final guncelTarif = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TarifOlusturma(tarifData: widget.tarif),
                ),
              );
              if (guncelTarif != null && guncelTarif is TarifData) {
                Navigator.pop(context, guncelTarif);
              }
            },
            tooltip: 'recipe_detail_edit_tooltip'.tr(),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Görseller
              if (widget.tarif.tarif_resimler.isNotEmpty)
                Container(
                  height: 280,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: PageView.builder(
                    itemCount: widget.tarif.tarif_resimler.length,
                    itemBuilder: (context, index) {
                      final imagePath = widget.tarif.tarif_resimler[index];
                      return GestureDetector(
                        onTap: () => _showBigPhoto(imagePath),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Görseli göster
                                imagePath.startsWith('http')
                                    ? Image.network(
                                        imagePath,
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
                                            color: Colors.grey[300],
                                            child: _buildErrorWidget(Icons.broken_image, 'image_load_error'.tr()),
                                          );
                                        },
                                      )
                                    : File(imagePath).existsSync()
                                        ? Image.file(
                                            File(imagePath),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: _buildErrorWidget(Icons.broken_image, 'image_load_error'.tr()),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: _buildErrorWidget(Icons.image_not_supported, 'image_not_found'.tr()),
                                          ),
                                // Görsel sayısını göster
                                if (widget.tarif.tarif_resimler.length > 1)
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${index + 1} / ${widget.tarif.tarif_resimler.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Tarif adı ve favori durumu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.tarif.tarif_adi,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.headlineMedium?.color,
                      ),
                    ),
                  ),
                  if (widget.tarif.isFavorite)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Porsiyon Ayarlama
              if (sections.any((s) => s['type'] == 'malzemeler' || s['type'] == 'harc' || s['type'] == 'hamur'))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'recipe_detail_portions'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            )
                          ]
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _portionMultiplier > 0.5 ? () {
                                setState(() {
                                  _portionMultiplier -= 0.5;
                                });
                              } : null,
                            ),
                            Text(
                              '${_portionMultiplier}x',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _portionMultiplier += 0.5;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

              // Bölümleri göster
              if (sections.isNotEmpty)
                ...sections.map((section) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getSectionIcon(section['type']),
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  section['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          // İçerik listesi
                          ...List.generate(section['items'].length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Numaralandırma veya bullet point
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: section['type'] == 'yapilis'
                                          ? Text(
                                              "${i + 1}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                                fontSize: 16,
                                              ),
                                            )
                                          : Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Theme.of(context).primaryColor,
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
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.link,
                                                    size: 18,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      section['items'][i],
                                                      style: const TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 16,
                                                        decoration: TextDecoration.underline,
                                                        decorationColor: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              (section['type'] == 'malzemeler' || section['type'] == 'harc' || section['type'] == 'hamur' || section['type'] == 'serbet' || section['type'] == 'sos')
                                                  ? _scaleIngredient(section['items'][i], _portionMultiplier)
                                                  : section['items'][i],
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                                fontSize: 16,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (section['type'] == 'malzemeler' || section['type'] == 'harc' || section['type'] == 'hamur' || section['type'] == 'serbet' || section['type'] == 'sos')
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart, size: 22),
                                      color: Colors.grey,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        String scaled = _scaleIngredient(section['items'][i], _portionMultiplier);
                                        _addToShoppingList(scaled);
                                      },
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),

              // Eğer section yoksa (eski format) açıklamayı göster
              if (sections.isEmpty && widget.tarif.tarif_aciklama.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'recipe_detail_description_title'.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          widget.tarif.tarif_aciklama,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YemekYapmaModu(tarif: widget.tarif, portionMultiplier: _portionMultiplier),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.restaurant, color: Colors.white),
        label: Text(
          'recipe_detail_cooking_mode'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
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
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'folders_select_move'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: klasorler.length,
                  itemBuilder: (context, index) {
                    final klasorMap = klasorler[index];
                    int kId = klasorMap['klasor_id'] ?? (index + 1);
                    if (kId == widget.tarif.klasor_id) return const SizedBox.shrink(); // Zaten bu klasörde
                    
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
                    
                    return ListTile(
                      leading: Icon(Icons.folder, color: Theme.of(context).primaryColor),
                      title: Text(displayName),
                      onTap: () async {
                        Navigator.pop(context);
                        await _moveTarif(kId);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('folders_move_success'.tr),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context, true); // Pop the screen and return true to indicate change
  }
}



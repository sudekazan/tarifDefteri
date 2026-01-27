import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/sayfalar/tarif_olusturma.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../services/ai_recipe_service.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';

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
    AdService.loadInterstitialAd();
  }

  Future<void> _tarifleriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    setState(() {
      tarifListesi = tariflerJson.map((e) {
        var map = json.decode(e);
        return TarifData(
          tarif_id: map['tarif_id'],
          tarif_adi: map['tarif_adi'],
          tarif_aciklama: map['tarif_aciklama'],
          tarif_resimler: map['tarif_resimler'] != null
              ? List<String>.from(map['tarif_resimler'])
              : map['tarif_resim'] != null && map['tarif_resim'].isNotEmpty
                  ? [map['tarif_resim']]
                  : [],
          klasor_id: map['klasor_id'],
          isFavorite: map['isFavorite'] ?? false,
        );
      }).toList();
      filtreliTarifler = List.from(tarifListesi);
    });
  }

  void _filtreleTarifler(String arama) {
    setState(() {
      if (arama.isEmpty) {
        filtreliTarifler = List.from(tarifListesi);
      } else {
        filtreliTarifler = tarifListesi.where((tarif) =>
          tarif.tarif_adi.toLowerCase().contains(arama.toLowerCase()) ||
          tarif.tarif_aciklama.toLowerCase().contains(arama.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _tarifEkle(TarifData yeniTarif) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    yeniTarif.tarif_id = tariflerJson.length + 1;
    tariflerJson.add(json.encode({
      'tarif_id': yeniTarif.tarif_id,
      'tarif_adi': yeniTarif.tarif_adi,
      'tarif_aciklama': yeniTarif.tarif_aciklama,
      'tarif_resimler': yeniTarif.tarif_resimler,
      'klasor_id': yeniTarif.klasor_id,
      'isFavorite': yeniTarif.isFavorite,
    }));
    await prefs.setStringList(key, tariflerJson);
    
    // Firebase'e de kaydet
    await _firebaseService.saveTarifToFirebase(yeniTarif);
    
    _tarifleriYukle();
  }

  Future<void> _tarifGuncelle(TarifData guncelTarif) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    int index = tariflerJson.indexWhere((e) => json.decode(e)['tarif_id'] == guncelTarif.tarif_id);
    if (index != -1) {
      tariflerJson[index] = json.encode({
        'tarif_id': guncelTarif.tarif_id,
        'tarif_adi': guncelTarif.tarif_adi,
        'tarif_aciklama': guncelTarif.tarif_aciklama,
        'tarif_resimler': guncelTarif.tarif_resimler,
        'klasor_id': guncelTarif.klasor_id,
        'isFavorite': guncelTarif.isFavorite,
      });
      await prefs.setStringList(key, tariflerJson);
      
      // Firebase'de de güncelle
      await _firebaseService.updateTarifInFirebase(guncelTarif);
      
      _tarifleriYukle();
    }
  }

  void _tarifDuzenle(TarifData tarif) async {
    final guncelTarif = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TarifOlusturma(
        tarifData: tarif,
        isManual: true,
      )),
    );
    if (guncelTarif != null && guncelTarif is TarifData && guncelTarif.tarif_adi.isNotEmpty) {
      _tarifGuncelle(guncelTarif);
    }
  }

  Future<void> _tarifSil(int tarif_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    tariflerJson.removeWhere((e) => json.decode(e)['tarif_id'] == tarif_id);
    await prefs.setStringList(key, tariflerJson);
    
    // Firebase'den de sil
    await _firebaseService.deleteTarifFromFirebase(widget.klasorData.klasor_id, tarif_id);
    
    _tarifleriYukle();
  }

  // AI Service
  final AiRecipeService _aiRecipeService = AiRecipeService();

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'add_option_title'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.edit_note,
              color: Colors.orange,
              title: 'add_option_manual'.tr(),
              onTap: () {
                Navigator.pop(context); // Close sheet
                _yeniTarifEkle(); // Old flow
              },
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.psychology, 
              color: Colors.purple,
              title: 'add_option_ai'.tr(),
              isLocked: !_firebaseService.isUserLoggedIn,
              onTap: () {
                Navigator.pop(context); // Close sheet
                if (_firebaseService.isUserLoggedIn) {
                  _showAiDialog(); // New AI flow
                } else {
                  // İsteğe bağlı: Giriş sayfasına yönlendir veya mesaj göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ai_login_required'.tr())),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLocked ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.withOpacity(0.2) : color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(isLocked ? Icons.lock : icon, color: isLocked ? Colors.grey : color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isLocked ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (isLocked)
                    Text(
                      'ai_login_required'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showAiDialog() {
    final TextEditingController _promptController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('add_option_ai'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ai_input_hint'.tr()),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Mantı, Karnıyarık...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ai_dialog_cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _promptController.text.trim();
              if (text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ai_name_warning'.tr()), backgroundColor: Colors.red),
                 );
                 return;
              }
              
              // Saçma sapan yazı kontrolü (Örn: "asdfasdf" veya çok kısa)
              if (text.length < 2 || !RegExp(r'[a-zA-ZçğıöşüÇĞİÖŞÜ]').hasMatch(text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ai_error_not_food'.tr()), backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.pop(context); // Close dialog
              _generateAndNavigate(text); // Start magic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            child: Text('ai_dialog_create'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndNavigate(String dishName) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
             color: Theme.of(context).cardColor,
             borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              Text(
                'ai_generating_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('ai_generating_message'.tr(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    try {
      // AdMob: Geçiş reklamını göster, kapandıktan sonra AI işlemini başlat
      AdService.showInterstitialAd(onAdClosed: () async {
        try {
          // Reklam kapandıktan sonra AI servisini çağır
          final recipeData = await _aiRecipeService.generateRecipe(dishName);
          
          if (!mounted) return;
          Navigator.pop(context); // Close Loading

          // Create TarifData from JSON
          final yeniTarif = TarifData(
            tarif_id: 0,
            tarif_adi: recipeData['baslik'] ?? dishName,
            tarif_aciklama: '',
            tarif_resimler: [],
            klasor_id: widget.klasorData.klasor_id,
            isFavorite: false,
          );

          // Navigate to Edit Page with Pre-filled Data
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TarifOlusturma(
                 tarifData: yeniTarif, 
                 aiResultMap: recipeData 
              ),
            ),
          );

          if (result != null && result is TarifData) {
            _tarifEkle(result);
          }
        } catch (e) {
          _handleAiError(e);
        }
      });

    } catch (e) {
      _handleAiError(e);
    }
  }

  void _handleAiError(dynamic e) {
    print('Handling AI Error in UI: $e');
    if (!mounted) return;
    
    // Eğer yükleniyor dialogu hala açıksa kapat (üst üste binmemesi için try-catch içinde güvenli pop)
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); 
      }
    } catch (_) {}
    
    // Show Error (Validation or Server Error)
    String message = e.toString();
    if (message.contains("Exception:")) message = message.replaceAll("Exception:", "").trim();
    if (message.contains("TimeoutException")) message = "Sunucu yanıt vermedi, lütfen tekrar deneyin.";
    
    // Translate specific validation error if strictly matching key, else show raw
    if (message.contains("yemek tarifi değil") || message.contains("yemek ismi değil")) {
      message = 'ai_error_not_food'.tr();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ai_error_title'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          )
        ],
      ),
    );
  }

  void _yeniTarifEkle() async {
    final yeniTarif = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TarifOlusturma(
          isManual: true,
          tarifData: TarifData(
            tarif_id: 0,
            tarif_adi: '',
            tarif_aciklama: '',
            tarif_resimler: [],
            klasor_id: widget.klasorData.klasor_id,
            isFavorite: false,
          ),
        ),
      ),
    );
    if (yeniTarif != null && yeniTarif is TarifData && yeniTarif.tarif_adi.isNotEmpty) {
      _tarifEkle(yeniTarif);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    return Scaffold(
        appBar: AppBar(
          title: aramaYapiliyorMu
              ? TextField(
                  controller: aramaController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'recipes_search_hint'.tr(),
                  ),
                  onChanged: (arama) {
                    if (mounted) {
                      _filtreleTarifler(arama);
                    }
                  },
                )
              : Text(widget.klasorData.klasor_adi, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          actions: [
            aramaYapiliyorMu
                ? IconButton(
                    key: const ValueKey('clear_search'),
                    icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          aramaYapiliyorMu = false;
                          aramaController.clear();
                          filtreliTarifler = List.from(tarifListesi);
                        });
                      }
                    },
                  )
                : IconButton(
                    key: const ValueKey('search_button'),
                    icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          aramaYapiliyorMu = true;
                        });
                      }
                    },
                  ),
          ],
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: filtreliTarifler.isEmpty
              ? Center(
                  child: Text(
                    'recipes_empty_title'.tr(),
                    style:
                        TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  itemCount: filtreliTarifler.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    var tarif = filtreliTarifler[index];
                    return GestureDetector(
                      onTap: () async {
                        final guncelTarif = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TarifDetay(tarif: tarif),
                          ),
                        );
                        if (guncelTarif != null && guncelTarif is TarifData) {
                          _tarifGuncelle(guncelTarif);
                        }
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Theme.of(context).cardColor,
                        child: SizedBox(
                          height: 90,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Görsel önizleme
                                if (tarif.tarif_resimler.isNotEmpty)
                                  Container(
                                    width: 60,
                                    height: 60,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: tarif.tarif_resimler.first.startsWith('http')
                                        ? Image.network(
                                            tarif.tarif_resimler.first,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Icon(Icons.broken_image, color: Colors.grey[600], size: 24),
                                              );
                                            },
                                          )
                                        : File(tarif.tarif_resimler.first).existsSync()
                                          ? Image.file(
                                              File(tarif.tarif_resimler.first),
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: Icon(Icons.broken_image, color: Colors.grey[600], size: 24),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 24),
                                            ),
                                    ),
                                  ),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        tarif.tarif_adi,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'recipes_tap_for_details'.tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Favori butonu
                                    IconButton(
                                      icon: Icon(
                                        tarif.isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () async {
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
                                      },
                                    ),
                                    
                                    // Paylaş butonu
                                    Builder(
                                      builder: (BuildContext btnContext) {
                                        return IconButton(
                                          icon: Icon(
                                            Icons.share,
                                            color: Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: () async {
                                            try {
                                              String shareText = '📖 ${tarif.tarif_adi}\n\n';
                                              shareText += tarif.tarif_aciklama;
                                              shareText += '\n\n━━━━━━━━━━━━━━━━━━\n';
                                              shareText += 'share_from_app'.tr();
                                              
                                              // iOS için butonun konumunu al
                                              final box = btnContext.findRenderObject() as RenderBox?;
                                              final sharePositionOrigin = box != null 
                                                ? box.localToGlobal(Offset.zero) & box.size
                                                : null;
                                              
                                              await Share.share(
                                                shareText,
                                                subject: tarif.tarif_adi,
                                                sharePositionOrigin: sharePositionOrigin,
                                              );
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'share_error_generic'
                                                          .tr(),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    
                                    // Silme butonu
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              'recipes_delete_title'.tr(),
                                            ),
                                            content: Text(
                                              '${tarif.tarif_adi}${'recipes_delete_confirm_suffix'.tr()}',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('common_no'.tr()),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _tarifSil(tarif.tarif_id);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: Text(
                                                  'common_yes'.tr(),
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddOptions,
          backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
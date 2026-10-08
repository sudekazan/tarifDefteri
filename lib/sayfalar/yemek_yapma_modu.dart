import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';

class YemekYapmaModu extends StatefulWidget {
  final TarifData tarif;
  final double portionMultiplier;

  const YemekYapmaModu({Key? key, required this.tarif, this.portionMultiplier = 1.0}) : super(key: key);

  @override
  State<YemekYapmaModu> createState() => _YemekYapmaModuState();
}

class _YemekYapmaModuState extends State<YemekYapmaModu> {
  final PageController _pageController = PageController();
  List<Widget> _pages = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ekranın kapanmasını engelle
    WakelockPlus.enable();
    _preparePages();
  }

  @override
  void dispose() {
    // Ekran kilidini eski haline getir
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  String _scaleIngredient(String ingredient, double multiplier) {
    if (multiplier == 1.0) return ingredient;
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

  void _preparePages() {
    List<Widget> pages = [];
    
    // İlk sayfa: Başlık ve Malzemeler
    List<String> malzemeler = [];
    List<String> adimlar = [];

    if (widget.tarif.tarif_aciklama_json != null && widget.tarif.tarif_aciklama_json!.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(widget.tarif.tarif_aciklama_json!);
        for (var section in decoded) {
          if (section['type'] == 'malzemeler' || section['type'] == 'harc' || section['type'] == 'hamur' || section['type'] == 'serbet' || section['type'] == 'sos') {
            malzemeler.add('${section['title']}:');
            for (var item in (section['items'] ?? [])) {
              malzemeler.add('• ' + _scaleIngredient(item.toString(), widget.portionMultiplier));
            }
            malzemeler.add('');
          } else if (section['type'] == 'yapilis') {
            for (var item in (section['items'] ?? [])) {
              adimlar.add(item.toString());
            }
          }
        }
      } catch (e) {
        print('JSON parsing error in YemekYapmaModu: $e');
      }
    }

    // JSON boşsa veya eski format ise fallback
    if (malzemeler.isEmpty && adimlar.isEmpty) {
      final lines = widget.tarif.tarif_aciklama.split('\n');
      bool isYapilis = false;
      for (String line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        
        String lower = trimmed.toLowerCase();
        if (lower.contains('yapılış') || lower.contains('hazırlanış') || lower.contains('instructions')) {
          isYapilis = true;
          continue;
        }
        
        if (isYapilis) {
          adimlar.add(trimmed);
        } else {
          malzemeler.add(_scaleIngredient(trimmed, widget.portionMultiplier));
        }
      }
    }

    // Malzemeler Sayfası
    pages.add(_buildPage(
      title: 'cooking_mode_ingredients'.tr,
      contentList: malzemeler,
      icon: Icons.kitchen,
      isNumbered: false,
    ));

    // Yapılış Adımları (Her adım için bir sayfa veya liste)
    // Eğer çok adım varsa her sayfaya 1-2 adım koyabiliriz, şimdilik hepsini liste yapalım
    if (adimlar.isNotEmpty) {
      for (int i = 0; i < adimlar.length; i++) {
        pages.add(_buildPage(
          title: '${'cooking_mode_step'.tr} ${i + 1}',
          contentList: [adimlar[i]],
          icon: Icons.restaurant_menu,
          isNumbered: false,
        ));
      }
    } else {
       pages.add(_buildPage(
          title: 'cooking_mode_steps'.tr,
          contentList: ['Tarifin yapılış adımları bulunamadı.'],
          icon: Icons.error_outline,
          isNumbered: false,
        ));
    }

    setState(() {
      _pages = pages;
    });
  }

  Widget _buildPage({required String title, required List<String> contentList, required IconData icon, required bool isNumbered}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).primaryColor.withOpacity(0.8)),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contentList.map((item) {
                    if (item.isEmpty) return const SizedBox(height: 16);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 24, // BÜYÜK YAZI (Yemek yaparken uzaktan okumak için)
                          height: 1.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.tarif.tarif_adi),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_currentIndex + 1} / ${_pages.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _pages,
            ),
          ),
          // Navigasyon Butonları
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Icon(Icons.arrow_back_ios, size: 28),
                ),
                ElevatedButton(
                  onPressed: _currentIndex < _pages.length - 1
                      ? () {
                          _pageController.nextPage(
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      : () {
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: _currentIndex < _pages.length - 1 
                        ? Theme.of(context).primaryColor 
                        : Colors.green, // Son sayfadaysa bitti rengi
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Icon(
                    _currentIndex < _pages.length - 1 ? Icons.arrow_forward_ios : Icons.check, 
                    size: 28, 
                    color: Colors.white
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

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
  int _currentIndex = 0;

  List<String> _malzemeler = [];
  List<String> _adimlar = [];
  final Set<int> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _parseRecipeContent();
  }

  @override
  void dispose() {
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

  void _parseRecipeContent() {
    List<String> tempMalzemeler = [];
    List<String> tempAdimlar = [];

    if (widget.tarif.tarif_aciklama_json != null && widget.tarif.tarif_aciklama_json!.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(widget.tarif.tarif_aciklama_json!);
        for (var section in decoded) {
          if (section['type'] == 'malzemeler' ||
              section['type'] == 'harc' ||
              section['type'] == 'hamur' ||
              section['type'] == 'serbet' ||
              section['type'] == 'sos') {
            for (var item in (section['items'] ?? [])) {
              tempMalzemeler.add(_scaleIngredient(item.toString(), widget.portionMultiplier));
            }
          } else if (section['type'] == 'yapilis') {
            for (var item in (section['items'] ?? [])) {
              tempAdimlar.add(item.toString());
            }
          }
        }
      } catch (e) {
        print('JSON parsing error in YemekYapmaModu: $e');
      }
    }

    // Fallback if JSON is empty
    if (tempMalzemeler.isEmpty && tempAdimlar.isEmpty) {
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
          tempAdimlar.add(trimmed);
        } else {
          tempMalzemeler.add(_scaleIngredient(trimmed, widget.portionMultiplier));
        }
      }
    }

    setState(() {
      _malzemeler = tempMalzemeler;
      _adimlar = tempAdimlar;
    });
  }

  void _showIngredientsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D2B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.kitchen_rounded, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              'cooking_mode_ingredients'.tr(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _malzemeler.isEmpty
                        ? Center(child: Text('Malzeme bulunamadı', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _malzemeler.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _malzemeler[index];
                              final isChecked = _checkedIngredients.contains(index);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isChecked) {
                                      _checkedIngredients.remove(index);
                                    } else {
                                      _checkedIngredients.add(index);
                                    }
                                  });
                                  setModalState(() {});
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? Colors.green.withOpacity(isDark ? 0.2 : 0.1)
                                        : (isDark ? const Color(0xFF141622) : Colors.grey[100]),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isChecked
                                          ? Colors.green
                                          : (isDark ? const Color(0xFF2C3044) : Colors.transparent),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        color: isChecked ? Colors.green : (isDark ? Colors.white38 : Colors.grey[500]),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                            decoration: isChecked ? TextDecoration.lineThrough : null,
                                            color: isChecked
                                                ? (isDark ? Colors.white60 : Colors.grey[600])
                                                : (isDark ? Colors.white : Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIngredientsPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final int totalCount = _malzemeler.length;
    final int checkedCount = _checkedIngredients.length;
    final double progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Progress
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D2B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.soup_kitchen_rounded, color: primaryColor, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'cooking_mode_ingredients'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: checkedCount == totalCount && totalCount > 0
                            ? Colors.green.withOpacity(0.15)
                            : primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$checkedCount / $totalCount ${'hazır'.tr()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: checkedCount == totalCount && totalCount > 0
                              ? Colors.green
                              : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF121420) : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      checkedCount == totalCount && totalCount > 0 ? Colors.green : primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ingredients Interactive Cards Grid/List
          Expanded(
            child: _malzemeler.isEmpty
                ? Center(
                    child: Text(
                      'Malzeme listesi bulunamadı.',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _malzemeler.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _malzemeler[index];
                      final isChecked = _checkedIngredients.contains(index);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _checkedIngredients.remove(index);
                              } else {
                                _checkedIngredients.add(index);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? Colors.green.withOpacity(isDark ? 0.18 : 0.08)
                                  : (isDark ? const Color(0xFF1A1D2B) : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isChecked
                                    ? Colors.green
                                    : (isDark ? const Color(0xFF2C3044) : Colors.grey.withOpacity(0.15)),
                                width: isChecked ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isChecked ? Colors.green : Colors.transparent,
                                    border: Border.all(
                                      color: isChecked ? Colors.green : (isDark ? Colors.white38 : Colors.grey[400]!),
                                      width: 2,
                                    ),
                                  ),
                                  child: isChecked
                                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                      decoration: isChecked ? TextDecoration.lineThrough : null,
                                      color: isChecked
                                          ? (isDark ? Colors.white60 : Colors.grey[600])
                                          : (isDark ? Colors.white : Colors.black87),
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
        ],
      ),
    );
  }

  Widget _buildStepPage(int stepIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final stepText = _adimlar[stepIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu_rounded, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  '${'cooking_mode_step'.tr()} ${stepIndex + 1}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Step Text Container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D2B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C3044) : Colors.grey.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Text(
                      stepText,
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final int totalPages = 1 + (_adimlar.isEmpty ? 1 : _adimlar.length);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          widget.tarif.tarif_adi,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          // Floating Ingredients Button (Always visible on any step)
          TextButton.icon(
            onPressed: () => _showIngredientsBottomSheet(context),
            icon: const Icon(Icons.soup_kitchen_rounded, size: 20),
            label: Text(
              'cooking_mode_ingredients'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              backgroundColor: primaryColor.withOpacity(0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page Indicator Progress Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentIndex == 0
                        ? 'cooking_mode_ingredients'.tr()
                        : '${'cooking_mode_step'.tr()} $_currentIndex / ${_adimlar.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1} / $totalPages',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildIngredientsPage();
                  } else {
                    final stepIndex = index - 1;
                    if (_adimlar.isEmpty) {
                      return Center(
                        child: Text(
                          'Tarifin yapılış adımları bulunamadı.',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                        ),
                      );
                    }
                    return _buildStepPage(stepIndex);
                  }
                },
              ),
            ),

            // Navigation Controls Footer
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Back Button
                  if (_currentIndex > 0) ...[
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                        label: Text('Önceki'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1A1D2B) : Colors.grey[200],
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Next / Finish Button
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _currentIndex < totalPages - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : () => Navigator.pop(context),
                        icon: Icon(
                          _currentIndex < totalPages - 1 ? Icons.arrow_forward_ios_rounded : Icons.check_circle_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: Text(
                          _currentIndex < totalPages - 1 ? 'Sonraki Adım'.tr() : 'Tamamla'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentIndex < totalPages - 1 ? primaryColor : Colors.green,
                          elevation: 4,
                          shadowColor: (_currentIndex < totalPages - 1 ? primaryColor : Colors.green).withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

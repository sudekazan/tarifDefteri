import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_recipe_service.dart';
import '../services/revenuecat_service.dart';
import '../services/firebase_service.dart';
import '../services/ad_service.dart';
import '../tarifler_data/tarif_data.dart';
import '../tarifler_data/klasor_data.dart';
import 'tarif_olusturma.dart';
import 'premium_sayfasi.dart';
import '../auth_screen.dart';
import '../utils/error_helper.dart';

class BugunNePisisemSayfasi extends StatefulWidget {
  const BugunNePisisemSayfasi({super.key});

  @override
  State<BugunNePisisemSayfasi> createState() => _BugunNePisisemSayfasiState();
}

class _BugunNePisisemSayfasiState extends State<BugunNePisisemSayfasi> {
  final TextEditingController _customMalzemeController = TextEditingController();
  final AiRecipeService _aiRecipeService = AiRecipeService();
  final FirebaseService _firebaseService = FirebaseService();

  final List<String> _secilenMalzemeler = [];

  // Popüler Malzemeler (başlangıç değerleri initState'te çevrilir)
  List<Map<String, String>> _populerMalzemeler = [];

  String? _secilenOgun;
  List<String> _ogunSecenekleri = [];

  String? _secilenSure;
  List<String> _sureSecenekleri = [];

  List<KlasorData> _klasorListesi = [];
  KlasorData? _hedefKlasor;
  int _kalanHak = 3;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initLocalizedOptions();
    _verileriYukle();
  }

  void _initLocalizedOptions() {
    _populerMalzemeler = [
      {'name': 'ingredient_egg'.tr(), 'emoji': '🥚'},
      {'name': 'ingredient_potato'.tr(), 'emoji': '🥔'},
      {'name': 'ingredient_chicken'.tr(), 'emoji': '🍗'},
      {'name': 'ingredient_ground_meat'.tr(), 'emoji': '🥩'},
      {'name': 'ingredient_cheese'.tr(), 'emoji': '🧀'},
      {'name': 'ingredient_onion'.tr(), 'emoji': '🧅'},
      {'name': 'ingredient_tomato'.tr(), 'emoji': '🍅'},
      {'name': 'ingredient_pasta'.tr(), 'emoji': '🍝'},
      {'name': 'ingredient_rice'.tr(), 'emoji': '🍚'},
      {'name': 'ingredient_mushroom'.tr(), 'emoji': '🍄'},
      {'name': 'ingredient_milk_yogurt'.tr(), 'emoji': '🥛'},
      {'name': 'ingredient_bread'.tr(), 'emoji': '🥖'},
      {'name': 'ingredient_garlic'.tr(), 'emoji': '🧄'},
      {'name': 'ingredient_pepper'.tr(), 'emoji': '🫑'},
      {'name': 'ingredient_carrot'.tr(), 'emoji': '🥕'},
      {'name': 'ingredient_tomato_paste'.tr(), 'emoji': '🥫'},
      {'name': 'ingredient_tuna'.tr(), 'emoji': '🐟'},
      {'name': 'ingredient_butter'.tr(), 'emoji': '🧈'},
    ];

    _ogunSecenekleri = [
      'what_to_cook_meal_any'.tr(),
      'what_to_cook_meal_breakfast'.tr(),
      'what_to_cook_meal_lunch_dinner'.tr(),
      'what_to_cook_meal_light'.tr(),
      'what_to_cook_meal_dessert'.tr(),
      'what_to_cook_meal_soup'.tr(),
    ];
    _secilenOgun = _ogunSecenekleri.first;

    _sureSecenekleri = [
      'what_to_cook_time_any'.tr(),
      'what_to_cook_time_quick'.tr(),
      'what_to_cook_time_oven'.tr(),
      'what_to_cook_time_pot'.tr(),
    ];
    _secilenSure = _sureSecenekleri.first;
  }

  @override
  void dispose() {
    _customMalzemeController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    final remaining = await RevenueCatService.getRemainingAiUses();
    final prefs = await SharedPreferences.getInstance();
    final klasorJsonList = prefs.getStringList('klasorler') ?? [];

    List<KlasorData> list = [];
    for (int i = 0; i < klasorJsonList.length; i++) {
      try {
        final map = json.decode(klasorJsonList[i]);
        list.add(KlasorData.fromMap(map));
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _kalanHak = remaining;
        _klasorListesi = list;
        if (_klasorListesi.isNotEmpty) {
          _hedefKlasor = _klasorListesi.first;
        }
      });
    }
  }

  void _malzemeEkle(String malzeme) {
    final temiz = malzeme.trim();
    if (temiz.isEmpty) return;
    if (!_secilenMalzemeler.contains(temiz)) {
      setState(() {
        _secilenMalzemeler.add(temiz);
      });
    }
    _customMalzemeController.clear();
  }

  void _malzemeCikar(String malzeme) {
    setState(() {
      _secilenMalzemeler.remove(malzeme);
    });
  }

  Future<void> _tarifiUret() async {
    if (_secilenMalzemeler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('what_to_cook_no_ingredients_warning'.tr()),
          backgroundColor: const Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Giriş Kontrolü
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth_required_for_ai'.tr()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'auth_button_login'.tr(),
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    // Limit Kontrolü
    bool canUseAi = await RevenueCatService.canUseAi();
    if (!mounted) return;
    if (!canUseAi) {
      _showLimitExceededDialog();
      return;
    }

    setState(() => _isLoading = true);

    // Prompt Oluştur
    String prompt = '${'what_to_cook_prompt_ingredients_prefix'.tr()}${_secilenMalzemeler.join(', ')}. ';
    if (_secilenOgun != _ogunSecenekleri.first) {
      prompt += '${'what_to_cook_prompt_meal_prefix'.tr()}$_secilenOgun. ';
    }
    if (_secilenSure != _sureSecenekleri.first) {
      prompt += '${'what_to_cook_prompt_time_prefix'.tr()}$_secilenSure. ';
    }
    prompt += 'what_to_cook_prompt_instruction'.tr();

    final languageCode = context.locale.languageCode;

    try {
      final recipeFuture = _aiRecipeService.generateRecipe(
        prompt,
        languageCode: languageCode,
      );

      // Reklam göster (ücretsiz kullanıcılar için)
      if (!RevenueCatService.isProUser) {
        AdService.showRewardedAd(
          onUserEarnedReward: (_) {},
          onAdClosed: () async {
            await _handleRecipeResult(recipeFuture);
          },
        );
      } else {
        await _handleRecipeResult(recipeFuture);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _handleRecipeResult(Future<AiRecipeResult> recipeFuture) async {
    try {
      final aiResult = await recipeFuture;
      final recipeData = aiResult.recipeData;
      await RevenueCatService.syncRemainingFromServer(aiResult.remaining);
      _verileriYukle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      final hedefKlasorId = _hedefKlasor?.klasor_id ?? 1;

      final yeniTarif = TarifData(
        tarif_id: 0,
        tarif_adi: recipeData['baslik'] ?? 'what_to_cook_fallback_title'.tr(),
        tarif_aciklama: '',
        tarif_resimler: [],
        klasor_id: hedefKlasorId,
        isFavorite: false,
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TarifOlusturma(
            tarifData: yeniTarif,
            aiResultMap: recipeData,
          ),
        ),
      );

      if (result != null && result is TarifData) {
        await _tarifKaydet(result, hedefKlasorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('what_to_cook_saved_success'.tr()),
              backgroundColor: const Color(0xFF2ECC71),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e is AiLimitExceededException) {
          await RevenueCatService.syncRemainingFromServer(0);
          _showLimitExceededDialog();
        } else {
          _showErrorDialog(e.toString());
        }
      }
    }
  }

  Future<void> _tarifKaydet(TarifData yeniTarif, int klasorId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_$klasorId';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];

    yeniTarif.tarif_id = DateTime.now().millisecondsSinceEpoch;

    final cloudResimler = await _firebaseService.saveTarifToFirebase(yeniTarif);

    yeniTarif.klasor_id = klasorId;
    yeniTarif.tarif_resimler = cloudResimler;
    yeniTarif.updatedAt = DateTime.now().millisecondsSinceEpoch;
    tariflerJson.add(json.encode(yeniTarif.toMap()));
    await prefs.setStringList(key, tariflerJson);
  }

  void _showLimitExceededDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFFFA000), size: 28),
            const SizedBox(width: 10),
            Text('what_to_cook_limit_dialog_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'what_to_cook_limit_dialog_body'.tr(),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common_later'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumSayfasi()),
              ).then((_) => _verileriYukle());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('premium_upgrade_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('ai_error_title'.tr()),
        content: Text(ErrorHelper.getFriendlyErrorMessage(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common_ok'.tr()),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181B2A) : const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF3E2723)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'what_to_cook_title'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF3E2723),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (!RevenueCatService.isProUser)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PremiumSayfasi()),
                ).then((_) => _verileriYukle());
              },
              icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFA000), size: 18),
              label: const Text('Pro', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE65100).withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'what_to_cook_hero_badge'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'what_to_cook_title'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'what_to_cook_subtitle'.tr(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🧑‍🍳', style: TextStyle(fontSize: 34)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Kalan Hak Rozeti
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: RevenueCatService.isProUser
                        ? const Color(0xFFFFF8E1)
                        : (isDark ? const Color(0xFF222638) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: RevenueCatService.isProUser
                          ? const Color(0xFFFFB74D)
                          : (isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        RevenueCatService.isProUser ? Icons.workspace_premium : Icons.bolt_rounded,
                        color: const Color(0xFFE65100),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          RevenueCatService.isProUser
                              ? 'what_to_cook_limit_badge_pro'.tr()
                              : 'what_to_cook_limit_badge_free'.tr(args: ['$_kalanHak']),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF5D4037),
                          ),
                        ),
                      ),
                      if (!RevenueCatService.isProUser)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PremiumSayfasi()),
                            ).then((_) => _verileriYukle());
                          },
                          child: Text(
                            'what_to_cook_make_unlimited'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Seçilen Malzemeler Başlığı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'what_to_cook_selected_ingredients_count'.tr(args: ['${_secilenMalzemeler.length}']),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF3E2723),
                      ),
                    ),
                    if (_secilenMalzemeler.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _secilenMalzemeler.clear()),
                        child: Text('common_clear'.tr(), style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Seçilen Malzemeler Alanı
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF222638) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
                  ),
                  child: _secilenMalzemeler.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'what_to_cook_selected_empty'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : const Color(0xFF8D6E63),
                              ),
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _secilenMalzemeler.map((m) {
                            return Chip(
                              backgroundColor: const Color(0xFFFFF3E0),
                              side: const BorderSide(color: Color(0xFFFFCC80)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              label: Text(
                                m,
                                style: const TextStyle(
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFE65100)),
                              onDeleted: () => _malzemeCikar(m),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(height: 16),

                // Özel Malzeme Ekleme Kutusu
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customMalzemeController,
                        decoration: InputDecoration(
                          hintText: 'what_to_cook_custom_hint'.tr(),
                          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[500]),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF222638) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                          ),
                        ),
                        onSubmitted: _malzemeEkle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _malzemeEkle(_customMalzemeController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: Text('what_to_cook_add_btn'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Popüler Malzemeler
                Text(
                  'what_to_cook_popular_title'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _populerMalzemeler.map((item) {
                    final name = item['name']!;
                    final emoji = item['emoji']!;
                    final isSelected = _secilenMalzemeler.contains(name);
                    return FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Text(emoji, style: const TextStyle(fontSize: 15)),
                      label: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4E342E)),
                        ),
                      ),
                      backgroundColor: isDark ? const Color(0xFF222638) : Colors.white,
                      selectedColor: const Color(0xFFE65100),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFE65100)
                            : (isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (selected) {
                        if (selected) {
                          _malzemeEkle(name);
                        } else {
                          _malzemeCikar(name);
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Öğün ve Süre Tercihleri
                Text(
                  'what_to_cook_meal_type'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _ogunSecenekleri.map((ogun) {
                      final isSelected = _secilenOgun == ogun;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(ogun),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFFA000),
                          backgroundColor: isDark ? const Color(0xFF222638) : Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4E342E)),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFFFA000) : (isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
                          ),
                          onSelected: (_) => setState(() => _secilenOgun = ogun),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'what_to_cook_time_type'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _sureSecenekleri.map((sure) {
                      final isSelected = _secilenSure == sure;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(sure),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFFA000),
                          backgroundColor: isDark ? const Color(0xFF222638) : Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4E342E)),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFFFA000) : (isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
                          ),
                          onSelected: (_) => setState(() => _secilenSure = sure),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                if (_klasorListesi.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'what_to_cook_select_folder'.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222638) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<KlasorData>(
                        isExpanded: true,
                        value: _hedefKlasor,
                        dropdownColor: isDark ? const Color(0xFF222638) : Colors.white,
                        items: _klasorListesi.map((k) {
                          return DropdownMenuItem<KlasorData>(
                            value: k,
                            child: Row(
                              children: [
                                Icon(k.icon, size: 20, color: const Color(0xFFE65100)),
                                const SizedBox(width: 10),
                                Text(
                                  k.klasor_adi,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF3E2723),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _hedefKlasor = val);
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // CTA Butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _tarifiUret,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                      shadowColor: const Color(0xFFE65100).withOpacity(0.4),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'what_to_cook_generate_btn'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.65),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF222638) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'what_to_cook_loading_title'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'what_to_cook_loading_message'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
}

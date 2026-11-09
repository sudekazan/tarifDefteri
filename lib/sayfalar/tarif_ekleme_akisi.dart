import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_service.dart';
import '../services/ai_recipe_service.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../services/review_service.dart';
import '../services/revenuecat_service.dart';
import '../tarifler_data/klasor_data.dart';
import '../tarifler_data/tarif_data.dart';
import '../utils/error_helper.dart';
import '../widgets/ai_chef_loading_animation.dart';
import '../widgets/ai_hak_doldu_dialog.dart';
import '../widgets/tarif_ekle_alt_sayfasi.dart';
import 'premium_sayfasi.dart';
import 'tarif_olusturma.dart';

/// Cihazda kayıtlı klasörleri okur (ana sayfadaki okumayla aynı: eski
/// kayıtlarda kimlik yoksa sırası + 1).
Future<List<KlasorData>> kayitliKlasorleriOku() async {
  final prefs = await SharedPreferences.getInstance();
  final klasorler = prefs.getStringList('klasorler') ?? [];
  return klasorler.asMap().entries.map((e) {
    final map = json.decode(e.value);
    map['klasor_id'] ??= e.key + 1;
    return KlasorData.fromMap(map);
  }).toList();
}

/// "Yeni tarif" alt sayfasında seçilen yolu yürütür: kendim yazacağım, Şefe
/// sor (yapay zekâ) ve linkten tarif.
///
/// Bu akışlar önceden klasör içi sayfasındaydı; mantıkları ve analitik
/// olayları aynen korundu. Artık tarifin gideceği klasör ([klasor]) dışarıdan
/// verilir, böylece akış ana sayfadan da başlatılabilir.
class TarifEklemeAkisi {
  TarifEklemeAkisi({
    required this.context,
    required this.klasor,
    required this.kaydedilince,
    this.yenile,
  });

  /// Akışı başlatan sayfanın context'i. Diyaloglar ve sayfalar bununla açılır.
  final BuildContext context;

  /// Tarifin kaydedileceği klasör.
  final KlasorData klasor;

  /// Tarif cihaza ve Firebase'e kaydedilince çağrılır.
  final ValueChanged<TarifData> kaydedilince;

  /// Premium sayfası kapanınca çağrılır (sayfa Pro durumunu yeniden çizer).
  final VoidCallback? yenile;

  final FirebaseService _firebaseService = FirebaseService();
  final AiRecipeService _aiRecipeService = AiRecipeService();

  void _yenile() {
    if (context.mounted) yenile?.call();
  }

  Future<void> baslat(TarifEklemeYolu yol) async {
    switch (yol) {
      case TarifEklemeYolu.kendim:
        await _yeniTarifEkle();
      case TarifEklemeYolu.sef:
        await _girisVeBaglantiIle(_showAiDialog);
      case TarifEklemeYolu.link:
        await _girisVeBaglantiIle(_showLinkImportDialog);
    }
  }

  /// Şefe sor ve linkten tarif giriş ve internet ister.
  Future<void> _girisVeBaglantiIle(VoidCallback ac) async {
    if (_firebaseService.isUserLoggedIn) {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          if (context.mounted) ac();
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth_error_network'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ai_login_required'.tr())),
      );
    }
  }

  /// Klasördeki tarif sayısı (ücretsiz kullanıcının klasör başına sınırı için).
  Future<int> _klasordekiTarifSayisi() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('tarifler_${klasor.klasor_id}') ?? []).length;
  }

  Future<void> _tarifEkle(TarifData yeniTarif) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${klasor.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];

    // Silinmiş tarif ID'leri ile çakışmayı önlemek için zaman damgası kullanıyoruz
    yeniTarif.tarif_id = DateTime.now().millisecondsSinceEpoch;

    // Firebase'e kaydet ve cloud URL'lerini al
    final cloudResimler = await _firebaseService.saveTarifToFirebase(yeniTarif);

    // Cloud URL'leri ve tüm alanları (tarif_aciklama_json, updatedAt dahil) SharedPreferences'a kaydet
    yeniTarif.tarif_resimler = cloudResimler;
    yeniTarif.updatedAt = DateTime.now().millisecondsSinceEpoch;
    tariflerJson.add(json.encode(yeniTarif.toMap()));
    await prefs.setStringList(key, tariflerJson);

    kaydedilince(yeniTarif);
  }

  void _showLinkImportDialog() {
    final TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.link_rounded, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'link_dialog_title'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'link_dialog_hint'.tr(),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'link_dialog_placeholder'.tr(),
                prefixIcon: const Icon(Icons.language_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded),
                  tooltip: 'link_dialog_paste'.tr(),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      urlController.text = data!.text!;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty || !url.contains('.')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('link_error_invalid'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              _generateAndNavigate(url, true);
            },
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            label: Text('link_dialog_import'.tr(), style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAiDialog() {
    final TextEditingController promptController = TextEditingController();
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
              controller: promptController,
              autofocus: true,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'ai_input_placeholder'.tr(),
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
              final text = promptController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ai_name_warning'.tr()), backgroundColor: Colors.red),
                );
                return;
              }

              // Link kontrolü veya saçma kelime kontrolü
              bool isUrl = Uri.tryParse(text)?.hasAbsolutePath ?? false;
              if (!isUrl && (text.length < 2 || !RegExp(r'[a-zA-ZçğıöşüÇĞİÖŞÜ]').hasMatch(text))) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ai_error_not_food'.tr()), backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.pop(context); // Close dialog
              _generateAndNavigate(text, isUrl); // Start magic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            child: Text('ai_dialog_create'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndNavigate(String input, [bool isUrl = false]) async {
    if (!RevenueCatService.isProUser &&
        await _klasordekiTarifSayisi() >= RevenueCatService.freeTarifPerKlasorLimit) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('tarif_limit_reached'.tr(args: ['${RevenueCatService.freeTarifPerKlasorLimit}'])),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'tarif_limit')),
      ).then((_) => _yenile());
      return;
    }
    if (!context.mounted) return;

    if (isUrl && !RevenueCatService.isProUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('link_recipe_pro_only'.tr()), backgroundColor: Colors.orange),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'link_pro_only')),
      ).then((_) => _yenile());
      return;
    }

    bool canUseAi = await RevenueCatService.canUseAi();
    if (!canUseAi) {
      AnalyticsService.aiLimitDoldu(kaynak: isUrl ? 'link' : 'klasor_ai');
      _showAiLimitChoiceDialog(input, isUrl);
      return;
    }
    if (!context.mounted) return;

    // Show Loading dialog
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
          child: AiChefLoadingAnimation(
            title: 'ai_generating_title'.tr(),
            messages: [
              'ai_generating_step_1'.tr(),
              'ai_generating_step_2'.tr(),
              'ai_generating_step_3'.tr(),
            ],
          ),
        ),
      ),
    );

    try {
      String finalPrompt = input;

      if (isUrl) {
        try {
          final response = await http.get(Uri.parse(input)).timeout(const Duration(seconds: 15));
          if (response.statusCode == 200) {
            String htmlText = response.body;
            final bodyMatch = RegExp(r'<body[^>]*>(.*?)</body>', dotAll: true).firstMatch(htmlText);
            if (bodyMatch != null) htmlText = bodyMatch.group(1)!;
            String plainText = htmlText.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ');
            if (plainText.length > 5000) plainText = plainText.substring(0, 5000);

            finalPrompt = "Lütfen şu metin içerisindeki yemek tarifini çıkar ve belirtilen formata göre döndür. Metin: $plainText";
          }
        } catch (e) {
          debugPrint("Link okuma hatası: $e");
          // Eğer okuyamazsa linkin kendisini göndeririz, belki backend/AI anlar.
        }
      }

      // AI Şef'in ücretsiz günlük hakları artık reklamsız kullanılır;
      // reklam yalnızca hak bittiğinde isteğe bağlı "+1 hak" olarak sunulur
      // (bkz. _showAiLimitChoiceDialog).
      if (!context.mounted) return;
      final languageCode = context.locale.languageCode;
      final aiResult = await _aiRecipeService.generateRecipe(
        finalPrompt,
        languageCode: languageCode,
      );
      final recipeData = aiResult.recipeData;
      AnalyticsService.aiKullanildi(isPro: RevenueCatService.isProUser, kaynak: isUrl ? 'link' : 'klasor_ai');

      if (!context.mounted) return;
      Navigator.pop(context); // Close Loading

      // Create TarifData from JSON
      final yeniTarif = TarifData(
        tarif_id: 0,
        tarif_adi: recipeData['baslik'] ?? (isUrl ? 'link_recipe_fallback_title'.tr() : input),
        tarif_aciklama: '',
        tarif_resimler: [],
        klasor_id: klasor.klasor_id,
        isFavorite: false,
      );

      await RevenueCatService.syncRemainingFromServer(aiResult.remaining);
      if (!context.mounted) return;

      // Navigate to Edit Page with Pre-filled Data
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
        await _tarifEkle(result);
        AnalyticsService.tarifKaydedildi(isAiGenerated: true);
        if (context.mounted) {
          await ReviewService.onRecipeSaved(context, isAiGenerated: true);
        }
      }
    } catch (e) {
      _handleAiError(e, input: input, isUrl: isUrl);
    }
  }

  /// Günlük AI hakkı bittiğinde gösterilir. Pro kullanıcıya "reklam izle"
  /// ya da "Pro'ya geç" seçenekleri anlamsız olduğundan (zaten Pro ve bonus
  /// hakkı yok), onlara sadece günlük tavanın dolduğunu söyleyen basit bir
  /// bilgi gösterilir; free kullanıcıya eski "reklam/Pro" seçim diyaloğu çıkar.
  Future<void> _showAiLimitChoiceDialog(String input, bool isUrl) async {
    if (!context.mounted) return;
    if (RevenueCatService.isProUser) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('ai_limit_pro_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text('ai_limit_pro_body'.tr(), style: const TextStyle(fontSize: 14, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ai_limit_pro_ok'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }
    final secim = await aiHakDolduDialogGoster(context);
    if (!context.mounted) return;
    switch (secim) {
      case AiHakDolduSecim.reklamIzle:
        _watchAdForBonusUse(input, isUrl);
      case AiHakDolduSecim.proyaGec:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'ai_limit_choice')),
        ).then((_) => _yenile());
      case null:
        break;
    }
  }

  /// Kullanıcı "+1 hak" için reklam izlemeyi seçtiğinde çağrılır. Reklam
  /// tam izlenirse backend'den bonus hak istenir ve istek otomatik tekrar
  /// denenir.
  void _watchAdForBonusUse(String input, bool isUrl) {
    bool rewardEarned = false;
    AdService.showRewardedAd(
      yer: 'klasor_ici',
      onUserEarnedReward: (reward) {
        rewardEarned = true;
      },
      onAdClosed: () async {
        if (!rewardEarned) return; // Reklam tam izlenmeden kapatıldı
        final newRemaining = await _aiRecipeService.grantBonusUse();
        await RevenueCatService.syncRemainingFromServer(newRemaining);
        if (context.mounted) {
          _generateAndNavigate(input, isUrl);
        }
      },
    );
  }

  void _handleAiError(dynamic e, {String? input, bool isUrl = false}) {
    debugPrint('Handling AI Error in UI: $e');
    if (!context.mounted) return;

    // Eğer yükleniyor dialogu hala açıksa kapat (üst üste binmemesi için try-catch içinde güvenli pop)
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (_) {}

    if (e is AiLimitExceededException) {
      RevenueCatService.syncRemainingFromServer(0);
      AnalyticsService.aiLimitDoldu(kaynak: isUrl ? 'link' : 'klasor_ai');
      if (input != null) {
        _showAiLimitChoiceDialog(input, isUrl);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'ai_limit')),
        ).then((_) => _yenile());
      }
      return;
    }

    // Show Error (Validation or Server Error)
    String message = ErrorHelper.getFriendlyErrorMessage(e);

    // Hem Türkçe hem İngilizce hata mesajlarını yakala
    if (message.contains("yemek tarifi değil") ||
        message.contains("yemek ismi değil") ||
        message.contains("not a food") ||
        message.contains("not a dish") ||
        message.contains("not a meal") ||
        message.toLowerCase().contains("food name")) {
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
            child: Text('common_ok'.tr()),
          )
        ],
      ),
    );
  }

  Future<void> _yeniTarifEkle() async {
    if (!RevenueCatService.isProUser &&
        await _klasordekiTarifSayisi() >= RevenueCatService.freeTarifPerKlasorLimit) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('tarif_limit_reached'.tr(args: ['${RevenueCatService.freeTarifPerKlasorLimit}'])),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'tarif_limit')),
      ).then((_) => _yenile());
      return;
    }
    if (!context.mounted) return;

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
            klasor_id: klasor.klasor_id,
            isFavorite: false,
          ),
        ),
      ),
    );
    if (yeniTarif != null && yeniTarif is TarifData && yeniTarif.tarif_adi.isNotEmpty) {
      await _tarifEkle(yeniTarif);
      AnalyticsService.tarifKaydedildi(isAiGenerated: false);
      if (context.mounted) {
        await ReviewService.onRecipeSaved(context);
      }
    }
  }
}

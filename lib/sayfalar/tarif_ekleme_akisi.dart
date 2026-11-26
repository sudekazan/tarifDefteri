import 'dart:async';
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
import '../utils/tarif_kayit.dart';
import '../widgets/ai_chef_loading_animation.dart';
import '../widgets/ai_hak_doldu_dialog.dart';
import '../widgets/kil/kil.dart';
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
          KilBildirim.goster(
            context,
            'auth_error_network'.tr(),
            tur: KilBildirimTuru.hata,
          );
        }
      }
    } else {
      KilBildirim.goster(context, 'ai_login_required'.tr());
    }
  }

  /// Klasördeki tarif sayısı (ücretsiz kullanıcının klasör başına sınırı için).
  Future<int> _klasordekiTarifSayisi() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('tarifler_${klasor.klasor_id}') ?? []).length;
  }

  Future<void> _tarifEkle(TarifData yeniTarif) async {
    // Silinmiş tarif ID'leri ile çakışmayı önlemek için zaman damgası kullanıyoruz
    yeniTarif.tarif_id = DateTime.now().millisecondsSinceEpoch;
    yeniTarif.klasor_id = klasor.klasor_id;
    yeniTarif.updatedAt = DateTime.now().millisecondsSinceEpoch;

    // Önce cihaza yaz ve ekranı güncelle; Firebase beklenmez (internet
    // yokken yazma bitmez, tarif kaydedilmemiş gibi görünürdü).
    await yeniTarifiCihazaYaz(yeniTarif);
    kaydedilince(yeniTarif);

    unawaited(tarifiArkadanBulutaGonder(
      yeniTarif,
      _firebaseService.saveTarifToFirebase,
    ));
  }

  void _showLinkImportDialog() {
    final TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => KilDiyalog(
        ikon: Icons.link_rounded,
        baslik: 'link_dialog_title'.tr(),
        mesaj: 'link_dialog_hint'.tr(),
        icerik: TextField(
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
        eylemler: [
          KilDugme.birincil(
            etiket: 'link_dialog_import'.tr(),
            ikon: Icons.download_rounded,
            tamGenislik: true,
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty || !url.contains('.')) {
                KilBildirim.goster(
                  context,
                  'link_error_invalid'.tr(),
                  tur: KilBildirimTuru.hata,
                );
                return;
              }

              Navigator.pop(context);
              _generateAndNavigate(url, true);
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

  void _showAiDialog() {
    final TextEditingController promptController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => KilDiyalog(
        ikon: Icons.auto_awesome_rounded,
        baslik: 'add_option_ai'.tr(),
        mesaj: 'ai_input_hint'.tr(),
        icerik: TextField(
          controller: promptController,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'ai_input_placeholder'.tr(),
          ),
        ),
        eylemler: [
          KilDugme.birincil(
            etiket: 'ai_dialog_create'.tr(),
            tamGenislik: true,
            onPressed: () {
              final text = promptController.text.trim();
              if (text.isEmpty) {
                KilBildirim.goster(
                  context,
                  'ai_name_warning'.tr(),
                  tur: KilBildirimTuru.hata,
                );
                return;
              }

              // Link kontrolü veya saçma kelime kontrolü
              bool isUrl = Uri.tryParse(text)?.hasAbsolutePath ?? false;
              if (!isUrl && (text.length < 2 || !RegExp(r'[a-zA-ZçğıöşüÇĞİÖŞÜ]').hasMatch(text))) {
                KilBildirim.goster(
                  context,
                  'ai_error_not_food'.tr(),
                  tur: KilBildirimTuru.hata,
                );
                return;
              }

              Navigator.pop(context); // Close dialog
              _generateAndNavigate(text, isUrl); // Start magic
            },
          ),
          KilDiyalogMetinDugmesi(
            etiket: 'ai_dialog_cancel'.tr(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndNavigate(String input, [bool isUrl = false]) async {
    if (!RevenueCatService.isProUser &&
        await _klasordekiTarifSayisi() >= RevenueCatService.freeTarifPerKlasorLimit) {
      if (!context.mounted) return;
      KilBildirim.goster(
        context,
        'tarif_limit_reached'.tr(args: ['${RevenueCatService.freeTarifPerKlasorLimit}']),
        tur: KilBildirimTuru.uyari,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'tarif_limit')),
      ).then((_) => _yenile());
      return;
    }
    if (!context.mounted) return;

    if (isUrl && !RevenueCatService.isProUser) {
      KilBildirim.goster(
        context,
        'link_recipe_pro_only'.tr(),
        tur: KilBildirimTuru.uyari,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'link_pro_only')),
      ).then((_) => _yenile());
      return;
    }

    bool canUseAi = await RevenueCatService.canUseAi(mod: AiModu.yemekAdi);
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
        backgroundColor: context.kil.kart,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KilDiyalog.koseYaricapi),
          side: BorderSide(color: context.kil.kenar, width: KilKart.kenarKalinligi),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
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

      await RevenueCatService.syncRemainingFromServer(aiResult.remaining, mod: AiModu.yemekAdi);
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
      KilDiyalog.bilgiGoster(
        context,
        ikon: Icons.hourglass_bottom_rounded,
        baslik: 'ai_limit_pro_title'.tr(),
        mesaj: 'ai_limit_pro_body'.tr(),
        tamamEtiketi: 'ai_limit_pro_ok'.tr(),
      );
      return;
    }
    final reklamVar = await RevenueCatService.bonusHakKaldiMi();
    if (!context.mounted) return;
    final secim = await aiHakDolduDialogGoster(context, reklamVar: reklamVar);
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
        final sonuc = await _aiRecipeService.grantBonusUse(mod: AiModu.yemekAdi);
        if (sonuc.durum == BonusDurumu.sinirDoldu) {
          // Haftanın ek hakları bitmiş (ör. başka cihazda): tekrar denemek
          // aynı pencereyi açıp reklamı boşa izletirdi.
          await RevenueCatService.bonusHakkiniBitir();
          if (context.mounted) {
            KilBildirim.goster(
              context,
              'ai_bonus_limit_reached'.tr(),
              tur: KilBildirimTuru.uyari,
            );
          }
          return;
        }
        if (sonuc.durum == BonusDurumu.verildi) {
          await RevenueCatService.bonusKazanildi();
        }
        await RevenueCatService.syncRemainingFromServer(sonuc.kalan, mod: AiModu.yemekAdi);
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
      RevenueCatService.syncRemainingFromServer(0, mod: AiModu.yemekAdi);
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

    KilDiyalog.bilgiGoster(
      context,
      ikon: Icons.error_outline_rounded,
      tur: KilDiyalogTuru.tehlike,
      baslik: 'ai_error_title'.tr(),
      mesaj: message,
      tamamEtiketi: 'common_ok'.tr(),
    );
  }

  Future<void> _yeniTarifEkle() async {
    if (!RevenueCatService.isProUser &&
        await _klasordekiTarifSayisi() >= RevenueCatService.freeTarifPerKlasorLimit) {
      if (!context.mounted) return;
      KilBildirim.goster(
        context,
        'tarif_limit_reached'.tr(args: ['${RevenueCatService.freeTarifPerKlasorLimit}']),
        tur: KilBildirimTuru.uyari,
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

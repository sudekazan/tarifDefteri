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
import '../services/review_service.dart';
import '../services/analytics_service.dart';
import '../utils/klasor_adi.dart';
import '../widgets/ana_sayfa_parcalari.dart';
import '../widgets/kil/kil.dart';
import '../widgets/ne_pisirsem_parcalari.dart';
import '../widgets/ai_hak_doldu_dialog.dart';

class BugunNePisisemSayfasi extends StatefulWidget {
  const BugunNePisisemSayfasi({
    super.key,
    this.gorunduSinyali,
    this.tarifKaydedilince,
  });

  /// Kabukta bu sekme yeniden seçilince haber verir; klasörler ve kalan hak
  /// yeniden okunur.
  final Listenable? gorunduSinyali;

  /// Sekme olarak kullanılırken tarif kaydedilince çağrılır (kabuk Defterim'e
  /// geçer). Verilmezse sayfa eskisi gibi kapanır.
  final VoidCallback? tarifKaydedilince;

  @override
  State<BugunNePisisemSayfasi> createState() => _BugunNePisisemSayfasiState();
}

class _BugunNePisisemSayfasiState extends State<BugunNePisisemSayfasi> {
  final TextEditingController _customMalzemeController = TextEditingController();
  final AiRecipeService _aiRecipeService = AiRecipeService();
  // İlk kullanıldığında kurulur (kayıt anında); sayfa Firebase olmadan da
  // açılabilir (testler).
  late final FirebaseService _firebaseService = FirebaseService();

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
    widget.gorunduSinyali?.addListener(_verileriYukle);
  }

  /// Sekmede kalan sayfa, kayıttan sonra yeni açılmış gibi boş başlar.
  void _formuSifirla() {
    _customMalzemeController.clear();
    setState(() {
      _secilenMalzemeler.clear();
      _secilenOgun = _ogunSecenekleri.first;
      _secilenSure = _sureSecenekleri.first;
    });
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
    widget.gorunduSinyali?.removeListener(_verileriYukle);
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
        // Sekme yeniden açılınca seçili klasör korunur; silinmişse ilk klasör.
        final seciliId = _hedefKlasor?.klasor_id;
        _hedefKlasor = list.isEmpty
            ? null
            : list.firstWhere((k) => k.klasor_id == seciliId,
                orElse: () => list.first);
      });
    }
  }

  /// Kullanıcının hedef klasörünü döndürür. Hiç klasörü yoksa (örn. ilk
  /// kurulumda klasör oluşturmadan doğrudan "Bugün ne pişirsem"i kullandıysa),
  /// tarifin "kayboluyor" hissi vermemesi için otomatik bir varsayılan klasör
  /// oluşturup oraya kaydeder — eskiden burada sabit `1` ID'sine düşülüyordu,
  /// ama o ID'ye ait bir klasör hiç oluşmamışsa tarif hiçbir yerde görünmüyordu.
  Future<int> _hedefKlasorIdGetir() async {
    if (_hedefKlasor != null) return _hedefKlasor!.klasor_id;
    if (_klasorListesi.isNotEmpty) return _klasorListesi.first.klasor_id;

    final prefs = await SharedPreferences.getInstance();
    final klasorJsonList = prefs.getStringList('klasorler') ?? [];
    final yeniKlasorId = DateTime.now().millisecondsSinceEpoch;
    final yeniKlasor = KlasorData(
      klasor_id: yeniKlasorId,
      klasor_adi: 'what_to_cook_default_folder_name'.tr(),
    );
    klasorJsonList.add(json.encode(yeniKlasor.toMap()));
    await prefs.setStringList('klasorler', klasorJsonList);
    await _firebaseService.saveKlasorToFirebase(yeniKlasor);

    if (mounted) {
      setState(() {
        _klasorListesi = [..._klasorListesi, yeniKlasor];
        _hedefKlasor = yeniKlasor;
      });
    }
    return yeniKlasorId;
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
      KilBildirim.goster(
        context,
        'what_to_cook_no_ingredients_warning'.tr(),
        tur: KilBildirimTuru.uyari,
      );
      return;
    }

    // Giriş Kontrolü
    if (FirebaseAuth.instance.currentUser == null) {
      KilBildirim.goster(
        context,
        'auth_required_for_ai'.tr(),
        tur: KilBildirimTuru.hata,
        eylemEtiketi: 'auth_button_login'.tr(),
        onEylem: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        },
      );
      return;
    }

    // Limit Kontrolü
    bool canUseAi = await RevenueCatService.canUseAi();
    if (!mounted) return;
    if (!canUseAi) {
      AnalyticsService.aiLimitDoldu(kaynak: 'ne_pisirsem');
      _showAiLimitChoiceDialog();
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
      // AI Şef'in ücretsiz günlük hakları artık reklamsız kullanılır;
      // reklam yalnızca hak bittiğinde isteğe bağlı "+1 hak" olarak sunulur
      // (bkz. _showAiLimitChoiceDialog, _watchAdForBonusUse).
      final recipeFuture = _aiRecipeService.generateRecipe(
        prompt,
        languageCode: languageCode,
        mode: 'ingredients',
      );
      await _handleRecipeResult(recipeFuture);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e);
      }
    }
  }

  Future<void> _handleRecipeResult(Future<AiRecipeResult> recipeFuture) async {
    try {
      final aiResult = await recipeFuture;
      final recipeData = aiResult.recipeData;
      AnalyticsService.aiKullanildi(isPro: RevenueCatService.isProUser, kaynak: 'ne_pisirsem');
      await RevenueCatService.syncRemainingFromServer(aiResult.remaining);
      _verileriYukle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      final hedefKlasorId = await _hedefKlasorIdGetir();
      if (!mounted) return;

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
        AnalyticsService.tarifKaydedildi(isAiGenerated: true);
        if (mounted) {
          await ReviewService.onRecipeSaved(context, isAiGenerated: true);
        }
        if (mounted) {
          KilBildirim.goster(
            context,
            'what_to_cook_saved_success'.tr(),
            tur: KilBildirimTuru.basari,
          );
          final kaydedilince = widget.tarifKaydedilince;
          if (kaydedilince != null) {
            _formuSifirla();
            kaydedilince();
          } else {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e is AiLimitExceededException) {
          await RevenueCatService.syncRemainingFromServer(0);
          AnalyticsService.aiLimitDoldu(kaynak: 'ne_pisirsem');
          _showAiLimitChoiceDialog();
        } else {
          _showErrorDialog(e);
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

  /// Günlük AI hakkı bittiğinde gösterilir. Pro kullanıcıya "reklam izle"
  /// ya da "Pro'ya geç" seçenekleri anlamsız olduğundan (zaten Pro ve bonus
  /// hakkı yok), onlara sadece günlük tavanın dolduğunu söyleyen basit bir
  /// bilgi gösterilir; free kullanıcıya eski "reklam/Pro" seçim diyaloğu çıkar.
  Future<void> _showAiLimitChoiceDialog() async {
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
    final secim = await aiHakDolduDialogGoster(context);
    if (!mounted) return;
    switch (secim) {
      case AiHakDolduSecim.reklamIzle:
        _watchAdForBonusUse();
      case AiHakDolduSecim.proyaGec:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'ai_limit_choice')),
        ).then((_) => _verileriYukle());
      case null:
        break;
    }
  }

  /// Kullanıcı "+1 hak" için reklam izlemeyi seçtiğinde çağrılır. Reklam
  /// tam izlenirse backend'den bonus hak istenir ve istek otomatik tekrar
  /// denenir.
  void _watchAdForBonusUse() {
    bool rewardEarned = false;
    AdService.showRewardedAd(
      yer: 'ne_pisirsem',
      onUserEarnedReward: (reward) {
        rewardEarned = true;
      },
      onAdClosed: () async {
        if (!rewardEarned) return; // Reklam tam izlenmeden kapatıldı
        final newRemaining = await _aiRecipeService.grantBonusUse();
        await RevenueCatService.syncRemainingFromServer(newRemaining);
        if (mounted) {
          _tarifiUret();
        }
      },
    );
  }

  void _showErrorDialog(Object error) {
    KilDiyalog.bilgiGoster(
      context,
      ikon: Icons.error_outline_rounded,
      tur: KilDiyalogTuru.tehlike,
      baslik: 'ai_error_title'.tr(),
      mesaj: ErrorHelper.getFriendlyErrorMessage(error),
      tamamEtiketi: 'common_ok'.tr(),
    );
  }

  void _premiumAc(String kaynak) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PremiumSayfasi(source: kaynak)),
    ).then((_) => _verileriYukle());
  }

  /// Ana sayfadaki klasör kartlarıyla aynı renk sırası.
  KlasorRenk _klasorRengi(KilRenkleri r, KlasorData klasor) {
    if (klasor.klasor_id == -1) return r.klasorFavori;
    final renkler = [r.klasorTatli, r.klasorCorba, r.klasorKahvalti];
    final sira = _klasorListesi.indexOf(klasor);
    return renkler[(sira < 0 ? 0 : sira) % renkler.length];
  }

  void _klasorSec() {
    final r = context.kil;
    KilAltSayfa.goster<void>(
      context,
      baslik: 'what_to_cook_select_folder'.tr(),
      builder: (sayfaContext) => KilSecimListesi(
        secenekler: [
          for (final k in _klasorListesi)
            KilSecenek(
              ikon: k.icon,
              renk: _klasorRengi(r, k),
              etiket: klasorGorunenAdi(k),
              secili: k.klasor_id == _hedefKlasor?.klasor_id,
              onTap: () {
                Navigator.pop(sayfaContext);
                setState(() => _hedefKlasor = k);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final pro = RevenueCatService.isProUser;
    // Sekmedeyken geri düğmesi yok; üstüne açıldıysa var. (Rotanın altında
    // sayfa var mı diye bakılır; üstte açık sayfa sayılmaz.)
    final geriVar = ModalRoute.of(context)?.canPop ?? false;
    final hedefKlasor = _hedefKlasor;

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NePisirsemBasligi(
                      baslik: 'what_to_cook_title'.tr(),
                      geriVar: geriVar,
                      proRozeti: pro
                          ? null
                          : ProRozeti(
                              etiket: 'home_pro_badge'.tr(),
                              anlamEtiketi: 'premium_title'.tr(),
                              onPressed: () => _premiumAc('ne_pisirsem_ekrani'),
                            ),
                    ),
                    const SizedBox(height: 12),
                    NePisirsemTanitimKarti(
                      rozet: 'what_to_cook_hero_badge'.tr(),
                      aciklama: 'what_to_cook_subtitle'.tr(),
                    ),
                    const SizedBox(height: 16),
                    NePisirsemHakKarti(
                      pro: pro,
                      metin: pro
                          ? 'what_to_cook_limit_badge_pro'.tr()
                          : 'what_to_cook_limit_badge_free'.tr(
                              args: ['$_kalanHak'],
                            ),
                      eylemEtiketi: pro
                          ? null
                          : 'what_to_cook_make_unlimited'.tr(),
                      onEylem: pro
                          ? null
                          : () => _premiumAc('ne_pisirsem_badge'),
                    ),
                    const SizedBox(height: 24),

                    // Seçilen malzemeler
                    NePisirsemBolumBasligi(
                      metin: 'what_to_cook_selected_ingredients_count'.tr(
                        args: ['${_secilenMalzemeler.length}'],
                      ),
                      eylem: _secilenMalzemeler.isEmpty
                          ? null
                          : TextButton(
                              onPressed: () =>
                                  setState(() => _secilenMalzemeler.clear()),
                              style: TextButton.styleFrom(
                                foregroundColor: r.hata,
                                minimumSize: const Size(48, 48),
                              ),
                              child: Text('common_clear'.tr()),
                            ),
                    ),
                    const SizedBox(height: 8),
                    SeciliMalzemelerKutusu(
                      bosMetin: 'what_to_cook_selected_empty'.tr(),
                      cipler: [
                        for (final m in _secilenMalzemeler)
                          SeciliMalzemeCipi(
                            malzeme: m,
                            kaldirIpucu: MaterialLocalizations.of(
                              context,
                            ).deleteButtonTooltip,
                            onKaldir: () => _malzemeCikar(m),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MalzemeEklemeSatiri(
                      controller: _customMalzemeController,
                      ipucu: 'what_to_cook_custom_hint'.tr(),
                      ekleEtiketi: 'what_to_cook_add_btn'.tr(),
                      onEkle: _malzemeEkle,
                    ),
                    const SizedBox(height: 24),

                    // Popüler malzemeler
                    NePisirsemBolumBasligi(
                      metin: 'what_to_cook_popular_title'.tr(),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final item in _populerMalzemeler)
                          KilCip(
                            etiket: item['name']!,
                            emoji: item['emoji'],
                            secili: _secilenMalzemeler.contains(item['name']),
                            onSelected: (secildi) => secildi
                                ? _malzemeEkle(item['name']!)
                                : _malzemeCikar(item['name']!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Öğün ve süre tercihleri
                    NePisirsemBolumBasligi(
                      metin: 'what_to_cook_meal_type'.tr(),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final ogun in _ogunSecenekleri)
                          KilCip(
                            etiket: ogun,
                            secili: _secilenOgun == ogun,
                            onSelected: (_) =>
                                setState(() => _secilenOgun = ogun),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    NePisirsemBolumBasligi(
                      metin: 'what_to_cook_time_type'.tr(),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final sure in _sureSecenekleri)
                          KilCip(
                            etiket: sure,
                            secili: _secilenSure == sure,
                            onSelected: (_) =>
                                setState(() => _secilenSure = sure),
                          ),
                      ],
                    ),

                    if (hedefKlasor != null) ...[
                      const SizedBox(height: 20),
                      NePisirsemBolumBasligi(
                        metin: 'what_to_cook_select_folder'.tr(),
                      ),
                      const SizedBox(height: 8),
                      KlasorSecimKutusu(
                        ad: klasorGorunenAdi(hedefKlasor),
                        ikon: hedefKlasor.icon,
                        renk: _klasorRengi(r, hedefKlasor),
                        degistirIpucu: 'what_to_cook_select_folder'.tr(),
                        onTap: _klasorSec,
                      ),
                    ],

                    const SizedBox(height: 32),
                    KilDugme.birincil(
                      etiket: 'what_to_cook_generate_btn'.tr(),
                      ikon: Icons.auto_awesome_rounded,
                      tamGenislik: true,
                      buyuk: true,
                      onPressed: _isLoading ? null : _tarifiUret,
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: AiBeklemeKatmani(
                  baslik: 'what_to_cook_loading_title'.tr(),
                  mesajlar: [
                    'what_to_cook_loading_step_1'.tr(),
                    'what_to_cook_loading_step_2'.tr(),
                    'what_to_cook_loading_step_3'.tr(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

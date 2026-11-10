import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../utils/porsiyon_olcekleyici.dart';
import '../utils/malzeme_basliklari.dart';
import '../widgets/kil/kil.dart';
import '../widgets/yemek_modu_parcalari.dart';

/// Düz metin (eski) tariflerde malzemeler ile yapılış adımlarını ayıran
/// başlık kelimeleri; uygulamanın desteklediği 6 dil için, küçük harfle.
const _adimBasliklari = [
  'yapılış', 'hazırlanış', 'hazırlanışı', // tr
  'instructions', 'directions', 'preparation', 'method', // en
  'zubereitung', 'anleitung', // de
  'preparación', 'instrucciones', 'elaboración', // es
  'préparation', 'instructions', // fr
  'preparo', 'modo de preparo', 'instruções', // pt
];

class YemekYapmaModu extends StatefulWidget {
  final TarifData tarif;
  final double portionMultiplier;

  const YemekYapmaModu({
    super.key,
    required this.tarif,
    this.portionMultiplier = 1.0,
  });

  @override
  State<YemekYapmaModu> createState() => _YemekYapmaModuState();
}

class _YemekYapmaModuState extends State<YemekYapmaModu> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _bitiriliyor = false;

  List<String> _malzemeler = [];
  List<String> _adimlar = [];

  /// Malzemelerin arasındaki ara başlıklar ("Kek İçin"); işaretlenmez ve
  /// "hazır" sayısına girmez.
  Set<int> _malzemeBasliklari = {};
  final Set<int> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    AnalyticsService.yemekModuAcildi();
    _parseRecipeContent();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  void _parseRecipeContent() {
    List<String> tempMalzemeler = [];
    List<String> tempAdimlar = [];

    if (widget.tarif.tarif_aciklama_json != null &&
        widget.tarif.tarif_aciklama_json!.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(
          widget.tarif.tarif_aciklama_json!,
        );
        for (var section in decoded) {
          if (section['type'] == 'malzemeler' ||
              section['type'] == 'harc' ||
              section['type'] == 'hamur' ||
              section['type'] == 'serbet' ||
              section['type'] == 'sos') {
            for (var item in (section['items'] ?? [])) {
              tempMalzemeler.add(
                olcekleMalzeme(item.toString(), widget.portionMultiplier),
              );
            }
          } else if (section['type'] == 'yapilis') {
            for (var item in (section['items'] ?? [])) {
              tempAdimlar.add(item.toString());
            }
          }
        }
      } catch (e) {
        debugPrint('JSON parsing error in YemekYapmaModu: $e');
      }
    }

    // Fallback if JSON is empty
    if (tempMalzemeler.isEmpty && tempAdimlar.isEmpty) {
      final lines = widget.tarif.tarif_aciklama.split('\n');
      bool isYapilis = false;
      for (String line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // Dart'ın toLowerCase'i Türkçe I/İ'yi doğru küçültmez ("YAPILIŞ" ->
        // "yapiliş"); başlık eşleşmesi için önce Türkçe harfleri düzelt.
        final lower = trimmed
            .replaceAll('I', 'ı')
            .replaceAll('İ', 'i')
            .toLowerCase();
        if (_adimBasliklari.any(lower.contains)) {
          isYapilis = true;
          continue;
        }

        if (isYapilis) {
          tempAdimlar.add(trimmed);
        } else {
          tempMalzemeler.add(olcekleMalzeme(trimmed, widget.portionMultiplier));
        }
      }
    }

    setState(() {
      // Başlıklar işaretlere bakılarak bulunur; işaretler ondan sonra atılır.
      _malzemeBasliklari = malzemeBaslikIndeksleri(tempMalzemeler);
      _malzemeler = tempMalzemeler.map(malzemeIsaretsiz).toList();
      _adimlar = tempAdimlar;
    });
  }

  void _malzemeyiDegistir(int index) {
    setState(() {
      if (!_checkedIngredients.remove(index)) _checkedIngredients.add(index);
    });
  }

  void _showIngredientsBottomSheet(BuildContext context) {
    KilAltSayfa.goster<void>(
      context,
      dolgu: EdgeInsets.zero,
      builder: (sayfaContext) {
        return StatefulBuilder(
          builder: (sayfaContext, setModalState) {
            final yukseklik = MediaQuery.sizeOf(sayfaContext).height;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: yukseklik * 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: yemekYaziSiniri(
                            Semantics(
                              header: true,
                              child: Text(
                                'cooking_mode_ingredients'.tr(),
                                style: Theme.of(sayfaContext)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: sayfaContext.kil.baslik),
                              ),
                            ),
                          ),
                        ),
                        KilYuvarlakDugme(
                          ikon: Icons.close_rounded,
                          etiket: MaterialLocalizations.of(
                            sayfaContext,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.pop(sayfaContext),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: YemekMalzemeListesi(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      malzemeler: _malzemeler,
                      secililer: _checkedIngredients,
                      basliklar: _malzemeBasliklari,
                      bosMetni: 'cooking_mode_no_ingredients_short'.tr(),
                      onDegistir: (index) {
                        _malzemeyiDegistir(index);
                        setModalState(() {});
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

  /// Sayfa geçişi; "hareketi azalt" açıksa animasyonsuz.
  void _sayfayaGit(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _bitir() async {
    // Değerlendirme beklenirken ikinci dokunuş Navigator.pop'u iki kez
    // çalıştırıp arkadaki tarif sayfasını da kapatıyordu.
    setState(() => _bitiriliyor = true);
    // Tarifi bitirmek mutlu bir an olduğu için değerlendirme isteği burada
    // sorulur.
    AnalyticsService.yemekModuTamamlandi();
    await ReviewService.checkAndRequestReview(context);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final int totalPages = 1 + (_adimlar.isEmpty ? 1 : _adimlar.length);
    final sonSayfa = _currentIndex >= totalPages - 1;

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: yemekYaziSiniri(
                  YemekModuBasligi(
                    baslik: widget.tarif.tarif_adi,
                    malzemeEtiketi: 'cooking_mode_ingredients'.tr(),
                    onMalzemeler: () => _showIngredientsBottomSheet(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: yemekYaziSiniri(
                  YemekSayfaIlerlemesi(
                    konum: _currentIndex == 0
                        ? 'cooking_mode_ingredients'.tr()
                        : _adimlar.isEmpty
                        ? ''
                        : '${'cooking_mode_step'.tr()} $_currentIndex / ${_adimlar.length}',
                    sayfa: _currentIndex,
                    toplamSayfa: totalPages,
                  ),
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
                      return YemekMalzemeListesi(
                        malzemeler: _malzemeler,
                        secililer: _checkedIngredients,
                        basliklar: _malzemeBasliklari,
                        onDegistir: _malzemeyiDegistir,
                        bosMetni: 'cooking_mode_no_ingredients_list'.tr(),
                        ozet: YemekMalzemeOzeti(
                          baslik: 'cooking_mode_ingredients'.tr(),
                          hazirMetni: 'cooking_mode_ready'.tr(),
                          hazir: _checkedIngredients.length,
                          toplam:
                              _malzemeler.length - _malzemeBasliklari.length,
                        ),
                      );
                    }
                    if (_adimlar.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'cooking_mode_no_steps'.tr(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: r.solukYazi),
                          ),
                        ),
                      );
                    }
                    final stepIndex = index - 1;
                    return YemekAdimSayfasi(
                      numara: stepIndex + 1,
                      adimEtiketi: 'cooking_mode_step'.tr(),
                      metin: _adimlar[stepIndex],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: yemekYaziSiniri(
                  YemekModuAltCubuk(
                    oncekiEtiketi: 'cooking_mode_previous'.tr(),
                    ileriEtiketi: sonSayfa
                        ? 'cooking_mode_finish'.tr()
                        : 'cooking_mode_next_step'.tr(),
                    sonSayfa: sonSayfa,
                    onOnceki: _currentIndex > 0
                        ? () => _sayfayaGit(_currentIndex - 1)
                        : null,
                    onIleri: !sonSayfa
                        ? () => _sayfayaGit(_currentIndex + 1)
                        : _bitiriliyor
                        ? null
                        : _bitir,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

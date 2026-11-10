import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';
import '../services/analytics_service.dart';
import '../utils/abonelik_kosullari.dart';
import '../widgets/kil/kil.dart';
import '../widgets/premium_parcalari.dart';

class PremiumSayfasi extends StatefulWidget {
  /// Bu ekranın hangi noktadan açıldığı (ör. "ai_limit", "klasor_limit",
  /// "tarif_limit", "link_pro_only", "ayarlar", "ana_ekran"). Analytics'te
  /// paywall_goruldu olayının "source" parametresi olarak kullanılır.
  final String source;

  const PremiumSayfasi({super.key, this.source = 'unknown'});

  /// Paketleri getiren işlev. Uygulamada RevenueCat; testte sahte paketler
  /// verilebilsin diye değiştirilebilir.
  @visibleForTesting
  static Future<List<Offering>> Function() paketGetir = RevenueCatService.getOfferings;

  @override
  State<PremiumSayfasi> createState() => _PremiumSayfasiState();
}

class _PremiumSayfasiState extends State<PremiumSayfasi> {
  List<Offering> _offerings = [];
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;

  /// Satın alma veya geri yükleme başarılı olduysa true; bu durumda ekranın
  /// kapanması "vazgeçti" sayılmaz ve paywall_kapatildi gönderilmez.
  bool _proAktiflesti = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.paywallGoruldu(widget.source);
    _fetchOfferings();
  }

  @override
  void dispose() {
    if (!_proAktiflesti) AnalyticsService.paywallKapatildi(widget.source);
    super.dispose();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await PremiumSayfasi.paketGetir();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
        if (offerings.isNotEmpty && offerings.first.availablePackages.isNotEmpty) {
          final packages = offerings.first.availablePackages;
          // Yıllık paket varsa varsayılan seçim o olsun (en çok önerdiğimiz plan).
          _selectedPackage = packages.firstWhere(
            (p) => p.packageType == PackageType.annual,
            orElse: () => packages.first,
          );
        }
      });
    }
  }

  /// Paketleri kullanıcı dostu bir sırayla (aylık → yıllık → ömür boyu) dizer.
  List<Package> _sortedPackages(List<Package> packages) {
    const order = {
      PackageType.weekly: 0,
      PackageType.monthly: 1,
      PackageType.twoMonth: 2,
      PackageType.threeMonth: 3,
      PackageType.sixMonth: 4,
      PackageType.annual: 5,
      PackageType.lifetime: 6,
    };
    final sorted = [...packages];
    sorted.sort((a, b) => (order[a.packageType] ?? 99).compareTo(order[b.packageType] ?? 99));
    return sorted;
  }

  /// Aynı offering içinde hem aylık hem yıllık paket varsa, yıllığın aylığa
  /// göre gerçek tasarruf yüzdesini hesaplar (sabit "%40" gibi yanlış
  /// olabilecek bir sayı yazmak yerine, panelde girilen gerçek fiyatlardan).
  int? _annualSavingsPercent() {
    if (_offerings.isEmpty) return null;
    final packages = _offerings.first.availablePackages;
    Package? monthly;
    Package? annual;
    for (final p in packages) {
      if (p.packageType == PackageType.monthly) monthly = p;
      if (p.packageType == PackageType.annual) annual = p;
    }
    if (monthly == null || annual == null || monthly.storeProduct.price <= 0) return null;
    final monthlyEquivalentOfAnnual = annual.storeProduct.price / 12;
    final savings = (1 - (monthlyEquivalentOfAnnual / monthly.storeProduct.price)) * 100;
    if (savings <= 0) return null;
    return savings.round();
  }

  String _packageTitle(Package pkg) {
    switch (pkg.packageType) {
      case PackageType.annual:
        return 'premium_plan_annual_title'.tr();
      case PackageType.monthly:
        return 'premium_plan_monthly_title'.tr();
      case PackageType.lifetime:
        return 'premium_plan_lifetime_title'.tr();
      default:
        return pkg.storeProduct.title;
    }
  }

  String _packageDescription(Package pkg) {
    switch (pkg.packageType) {
      case PackageType.annual:
        final savings = _annualSavingsPercent();
        return savings != null
            ? 'premium_plan_annual_desc_with_savings'.tr(args: ['$savings'])
            : 'premium_plan_annual_desc'.tr();
      case PackageType.monthly:
        return 'premium_plan_monthly_desc'.tr();
      case PackageType.lifetime:
        return 'premium_plan_lifetime_desc'.tr();
      default:
        return pkg.storeProduct.description;
    }
  }

  /// Seçili plana göre abonelik koşulları metni; paket yüklenemediyse
  /// platformun genel metni gösterilir.
  String _abonelikKosullariMetni() {
    final pkg = _selectedPackage;
    if (pkg == null) {
      return genelKosulAnahtari(isIOS: Platform.isIOS).tr();
    }
    final kosul = abonelikKosullari(pkg.packageType, pkg.storeProduct.priceString, isIOS: Platform.isIOS);
    return kosul.key.tr(args: kosul.args);
  }

  /// "En avantajlı" rozeti yalnızca yıllık pakette gösterilir.
  String? _packageBadge(Package pkg) {
    if (pkg.packageType == PackageType.annual) {
      return 'premium_badge_most_popular'.tr();
    }
    return null;
  }

  Future<void> _purchase(Package package) async {
    setState(() => _isPurchasing = true);
    final sonuc = await RevenueCatService.purchasePackage(package);
    if (sonuc == SatinAlmaSonucu.basarili) {
      _proAktiflesti = true;
      AnalyticsService.satinAlma(
        packageId: package.identifier,
        priceString: package.storeProduct.priceString,
        source: widget.source,
      );
    } else {
      AnalyticsService.satinAlmaBasarisiz(
        source: widget.source,
        packageId: package.identifier,
        iptalEdildi: sonuc == SatinAlmaSonucu.iptal,
      );
    }
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (sonuc == SatinAlmaSonucu.basarili) {
        KilBildirim.goster(
          context,
          'premium_success'.tr(),
          tur: KilBildirimTuru.basari,
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    bool success = await RevenueCatService.restorePurchases();
    if (success) _proAktiflesti = true;
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        KilBildirim.goster(
          context,
          'premium_restored'.tr(),
          tur: KilBildirimTuru.basari,
        );
        Navigator.pop(context, true);
      } else {
        KilBildirim.goster(
          context,
          'premium_restore_failed'.tr(),
          // Profil'deki gibi bilgi (gri); bir hata değil.
          tur: KilBildirimTuru.bilgi,
        );
      }
    }
  }

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  /// RevenueCat'in ham teşhis mesajını (ör. "App Store Connect > Agreements...",
  /// "Service Account (JSON)...") yalnızca debug build'de gösterir; gerçek
  /// kullanıcılara bu geliştirici mesajları yerine genel, güven veren bir
  /// metin gösterilir. Hata yine de debugPrint ile konsola düşer.
  String _userFacingOfferingsError() {
    final raw = RevenueCatService.lastOfferingsError;
    if (raw == null) return 'premium_connection_error_generic'.tr();
    debugPrint('RevenueCat offerings error: $raw');
    if (kDebugMode) return raw;
    return 'premium_connection_error_generic'.tr();
  }

  void _showErrorDialog(String errorDetail) {
    showDialog(
      context: context,
      builder: (ctx) {
        final r = ctx.kil;
        final yazi = Theme.of(ctx).textTheme;
        return KilDiyalog(
          ikon: Icons.info_outline_rounded,
          baslik: 'premium_package_error_title'.tr(),
          mesaj: 'premium_package_error_body'.tr(),
          icerik: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: r.hataZemin,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  errorDetail,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: r.hataZeminYazi,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                Platform.isIOS
                    ? 'premium_package_error_reasons_ios'.tr()
                    : 'premium_package_error_reasons_android'.tr(),
                style: yazi.bodySmall?.copyWith(color: r.solukYazi, height: 1.5),
              ),
            ],
          ),
          eylemler: [
            KilDugme.birincil(
              etiket: 'common_ok'.tr(),
              tamGenislik: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        );
      },
    );
  }

  /// Satın al düğmesi: paket seçiliyse satın alır; değilse paketleri yeniden
  /// ister, gelmezse hata ayrıntısını gösterir.
  Future<void> _satinAlDugmesineBasildi() async {
    if (_selectedPackage != null) {
      _purchase(_selectedPackage!);
      return;
    }
    setState(() => _isPurchasing = true);
    await _fetchOfferings();
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (_selectedPackage != null) {
      _purchase(_selectedPackage!);
      return;
    }

    _showErrorDialog(_userFacingOfferingsError());
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final paketVar = _offerings.isNotEmpty && _offerings.first.availablePackages.isNotEmpty;
    final geriYukle = _isPurchasing ? null : _restore;
    final yanBosluk = premiumUstUsteMi(context) ? 16.0 : 20.0;

    final icerik = <Widget>[
      PremiumUstSatiri(
        kapatEtiketi: MaterialLocalizations.of(context).closeButtonTooltip,
        onKapat: () => Navigator.pop(context),
        geriYukleEtiketi: 'premium_restore'.tr(),
        onGeriYukle: geriYukle,
      ),
      const SizedBox(height: 4),
      PremiumTanitim(
        rozet: 'premium_badge_pro'.tr(),
        baslik: 'premium_headline'.tr(),
        altBaslik: 'premium_subtitle'.tr(),
      ),
      const SizedBox(height: 24),
      PremiumOzellikKarti(
        ozellikler: [
          PremiumOzellik(
            ikon: Icons.restaurant_menu_rounded,
            baslik: 'premium_feature_what_to_cook'.tr(),
            aciklama: 'premium_feature_what_to_cook_desc'.tr(),
          ),
          PremiumOzellik(
            ikon: Icons.link_rounded,
            baslik: 'premium_feature_web_link'.tr(),
            aciklama: 'premium_feature_web_link_desc'.tr(),
          ),
          PremiumOzellik(
            ikon: Icons.folder_special_rounded,
            baslik: 'premium_feature_unlimited'.tr(),
            aciklama: 'premium_feature_unlimited_desc'.tr(),
          ),
          PremiumOzellik(
            ikon: Icons.block_rounded,
            baslik: 'premium_feature_zero_ads'.tr(),
            aciklama: 'premium_feature_zero_ads_desc'.tr(),
          ),
        ],
      ),
      const SizedBox(height: 24),
      if (paketVar)
        for (final pkg in _sortedPackages(_offerings.first.availablePackages)) ...[
          PremiumPlanKarti(
            baslik: _packageTitle(pkg),
            aciklama: _packageDescription(pkg),
            fiyat: pkg.storeProduct.priceString,
            secili: _selectedPackage == pkg,
            onTap: _isPurchasing ? null : () => setState(() => _selectedPackage = pkg),
            rozet: _packageBadge(pkg),
          ),
          const SizedBox(height: 12),
        ]
      else ...[
        // Mağazadan fiyat çekilemediğinde gösterilir.
        PremiumPlanKarti(
          baslik: 'premium_fallback_package_title'.tr(),
          aciklama: 'premium_fallback_package_desc'.tr(),
          fiyat: 'premium_price_unavailable'.tr(),
          fiyatAltta: true,
          secili: true,
          onTap: _isPurchasing
              ? null
              : () {
                  if (RevenueCatService.lastOfferingsError != null) {
                    _showErrorDialog(_userFacingOfferingsError());
                  }
                },
        ),
        const SizedBox(height: 12),
        if (RevenueCatService.lastOfferingsError != null) ...[
          PremiumHataSatiri(
            metin: '${'premium_error_detail_tap_prefix'.tr()}${_userFacingOfferingsError()}',
            onTap: () => _showErrorDialog(_userFacingOfferingsError()),
          ),
          const SizedBox(height: 12),
        ],
      ],
      const SizedBox(height: 4),
      KilDugme.birincil(
        etiket: 'premium_cta_button'.tr(),
        ikon: Icons.stars_rounded,
        tamGenislik: true,
        buyuk: true,
        onPressed: _isPurchasing ? null : _satinAlDugmesineBasildi,
      ),
      if (iptalNotuGosterilsinMi(_selectedPackage?.packageType)) ...[
        const SizedBox(height: 12),
        Text(
          'premium_cancel_anytime'.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: r.solukYazi),
        ),
      ],
      const SizedBox(height: 24),
      // Apple kural 3.1.2: otomatik yenilenen abonelik koşulları.
      PremiumKosullarKarti(
        baslik: 'premium_sub_terms_title'.tr(),
        metin: _abonelikKosullariMetni(),
        baglantilar: [
          PremiumBaglanti(
            etiket: 'premium_terms_of_use'.tr(),
            onTap: () => _openUrl(kullanimKosullariAdresi(isIOS: Platform.isIOS)),
          ),
          PremiumBaglanti(
            etiket: 'premium_privacy_policy'.tr(),
            onTap: () => _openUrl('https://sudekazan.github.io/tarifDefteri/privacy.html'),
          ),
          PremiumBaglanti(
            etiket: 'premium_restore_purchases'.tr(),
            onTap: geriYukle,
          ),
        ],
      ),
    ];

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(r.birincil),
                ),
              )
            : Stack(
                children: [
                  SafeArea(
                    child: ListView(
                      // Büyük yazıda uzun kelimeler bölünmesin diye kenar
                      // boşluğu daralır.
                      padding: EdgeInsets.fromLTRB(yanBosluk, 4, yanBosluk, 28),
                      children: icerik,
                    ),
                  ),
                  if (_isPurchasing) const PremiumBeklemeKatmani(),
                ],
              ),
      ),
    );
  }
}

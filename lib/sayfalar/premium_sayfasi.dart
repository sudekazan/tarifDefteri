import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';

class PremiumSayfasi extends StatefulWidget {
  const PremiumSayfasi({super.key});

  @override
  State<PremiumSayfasi> createState() => _PremiumSayfasiState();
}

class _PremiumSayfasiState extends State<PremiumSayfasi> {
  List<Offering> _offerings = [];
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await RevenueCatService.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
        if (offerings.isNotEmpty && offerings.first.availablePackages.isNotEmpty) {
          _selectedPackage = offerings.first.availablePackages.first;
        }
      });
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() => _isPurchasing = true);
    bool success = await RevenueCatService.purchasePackage(package);
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('premium_success'.tr()),
            backgroundColor: const Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    bool success = await RevenueCatService.restorePurchases();
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('premium_restored'.tr()),
            backgroundColor: const Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('premium_restore_failed'.tr()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFE65100), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'premium_package_error_title'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'premium_package_error_body'.tr(),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCCBC)),
                ),
                child: SelectableText(
                  errorDetail,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFBF360C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                Platform.isIOS
                    ? 'premium_package_error_reasons_ios'.tr()
                    : 'premium_package_error_reasons_android'.tr(),
                style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common_ok'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131520) : const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : const Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isPurchasing ? null : _restore,
            child: Text(
              'premium_restore'.tr(),
              style: const TextStyle(
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Gourmet Hero Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA000), Color(0xFFFFD54F)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFA000).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFF3E2723)),
                              const SizedBox(width: 6),
                              Text(
                                'premium_badge_pro'.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF3E2723),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chef Icon Circle
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE65100).withOpacity(0.32),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🧑‍🍳', style: TextStyle(fontSize: 44)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Headline
                      Text(
                        'premium_headline'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF3E2723),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'premium_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: isDark ? Colors.white70 : const Color(0xFF795548),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Feature Cards Grid/List
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2235) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFFFE0B2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE65100).withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildModernFeatureRow(
                              icon: Icons.restaurant_menu_rounded,
                              iconBg: const Color(0xFFE65100),
                              title: 'premium_feature_what_to_cook'.tr(),
                              desc: 'premium_feature_what_to_cook_desc'.tr(),
                              isDark: isDark,
                            ),
                            Divider(color: isDark ? Colors.white10 : const Color(0xFFFFF3E0), height: 24),
                            _buildModernFeatureRow(
                              icon: Icons.link_rounded,
                              iconBg: const Color(0xFF1976D2),
                              title: 'premium_feature_web_link'.tr(),
                              desc: 'premium_feature_web_link_desc'.tr(),
                              isDark: isDark,
                            ),
                            Divider(color: isDark ? Colors.white10 : const Color(0xFFFFF3E0), height: 24),
                            _buildModernFeatureRow(
                              icon: Icons.folder_special_rounded,
                              iconBg: const Color(0xFFFFA000),
                              title: 'premium_feature_unlimited'.tr(),
                              desc: 'premium_feature_unlimited_desc'.tr(),
                              isDark: isDark,
                            ),
                            Divider(color: isDark ? Colors.white10 : const Color(0xFFFFF3E0), height: 24),
                            _buildModernFeatureRow(
                              icon: Icons.block_rounded,
                              iconBg: const Color(0xFF2ECC71),
                              title: 'premium_feature_zero_ads'.tr(),
                              desc: 'premium_feature_zero_ads_desc'.tr(),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Packages Section
                      if (_offerings.isNotEmpty && _offerings.first.availablePackages.isNotEmpty) ...[
                        ..._offerings.first.availablePackages.map((pkg) {
                          final isSelected = _selectedPackage == pkg;
                          return _buildPackageCard(
                            title: pkg.storeProduct.title,
                            description: pkg.storeProduct.description,
                            priceString: pkg.storeProduct.priceString,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedPackage = pkg),
                            badgeText: 'premium_badge_most_popular'.tr(),
                            isDark: isDark,
                          );
                        }),
                      ] else ...[
                        // Fallback UI (mağazadan fiyat çekilemediğinde gösterilir)
                        _buildPackageCard(
                          title: 'premium_fallback_package_title'.tr(),
                          description: 'premium_fallback_package_desc'.tr(),
                          priceString: 'premium_price_unavailable'.tr(),
                          isSelected: true,
                          badgeText: 'premium_badge_most_popular'.tr(),
                          onTap: () {
                            if (RevenueCatService.lastOfferingsError != null) {
                              _showErrorDialog(_userFacingOfferingsError());
                            }
                          },
                          isDark: isDark,
                        ),
                        if (RevenueCatService.lastOfferingsError != null) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _showErrorDialog(_userFacingOfferingsError()),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFCC80)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFE65100)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${'premium_error_detail_tap_prefix'.tr()}${_userFacingOfferingsError()}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFD84315), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 16, color: Color(0xFFE65100)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 16),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isPurchasing
                              ? null
                              : () async {
                                  if (_selectedPackage != null) {
                                    _purchase(_selectedPackage!);
                                  } else {
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
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 8,
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
                                  const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'premium_cta_button'.tr(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Trust & Cancel Info
                      Center(
                        child: Text(
                          'premium_cancel_anytime'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : const Color(0xFF8D6E63),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Apple Guideline 3.1.2 - Auto-Renewable Subscription Terms
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2235) : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFFFE0B2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'premium_sub_terms_title'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF4E342E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'premium_sub_terms_body'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF6D4C41),
                                fontSize: 11,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Divider(color: isDark ? Colors.white12 : const Color(0xFFFFCC80), height: 24),
                            // Clickable Legal Links
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                InkWell(
                                  onTap: () => _openUrl(
                                    Platform.isIOS
                                        ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
                                        : 'https://sudekazan.github.io/tarifDefteri/terms.html',
                                  ),
                                  child: Text(
                                    'premium_terms_of_use'.tr(),
                                    style: const TextStyle(
                                      color: Color(0xFFE65100),
                                      fontSize: 11,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text('•', style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFFBCAAA4), fontSize: 11)),
                                InkWell(
                                  onTap: () => _openUrl('https://sudekazan.github.io/tarifDefteri/privacy.html'),
                                  child: Text(
                                    'premium_privacy_policy'.tr(),
                                    style: const TextStyle(
                                      color: Color(0xFFE65100),
                                      fontSize: 11,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text('•', style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFFBCAAA4), fontSize: 11)),
                                InkWell(
                                  onTap: _isPurchasing ? null : _restore,
                                  child: Text(
                                    'premium_restore_purchases'.tr(),
                                    style: const TextStyle(
                                      color: Color(0xFFE65100),
                                      fontSize: 11,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
                if (_isPurchasing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildModernFeatureRow({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconBg, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF8D6E63),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71), size: 20),
      ],
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String description,
    required String priceString,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    String? badgeText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF2A2035) : const Color(0xFFFFF8E1))
            : (isDark ? const Color(0xFF1E2235) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFE65100) : (isDark ? Colors.white12 : const Color(0xFFFFE0B2)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFE65100).withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isPurchasing ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE65100) : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFFE65100) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF3E2723),
                              ),
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA000),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF8D6E63),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  priceString,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

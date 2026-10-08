import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';

class PremiumSayfasi extends StatefulWidget {
  const PremiumSayfasi({Key? key}) : super(key: key);

  @override
  State<PremiumSayfasi> createState() => _PremiumSayfasiState();
}

class _PremiumSayfasiState extends State<PremiumSayfasi> {
  List<Offering> _offerings = [];
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
          SnackBar(content: Text('premium_success'.tr), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Pro oldu bilgisini döndür
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
          SnackBar(content: Text('premium_restored'.tr), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('premium_restore_failed'.tr), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('premium_title'.tr(defaultValue: 'Premium\'a Geç')),
        actions: [
          TextButton(
            onPressed: _isPurchasing ? null : _restore,
            child: Text('premium_restore'.tr, style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.workspace_premium, size: 100, color: Colors.amber[700]),
                      const SizedBox(height: 24),
                      Text(
                        'premium_headline'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      _buildFeatureRow(Icons.no_cell, 'premium_feature_ads'.tr),
                      const SizedBox(height: 16),
                      _buildFeatureRow(Icons.auto_awesome, 'premium_feature_ai'.tr),
                      const SizedBox(height: 16),
                      _buildFeatureRow(Icons.link, 'premium_feature_link'.tr),
                      
                      const SizedBox(height: 48),
                      
                      if (_offerings.isNotEmpty && _offerings.first.availablePackages.isNotEmpty)
                        ..._offerings.first.availablePackages.map((pkg) => _buildPackageCard(pkg)).toList()
                      else
                        Center(
                          child: Text(
                            'premium_no_packages'.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isPurchasing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  )
              ],
            ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber[700], size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(Package pkg) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _isPurchasing ? null : () => _purchase(pkg),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.storeProduct.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pkg.storeProduct.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                pkg.storeProduct.priceString,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

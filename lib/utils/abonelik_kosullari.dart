import 'package:purchases_flutter/purchases_flutter.dart';

/// Paywall'daki abonelik koşulları metni için seçili plana göre çeviri
/// anahtarını ve fiyat argümanını döndürür (Apple kural 3.1.2: süre ve fiyat
/// seçilen plana uygun olmalı). Bilinmeyen plan türünde eski genel metne düşer.
({String key, List<String> args}) abonelikKosullari(
  PackageType type,
  String priceString, {
  required bool isIOS,
}) {
  final platform = isIOS ? 'ios' : 'android';
  switch (type) {
    case PackageType.monthly:
      return (key: 'premium_terms_monthly_$platform', args: [priceString]);
    case PackageType.annual:
      return (key: 'premium_terms_annual_$platform', args: [priceString]);
    case PackageType.lifetime:
      return (key: 'premium_terms_lifetime', args: [priceString]);
    default:
      return (key: 'premium_sub_terms_body', args: const []);
  }
}

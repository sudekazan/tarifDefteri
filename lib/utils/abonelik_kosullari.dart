import 'package:purchases_flutter/purchases_flutter.dart';

/// Paywall'daki abonelik koşulları metni için seçili plana göre çeviri
/// anahtarını ve fiyat argümanını döndürür (Apple kural 3.1.2: süre ve fiyat
/// seçilen plana uygun olmalı). Bilinmeyen plan türünde platformun genel
/// metnine düşer.
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
      return (key: genelKosulAnahtari(isIOS: isIOS), args: const []);
  }
}

/// Paket yüklenemediğinde ya da plan türü bilinmediğinde gösterilen genel
/// koşul metni. iOS'ta Apple Kimliği, Android'de Google Play hesabı der.
String genelKosulAnahtari({required bool isIOS}) =>
    isIOS ? 'premium_sub_terms_body' : 'premium_sub_terms_body_android';

/// "Kullanım koşulları" bağlantısı: iOS'ta Apple'ın standart sözleşmesi,
/// Android'de uygulamanın kendi koşulları. Premium ve Profil aynı adresi açar.
String kullanimKosullariAdresi({required bool isIOS}) => isIOS
    ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
    : 'https://sudekazan.github.io/tarifDefteri/terms.html';

/// "İstediğiniz zaman iptal edebilirsiniz" notu yalnızca yenilenen
/// planlarda gösterilir; ömür boyu tek seferlik ödemedir, iptal edilecek
/// abonelik yoktur. Plan henüz yüklenmediyse ([tur] null) not gösterilir.
bool iptalNotuGosterilsinMi(PackageType? tur) => tur != PackageType.lifetime;

import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tarif_defteri/utils/abonelik_kosullari.dart';

void main() {
  test('yıllık plan Android\'de Google Play metnini ve fiyatı kullanır', () {
    final sonuc = abonelikKosullari(PackageType.annual, '₺100', isIOS: false);

    expect(sonuc.key, 'premium_terms_annual_android');
    expect(sonuc.args, ['₺100']);
  });

  test('aylık plan iOS\'ta Apple metnini kullanır', () {
    final sonuc = abonelikKosullari(PackageType.monthly, r'$4.99', isIOS: true);

    expect(sonuc.key, 'premium_terms_monthly_ios');
    expect(sonuc.args, [r'$4.99']);
  });

  test('ömür boyu plan iki platformda da aynı, yenilenmez metnini kullanır', () {
    expect(abonelikKosullari(PackageType.lifetime, '₺500', isIOS: true).key, 'premium_terms_lifetime');
    expect(abonelikKosullari(PackageType.lifetime, '₺500', isIOS: false).key, 'premium_terms_lifetime');
    expect(abonelikKosullari(PackageType.lifetime, '₺500', isIOS: false).args, ['₺500']);
  });

  test('bilinmeyen plan türü eski genel metne düşer', () {
    final sonuc = abonelikKosullari(PackageType.weekly, '₺10', isIOS: true);

    expect(sonuc.key, 'premium_sub_terms_body');
    expect(sonuc.args, isEmpty);
  });
}

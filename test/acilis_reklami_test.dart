import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/services/ad_service.dart';

void main() {
  final acilis = DateTime(2026, 11, 10, 12);
  bool gosterilir(Duration gecen, {bool anaEkranda = true}) =>
      AdService.acilisReklamiGosterilebilir(
        acilisAni: acilis,
        simdi: acilis.add(gecen),
        anaEkranda: anaEkranda,
      );

  test('pencere içinde yüklenen açılış reklamı gösterilir', () {
    expect(gosterilir(const Duration(seconds: 2)), isTrue);
    expect(gosterilir(AdService.acilisReklamPenceresi), isTrue);
  });

  test('geç yüklenen açılış reklamı gösterilmez', () {
    expect(
      gosterilir(
        AdService.acilisReklamPenceresi + const Duration(milliseconds: 1),
      ),
      isFalse,
    );
    expect(gosterilir(const Duration(seconds: 10)), isFalse);
  });

  test('kullanıcı ana ekrandan ayrıldıysa pencere içinde de gösterilmez', () {
    expect(gosterilir(const Duration(seconds: 1), anaEkranda: false), isFalse);
  });
}

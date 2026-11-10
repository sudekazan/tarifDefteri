import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarif_defteri/services/review_service.dart';

void main() {
  late DateTime saat;
  late int gosterilen;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    saat = DateTime(2026, 11, 1, 12);
    gosterilen = 0;
    ReviewService.simdi = () => saat;
    ReviewService.pencereyiGoster = () async => gosterilen++;
  });

  Future<BuildContext> baglam(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    return tester.element(find.byType(SizedBox));
  }

  testWidgets('ilk açılıştan 7 gün sonraki ilk tetiklemede sorulur', (tester) async {
    final context = await baglam(tester);
    await ReviewService.ilkAcilisiKaydet();

    saat = saat.add(const Duration(days: 6));
    await ReviewService.checkAndRequestReview(context);
    expect(gosterilen, 0);

    saat = saat.add(const Duration(days: 1));
    await ReviewService.checkAndRequestReview(context);
    expect(gosterilen, 1);
  });

  testWidgets('sonraki açılışlar ilk açılış tarihini değiştirmez', (tester) async {
    final context = await baglam(tester);
    await ReviewService.ilkAcilisiKaydet();
    saat = saat.add(const Duration(days: 8));
    await ReviewService.ilkAcilisiKaydet();

    await ReviewService.checkAndRequestReview(context);
    expect(gosterilen, 1);
  });

  testWidgets('sorulduktan sonra 30 gün dolmadan yeniden sorulmaz', (tester) async {
    final context = await baglam(tester);
    await ReviewService.ilkAcilisiKaydet();
    saat = saat.add(const Duration(days: 7));
    await ReviewService.checkAndRequestReview(context);

    saat = saat.add(const Duration(days: 29));
    await ReviewService.checkAndRequestReview(context);
    expect(gosterilen, 1);

    saat = saat.add(const Duration(days: 1));
    await ReviewService.checkAndRequestReview(context);
    expect(gosterilen, 2);
  });

  testWidgets('5. tarif ilk 7 günde kaydedilirse istek bekleme dolunca sorulur', (tester) async {
    final context = await baglam(tester);
    await ReviewService.ilkAcilisiKaydet();
    for (var i = 0; i < 5; i++) {
      await ReviewService.onRecipeSaved(context);
    }
    expect(gosterilen, 0);

    saat = saat.add(const Duration(days: 7));
    await ReviewService.onRecipeSaved(context);
    expect(gosterilen, 1);
  });

  testWidgets('5 tarifin altında elle kayıt sormaz, yapay zekâ tarifi sorar', (tester) async {
    final context = await baglam(tester);
    await ReviewService.ilkAcilisiKaydet();
    saat = saat.add(const Duration(days: 7));

    await ReviewService.onRecipeSaved(context);
    expect(gosterilen, 0);
    await ReviewService.onRecipeSaved(context, isAiGenerated: true);
    expect(gosterilen, 1);
  });

  testWidgets('değerlendiren kullanıcıya sorulmaz', (tester) async {
    final context = await baglam(tester);
    await ReviewService.ilkAcilisiKaydet();
    await ReviewService.markAsRated();
    saat = saat.add(const Duration(days: 40));

    await ReviewService.checkAndRequestReview(context);
    expect(gosterilen, 0);
  });
}

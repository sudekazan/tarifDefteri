import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/screens/update_screen.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:upgrader/upgrader.dart';

Widget _sar(
  Widget child, {
  double yaziOlcegi = 1,
  KilRenkleri renkler = KilRenkleri.acik,
}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: renkler.sertGolge ? Brightness.light : Brightness.dark,
      extensions: [renkler],
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(yaziOlcegi)),
      child: child!,
    ),
    home: Scaffold(body: child),
  );
}

Widget _diyalog(List<String> cagrilar, {bool engelli = false}) =>
    guncellemeKilDiyalogu(
      baslik: 'Yeni Güncelleme Mevcut!',
      mesaj: 'Tarifly için yeni ve daha gelişmiş bir sürüm hazır!',
      soru: 'Şimdi güncellemek ister misiniz?',
      yenilikBasligi: 'Yenilikler',
      yenilikler: 'Kil tasarımı',
      guncelleEtiketi: 'Şimdi Güncelle',
      sonraEtiketi: 'Daha Sonra',
      yoksayEtiketi: 'Yoksay',
      engelli: engelli,
      sonraGoster: true,
      yoksayGoster: false,
      onGuncelle: () => cagrilar.add('guncelle'),
      onSonra: () => cagrilar.add('sonra'),
      onYoksay: () => cagrilar.add('yoksay'),
    );

void main() {
  test('iOS ve macOS Cupertino, diğerleri kil (Material)', () {
    expect(guncellemeDiyalogStili(TargetPlatform.iOS),
        UpgradeDialogStyle.cupertino);
    expect(guncellemeDiyalogStili(TargetPlatform.macOS),
        UpgradeDialogStyle.cupertino);
    expect(guncellemeDiyalogStili(TargetPlatform.android),
        UpgradeDialogStyle.material);
  });

  testWidgets('düğmeler doğru işlemi çağırır; yoksay gizli', (tester) async {
    final cagrilar = <String>[];
    await tester.pumpWidget(_sar(_diyalog(cagrilar)));
    expect(find.text('Yenilikler'), findsOneWidget);
    expect(find.text('Kil tasarımı'), findsOneWidget);
    expect(find.text('Yoksay'), findsNothing);
    await tester.tap(find.text('Şimdi Güncelle'));
    await tester.tap(find.text('Daha Sonra'));
    expect(cagrilar, ['guncelle', 'sonra']);
  });

  testWidgets('engelleyici sürümde "Daha Sonra" çıkmaz', (tester) async {
    await tester.pumpWidget(_sar(_diyalog([], engelli: true)));
    expect(find.text('Daha Sonra'), findsNothing);
    expect(find.text('Şimdi Güncelle'), findsOneWidget);
  });

  for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
    testWidgets(
        '${renkler.sertGolge ? 'açık' : 'koyu'}: 320 genişlik, 3.2 katta taşma yok',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          _sar(_diyalog([]), yaziOlcegi: 3.2, renkler: renkler));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

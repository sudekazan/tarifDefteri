import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tarif_defteri/builders/app_theme_builder.dart';
import 'package:tarif_defteri/theme/kil_renkleri.dart';

/// Temayı kurar. google_fonts testte font dosyası bulamayınca arka planda hata
/// fırlatır; burada yalnızca stil değerleri denendiği için o hata yutulur.
ThemeData kur(ThemeData Function() kurucu) {
  GoogleFonts.config.allowRuntimeFetching = false;
  late ThemeData tema;
  runZonedGuarded(() => tema = kurucu(), (_, _) {});
  return tema;
}

List<TextStyle> stiller(TextTheme t) => [
      t.displayLarge!, t.displayMedium!, t.displaySmall!,
      t.headlineLarge!, t.headlineMedium!, t.headlineSmall!,
      t.titleLarge!, t.titleMedium!, t.titleSmall!,
      t.bodyLarge!, t.bodyMedium!, t.bodySmall!,
      t.labelLarge!, t.labelMedium!, t.labelSmall!,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gömülü fontlar internetsiz yüklenir', () async {
    // Dosya eksikse ya da adı uymuyorsa fontlariHazirla hata fırlatır.
    await AppThemeBuilder.fontlariHazirla();
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);

    final dosyalar =
        (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets();
    expect(
      dosyalar,
      containsAll([
        'assets/fonts/Quicksand-Medium.ttf',
        'assets/fonts/Quicksand-Bold.ttf',
        'assets/fonts/Caveat-Bold.ttf',
        'assets/fonts/OFL-Quicksand.txt',
        'assets/fonts/OFL-Caveat.txt',
      ]),
    );
  });

  for (final (ad, kurucu, renkler) in [
    ('açık', AppThemeBuilder.buildLightTheme, KilRenkleri.acik),
    ('koyu', AppThemeBuilder.buildDarkTheme, KilRenkleri.koyu),
  ]) {
    group('$ad tema', () {
      final tema = kur(kurucu);

      test('KilRenkleri ve zemin doğru', () {
        expect(tema.extension<KilRenkleri>(), renkler);
        expect(tema.scaffoldBackgroundColor, renkler.zemin);
        expect(tema.colorScheme.primary, renkler.birincil);
        expect(tema.colorScheme.error, renkler.hata);
      });

      test('en küçük yazı 11 pt', () {
        for (final s in stiller(tema.textTheme)) {
          expect(s.fontSize, greaterThanOrEqualTo(11), reason: '$s');
        }
      });

      test('Caveat yalnızca 22 pt ve üstünde, diğerleri Quicksand', () {
        for (final s in stiller(tema.textTheme)) {
          final aile = s.fontFamily ?? '';
          if (aile.startsWith('Caveat')) {
            expect(s.fontSize, greaterThanOrEqualTo(22), reason: '$s');
            expect(s.fontWeight, FontWeight.w700);
          } else {
            expect(aile, startsWith('Quicksand'), reason: '$s');
            expect(s.fontWeight, anyOf(FontWeight.w500, FontWeight.w700));
          }
        }
        final ustCubuk = tema.appBarTheme.titleTextStyle!;
        expect(ustCubuk.fontFamily, startsWith('Caveat'));
        expect(ustCubuk.fontSize, greaterThanOrEqualTo(22));
      });
    });
  }
}

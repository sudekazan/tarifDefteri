import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
// Çeviriyi EasyLocalization sarmalayıcısı olmadan yüklemek için.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/auth_screen.dart';
import 'package:tarif_defteri/widgets/giris_parcalari.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';

void _ekran(WidgetTester tester, double genislik, [double yukseklik = 800]) {
  tester.view.physicalSize = Size(genislik, yukseklik);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

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
    home: child,
  );
}

void main() {
  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
    final tr = json.decode(File('assets/lang/tr.json').readAsStringSync())
        as Map<String, dynamic>;
    Localization.load(const Locale('tr'), translations: Translations(tr));
  });

  setUp(() => girisAppleGosterilsinMi = true);
  tearDown(() => girisAppleGosterilsinMi = null);

  group('Giriş ekranı', () {
    testWidgets('açılışta giriş seçili; üç giriş yolu görünür', (tester) async {
      _ekran(tester, 402, 1000);
      await tester.pumpWidget(_sar(const AuthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tarifly'), findsOneWidget);
      expect(find.text('Tariflere erişmek için giriş yapın'), findsOneWidget);
      expect(find.text('Şifremi Unuttum'), findsOneWidget);
      // Seçicide ve ana düğmede "Giriş Yap".
      expect(find.text('Giriş Yap'), findsNWidgets(2));
      expect(find.text('Google ile devam et'), findsOneWidget);
      expect(find.text('Apple ile devam et'), findsOneWidget);
      expect(find.byType(GirisHataKutusu), findsNothing);
    });

    testWidgets('Apple düğmesi yalnızca izin verilen platformda', (tester) async {
      girisAppleGosterilsinMi = false;
      await tester.pumpWidget(_sar(const AuthScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Apple ile devam et'), findsNothing);
    });

    testWidgets('kayıt seçilince alt yazı ve düğme değişir, şifremi unuttum gider',
        (tester) async {
      _ekran(tester, 402, 1000);
      await tester.pumpWidget(_sar(const AuthScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kayıt Ol'));
      await tester.pumpAndSettle();
      expect(find.text('Tariflerinizi bulutta saklayın'), findsOneWidget);
      expect(find.text('Kayıt Ol'), findsNWidgets(2));
      expect(find.text('Şifremi Unuttum'), findsNothing);

      // Seçicide seçili parça ekran okuyucuya "seçili" der.
      expect(
        tester.getSemantics(find.text('Kayıt Ol').first),
        isSemantics(isSelected: true, isButton: true),
      );
    });

    testWidgets('boş formda doğrulama mesajları çıkar', (tester) async {
      _ekran(tester, 402, 1000);
      await tester.pumpWidget(_sar(const AuthScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Giriş Yap').last);
      await tester.pumpAndSettle();
      expect(find.text('Lütfen geçerli bir e-posta adresi girin'), findsOneWidget);
      expect(find.text('Şifre en az 6 karakter olmalıdır'), findsOneWidget);
    });

    testWidgets('e-postasız şifre sıfırlama hata kutusunu gösterir; '
        'sekme değişince kaybolur', (tester) async {
      _ekran(tester, 402, 1000);
      await tester.pumpWidget(_sar(const AuthScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Şifremi Unuttum'));
      await tester.pumpAndSettle();
      expect(find.byType(GirisHataKutusu), findsOneWidget);
      expect(
        find.text('Şifre sıfırlamak için geçerli bir e-posta adresi girin.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Kayıt Ol'));
      await tester.pumpAndSettle();
      expect(find.byType(GirisHataKutusu), findsNothing);
    });

    testWidgets('dokunulan öğeler en az 48', (tester) async {
      _ekran(tester, 402, 1000);
      await tester.pumpWidget(_sar(const AuthScreen()));
      await tester.pumpAndSettle();

      for (final metin in ['Kayıt Ol', 'Şifremi Unuttum', 'Google ile devam et']) {
        final kutu = find.ancestor(
          of: find.text(metin).first,
          matching: find.byWidgetPredicate(
            (w) => w is AnimatedContainer || w is TextButton,
          ),
        );
        expect(tester.getSize(kutu.first).height, greaterThanOrEqualTo(48),
            reason: metin);
      }
      final geri = find.byType(KilYuvarlakDugme);
      expect(tester.getSize(geri).height, greaterThanOrEqualTo(48));
    });

    testWidgets('hata kutusu hata zemin renklerinde', (tester) async {
      await tester.pumpWidget(_sar(
        const Scaffold(body: GirisHataKutusu(mesaj: 'Hatalı şifre')),
        renkler: KilRenkleri.koyu,
      ));
      final kutu = tester.widget<Container>(find.descendant(
        of: find.byType(GirisHataKutusu),
        matching: find.byType(Container),
      ));
      expect((kutu.decoration as BoxDecoration).color, KilRenkleri.koyu.hataZemin);
      expect(tester.widget<Text>(find.text('Hatalı şifre')).style?.color,
          KilRenkleri.koyu.hataZeminYazi);
    });

    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      for (final olcek in [1.0, 3.2]) {
        final ad = '${renkler.sertGolge ? 'açık' : 'koyu'} $olcek kat';
        testWidgets('$ad, 320 genişlikte taşma yok (giriş ve kayıt, hata ile)',
            (tester) async {
          _ekran(tester, 320, 640);
          await tester.pumpWidget(_sar(
            const AuthScreen(),
            yaziOlcegi: olcek,
            renkler: renkler,
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.scrollUntilVisible(find.text('Şifremi Unuttum'), 100,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(find.text('Şifremi Unuttum'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.scrollUntilVisible(find.text('Kayıt Ol').first, -100,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(find.text('Kayıt Ol').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

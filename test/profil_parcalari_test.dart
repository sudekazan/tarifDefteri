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
import 'package:tarif_defteri/sayfalar/profil_sayfasi.dart';
import 'package:tarif_defteri/services/firebase_service.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/premium_parcalari.dart';
import 'package:tarif_defteri/widgets/profil_parcalari.dart';

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

const _hesap = ProfilHesap(
  ad: 'Sude Kazan',
  eposta: 'sude@example.com',
  yontem: ReauthYontemi.google,
);

/// Geri çağrıları adıyla kaydeden profil görünümü.
ProfilGorunumu _profil(
  List<String> cagrilar, {
  ProfilHesap? hesap = _hesap,
  bool pro = false,
  bool koyu = false,
  bool gizlilikSecenekleri = false,
}) {
  VoidCallback c(String ad) => () => cagrilar.add(ad);
  return ProfilGorunumu(
    hesap: hesap,
    proKullanici: pro,
    koyuMod: koyu,
    dilAdi: '🇹🇷 Türkçe',
    surum: '2.3.0',
    onKoyuMod: (d) => cagrilar.add('koyu:$d'),
    onDil: c('dil'),
    onPremium: c('premium'),
    onAbonelikYonet: c('abonelik'),
    onGeriYukle: c('geriYukle'),
    onGiris: c('giris'),
    onYedekle: c('yedekle'),
    onCikis: c('cikis'),
    onHesapSil: c('hesapSil'),
    onDegerlendir: c('degerlendir'),
    onGizlilik: c('gizlilik'),
    onKosullar: c('kosullar'),
    onGizlilikSecenekleri: gizlilikSecenekleri ? c('reklamGizlilik') : null,
  );
}

Future<void> _dokun(WidgetTester tester, String metin) async {
  final hedef = find.text(metin);
  await tester.scrollUntilVisible(hedef, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.tap(hedef);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
    final tr = json.decode(File('assets/lang/tr.json').readAsStringSync())
        as Map<String, dynamic>;
    Localization.load(const Locale('tr'), translations: Translations(tr));
  });

  group('Profil', () {
    testWidgets('üstte başlık ve hesap kartı, hemen altında ayarlar; sayı yok',
        (tester) async {
      _ekran(tester, 402, 900);
      await tester.pumpWidget(_sar(_profil([])));
      await tester.pumpAndSettle();

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Sude Kazan'), findsOneWidget);
      expect(find.text('sude@example.com'), findsOneWidget);
      expect(find.text('Google ile giriş yapıldı'), findsOneWidget);

      // Hesap kartının hemen altında Premium kartı ve ayar satırları.
      final kartAlti = tester.getBottomLeft(find.byType(ProfilHesapKarti)).dy;
      final proUstu = tester.getTopLeft(find.byType(ProyaGecKarti)).dy;
      expect(proUstu - kartAlti, lessThanOrEqualTo(32));
      expect(find.byType(ProfilBolumu), findsWidgets);
    });

    testWidgets('ad yoksa e-posta başlık olur ve tekrar edilmez',
        (tester) async {
      await tester.pumpWidget(_sar(_profil([],
          hesap: const ProfilHesap(
            eposta: 'sude@example.com',
            yontem: ReauthYontemi.sifre,
          ))));
      await tester.pumpAndSettle();
      expect(find.text('sude@example.com'), findsOneWidget);
      expect(find.text('E-posta ile giriş yapıldı'), findsOneWidget);
    });

    testWidgets('hiç bilgi yoksa "Kullanıcı", yöntem bilinmiyorsa hap yok',
        (tester) async {
      await tester.pumpWidget(_sar(_profil([], hesap: const ProfilHesap())));
      await tester.pumpAndSettle();
      expect(find.text('Kullanıcı'), findsOneWidget);
      expect(find.textContaining('ile giriş yapıldı'), findsNothing);
    });

    testWidgets('girişsizken giriş kartı; hesap bölümü yok', (tester) async {
      final cagrilar = <String>[];
      await tester.pumpWidget(_sar(_profil(cagrilar, hesap: null)));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilHesapKarti), findsNothing);
      expect(find.text('Giriş Yap / Kayıt Ol'), findsOneWidget);
      expect(find.text('Hesap Yönetimi'), findsNothing);
      expect(find.text('Hesabımı Sil'), findsNothing);
      expect(find.text('Çıkış Yap'), findsNothing);

      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();
      expect(cagrilar, ['giris']);
    });

    testWidgets('girişliyken satırlar doğru işlemi çağırır', (tester) async {
      _ekran(tester, 402, 900);
      final cagrilar = <String>[];
      await tester.pumpWidget(_sar(_profil(cagrilar, gizlilikSecenekleri: true)));
      await tester.pumpAndSettle();

      await _dokun(tester, "Premium'a Geç");
      await _dokun(tester, 'Satın Alımlarımı Geri Yükle');
      await _dokun(tester, 'Koyu Mod');
      await _dokun(tester, 'Dil');
      await _dokun(tester, 'Verileri Yedekle');
      await _dokun(tester, 'Çıkış Yap');
      await _dokun(tester, 'Hesabımı Sil');
      await _dokun(tester, 'Uygulamayı Değerlendir');
      await _dokun(tester, 'Gizlilik Politikası');
      await _dokun(tester, 'Kullanım Koşulları (EULA)');
      await _dokun(tester, 'Reklam gizlilik seçenekleri');

      expect(cagrilar, [
        'premium',
        'geriYukle',
        'koyu:true',
        'dil',
        'yedekle',
        'cikis',
        'hesapSil',
        'degerlendir',
        'gizlilik',
        'kosullar',
        'reklamGizlilik',
      ]);
    });

    testWidgets('anahtar da koyu modu değiştirir', (tester) async {
      final cagrilar = <String>[];
      await tester.pumpWidget(_sar(_profil(cagrilar, koyu: true)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(Switch), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(cagrilar, ['koyu:false']);
    });

    testWidgets('Pro kullanıcıda "Premium Aktif" ve abonelik yönetimi',
        (tester) async {
      final cagrilar = <String>[];
      await tester.pumpWidget(_sar(_profil(cagrilar, pro: true)));
      await tester.pumpAndSettle();
      expect(find.text('Premium Aktif'), findsOneWidget);
      expect(find.text('Satın Alımlarımı Geri Yükle'), findsNothing);
      await _dokun(tester, 'Aboneliği Yönet');
      expect(cagrilar, ['abonelik']);
    });

    testWidgets('reklam gizlilik satırı yalnızca gerekirse', (tester) async {
      await tester.pumpWidget(_sar(_profil([])));
      await tester.pumpAndSettle();
      expect(find.text('Reklam gizlilik seçenekleri', skipOffstage: false),
          findsNothing);
    });

    testWidgets('satırlar en az 56, ekran okuyucu tek öğe okur', (tester) async {
      await tester.pumpWidget(_sar(_profil([])));
      await tester.pumpAndSettle();
      for (final satir in tester.widgetList(find.byType(ProfilSatiri))) {
        final boy = tester.getSize(find.byWidget(satir)).height;
        expect(boy, greaterThanOrEqualTo(ProfilSatiri.enKucukYukseklik));
      }
      final anlam = tester.getSemantics(find.text('Dil'));
      expect(anlam.label, contains('Türkçe'));
    });

    testWidgets('hesap sil satırı hata renginde', (tester) async {
      _ekran(tester, 402, 2000);
      await tester.pumpWidget(_sar(_profil([]), renkler: KilRenkleri.koyu));
      await tester.pumpAndSettle();
      final yazi = tester.widget<Text>(find.text('Hesabımı Sil'));
      expect(yazi.style?.color, KilRenkleri.koyu.hata);
    });

    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      for (final olcek in [1.0, 3.2]) {
        for (final girisli in [true, false]) {
          final ad = '${renkler.sertGolge ? 'açık' : 'koyu'} $olcek kat, '
              '${girisli ? 'girişli' : 'girişsiz'}';
          testWidgets('$ad: 320 genişlikte taşma yok', (tester) async {
            _ekran(tester, 320, 640);
            await tester.pumpWidget(_sar(
              _profil([], hesap: girisli ? _hesap : null),
              yaziOlcegi: olcek,
              renkler: renkler,
            ));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
                find.byType(ProfilAltBilgi), 300,
                scrollable: find.byType(Scrollable).first);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  testWidgets('hesap silme uyarısı 320 genişlik ve 3.2 katta sığar',
      (tester) async {
    _ekran(tester, 320, 640);
    await tester.pumpWidget(_sar(
      Builder(
        builder: (c) => Center(
          child: TextButton(
            onPressed: () => KilDiyalog.onayIste(
              c,
              ikon: Icons.warning_amber_rounded,
              tehlikeli: true,
              baslik: 'Hesabı Sil?',
              icerik: const HesapSilmeUyarisi(),
              onayEtiketi: 'Hesabımı Sil',
              vazgecEtiketi: 'İptal',
            ),
            child: const Text('aç'),
          ),
        ),
      ),
      yaziOlcegi: 3.2,
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Bu işlem geri alınamaz!'), findsOneWidget);
  });

  test('yeni metinler altı dilde var', () {
    const anahtarlar = [
      'profile_signed_in_with_email',
      'profile_signed_in_with_google',
      'profile_signed_in_with_apple',
    ];
    for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      final m = json.decode(File('assets/lang/$dil.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final a in anahtarlar) {
        expect((m[a] as String?)?.trim(), isNotEmpty, reason: '$dil: $a');
      }
    }
  });
}

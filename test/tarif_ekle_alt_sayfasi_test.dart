import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/sayfalar/klasor_kayit.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';
import 'package:tarif_defteri/widgets/klasor_ikon_secici.dart';
import 'package:tarif_defteri/widgets/tarif_ekle_alt_sayfasi.dart';

const _diller = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

const _yeniAnahtarlar = [
  'home_new_recipe',
  'home_new_folder',
  'recipe_add_folder_label',
  'add_option_manual_desc',
  'add_option_ai_desc',
  'add_option_link_desc',
  'folder_name_label',
  'recipe_favorite_add',
  'recipe_favorite_remove',
];

const _metinler = TarifEkleMetinleri(
  baslik: 'Yeni tarif',
  klasorSorusu: 'Hangi klasöre?',
  kendim: 'Kendim Yazacağım',
  kendimAciklama: 'Malzemeleri ve adımları kendiniz yazın',
  sef: 'Şefe Sor (Yapay Zeka)',
  sefAciklama: 'Yemeğin adını yazın, Şef tarifi hazırlasın',
  link: 'Web Linkinden Tarif Yükle',
  linkAciklama: 'Bir tarif sayfasının linkini yapıştırın',
  girisGerekli: 'Giriş Gerekli',
);

final _klasorler = [
  KlasorData(klasor_id: 1, klasor_adi: 'Tatlılar'),
  KlasorData(klasor_id: 2, klasor_adi: 'Çorbalar'),
  KlasorData(klasor_id: 3, klasor_adi: 'Hamur işleri'),
];

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
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(yaziOlcegi)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Widget _altSayfa({
  bool girisYapildi = true,
  KlasorData? baslangic,
  ValueChanged<TarifEklemeSecimi>? onSecildi,
}) {
  return KilAltSayfa(
    baslik: _metinler.baslik,
    child: TarifEkleAltSayfasi(
      klasorler: _klasorler,
      baslangicKlasoru: baslangic ?? _klasorler.first,
      girisYapildi: girisYapildi,
      klasorAdi: (k) => k.klasor_adi,
      metinler: _metinler,
      onSecildi: onSecildi ?? (_) {},
    ),
  );
}

bool _secili(WidgetTester tester, String etiket) => tester
    .widget<KilCip>(find.widgetWithText(KilCip, etiket))
    .secili;

void main() {
  test('Aşama 3 metinleri altı dilde de var ve boş değil', () {
    for (final dil in _diller) {
      final dosya = json.decode(
        File('assets/lang/$dil.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final anahtar in _yeniAnahtarlar) {
        expect(dosya[anahtar], isA<String>(), reason: '$dil: $anahtar yok');
        expect((dosya[anahtar] as String).trim(), isNotEmpty,
            reason: '$dil: $anahtar boş');
      }
    }
  });

  group('TarifEkleAltSayfasi', () {
    testWidgets('başlangıç klasörü seçili, üç yol görünür', (tester) async {
      await tester.pumpWidget(_sar(_altSayfa(baslangic: _klasorler[1])));

      expect(_secili(tester, 'Çorbalar'), isTrue);
      expect(_secili(tester, 'Tatlılar'), isFalse);
      expect(find.text('Kendim Yazacağım'), findsOneWidget);
      expect(find.text('Şefe Sor (Yapay Zeka)'), findsOneWidget);
      expect(find.text('Web Linkinden Tarif Yükle'), findsOneWidget);
    });

    testWidgets('klasör değiştirilip yol seçilince ikisi birlikte döner',
        (tester) async {
      TarifEklemeSecimi? secim;
      await tester.pumpWidget(_sar(_altSayfa(onSecildi: (s) => secim = s)));

      await tester.tap(find.text('Hamur işleri'));
      await tester.pump();
      expect(_secili(tester, 'Hamur işleri'), isTrue);
      expect(_secili(tester, 'Tatlılar'), isFalse);

      await tester.tap(find.text('Şefe Sor (Yapay Zeka)'));
      expect(secim?.yol, TarifEklemeYolu.sef);
      expect(secim?.klasor.klasor_id, 3);
    });

    testWidgets('seçili klasöre yeniden dokunmak seçimi kaldırmaz',
        (tester) async {
      await tester.pumpWidget(_sar(_altSayfa()));
      await tester.tap(find.text('Tatlılar'));
      await tester.pump();
      expect(_secili(tester, 'Tatlılar'), isTrue);
    });

    testWidgets('girişsiz: Şef ve link kilitli ama dokunulabilir',
        (tester) async {
      TarifEklemeSecimi? secim;
      await tester.pumpWidget(_sar(_altSayfa(
        girisYapildi: false,
        onSecildi: (s) => secim = s,
      )));

      expect(find.text('Giriş Gerekli'), findsNWidgets(2));
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
      expect(find.text('Malzemeleri ve adımları kendiniz yazın'),
          findsOneWidget);

      await tester.tap(find.text('Web Linkinden Tarif Yükle'));
      expect(secim?.yol, TarifEklemeYolu.link);
    });

    testWidgets('yollar ve klasör çipleri en az 48 yüksek', (tester) async {
      await tester.pumpWidget(_sar(_altSayfa()));
      final yol = tester.getSize(
        find.ancestor(of: find.text('Kendim Yazacağım'), matching: find.byType(KilKart)),
      );
      final cip = tester.getSize(find.widgetWithText(KilCip, 'Tatlılar'));
      expect(yol.height, greaterThanOrEqualTo(48));
      expect(cip.height, greaterThanOrEqualTo(48));
      expect(cip.width, greaterThanOrEqualTo(48));
    });

    testWidgets('büyük yazıda ikon metnin üstüne çıkar', (tester) async {
      _ekran(tester, 390);
      await tester.pumpWidget(_sar(_altSayfa(), yaziOlcegi: 2));
      final ikon = tester.getBottomLeft(find.byIcon(Icons.edit_note_rounded));
      final baslik = tester.getTopLeft(find.text('Kendim Yazacağım'));
      expect(baslik.dy, greaterThan(ikon.dy));
    });

    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      final mod = renkler.sertGolge ? 'açık' : 'koyu';
      testWidgets('$mod modda 320 genişlikte ve 3.2 kat yazıda taşma yok',
          (tester) async {
        _ekran(tester, 320, 700);
        await tester.pumpWidget(_sar(
          _altSayfa(),
          yaziOlcegi: 3.2,
          renkler: renkler,
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('KlasorIkonSecici', () {
    testWidgets('kutular 56x56, dokunulan ikon seçilir', (tester) async {
      int? secilen;
      await tester.pumpWidget(_sar(KlasorIkonSecici(
        seciliKod: Icons.folder.codePoint,
        onSecildi: (k) => secilen = k,
        anlamEtiketi: (sira) => 'İkon $sira',
      )));

      final kutu = tester.getSize(find.ancestor(
        of: find.byIcon(Icons.cake),
        matching: find.byType(AnimatedContainer),
      ));
      expect(kutu, const Size(56, 56));

      await tester.tap(find.byIcon(Icons.cake));
      expect(secilen, Icons.cake.codePoint);
      // Seçili kutuda onay işareti var (yalnızca renkle anlatılmıyor).
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('ekran okuyucu seçili ikonu seçili diye okur', (tester) async {
      final anlam = tester.ensureSemantics();
      await tester.pumpWidget(_sar(KlasorIkonSecici(
        seciliKod: Icons.folder.codePoint,
        onSecildi: (_) {},
        anlamEtiketi: (sira) => 'İkon $sira',
      )));
      expect(
        tester.getSemantics(find.bySemanticsLabel('İkon 1')),
        matchesSemantics(
          label: 'İkon 1',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      anlam.dispose();
    });
  });

  group('KlasorKayit', () {
    setUpAll(() => EasyLocalization.logger.enableBuildModes = []);

    for (final renkler in [KilRenkleri.acik, KilRenkleri.koyu]) {
      final mod = renkler.sertGolge ? 'açık' : 'koyu';
      testWidgets('$mod modda 320 genişlikte ve 3.2 kat yazıda taşma yok',
          (tester) async {
        _ekran(tester, 320, 700);
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
            brightness: renkler.sertGolge ? Brightness.light : Brightness.dark,
            extensions: [renkler],
          ),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(3.2)),
              child: const KlasorKayit(),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('ad boşken Kaydet pasif; adla birlikte seçilen ikon döner',
        (tester) async {
      Object? sonuc;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [KilRenkleri.acik]),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  sonuc = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KlasorKayit()),
                  );
                },
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();

      // Çeviri yüklenmediği için metinler anahtar olarak görünür.
      final kaydet = find.widgetWithText(KilDugme, 'common_save');
      expect(tester.widget<KilDugme>(kaydet).onPressed, isNull);

      // Açılışta klasör ikonu seçili (onay işareti tek ve klasör kutusunda).
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.byIcon(Icons.folder),
            matching: find.byType(AnimatedContainer),
          ),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '  Hamur işleri  ');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.cake));
      await tester.pump();
      expect(tester.widget<KilDugme>(kaydet).onPressed, isNotNull);

      await tester.ensureVisible(kaydet);
      await tester.tap(kaydet);
      await tester.pumpAndSettle();
      expect(sonuc, {'klasorAdi': 'Hamur işleri', 'iconCode': Icons.cake.codePoint});
    });
  });
}

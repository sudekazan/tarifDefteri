import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/theme/kil_renkleri.dart';

/// WCAG kontrast oranı.
double kontrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final acik = la > lb ? la : lb;
  final koyu = la > lb ? lb : la;
  return (acik + 0.05) / (koyu + 0.05);
}

void main() {
  for (final (ad, r) in [('açık', KilRenkleri.acik), ('koyu', KilRenkleri.koyu)]) {
    group('$ad mod', () {
      test('yazılar en az 4.5:1', () {
        final ciftler = <String, (Color, Color)>{
          'ana yazı / zemin': (r.anaYazi, r.zemin),
          'ana yazı / kart': (r.anaYazi, r.kart),
          'ana yazı / soluk yüzey': (r.anaYazi, r.solukYuzey),
          'soluk yazı / zemin': (r.solukYazi, r.zemin),
          'soluk yazı / kart': (r.solukYazi, r.kart),
          'soluk yazı / soluk yüzey': (r.solukYazi, r.solukYuzey),
          'başlık / zemin': (r.baslik, r.zemin),
          'başlık / kart': (r.baslik, r.kart),
          'birincil düğme yazısı': (r.birincilUstuYazi, r.birincil),
          'öne çıkan kart yazısı': (r.oneCikanKartYazi, r.oneCikanKart),
          'vurgu düğme yazısı': (r.vurguUstuYazi, r.vurgu),
          'seçili çip': (r.seciliCipYazi, r.seciliCipZemin),
          'hata / zemin': (r.hata, r.zemin),
          'hata / kart': (r.hata, r.kart),
          'hata düğme yazısı': (r.hataUstuYazi, r.hata),
          'hata kutusu': (r.hataZeminYazi, r.hataZemin),
        };
        ciftler.forEach((ad, cift) {
          expect(kontrast(cift.$1, cift.$2), greaterThanOrEqualTo(4.5),
              reason: ad);
        });
      });

      test('öğeyi tanıtan kenar ve ikonlar en az 3:1', () {
        final ciftler = <String, (Color, Color)>{
          'tanıtan kenar / zemin': (r.tanitanKenar, r.zemin),
          'tanıtan kenar / kart': (r.tanitanKenar, r.kart),
          'tanıtan kenar / soluk yüzey': (r.tanitanKenar, r.solukYuzey),
          'onay kutusu / kart': (r.vurgu, r.kart),
          'birincil / zemin': (r.birincil, r.zemin),
          'favoriler ikonu': (r.klasorFavori.ikon, r.klasorFavori.zemin),
          'tatlılar ikonu': (r.klasorTatli.ikon, r.klasorTatli.zemin),
          'çorbalar ikonu': (r.klasorCorba.ikon, r.klasorCorba.zemin),
          'kahvaltılıklar ikonu':
              (r.klasorKahvalti.ikon, r.klasorKahvalti.zemin),
        };
        ciftler.forEach((ad, cift) {
          expect(kontrast(cift.$1, cift.$2), greaterThanOrEqualTo(3),
              reason: ad);
        });
      });
    });
  }

  test('açık modda sert gölge var, koyu modda yok', () {
    expect(KilRenkleri.acik.sertGolge, isTrue);
    expect(KilRenkleri.koyu.sertGolge, isFalse);
  });

  test('lerp uçlarda kendi değerlerini verir', () {
    expect(KilRenkleri.acik.lerp(KilRenkleri.koyu, 0).zemin,
        KilRenkleri.acik.zemin);
    expect(KilRenkleri.acik.lerp(KilRenkleri.koyu, 1).zemin,
        KilRenkleri.koyu.zemin);
    expect(KilRenkleri.acik.lerp(KilRenkleri.koyu, 1).sertGolge, isFalse);
  });

  test('copyWith yalnızca verilen alanı değiştirir', () {
    final yeni = KilRenkleri.acik.copyWith(zemin: KilRenkleri.koyu.zemin);
    expect(yeni.zemin, KilRenkleri.koyu.zemin);
    expect(yeni.kart, KilRenkleri.acik.kart);
  });
}

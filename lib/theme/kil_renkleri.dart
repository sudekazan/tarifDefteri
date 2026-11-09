import 'package:flutter/material.dart';

/// Bir klasör ikonunun zemin ve ikon rengi.
@immutable
class KlasorRenk {
  const KlasorRenk({required this.zemin, required this.ikon});

  final Color zemin;
  final Color ikon;

  static KlasorRenk lerp(KlasorRenk a, KlasorRenk b, double t) => KlasorRenk(
        zemin: Color.lerp(a.zemin, b.zemin, t)!,
        ikon: Color.lerp(a.ikon, b.ikon, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is KlasorRenk && other.zemin == zemin && other.ikon == ikon;

  @override
  int get hashCode => Object.hash(zemin, ikon);
}

/// Kil tasarımının renkleri. Ekranlar renkleri buradan okur, koda sabit yazmaz.
///
/// Değerler ve ölçülen kontrastlar: `docs/tasarim/kil-tasarim-plani.md`.
/// Kısa yol: `context.kil.birincil`.
@immutable
class KilRenkleri extends ThemeExtension<KilRenkleri> {
  const KilRenkleri({
    required this.sertGolge,
    required this.zemin,
    required this.kart,
    required this.solukYuzey,
    required this.kenar,
    required this.tanitanKenar,
    required this.ustCizgi,
    required this.anaYazi,
    required this.solukYazi,
    required this.baslik,
    required this.birincil,
    required this.birincilUstuYazi,
    required this.birincilGolge,
    required this.oneCikanKart,
    required this.oneCikanKartYazi,
    required this.vurgu,
    required this.vurguUstuYazi,
    required this.vurguGolge,
    required this.seciliCipZemin,
    required this.seciliCipYazi,
    required this.hata,
    required this.hataUstuYazi,
    required this.hataZemin,
    required this.hataZeminYazi,
    required this.klasorFavori,
    required this.klasorTatli,
    required this.klasorCorba,
    required this.klasorKahvalti,
  });

  /// Açık modda derinlik alttan sert gölgeyle verilir; koyu modda gölge yok,
  /// derinlik kenar ve üstteki açık çizgiyle verilir.
  final bool sertGolge;

  final Color zemin;
  final Color kart;

  /// Sekme zemini, alınanlar, pasif düğme.
  final Color solukYuzey;

  /// Süs kenarı (1.2–1.4:1). Açık modda kart gölgesi de bu renktir.
  final Color kenar;

  /// Bir öğeyi tanıtan kenar (onay kutusu, metin kutusu), en az 3:1.
  final Color tanitanKenar;

  /// Koyu modda kartın üstündeki ince açık çizgi.
  final Color ustCizgi;

  final Color anaYazi;
  final Color solukYazi;

  /// Başlık rengi (terrakota). Koyu modda düğme renginden daha açıktır.
  final Color baslik;
  final Color birincil;
  final Color birincilUstuYazi;

  /// Açık modda birincil düğmenin sert gölgesi, koyu modda kenarı.
  final Color birincilGolge;

  final Color oneCikanKart;
  final Color oneCikanKartYazi;

  /// Adaçayı vurgu (onay, tamamlandı).
  final Color vurgu;
  final Color vurguUstuYazi;

  /// Açık modda vurgu düğmesinin sert gölgesi, koyu modda kenarı.
  final Color vurguGolge;

  final Color seciliCipZemin;
  final Color seciliCipYazi;

  final Color hata;
  final Color hataUstuYazi;
  final Color hataZemin;
  final Color hataZeminYazi;

  final KlasorRenk klasorFavori;
  final KlasorRenk klasorTatli;
  final KlasorRenk klasorCorba;
  final KlasorRenk klasorKahvalti;

  static const KilRenkleri acik = KilRenkleri(
    sertGolge: true,
    zemin: Color(0xFFFFFBEB),
    kart: Color(0xFFFFFFFF),
    solukYuzey: Color(0xFFF8F2F0),
    kenar: Color(0xFFF2E6E2),
    tanitanKenar: Color(0xFF8A766F),
    ustCizgi: Color(0xFFFFFFFF),
    anaYazi: Color(0xFF0F172A),
    solukYazi: Color(0xFF475569),
    baslik: Color(0xFF9A3412),
    birincil: Color(0xFF9A3412),
    birincilUstuYazi: Color(0xFFFFFFFF),
    birincilGolge: Color(0xFF7C2D12),
    oneCikanKart: Color(0xFFC2410C),
    oneCikanKartYazi: Color(0xFFFFFFFF),
    vurgu: Color(0xFF059669),
    vurguUstuYazi: Color(0xFF000000),
    vurguGolge: Color(0xFF047857),
    seciliCipZemin: Color(0xFFFFEDD5),
    seciliCipYazi: Color(0xFF9A3412),
    hata: Color(0xFFDC2626),
    hataUstuYazi: Color(0xFFFFFFFF),
    hataZemin: Color(0xFFFEE2E2),
    hataZeminYazi: Color(0xFF991B1B),
    klasorFavori: KlasorRenk(zemin: Color(0xFFFFE4E6), ikon: Color(0xFFBE123C)),
    klasorTatli: KlasorRenk(zemin: Color(0xFFFFEDD5), ikon: Color(0xFF9A3412)),
    klasorCorba: KlasorRenk(zemin: Color(0xFFD1FAE5), ikon: Color(0xFF065F46)),
    klasorKahvalti: KlasorRenk(zemin: Color(0xFFFEF3C7), ikon: Color(0xFF92400E)),
  );

  static const KilRenkleri koyu = KilRenkleri(
    sertGolge: false,
    zemin: Color(0xFF1C1412),
    kart: Color(0xFF2A1F1B),
    solukYuzey: Color(0xFF241A16),
    kenar: Color(0xFF4A3830),
    tanitanKenar: Color(0xFF8A7268),
    ustCizgi: Color(0xFF6B5246),
    anaYazi: Color(0xFFFAF3EE),
    solukYazi: Color(0xFFC9B8AE),
    baslik: Color(0xFFFDBA74),
    birincil: Color(0xFFFB923C),
    birincilUstuYazi: Color(0xFF1C1412),
    birincilGolge: Color(0xFFC2410C),
    oneCikanKart: Color(0xFF3B2418),
    oneCikanKartYazi: Color(0xFFFDBA74),
    vurgu: Color(0xFF34D399),
    vurguUstuYazi: Color(0xFF000000),
    vurguGolge: Color(0xFF059669),
    seciliCipZemin: Color(0xFF3B2418),
    seciliCipYazi: Color(0xFFFDBA74),
    hata: Color(0xFFF87171),
    hataUstuYazi: Color(0xFF1C1412),
    hataZemin: Color(0xFF4A1D1D),
    hataZeminYazi: Color(0xFFFCA5A5),
    klasorFavori: KlasorRenk(zemin: Color(0xFF3F1D25), ikon: Color(0xFFFDA4AF)),
    klasorTatli: KlasorRenk(zemin: Color(0xFF3B2418), ikon: Color(0xFFFDBA74)),
    klasorCorba: KlasorRenk(zemin: Color(0xFF0F3A2E), ikon: Color(0xFF6EE7B7)),
    klasorKahvalti: KlasorRenk(zemin: Color(0xFF3A2C12), ikon: Color(0xFFFCD34D)),
  );

  /// Temada `KilRenkleri` yoksa (ör. eski bir test teması) parlaklığa göre seçer.
  static KilRenkleri of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<KilRenkleri>() ??
        (theme.brightness == Brightness.dark ? koyu : acik);
  }

  @override
  KilRenkleri copyWith({
    bool? sertGolge,
    Color? zemin,
    Color? kart,
    Color? solukYuzey,
    Color? kenar,
    Color? tanitanKenar,
    Color? ustCizgi,
    Color? anaYazi,
    Color? solukYazi,
    Color? baslik,
    Color? birincil,
    Color? birincilUstuYazi,
    Color? birincilGolge,
    Color? oneCikanKart,
    Color? oneCikanKartYazi,
    Color? vurgu,
    Color? vurguUstuYazi,
    Color? vurguGolge,
    Color? seciliCipZemin,
    Color? seciliCipYazi,
    Color? hata,
    Color? hataUstuYazi,
    Color? hataZemin,
    Color? hataZeminYazi,
    KlasorRenk? klasorFavori,
    KlasorRenk? klasorTatli,
    KlasorRenk? klasorCorba,
    KlasorRenk? klasorKahvalti,
  }) {
    return KilRenkleri(
      sertGolge: sertGolge ?? this.sertGolge,
      zemin: zemin ?? this.zemin,
      kart: kart ?? this.kart,
      solukYuzey: solukYuzey ?? this.solukYuzey,
      kenar: kenar ?? this.kenar,
      tanitanKenar: tanitanKenar ?? this.tanitanKenar,
      ustCizgi: ustCizgi ?? this.ustCizgi,
      anaYazi: anaYazi ?? this.anaYazi,
      solukYazi: solukYazi ?? this.solukYazi,
      baslik: baslik ?? this.baslik,
      birincil: birincil ?? this.birincil,
      birincilUstuYazi: birincilUstuYazi ?? this.birincilUstuYazi,
      birincilGolge: birincilGolge ?? this.birincilGolge,
      oneCikanKart: oneCikanKart ?? this.oneCikanKart,
      oneCikanKartYazi: oneCikanKartYazi ?? this.oneCikanKartYazi,
      vurgu: vurgu ?? this.vurgu,
      vurguUstuYazi: vurguUstuYazi ?? this.vurguUstuYazi,
      vurguGolge: vurguGolge ?? this.vurguGolge,
      seciliCipZemin: seciliCipZemin ?? this.seciliCipZemin,
      seciliCipYazi: seciliCipYazi ?? this.seciliCipYazi,
      hata: hata ?? this.hata,
      hataUstuYazi: hataUstuYazi ?? this.hataUstuYazi,
      hataZemin: hataZemin ?? this.hataZemin,
      hataZeminYazi: hataZeminYazi ?? this.hataZeminYazi,
      klasorFavori: klasorFavori ?? this.klasorFavori,
      klasorTatli: klasorTatli ?? this.klasorTatli,
      klasorCorba: klasorCorba ?? this.klasorCorba,
      klasorKahvalti: klasorKahvalti ?? this.klasorKahvalti,
    );
  }

  @override
  KilRenkleri lerp(ThemeExtension<KilRenkleri>? other, double t) {
    if (other is! KilRenkleri) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return KilRenkleri(
      sertGolge: t < 0.5 ? sertGolge : other.sertGolge,
      zemin: c(zemin, other.zemin),
      kart: c(kart, other.kart),
      solukYuzey: c(solukYuzey, other.solukYuzey),
      kenar: c(kenar, other.kenar),
      tanitanKenar: c(tanitanKenar, other.tanitanKenar),
      ustCizgi: c(ustCizgi, other.ustCizgi),
      anaYazi: c(anaYazi, other.anaYazi),
      solukYazi: c(solukYazi, other.solukYazi),
      baslik: c(baslik, other.baslik),
      birincil: c(birincil, other.birincil),
      birincilUstuYazi: c(birincilUstuYazi, other.birincilUstuYazi),
      birincilGolge: c(birincilGolge, other.birincilGolge),
      oneCikanKart: c(oneCikanKart, other.oneCikanKart),
      oneCikanKartYazi: c(oneCikanKartYazi, other.oneCikanKartYazi),
      vurgu: c(vurgu, other.vurgu),
      vurguUstuYazi: c(vurguUstuYazi, other.vurguUstuYazi),
      vurguGolge: c(vurguGolge, other.vurguGolge),
      seciliCipZemin: c(seciliCipZemin, other.seciliCipZemin),
      seciliCipYazi: c(seciliCipYazi, other.seciliCipYazi),
      hata: c(hata, other.hata),
      hataUstuYazi: c(hataUstuYazi, other.hataUstuYazi),
      hataZemin: c(hataZemin, other.hataZemin),
      hataZeminYazi: c(hataZeminYazi, other.hataZeminYazi),
      klasorFavori: KlasorRenk.lerp(klasorFavori, other.klasorFavori, t),
      klasorTatli: KlasorRenk.lerp(klasorTatli, other.klasorTatli, t),
      klasorCorba: KlasorRenk.lerp(klasorCorba, other.klasorCorba, t),
      klasorKahvalti: KlasorRenk.lerp(klasorKahvalti, other.klasorKahvalti, t),
    );
  }
}

extension KilRenkleriContext on BuildContext {
  /// Geçerli temanın kil renkleri.
  KilRenkleri get kil => KilRenkleri.of(this);
}

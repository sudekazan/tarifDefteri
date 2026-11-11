import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/kil_renkleri.dart';

/// Tek paletli kil teması (açık ve koyu).
///
/// Başlıklar Caveat 700, yalnızca 22 pt ve üstü (display ve headline stilleri).
/// Metin ve arayüz Quicksand 500/700. Bileşenler yazı stilini
/// `Theme.of(context).textTheme` üzerinden alır ve kalınlığı değiştirmez;
/// böylece google_fonts doğru ağırlıktaki font dosyasını yükler.
///
/// Font dosyaları uygulamayla gelir (`assets/fonts/`); internetten indirilmez.
/// Yeni bir ağırlık kullanılacaksa dosyası oraya ve [fontlariHazirla]'ya eklenir.
class AppThemeBuilder {
  const AppThemeBuilder._();

  /// İnternetten font indirmeyi kapatır ve gömülü fontları yükler. İlk kare
  /// çizilmeden önce çağrılır ki yazılar sistem fontuyla görünüp değişmesin.
  /// Gömülü dosya bulunamazsa hata fırlatır.
  static Future<void> fontlariHazirla() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await GoogleFonts.pendingFonts([
      GoogleFonts.quicksand(fontWeight: FontWeight.w500),
      GoogleFonts.quicksand(fontWeight: FontWeight.w700),
      GoogleFonts.caveat(fontWeight: FontWeight.w700),
    ]);
  }

  static ThemeData buildLightTheme() =>
      _tema(KilRenkleri.acik, KilRenkleri.koyu, Brightness.light);

  static ThemeData buildDarkTheme() =>
      _tema(KilRenkleri.koyu, KilRenkleri.acik, Brightness.dark);

  static const Color _saydam = Color(0x00000000);
  static const Color _siyah = Color(0xFF000000);

  static TextStyle _quicksand(
    TextStyle? temel,
    FontWeight kalinlik,
    Color renk, {
    double? boyut,
  }) =>
      GoogleFonts.quicksand(
        textStyle: temel,
        fontSize: boyut,
        fontWeight: kalinlik,
        color: renk,
      );

  static TextStyle _caveat(TextStyle? temel, double boyut, Color renk) =>
      GoogleFonts.caveat(
        textStyle: temel,
        fontSize: boyut,
        fontWeight: FontWeight.w700,
        color: renk,
      );

  static TextTheme _yaziTemasi(KilRenkleri r) {
    final g = Typography.material2021().englishLike;
    const w5 = FontWeight.w500;
    const w7 = FontWeight.w700;
    return TextTheme(
      displayLarge: _caveat(g.displayLarge, 57, r.baslik),
      displayMedium: _caveat(g.displayMedium, 45, r.baslik),
      displaySmall: _caveat(g.displaySmall, 36, r.baslik),
      headlineLarge: _caveat(g.headlineLarge, 34, r.baslik),
      headlineMedium: _caveat(g.headlineMedium, 30, r.baslik),
      headlineSmall: _caveat(g.headlineSmall, 26, r.baslik),
      titleLarge: _quicksand(g.titleLarge, w7, r.anaYazi),
      titleMedium: _quicksand(g.titleMedium, w7, r.anaYazi),
      titleSmall: _quicksand(g.titleSmall, w7, r.anaYazi),
      bodyLarge: _quicksand(g.bodyLarge, w5, r.anaYazi),
      bodyMedium: _quicksand(g.bodyMedium, w5, r.anaYazi),
      bodySmall: _quicksand(g.bodySmall, w5, r.solukYazi),
      labelLarge: _quicksand(g.labelLarge, w7, r.anaYazi, boyut: 16),
      labelMedium: _quicksand(g.labelMedium, w7, r.anaYazi),
      labelSmall: _quicksand(g.labelSmall, w7, r.solukYazi),
    );
  }

  static ThemeData _tema(KilRenkleri r, KilRenkleri ters, Brightness parlaklik) {
    final renkSemasi = ColorScheme(
      brightness: parlaklik,
      primary: r.birincil,
      onPrimary: r.birincilUstuYazi,
      primaryContainer: r.seciliCipZemin,
      onPrimaryContainer: r.seciliCipYazi,
      secondary: r.oneCikanKart,
      onSecondary: r.oneCikanKartYazi,
      secondaryContainer: r.seciliCipZemin,
      onSecondaryContainer: r.seciliCipYazi,
      tertiary: r.vurgu,
      onTertiary: r.vurguUstuYazi,
      tertiaryContainer: r.klasorCorba.zemin,
      onTertiaryContainer: r.klasorCorba.ikon,
      error: r.hata,
      onError: r.hataUstuYazi,
      errorContainer: r.hataZemin,
      onErrorContainer: r.hataZeminYazi,
      surface: r.zemin,
      onSurface: r.anaYazi,
      onSurfaceVariant: r.solukYazi,
      surfaceDim: r.solukYuzey,
      surfaceBright: r.kart,
      surfaceContainerLowest: r.kart,
      surfaceContainerLow: r.kart,
      surfaceContainer: r.kart,
      surfaceContainerHigh: r.kart,
      surfaceContainerHighest: r.solukYuzey,
      outline: r.tanitanKenar,
      outlineVariant: r.kenar,
      shadow: _siyah,
      scrim: _siyah,
      inverseSurface: ters.kart,
      onInverseSurface: ters.anaYazi,
      inversePrimary: ters.baslik,
      surfaceTint: _saydam,
    );

    final yazi = _yaziTemasi(r);
    final dugmeYazisi = yazi.labelLarge;
    final cipYazisi = _quicksand(null, FontWeight.w700, r.anaYazi, boyut: 14);
    final seciliCipYazisi = cipYazisi.copyWith(color: r.seciliCipYazi);
    final sekmeYazisi = _quicksand(null, FontWeight.w700, r.solukYazi, boyut: 12);
    final seciliSekmeYazisi = sekmeYazisi.copyWith(color: r.seciliCipYazi);
    final kutuYazisi = _quicksand(null, FontWeight.w500, r.solukYazi);

    const k16 = BorderRadius.all(Radius.circular(16));
    const k20 = BorderRadius.all(Radius.circular(20));
    const k24 = BorderRadius.all(Radius.circular(24));
    // Açık modda düğmenin derinliği KilDugme'deki sert gölgeyle verilir;
    // koyu modda gölge yok, kenar var.
    final birincilKenar = r.sertGolge
        ? BorderSide.none
        : BorderSide(color: r.birincilGolge, width: 2);
    final susKenari = BorderSide(color: r.kenar, width: 2);
    const dugmeBoyu = Size(64, 48);
    const dugmeDolgusu = EdgeInsets.symmetric(vertical: 14, horizontal: 24);

    OutlineInputBorder kutuKenari(Color renk, double kalinlik) =>
        OutlineInputBorder(
          borderRadius: k16,
          borderSide: BorderSide(color: renk, width: kalinlik),
        );

    bool secili(Set<WidgetState> s) => s.contains(WidgetState.selected);
    bool pasif(Set<WidgetState> s) => s.contains(WidgetState.disabled);

    final birincilDugmeStili = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
          (s) => pasif(s) ? r.solukYuzey : r.birincil),
      foregroundColor: WidgetStateProperty.resolveWith(
          (s) => pasif(s) ? r.solukYazi : r.birincilUstuYazi),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(_saydam),
      minimumSize: const WidgetStatePropertyAll(dugmeBoyu),
      padding: const WidgetStatePropertyAll(dugmeDolgusu),
      shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: k16)),
      side: WidgetStateProperty.resolveWith(
          (s) => pasif(s) ? BorderSide.none : birincilKenar),
      textStyle: WidgetStatePropertyAll(dugmeYazisi),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: parlaklik,
      colorScheme: renkSemasi,
      extensions: <ThemeExtension<dynamic>>[r],
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        primaryColor: r.birincil,
      ),
      scaffoldBackgroundColor: r.zemin,
      canvasColor: r.zemin,
      cardColor: r.kart,
      dividerColor: r.kenar,
      primaryColor: r.birincil,
      hintColor: r.solukYazi,
      textTheme: yazi,
      iconTheme: IconThemeData(color: r.anaYazi),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: r.birincil,
        selectionColor: r.birincil.withValues(alpha: 0.25),
        selectionHandleColor: r.birincil,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: r.zemin,
        foregroundColor: r.baslik,
        surfaceTintColor: _saydam,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: r.baslik),
        actionsIconTheme: IconThemeData(color: r.baslik),
        titleTextStyle: _caveat(null, 28, r.baslik),
      ),
      cardTheme: CardThemeData(
        color: r.kart,
        surfaceTintColor: _saydam,
        shadowColor: _saydam,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: k20, side: susKenari),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: birincilDugmeStili),
      filledButtonTheme: FilledButtonThemeData(style: birincilDugmeStili),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: r.baslik,
          backgroundColor: r.kart,
          side: susKenari,
          minimumSize: dugmeBoyu,
          padding: dugmeDolgusu,
          shape: const RoundedRectangleBorder(borderRadius: k16),
          textStyle: dugmeYazisi,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: r.baslik,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: k16),
          textStyle: dugmeYazisi,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: r.birincil,
        foregroundColor: r.birincilUstuYazi,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: k20, side: birincilKenar),
        extendedTextStyle: dugmeYazisi,
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((s) {
          if (pasif(s)) return r.solukYuzey;
          return secili(s) ? r.seciliCipZemin : r.kart;
        }),
        side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
              color: secili(s) ? r.seciliCipZemin : r.kenar,
              width: 2,
            )),
        labelStyle: WidgetStateTextStyle.resolveWith(
            (s) => secili(s) ? seciliCipYazisi : cipYazisi),
        checkmarkColor: r.seciliCipYazi,
        iconTheme: IconThemeData(color: r.seciliCipYazi, size: 18),
        shape: const StadiumBorder(),
        elevation: 0,
        pressElevation: 0,
        surfaceTintColor: _saydam,
        showCheckmark: true,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: r.kart,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: kutuYazisi,
        labelStyle: kutuYazisi,
        floatingLabelStyle: kutuYazisi.copyWith(color: r.baslik),
        errorStyle: kutuYazisi.copyWith(color: r.hata),
        prefixIconColor: r.solukYazi,
        suffixIconColor: r.solukYazi,
        border: kutuKenari(r.tanitanKenar, 1.5),
        enabledBorder: kutuKenari(r.tanitanKenar, 1.5),
        focusedBorder: kutuKenari(r.birincil, 2),
        errorBorder: kutuKenari(r.hata, 1.5),
        focusedErrorBorder: kutuKenari(r.hata, 2),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) {
          if (!secili(s)) return _saydam;
          return pasif(s) ? r.kenar : r.vurgu;
        }),
        checkColor: WidgetStatePropertyAll(r.vurguUstuYazi),
        side: WidgetStateBorderSide.resolveWith((s) {
          if (secili(s)) return BorderSide(color: r.vurgu, width: 2);
          return BorderSide(
            color: pasif(s) ? r.kenar : r.tanitanKenar,
            width: 2,
          );
        }),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) {
          if (pasif(s)) return r.kenar;
          return secili(s) ? r.birincil : r.tanitanKenar;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => secili(s) ? r.birincilUstuYazi : r.tanitanKenar),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => secili(s) ? r.birincil : r.solukYuzey),
        trackOutlineColor: WidgetStateProperty.resolveWith(
            (s) => secili(s) ? r.birincil : r.tanitanKenar),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: r.kart,
        surfaceTintColor: _saydam,
        shadowColor: _saydam,
        elevation: 0,
        height: 72,
        indicatorColor: r.seciliCipZemin,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => secili(s) ? seciliSekmeYazisi : sekmeYazisi),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: secili(s) ? r.seciliCipYazi : r.solukYazi,
              size: 24,
            )),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: r.kart,
        modalBackgroundColor: r.kart,
        surfaceTintColor: _saydam,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: r.tanitanKenar,
        dragHandleSize: const Size(40, 5),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: susKenari,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: r.kart,
        surfaceTintColor: _saydam,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: k24, side: susKenari),
        // Diyalog başlıkları çoğu zaman bir cümle; el yazısı yerine Quicksand.
        titleTextStyle: _quicksand(null, FontWeight.w700, r.anaYazi, boyut: 20),
        contentTextStyle:
            _quicksand(null, FontWeight.w500, r.anaYazi, boyut: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ters.kart,
        contentTextStyle:
            _quicksand(null, FontWeight.w500, ters.anaYazi, boyut: 15),
        actionTextColor: ters.baslik,
        shape: const RoundedRectangleBorder(borderRadius: k16),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: r.kart,
        surfaceTintColor: _saydam,
        shape: RoundedRectangleBorder(borderRadius: k16, side: susKenari),
        labelTextStyle: WidgetStatePropertyAll(
            _quicksand(null, FontWeight.w500, r.anaYazi, boyut: 15)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: r.baslik,
        unselectedLabelColor: r.solukYazi,
        indicatorColor: r.birincil,
        dividerColor: r.kenar,
        labelStyle: _quicksand(null, FontWeight.w700, r.baslik, boyut: 15),
        unselectedLabelStyle:
            _quicksand(null, FontWeight.w500, r.solukYazi, boyut: 15),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: r.solukYazi,
        textColor: r.anaYazi,
      ),
      dividerTheme: DividerThemeData(color: r.kenar, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: r.birincil,
        linearTrackColor: r.solukYuzey,
        circularTrackColor: _saydam,
      ),
    );
  }
}

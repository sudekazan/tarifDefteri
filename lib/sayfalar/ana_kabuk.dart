import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/revenuecat_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/kil/kil.dart';
import 'alisveris_listesi.dart';
import 'bugun_ne_pisisem_sayfasi.dart';
import 'klasorler.dart';
import 'profil_sayfasi.dart';

/// Uygulamanın ana kabuğu: alt sekme çubuğu ve dört sekme (Defterim,
/// Ne pişirsem, Alışveriş, Profil).
///
/// Sekmeler `IndexedStack` içinde tutulur, sekme değişince durum kaybolmaz.
/// Bir sekme ilk seçildiğinde kurulur; böylece açılışta dört ekranın yüklemesi
/// ve "açıldı" analitik olayları birden çalışmaz. Daha önce kurulmuş bir sekme
/// yeniden seçilince sayfaya haber verilir, sayfa verisini tazeler.
///
/// Banner reklam burada bir kez, sekme çubuğunun hemen üstünde durur; Pro
/// kullanıcılarda gösterilmez (bkz. [BannerAdWidget]).
class AnaKabuk extends StatefulWidget {
  const AnaKabuk({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    this.sekmeKurucu,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  /// Yalnızca testler için: sekmeleri sahte sayfalarla değiştirir (gerçek
  /// sayfalar Firebase ister). [sinyal], sekme yeniden seçilince tetiklenir.
  @visibleForTesting
  final Widget Function(int indeks, Listenable sinyal)? sekmeKurucu;

  /// `MaterialApp.navigatorObservers`'a eklenir. Kabuğun üstünde açılan bir
  /// sayfa (ör. Premium) kapanınca kabuk yeniden çizilir ve banner Pro
  /// durumunu yeniden okur.
  static final RouteObserver<ModalRoute<void>> rotaGozlemcisi =
      RouteObserver<ModalRoute<void>>();

  static const int defterim = 0;
  static const int nePisirsem = 1;
  static const int alisveris = 2;
  static const int profil = 3;
  static const int _sekmeSayisi = 4;

  @override
  State<AnaKabuk> createState() => _AnaKabukState();
}

/// Daha önce kurulmuş bir sekme yeniden seçilince sayfaya haber verir.
class _SekmeSinyali extends ChangeNotifier {
  void bildir() => notifyListeners();
}

class _AnaKabukState extends State<AnaKabuk> with RouteAware {
  int _secili = AnaKabuk.defterim;
  final Set<int> _kurulanlar = {AnaKabuk.defterim};
  final List<_SekmeSinyali> _sinyaller = List.generate(
    AnaKabuk._sekmeSayisi,
    (_) => _SekmeSinyali(),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rota = ModalRoute.of(context);
    if (rota != null) AnaKabuk.rotaGozlemcisi.subscribe(this, rota);
  }

  @override
  void dispose() {
    AnaKabuk.rotaGozlemcisi.unsubscribe(this);
    for (final s in _sinyaller) {
      s.dispose();
    }
    super.dispose();
  }

  /// Üstteki sayfa kapandı; Pro durumu değişmiş olabilir.
  @override
  void didPopNext() {
    if (mounted) setState(() {});
  }

  void _sekmeyeGec(int indeks) {
    if (indeks == _secili) return;
    final ilkKez = _kurulanlar.add(indeks);
    setState(() => _secili = indeks);
    if (!ilkKez) _sinyaller[indeks].bildir();
  }

  Widget _sekme(int indeks) {
    final kurucu = widget.sekmeKurucu;
    if (kurucu != null) return kurucu(indeks, _sinyaller[indeks]);
    switch (indeks) {
      case AnaKabuk.defterim:
        return Klasorler(
          nePisirsemAc: () => _sekmeyeGec(AnaKabuk.nePisirsem),
          gorunduSinyali: _sinyaller[indeks],
        );
      case AnaKabuk.nePisirsem:
        return BugunNePisisemSayfasi(
          gorunduSinyali: _sinyaller[indeks],
          tarifKaydedilince: () => _sekmeyeGec(AnaKabuk.defterim),
        );
      case AnaKabuk.alisveris:
        return AlisverisListesi(gorunduSinyali: _sinyaller[indeks]);
      default:
        return ProfilSayfasi(
          isDarkMode: widget.isDarkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
          gorunduSinyali: _sinyaller[indeks],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Android geri tuşu: ilk sekmede değilken önce Defterim'e döner.
      canPop: _secili == AnaKabuk.defterim,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sekmeyeGec(AnaKabuk.defterim);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _secili,
          children: [
            for (var i = 0; i < AnaKabuk._sekmeSayisi; i++)
              _kurulanlar.contains(i) ? _sekme(i) : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alt güvenli alanı sekme çubuğu bırakır; banner bırakmasın.
            MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              // Pro durumu değişince banner baştan kurulur (Pro'da boş kalır).
              child: BannerAdWidget(key: ValueKey(RevenueCatService.isProUser)),
            ),
            KilSekmeCubugu(
              seciliIndeks: _secili,
              onSecildi: _sekmeyeGec,
              sekmeler: [
                KilSekme(
                  ikon: Icons.menu_book_outlined,
                  seciliIkon: Icons.menu_book_rounded,
                  etiket: 'tab_notebook'.tr(),
                ),
                KilSekme(
                  ikon: Icons.soup_kitchen_outlined,
                  seciliIkon: Icons.soup_kitchen_rounded,
                  etiket: 'tab_what_to_cook'.tr(),
                ),
                KilSekme(
                  ikon: Icons.shopping_basket_outlined,
                  seciliIkon: Icons.shopping_basket_rounded,
                  etiket: 'tab_shopping'.tr(),
                ),
                KilSekme(
                  ikon: Icons.person_outline_rounded,
                  seciliIkon: Icons.person_rounded,
                  etiket: 'tab_profile'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

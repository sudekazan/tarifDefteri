// Uygulamanın kabuğu (AnaKabuk) için duman testi. Gerçek sekme sayfaları
// Firebase istediği için sekmeler sahte sayfalarla değiştirilir; denenen şey
// kabuğun kendisi: sekme geçişi, sekmelerin ilk seçilince kurulması, yeniden
// seçilince sinyal ve Android geri tuşu.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/sayfalar/ana_kabuk.dart';
import 'package:tarif_defteri/widgets/kil/kil.dart';

class _Kayit {
  final List<int> kurulan = [];
  final List<int> gorunen = [];
}

class _SahteSekme extends StatefulWidget {
  const _SahteSekme(this.indeks, this.sinyal, this.kayit);

  final int indeks;
  final Listenable sinyal;
  final _Kayit kayit;

  @override
  State<_SahteSekme> createState() => _SahteSekmeState();
}

class _SahteSekmeState extends State<_SahteSekme> {
  @override
  void initState() {
    super.initState();
    widget.kayit.kurulan.add(widget.indeks);
    widget.sinyal.addListener(_gorundu);
  }

  void _gorundu() => widget.kayit.gorunen.add(widget.indeks);

  @override
  void dispose() {
    widget.sinyal.removeListener(_gorundu);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('Sekme ${widget.indeks}'));
}

Future<_Kayit> _kabuguKur(WidgetTester tester) async {
  final kayit = _Kayit();
  await tester.pumpWidget(MaterialApp(
    // Fontsuz tema: google_fonts testte font indirmeye çalışmasın.
    theme: ThemeData(extensions: const [KilRenkleri.acik]),
    home: AnaKabuk(
      isDarkMode: false,
      onDarkModeChanged: (_) {},
      sekmeKurucu: (indeks, sinyal) => _SahteSekme(indeks, sinyal, kayit),
    ),
  ));
  return kayit;
}

int _seciliSekme(WidgetTester tester) =>
    tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

Future<void> _sekmeyeDokun(WidgetTester tester, int indeks) async {
  await tester.tap(find.byType(NavigationDestination).at(indeks));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('açılışta Defterim görünür ve yalnızca o kurulur',
      (tester) async {
    final kayit = await _kabuguKur(tester);
    expect(_seciliSekme(tester), AnaKabuk.defterim);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(kayit.kurulan, [AnaKabuk.defterim]);
    expect(kayit.gorunen, isEmpty);
  });

  testWidgets('sekme ilk seçilince kurulur, yeniden seçilince haber alır',
      (tester) async {
    final kayit = await _kabuguKur(tester);

    await _sekmeyeDokun(tester, AnaKabuk.alisveris);
    expect(_seciliSekme(tester), AnaKabuk.alisveris);
    expect(kayit.kurulan, [AnaKabuk.defterim, AnaKabuk.alisveris]);
    expect(kayit.gorunen, isEmpty);

    await _sekmeyeDokun(tester, AnaKabuk.defterim);
    await _sekmeyeDokun(tester, AnaKabuk.alisveris);
    expect(_seciliSekme(tester), AnaKabuk.alisveris);
    // Durum korunur: sekmeler yeniden kurulmaz, yalnızca haber alır.
    expect(kayit.kurulan, [AnaKabuk.defterim, AnaKabuk.alisveris]);
    expect(kayit.gorunen, [AnaKabuk.defterim, AnaKabuk.alisveris]);
  });

  testWidgets('açık sekmeye yeniden dokunmak bir şey yapmaz', (tester) async {
    final kayit = await _kabuguKur(tester);
    await _sekmeyeDokun(tester, AnaKabuk.defterim);
    expect(_seciliSekme(tester), AnaKabuk.defterim);
    expect(kayit.gorunen, isEmpty);
  });

  testWidgets('Android geri tuşu önce Defterim sekmesine döner',
      (tester) async {
    final kayit = await _kabuguKur(tester);
    await _sekmeyeDokun(tester, AnaKabuk.profil);
    expect(_seciliSekme(tester), AnaKabuk.profil);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_seciliSekme(tester), AnaKabuk.defterim);
    expect(kayit.gorunen, [AnaKabuk.defterim]);
  });
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/analytics_service.dart';
import '../widgets/alisveris_parcalari.dart';
import '../widgets/kil/kil.dart';
import '../widgets/ne_pisirsem_parcalari.dart' show MalzemeEklemeSatiri;
import '../widgets/tarif_listesi_parcalari.dart' show TarifBosDurum;

class AlisverisListesi extends StatefulWidget {
  const AlisverisListesi({super.key, this.gorunduSinyali});

  /// Kabukta bu sekme yeniden seçilince haber verir. Sekme açık kaldığı için
  /// "açıldı" olayı ve liste tazeleme o an tekrarlanır (tarif detayından
  /// eklenen malzemeler görünsün).
  final Listenable? gorunduSinyali;

  @override
  State<AlisverisListesi> createState() => _AlisverisListesiState();
}

class _AlisverisListesiState extends State<AlisverisListesi> {
  List<String> _alinacaklar = [];
  List<String> _alinanlar = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.alisverisListesiAcildi();
    _yukle();
    widget.gorunduSinyali?.addListener(_sekmeGorundu);
  }

  @override
  void dispose() {
    widget.gorunduSinyali?.removeListener(_sekmeGorundu);
    _controller.dispose();
    super.dispose();
  }

  void _sekmeGorundu() {
    AnalyticsService.alisverisListesiAcildi();
    _yukle();
  }

  Future<void> _yukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _alinacaklar = prefs.getStringList('shopping_list_todo') ?? [];
      _alinanlar = prefs.getStringList('shopping_list_done') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _kaydet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shopping_list_todo', _alinacaklar);
    await prefs.setStringList('shopping_list_done', _alinanlar);
  }

  void _ekle(String madde) {
    if (madde.trim().isNotEmpty) {
      setState(() {
        _alinacaklar.insert(0, madde.trim());
      });
      _controller.clear();
      _kaydet();
      AnalyticsService.alisverisListesineEklendi();
    }
  }

  void _sil(String madde, bool isDone) {
    setState(() {
      if (isDone) {
        _alinanlar.remove(madde);
      } else {
        _alinacaklar.remove(madde);
      }
    });
    _kaydet();
  }

  void _toggleDurum(String madde, bool isDone) {
    setState(() {
      if (isDone) {
        _alinanlar.remove(madde);
        _alinacaklar.insert(0, madde);
      } else {
        _alinacaklar.remove(madde);
        _alinanlar.insert(0, madde);
      }
    });
    _kaydet();
  }

  void _alinanlariTemizle() {
    setState(() {
      _alinanlar.clear();
    });
    _kaydet();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final silEtiketi = 'shopping_list_delete_item'.tr();

    Widget satir(String madde, bool alindi) => AlisverisMaddeSatiri(
      madde: madde,
      alindi: alindi,
      silEtiketi: silEtiketi,
      onDegistir: () => _toggleDurum(madde, alindi),
      onSil: () => _sil(madde, alindi),
    );

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          bottom: false,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: r.birincil))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    AlisverisBasligi(baslik: 'shopping_list_title'.tr()),
                    const SizedBox(height: 16),
                    MalzemeEklemeSatiri(
                      controller: _controller,
                      ipucu: 'shopping_list_add_hint'.tr(),
                      ekleEtiketi: 'shopping_list_add_button'.tr(),
                      onEkle: _ekle,
                    ),
                    const SizedBox(height: 24),
                    if (_alinacaklar.isEmpty && _alinanlar.isEmpty)
                      TarifBosDurum(
                        ikon: Icons.shopping_basket_rounded,
                        renk: r.klasorCorba,
                        baslik: 'shopping_list_empty_title'.tr(),
                        altBaslik: 'shopping_list_empty_subtitle'.tr(),
                      ),
                    if (_alinacaklar.isNotEmpty)
                      AlisverisBolumu(
                        baslik: 'shopping_list_todo'.tr(),
                        satirlar: [
                          for (final madde in _alinacaklar) satir(madde, false),
                        ],
                      ),
                    if (_alinacaklar.isNotEmpty && _alinanlar.isNotEmpty)
                      const SizedBox(height: 24),
                    if (_alinanlar.isNotEmpty)
                      AlisverisBolumu(
                        baslik: 'shopping_list_done'.tr(),
                        alindi: true,
                        eylem: KilDugme.ikincil(
                          etiket: 'common_clear'.tr(),
                          ikon: Icons.delete_sweep_rounded,
                          onPressed: _alinanlariTemizle,
                        ),
                        satirlar: [
                          for (final madde in _alinanlar) satir(madde, true),
                        ],
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

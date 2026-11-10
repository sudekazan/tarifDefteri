import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';
import '../services/analytics_service.dart';
import '../utils/arama_metni.dart';
import '../widgets/arama_parcalari.dart';
import '../widgets/kil/kil.dart';

class AramaSayfasi extends StatefulWidget {
  const AramaSayfasi({super.key});

  @override
  State<AramaSayfasi> createState() => _AramaSayfasiState();
}

class _AramaSayfasiState extends State<AramaSayfasi> {
  final TextEditingController _aramaController = TextEditingController();
  List<TarifData> _tumTarifler = [];
  List<TarifData> _filtrelenmisTarifler = [];
  bool _isLoading = true;

  /// Son boş olmayan aramanın sonuç bulup bulmadığı; hiç arama yapılmadıysa
  /// null. Sayfadan çıkarken tek bir arama_yapildi olayı göndermek için.
  bool? _sonAramaSonucVar;

  @override
  void initState() {
    super.initState();
    _tumTarifleriYukle();
  }

  @override
  void dispose() {
    if (_sonAramaSonucVar != null) {
      AnalyticsService.aramaYapildi(sonucVar: _sonAramaSonucVar!);
    }
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _tumTarifleriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? [];
    List<TarifData> tumTarifler = [];

    for (int i = 0; i < klasorJsonList.length; i++) {
      // Tek bir bozuk kayıt tüm aramayı (sonsuz yükleniyor) kilitlemesin.
      try {
        final map = json.decode(klasorJsonList[i]);
        int kid = map['klasor_id'] ?? (i + 1);

        String key = 'tarifler_$kid';
        List<String> tariflerJson = prefs.getStringList(key) ?? [];
        for (var e in tariflerJson) {
          try {
            tumTarifler.add(TarifData.fromMap(json.decode(e)));
          } catch (err) {
            debugPrint('Aramada bozuk tarif kaydı atlandı: $err');
          }
        }
      } catch (err) {
        debugPrint('Aramada bozuk klasör kaydı atlandı: $err');
      }
    }

    if (mounted) {
      setState(() {
        _tumTarifler = tumTarifler;
        _isLoading = false;
      });
    }
  }

  void _ara(String query) {
    if (query.isEmpty) {
      setState(() {
        _filtrelenmisTarifler = [];
      });
      return;
    }

    setState(() {
      _filtrelenmisTarifler = _tumTarifler.where((tarif) {
        return aramaEslesir(tarif.tarif_adi, query) ||
            aramaEslesir(tarif.tarif_aciklama, query);
      }).toList();
    });
    _sonAramaSonucVar = _filtrelenmisTarifler.isNotEmpty;
  }

  Future<void> _tarifiAc(TarifData tarif) async {
    final guncelTarif = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TarifDetay(tarif: tarif)),
    );
    if (guncelTarif == true ||
        (guncelTarif != null && guncelTarif is TarifData)) {
      _tumTarifleriYukle().then((_) {
        if (mounted) _ara(_aramaController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;

    final Widget icerik;
    if (_isLoading) {
      icerik = Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator(color: r.birincil)),
      );
    } else if (_aramaController.text.isEmpty) {
      icerik = AramaBilgiKarti(metin: 'recipe_search_prompt'.tr());
    } else if (_filtrelenmisTarifler.isEmpty) {
      icerik = AramaBilgiKarti(
        metin: 'recipes_search_no_results'.tr(),
        sonucYok: true,
      );
    } else {
      icerik = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _filtrelenmisTarifler.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            AramaSonucSatiri(
              ad: _filtrelenmisTarifler[i].tarif_adi,
              resimYolu: _filtrelenmisTarifler[i].tarif_resimler.isNotEmpty
                  ? _filtrelenmisTarifler[i].tarif_resimler.first
                  : null,
              onTap: () => _tarifiAc(_filtrelenmisTarifler[i]),
            ),
          ],
        ],
      );
    }

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          bottom: false,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              AramaUstSatiri(
                controller: _aramaController,
                ipucu: 'recipes_search_hint'.tr(),
                onDegisti: _ara,
                onTemizle: () {
                  _aramaController.clear();
                  _ara('');
                },
              ),
              const SizedBox(height: 16),
              icerik,
            ],
          ),
        ),
      ),
    );
  }
}

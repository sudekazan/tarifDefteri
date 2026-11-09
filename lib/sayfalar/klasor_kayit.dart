import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/kil/kil.dart';
import '../widgets/klasor_ikon_secici.dart';

/// Yeni klasör: ad ve ikon. Kaydet'e basınca `{'klasorAdi', 'iconCode'}`
/// döner; klasörü ana sayfa kaydeder.
class KlasorKayit extends StatefulWidget {
  const KlasorKayit({super.key});

  @override
  State<KlasorKayit> createState() => _KlasorKayitState();
}

class _KlasorKayitState extends State<KlasorKayit> {
  var tfklasorAdi = TextEditingController();
  int selectedIconCode = 0xe2c7; // Icons.folder

  @override
  void dispose() {
    tfklasorAdi.dispose();
    super.dispose();
  }

  bool get _adVar => tfklasorAdi.text.trim().isNotEmpty;

  void _kaydet() {
    final name = tfklasorAdi.text.trim();
    if (name.isNotEmpty) {
      Navigator.pop(context, {
        'klasorAdi': name,
        'iconCode': selectedIconCode,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              KilSayfaBasligi(baslik: 'home_new_folder'.tr()),
              const SizedBox(height: 20),
              TextField(
                controller: tfklasorAdi,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'folder_name_label'.tr(),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'folder_icon_select'.tr(),
                style: yaziTemasi.titleMedium,
              ),
              const SizedBox(height: 12),
              KlasorIkonSecici(
                seciliKod: selectedIconCode,
                onSecildi: (kod) => setState(() => selectedIconCode = kod),
                anlamEtiketi: (sira) => '${'folder_icon_select'.tr()} $sira',
              ),
              const SizedBox(height: 32),
              KilDugme.birincil(
                etiket: 'common_save'.tr(),
                ikon: Icons.check_rounded,
                tamGenislik: true,
                onPressed: _adVar ? _kaydet : null,
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }
}

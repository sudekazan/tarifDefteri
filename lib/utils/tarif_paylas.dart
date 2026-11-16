import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../auth_screen.dart';
import '../services/analytics_service.dart';
import '../services/tarif_paylasim_service.dart';
import '../tarifler_data/tarif_data.dart';
import '../widgets/kil/kil.dart';
import 'magaza_linki.dart';
import 'tarif_bolumleri.dart';

/// Tarifi paylaşır (tarif detayı, klasör içi ve klasörler ekranı ortak).
///
/// Giriş yapılmışsa Tarifly linki oluşturulur: alan kişi linke dokununca
/// tarif Tarifly'de açılır ve defterine ekleyebilir. Giriş yoksa ya da link
/// oluşturulamazsa (internet yok vb.) tarif düz metin olarak gider; giriş
/// yoksa paylaşımdan sonra "giriş yap" bildirimi çıkar.
///
/// [dugmeContext]: iPad'de paylaşım penceresi bu düğmenin yanından açılır.
Future<void> tarifiPaylas({
  required BuildContext context,
  required BuildContext dugmeContext,
  required TarifData tarif,
  required String kaynak,
}) async {
  final box = dugmeContext.findRenderObject() as RenderBox?;
  final konum = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

  final bolumler = tarifBolumleriniCoz(
    tarif,
    varsayilanBaslik: 'recipe_section_ingredients'.tr(),
  );
  final girisli = FirebaseAuth.instance.currentUser != null;

  String? link;
  if (girisli) {
    link = await _bekleterekLinkOlustur(context, tarif, bolumler);
  }
  if (!context.mounted) return;

  final metin = link != null
      ? '📖 ${tarif.tarif_adi}\n\n${'share_link_message'.tr()}\n$link'
      : '${tarifDuzMetni(tarif, bolumler)}'
          '\n━━━━━━━━━━━━━━━━━━\n'
          '${'share_from_app'.tr()}'
          '\n${'share_download_cta'.tr()} $magazaLinki';

  try {
    await Share.share(metin, subject: tarif.tarif_adi, sharePositionOrigin: konum);
    AnalyticsService.tarifPaylasildi(
      kaynak: kaynak,
      yontem: link != null ? 'link' : 'metin',
    );
  } catch (e) {
    debugPrint('Tarif paylaşma hatası: $e');
    if (context.mounted) {
      KilBildirim.goster(context, 'share_error_generic'.tr(), tur: KilBildirimTuru.hata);
    }
    return;
  }

  if (!girisli && context.mounted) {
    KilBildirim.goster(
      context,
      'share_login_hint'.tr(),
      sure: const Duration(seconds: 6),
      eylemEtiketi: 'auth_button_login'.tr(),
      onEylem: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      ),
    );
  }
}

/// Link hazırlanırken ekranda bekleme göstergesi durur. Başarısızsa null.
Future<String?> _bekleterekLinkOlustur(
  BuildContext context,
  TarifData tarif,
  List<Map<String, dynamic>> bolumler,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var acik = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Semantics(
          label: 'share_preparing'.tr(),
          child: const CircularProgressIndicator.adaptive(),
        ),
      ),
    ),
  ).whenComplete(() => acik = false);

  try {
    return await TarifPaylasimService()
        .linkOlustur(tarif, bolumler: bolumler, dil: context.locale.languageCode)
        .timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('Paylaşım linki oluşturulamadı, metin gidecek: $e');
    return null;
  } finally {
    if (acik) navigator.pop();
  }
}

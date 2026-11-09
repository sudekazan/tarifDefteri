import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'kil/kil.dart';

enum AiHakDolduSecim { reklamIzle, proyaGec }

/// Ücretsiz kullanıcının günlük AI Şef hakkı bittiğinde gösterilir.
/// Kullanıcının seçimini döndürür; diyalog dışına basıp kapatırsa ya da
/// "Daha sonra" derse `null` döner. Navigasyonu çağıran ekran yapar.
Future<AiHakDolduSecim?> aiHakDolduDialogGoster(BuildContext context) {
  return showDialog<AiHakDolduSecim>(
    context: context,
    builder: (_) => const _AiHakDolduDialog(),
  );
}

class _AiHakDolduDialog extends StatelessWidget {
  const _AiHakDolduDialog();

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: r.kart,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: r.kenar, width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      // Büyük yazıda içerik kaydırılır, düğmeler kesilmez.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: r.seciliCipZemin,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.stars_rounded,
                    color: r.seciliCipYazi,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                'ai_limit_choice_title'.tr(),
                textAlign: TextAlign.center,
                style: yaziTemasi.titleLarge?.copyWith(color: r.anaYazi),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ai_limit_choice_body'.tr(),
              textAlign: TextAlign.center,
              style: yaziTemasi.bodyLarge
                  ?.copyWith(color: r.solukYazi, height: 1.45),
            ),
            const SizedBox(height: 24),
            KilDugme.birincil(
              etiket: 'ai_limit_choice_watch_ad'.tr(),
              ikon: Icons.ondemand_video_rounded,
              tamGenislik: true,
              onPressed: () =>
                  Navigator.pop(context, AiHakDolduSecim.reklamIzle),
            ),
            const SizedBox(height: 10),
            KilDugme.ikincil(
              etiket: 'ai_limit_choice_go_pro'.tr(),
              ikon: Icons.workspace_premium_rounded,
              tamGenislik: true,
              onPressed: () => Navigator.pop(context, AiHakDolduSecim.proyaGec),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: r.solukYazi,
                minimumSize: const Size(double.infinity, 48),
                textStyle: yaziTemasi.labelLarge,
              ),
              child: Text('common_later'.tr(), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

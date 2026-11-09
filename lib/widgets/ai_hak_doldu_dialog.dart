import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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

  // Beyaz yazıyla 4.5:1 kontrastı sağlayan koyu turuncu (Apple HIG kararı);
  // önceki 0xFFE65100 beyaz yazıyla ~3.8:1 kalıyordu.
  static const _turuncu = Color(0xFFBF360C);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vurgu = isDark ? const Color(0xFFFF8A65) : _turuncu;
    final ikincilYazi = isDark ? Colors.white70 : Colors.black87;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Color(0xFFFFA000), size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              'ai_limit_choice_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'ai_limit_choice_body'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.45, color: ikincilYazi),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, AiHakDolduSecim.reklamIzle),
                icon: const Icon(Icons.ondemand_video_rounded, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'ai_limit_choice_watch_ad'.tr(),
                    maxLines: 1,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _turuncu,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, AiHakDolduSecim.proyaGec),
                icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'ai_limit_choice_go_pro'.tr(),
                    maxLines: 1,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: vurgu,
                  side: BorderSide(color: vurgu, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: ikincilYazi,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text('common_later'.tr(), style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

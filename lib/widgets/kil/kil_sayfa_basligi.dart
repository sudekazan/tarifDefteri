import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/kil_renkleri.dart';
import 'kil_yuvarlak_dugme.dart';

/// Üst çubuksuz (AppBar'sız) kil sayfalarında durum çubuğu ikonlarının rengi.
SystemUiOverlayStyle kilDurumCubuguStili(BuildContext context) {
  final koyu = Theme.of(context).brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: koyu ? Brightness.light : Brightness.dark,
    statusBarBrightness: koyu ? Brightness.dark : Brightness.light,
  );
}

/// İç sayfaların üst kısmı: solda geri düğmesi, sağda isteğe bağlı eylem
/// düğmeleri, altında Caveat ekran başlığı.
///
/// Üst çubuk yerine kaydırılan içeriğin başına konur; böylece başlık büyük
/// yazıda kesilmez, alt satıra geçer.
class KilSayfaBasligi extends StatelessWidget {
  const KilSayfaBasligi({
    super.key,
    required this.baslik,
    this.onGeri,
    this.eylemler = const [],
  });

  final String baslik;

  /// Verilmezse sayfa kapanır (`Navigator.maybePop`).
  final VoidCallback? onGeri;

  /// Sağdaki düğmeler (ör. arama). Her biri en az 48x48.
  final List<Widget> eylemler;

  /// Yuvarlak düğmenin görünen dairesi dokunma alanının içinde bu kadar
  /// içeride; düğmeler bu kadar kaydırılınca daire başlıkla aynı hizaya gelir.
  static const double _icPay =
      (KilYuvarlakDugme.dokunmaBoyutu - KilYuvarlakDugme.gorunenBoyut) / 2;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final ios = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Transform.translate(
              offset: const Offset(-_icPay, 0),
              child: KilYuvarlakDugme(
                ikon: ios
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_back_rounded,
                etiket: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onGeri ?? () => Navigator.maybePop(context),
              ),
            ),
            const Spacer(),
            for (final eylem in eylemler)
              Transform.translate(
                offset: const Offset(_icPay, 0),
                child: eylem,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          // Caveat (headlineLarge, 34).
          child: Text(
            baslik,
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(color: r.baslik),
          ),
        ),
      ],
    );
  }
}

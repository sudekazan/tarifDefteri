import 'package:flutter/material.dart';

import '../utils/yemek_zamanlayici.dart';
import 'kil/kil.dart';

const _rakamlar = [FontFeature.tabularFigures()];

/// Yemek modunda ilerleme çubuğunun altındaki zamanlayıcı şeridi.
/// Boşken tek bir "Zamanlayıcı" düğmesi; çalışırken kalan süre ve
/// Duraklat / Başlat / Sıfırla.
class YemekZamanlayiciSeridi extends StatelessWidget {
  const YemekZamanlayiciSeridi({
    super.key,
    required this.durum,
    required this.kalan,
    required this.etiket,
    required this.baslatEtiketi,
    required this.duraklatEtiketi,
    required this.sifirlaEtiketi,
    required this.bittiMetni,
    required this.onAc,
    required this.onDuraklat,
    required this.onDevam,
    required this.onSifirla,
  });

  final ZamanlayiciDurumu durum;
  final Duration kalan;
  final String etiket;
  final String baslatEtiketi;
  final String duraklatEtiketi;
  final String sifirlaEtiketi;
  final String bittiMetni;
  final VoidCallback onAc;
  final VoidCallback onDuraklat;
  final VoidCallback onDevam;
  final VoidCallback onSifirla;

  @override
  Widget build(BuildContext context) {
    if (durum == ZamanlayiciDurumu.bos) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: KilDugme.ikincil(
          etiket: etiket,
          ikon: Icons.timer_outlined,
          onPressed: onAc,
        ),
      );
    }

    final r = context.kil;
    final bitti = durum == ZamanlayiciDurumu.bitti;
    final yaziRengi = bitti ? r.oneCikanKartYazi : r.anaYazi;
    return Semantics(
      liveRegion: bitti,
      label: etiket,
      child: KilKart(
        oneCikan: bitti,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
        child: Row(
          children: [
            Icon(
              bitti ? Icons.alarm_on_rounded : Icons.timer_outlined,
              color: yaziRengi,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                bitti ? bittiMetni : zamanlayiciMetni(kalan),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: yaziRengi,
                  fontWeight: FontWeight.w700,
                  fontFeatures: _rakamlar,
                ),
              ),
            ),
            if (durum == ZamanlayiciDurumu.calisiyor)
              KilYuvarlakDugme(
                ikon: Icons.pause_rounded,
                etiket: duraklatEtiketi,
                onPressed: onDuraklat,
              ),
            if (durum == ZamanlayiciDurumu.duraklatildi)
              KilYuvarlakDugme(
                ikon: Icons.play_arrow_rounded,
                etiket: baslatEtiketi,
                onPressed: onDevam,
              ),
            KilYuvarlakDugme(
              ikon: bitti ? Icons.close_rounded : Icons.restart_alt_rounded,
              etiket: sifirlaEtiketi,
              onPressed: onSifirla,
            ),
          ],
        ),
      ),
    );
  }
}

/// Alt sayfadaki süre seçici: dakikayı -/+ ile ya da hazır seçeneklerle
/// ayarlar; "Başlat" seçilen süreyi döndürür (`Navigator.pop`).
class YemekZamanlayiciSecici extends StatefulWidget {
  const YemekZamanlayiciSecici({
    super.key,
    required this.baslik,
    required this.baslatEtiketi,
    this.ilkDakika = 5,
  });

  /// Alt sayfanın başlığı burada çizilir: büyük yazıda en fazla 2 kat.
  final String baslik;
  final String baslatEtiketi;
  final int ilkDakika;

  static const hazirDakikalar = [1, 3, 5, 10, 15, 20, 30, 45, 60];
  static const enCokDakika = 180;

  @override
  State<YemekZamanlayiciSecici> createState() => _YemekZamanlayiciSeciciState();
}

class _YemekZamanlayiciSeciciState extends State<YemekZamanlayiciSecici> {
  late int _dakika = widget.ilkDakika;

  void _ayarla(int d) =>
      setState(() => _dakika = d.clamp(1, YemekZamanlayiciSecici.enCokDakika));

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    // Büyük yazıda alt sayfa kaydırılabilir; süre rakamları en fazla 2 kat.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Semantics(
                header: true,
                child: Text(
                  widget.baslik,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: r.baslik),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KilYuvarlakDugme(
                ikon: Icons.remove_rounded,
                etiket: '-1:00',
                onPressed: _dakika > 1 ? () => _ayarla(_dakika - 1) : null,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 2,
                    child: Text(
                      zamanlayiciMetni(Duration(minutes: _dakika)),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 36,
                        color: r.anaYazi,
                        fontWeight: FontWeight.w700,
                        fontFeatures: _rakamlar,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              KilYuvarlakDugme(
                ikon: Icons.add_rounded,
                etiket: '+1:00',
                onPressed: _dakika < YemekZamanlayiciSecici.enCokDakika
                    ? () => _ayarla(_dakika + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in YemekZamanlayiciSecici.hazirDakikalar)
                KilCip(
                  etiket: zamanlayiciMetni(Duration(minutes: d)),
                  secili: d == _dakika,
                  onSelected: (_) => _ayarla(d),
                ),
            ],
          ),
          const SizedBox(height: 20),
          KilDugme.birincil(
            etiket: widget.baslatEtiketi,
            ikon: Icons.play_arrow_rounded,
            tamGenislik: true,
            onPressed: () => Navigator.pop(context, Duration(minutes: _dakika)),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'kil/kil.dart';

/// AI tarif oluşturulurken gösterilen "şef çalışıyor" animasyonu.
///
/// Animasyon: LottieFiles "Cooking" (Aravind Chowdary), Lottie Simple License.
/// 30 sn'lik çok sahneli bir yemek hikâyesi (wok'ta sote, kâsede çırpma);
/// altında belirli aralıklarla değişen adım metinleri gösterilir.
///
/// Dosya değiştirilmez; paletin dışındaki renkler çizilirken kil renklerine
/// eşlenir ([renkTemsilcileri]). Böylece animasyon açık ve koyu modda kartın
/// üstünde aynı paletle görünür.
class AiChefLoadingAnimation extends StatefulWidget {
  final String title;
  final List<String> messages;

  const AiChefLoadingAnimation({
    super.key,
    required this.title,
    required this.messages,
  });

  /// Animasyonun özgün renkleri (RGB). Yalnızca paletle uyuşmayanlar
  /// değiştirilir; sıcak yemek renkleri (alev, baharat, ahşap) kalır.
  static const int _mor = 0x58357C; // tava, çırpıcı ve kepçe sapı
  static const int _mor2 = 0x58347B;
  static const int _morAcik = 0x863576;
  static const int _pembeKase = 0xF59798; // kâse
  static const int _pembeOlcu = 0xF99999; // ölçü kabının içi
  static const int _pembeAcik = 0xFBC5C5; // ölçü kabı
  static const int _yesilKoyu = 0x206C51; // yağ şişesi
  static const int _yesil = 0x6ABC45;
  static const int _arduvaz = 0x2B3841; // tencere kulpları
  static const int _beyaz = 0xFFFFFF; // şekillerin çevresindeki ayırıcı çizgi

  /// Özgün renk → kil rengi. Koyu modda da açık modla aynı sırayla (koyu
  /// gölge / açık yüz) eşlenir.
  static Map<int, Color> _dolguEslemesi(KilRenkleri r) => {
        _mor: r.birincilGolge,
        _mor2: r.birincilGolge,
        _morAcik: r.birincil,
        _pembeKase: r.vurgu,
        _pembeOlcu: r.vurgu,
        _pembeAcik: Color.lerp(r.vurgu, r.kart, 0.6)!,
        _yesilKoyu: r.vurguGolge,
        _yesil: r.vurgu,
        _arduvaz: r.anaYazi,
      };

  static Map<int, Color> _cizgiEslemesi(KilRenkleri r) => {
        ..._dolguEslemesi(r),
        // Beyaz ayırıcı çizgiler zemin rengini taklit eder; koyu modda beyaz
        // kalırsa her şeklin çevresinde parlak bir çizgi çıkıyordu.
        _beyaz: r.kart,
      };

  /// Animasyon renklerini [r] paletine eşleyen temsilciler.
  ///
  /// Düz renkli katmanlar (animasyonun beyaz arka planı) kart rengine boyanır;
  /// yoksa koyu modda kartın ortasında beyaz bir dikdörtgen kalıyordu.
  static LottieDelegates renkTemsilcileri(KilRenkleri r) {
    final dolgu = _dolguEslemesi(r);
    final cizgi = _cizgiEslemesi(r);
    return LottieDelegates(
      values: [
        ValueDelegate.color(
          const ['**'],
          callback: (bilgi) {
            final ozgun = bilgi.startValue;
            // Düz renkli katmanda özgün renk gelmez.
            if (ozgun == null) return r.kart;
            return eslenmisRenk(ozgun, dolgu);
          },
        ),
        ValueDelegate.strokeColor(
          const ['**'],
          callback: (bilgi) {
            final ozgun = bilgi.startValue;
            if (ozgun == null) return r.kart;
            return eslenmisRenk(ozgun, cizgi);
          },
        ),
      ],
    );
  }

  /// [ozgun] eşlemede varsa (kanal başına ±2 yuvarlama payıyla) karşılığını,
  /// yoksa kendisini döndürür. Saydamlık korunur.
  @visibleForTesting
  static Color eslenmisRenk(Color ozgun, Map<int, Color> esleme) {
    final r = (ozgun.r * 255).round();
    final g = (ozgun.g * 255).round();
    final b = (ozgun.b * 255).round();
    bool yakin(int a, int b) => (a - b).abs() <= 2;
    for (final e in esleme.entries) {
      if (yakin((e.key >> 16) & 0xFF, r) &&
          yakin((e.key >> 8) & 0xFF, g) &&
          yakin(e.key & 0xFF, b)) {
        return e.value.withValues(alpha: ozgun.a);
      }
    }
    return ozgun;
  }

  @override
  State<AiChefLoadingAnimation> createState() => _AiChefLoadingAnimationState();
}

class _AiChefLoadingAnimationState extends State<AiChefLoadingAnimation> {
  static const _animasyonDosyasi = 'assets/animations/ai_tarif_hazirlaniyor.lottie';

  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.messages.length > 1) {
      _messageTimer = Timer.periodic(const Duration(milliseconds: 1900), (_) {
        if (!mounted) return;
        setState(() => _messageIndex = (_messageIndex + 1) % widget.messages.length);
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  /// .lottie dosyası bir zip; içindeki animasyon JSON'unu seçer.
  static Future<LottieComposition?> _dotLottieCoz(List<int> bytes) {
    return LottieComposition.decodeZip(
      bytes,
      filePicker: (files) => files
          .where((f) => f.name.startsWith('animations/') && f.name.endsWith('.json'))
          .firstOrNull,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;
    // Sistemde "hareketi azalt" açıksa animasyon ilk karede durur, metinler
    // geçişsiz değişir.
    final hareketAzaltildi = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: 220,
            height: 127, // Animasyonun 375x216 oranı
            child: Lottie.asset(
              _animasyonDosyasi,
              decoder: _dotLottieCoz,
              animate: !hareketAzaltildi,
              fit: BoxFit.contain,
              delegates: AiChefLoadingAnimation.renkTemsilcileri(r),
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Yükleme animasyonu açılamadı: $error');
                return Icon(
                  Icons.restaurant_rounded,
                  size: 48,
                  color: r.birincil,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            widget.title,
            style: yaziTemasi.titleMedium?.copyWith(color: r.anaYazi),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: hareketAzaltildi
              ? Duration.zero
              : const Duration(milliseconds: 350),
          child: Text(
            widget.messages[_messageIndex],
            key: ValueKey(_messageIndex),
            textAlign: TextAlign.center,
            style: yaziTemasi.bodyMedium?.copyWith(color: r.solukYazi),
          ),
        ),
      ],
    );
  }
}

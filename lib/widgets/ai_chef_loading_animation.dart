import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// AI tarif oluşturulurken gösterilen "şef çalışıyor" animasyonu.
///
/// Animasyon: LottieFiles "Cooking" (Aravind Chowdary), Lottie Simple License.
/// 30 sn'lik çok sahneli bir yemek hikâyesi (wok'ta sote, kâsede çırpma);
/// altında belirli aralıklarla değişen adım metinleri gösterilir.
class AiChefLoadingAnimation extends StatefulWidget {
  final String title;
  final List<String> messages;

  const AiChefLoadingAnimation({
    super.key,
    required this.title,
    required this.messages,
  });

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
    // Sistemde "hareketi azalt" açıksa animasyon ilk karede durur.
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
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Yükleme animasyonu açılamadı: $error');
                return Icon(
                  Icons.restaurant_rounded,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Text(
            widget.messages[_messageIndex],
            key: ValueKey(_messageIndex),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}

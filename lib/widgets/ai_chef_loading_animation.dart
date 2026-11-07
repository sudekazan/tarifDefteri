import 'dart:async';
import 'package:flutter/material.dart';

/// AI tarif oluşturulurken gösterilen "şef çalışıyor" animasyonu.
///
/// Harici bir animasyon paketi (Lottie vb.) gerektirmez; sade bir tencere +
/// üstünde sallanan bir kaşık/çatal ikonu (bıçak doğrama hissi) + yükselip
/// kaybolan buhar baloncukları + belirli aralıklarla değişen eğlenceli
/// metinlerden oluşur. Tamamı Flutter'ın kendi [AnimationController]'ları ile.
class AiChefLoadingAnimation extends StatefulWidget {
  final String title;
  final List<String> messages;
  final Color color;

  const AiChefLoadingAnimation({
    super.key,
    required this.title,
    required this.messages,
    this.color = const Color(0xFFE65100),
  });

  @override
  State<AiChefLoadingAnimation> createState() => _AiChefLoadingAnimationState();
}

class _AiChefLoadingAnimationState extends State<AiChefLoadingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _steamController;
  late final AnimationController _utensilController;
  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _utensilController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);

    if (widget.messages.length > 1) {
      _messageTimer = Timer.periodic(const Duration(milliseconds: 1900), (_) {
        if (!mounted) return;
        setState(() => _messageIndex = (_messageIndex + 1) % widget.messages.length);
      });
    }
  }

  @override
  void dispose() {
    _steamController.dispose();
    _utensilController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 76,
          width: 100,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Buhar baloncukları: yukarı doğru yükselip solar.
              ...List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _steamController,
                  builder: (context, child) {
                    final t = (_steamController.value + i / 3) % 1.0;
                    return Positioned(
                      bottom: 38 + t * 32,
                      left: 50 + (i - 1) * 16 - 4,
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0) * 0.55,
                        child: Container(
                          width: 6 + 5 * t,
                          height: 6 + 5 * t,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              // Dönen kaşık/çatal: bir bıçağın doğrarken yaptığı küçük açı
              // salınımını taklit eder.
              AnimatedBuilder(
                animation: _utensilController,
                builder: (context, child) {
                  final angle = (_utensilController.value - 0.5) * 0.5; // ~ -0.25..0.25 rad
                  return Positioned(
                    bottom: 30,
                    child: Transform.rotate(
                      angle: angle,
                      alignment: Alignment.bottomCenter,
                      child: Icon(Icons.restaurant_rounded, size: 28, color: color),
                    ),
                  );
                },
              ),
              // Tencere/kap.
              Positioned(
                bottom: 0,
                child: Icon(Icons.ramen_dining_rounded, size: 40, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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

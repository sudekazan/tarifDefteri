import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:tarif_defteri/widgets/ai_chef_loading_animation.dart';

void main() {
  testWidgets('yükleme animasyonu dosyası açılır ve yedek ikona düşmez', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AiChefLoadingAnimation(
          title: 'Şef hazırlıyor',
          messages: ['Adım 1', 'Adım 2'],
        ),
      ),
    ));

    // .lottie (zip) çözümü gerçek asenkron iş; test saatinin dışında bekle.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await tester.pump();

    expect(find.byType(Lottie), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_rounded), findsNothing,
        reason: 'Animasyon açılamazsa yedek ikon gösterilir');
    expect(find.text('Şef hazırlıyor'), findsOneWidget);
    expect(find.text('Adım 1'), findsOneWidget);

    // Dönen metin zamanlayıcısını kapat.
    await tester.pumpWidget(const SizedBox());
  });
}

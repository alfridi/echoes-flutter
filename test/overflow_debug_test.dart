import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes_flutter/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Check OnboardingScreen overflow', (tester) async {
    final sizes = [
      const Size(360, 800),
      const Size(375, 812),
      const Size(390, 844),
      const Size(393, 852),
      const Size(412, 915),
      const Size(414, 896),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      final exception = tester.takeException();
      if (exception != null) {
        print('Screen size: $size => Exception: $exception');
      } else {
        print('Screen size: $size => No exception');
      }
    }
  });
}

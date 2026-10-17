import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/app.dart';
import 'package:clinova/features/splash/splash_screen.dart';
import 'package:clinova/features/welcome/welcome_screen.dart';

void main() {
  group('SplashScreen Animation Tests', () {
    testWidgets('renders all three logo assets (heart, wordmark, leaves)',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ClinovaApp());

      // At start (0ms), the widget tree contains the three Image widgets
      final imageFinders = find.byType(Image);
      expect(imageFinders, findsNWidgets(3));

      // Check asset paths
      final images = tester.widgetList<Image>(imageFinders).toList();
      final assetNames = images
          .map((img) => (img.image as AssetImage).assetName)
          .toList();

      expect(assetNames, contains('assets/images/heart.png'));
      expect(assetNames, contains('assets/images/clinova_wordmark.png'));
      expect(assetNames, contains('assets/images/leaves.png'));
    });

    testWidgets('tap to skip immediately navigates to WelcomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ClinovaApp());

      expect(find.byType(SplashScreen), findsOneWidget);

      // Tap on the screen to skip animation
      await tester.tap(find.byType(SplashScreen));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('completing full choreographed animation transitions to WelcomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ClinovaApp());

      expect(find.byType(SplashScreen), findsOneWidget);

      // Progress through phases
      await tester.pump(const Duration(milliseconds: 400)); // Phase 1 done
      await tester.pump(const Duration(milliseconds: 900)); // Phase 2 (1300ms) done
      await tester.pump(const Duration(milliseconds: 400)); // Phase 3 (1700ms) done
      await tester.pump(const Duration(milliseconds: 500)); // Phase 4 (2200ms) done
      await tester.pump(const Duration(milliseconds: 1000)); // Phase 5 (3200ms) done

      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}

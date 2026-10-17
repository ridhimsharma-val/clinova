import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/app.dart';

void main() {
  testWidgets('Clinova app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ClinovaApp());
    // Verify the Clinova app initializes with the layered logo assets on splash screen
    expect(find.byType(Image), findsWidgets);
  });
}

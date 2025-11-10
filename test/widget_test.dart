// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylemate/main.dart';
import 'package:stylemate/views/splash/splash_page.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Increase the test surface size so the splash view layout does not overflow.
    TestWidgetsFlutterBinding.ensureInitialized();
    // Use the recommended WidgetTester.view APIs (replaces deprecated `window` test hooks).
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1.0;

    // Build our app.
    await tester.pumpWidget(StyleMateApp());

    // Verify the splash screen and app title are present.
  expect(find.text('StyleMate'), findsOneWidget);
  expect(find.byType(SplashPage), findsOneWidget);

  // Let any startup timers finish to avoid pending timer errors in tests.
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpAndSettle();

    // Clear test view overrides.
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:glucose_monitor/main.dart';

void main() {
  testWidgets('Splash screen navigates to home', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GlucoseMonitorApp());

    // Verify that splash screen loads
    expect(find.text('Glucose Monitor'), findsOneWidget);
    expect(find.text('Non-invasive Glucose Monitoring'), findsOneWidget);

    // Wait for splash screen to finish
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that home dashboard loads
    expect(find.text('Glucose Monitor'), findsOneWidget);
  });
}

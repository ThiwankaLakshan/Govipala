// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:agrimachine_app/main.dart';
import 'package:agrimachine_app/services/auth_service.dart';

void main() {
  testWidgets('GovipalaApp landing screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>(
        create: (_) => AuthService(),
        child: const GovipalaApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the title 'Govipala' is shown.
    expect(find.text('Govipala'), findsOneWidget);

    // Verify that the login and register buttons are present.
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}

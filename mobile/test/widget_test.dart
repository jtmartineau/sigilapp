import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/main.dart';
import 'package:mobile/services/auth_service.dart';

void main() {
  testWidgets('App starts at Login Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to inject the provider just like in main()
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthService())],
        child: const SigilApp(),
      ),
    );

    // Verify that we see the 'SigilApp' title (Login Screen)
    // Note: SigilApp title is in the AppBar or Headline of Login Screen
    expect(find.text('SigilApp'), findsOneWidget);

    // Verify we see the "ENTER" button
    expect(find.text('ENTER'), findsOneWidget);
  });
}

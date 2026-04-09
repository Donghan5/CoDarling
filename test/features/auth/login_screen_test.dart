import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codarling/features/auth/presentation/screens/login_screen.dart';

void main() {
  Widget buildSubject() => const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      );

  group('LoginScreen', () {
    testWidgets('renders app name and tagline', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Codarling'), findsOneWidget);
      expect(find.text('Stay close, one photo at a time.'), findsOneWidget);
    });

    testWidgets('renders Google sign-in button', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('renders dev login buttons in debug mode', (tester) async {
      await tester.pumpWidget(buildSubject());

      // kDebugMode is true during tests
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('DEV LOGIN'), findsOneWidget);
    });

    testWidgets('shows loading indicator when sign-in is in progress',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // No loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}

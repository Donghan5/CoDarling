// E2E integration tests — run on a real device/emulator.
//
// Prerequisites:
//   - Emulator running: ~/Android/Sdk/emulator/emulator -avd Pixel_8
//   - Dart-define values available (.dart_define.json)
//
// Run command:
//   flutter test integration_test/ -d emulator-5554 \
//     --dart-define-from-file=.dart_define.json

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:codarling/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App launch', () {
    testWidgets('starts and shows login screen when not signed in',
        (tester) async {
      app.main();
      // Wait for Supabase initialization + GoRouter redirect
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Codarling'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows dev login buttons in debug builds', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });
  });

  group('Dev login — Alice', () {
    // Requires alice@test.codarling to exist in Supabase with DEV_TEST_PASSWORD.
    testWidgets('signs in and navigates away from login screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap Alice dev login button
      await tester.tap(find.text('Alice'));
      // Wait for auth state change + router redirect (up to 10 s)
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // After login, login screen should be gone
      expect(find.text('Continue with Google'), findsNothing);
    });
  });
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Push] Background: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('=== FlutterError: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== PlatformError: $error');
    debugPrint(stack.toString());
    return true;
  };

  assert(
    SupabaseConstants.supabaseUrl.isNotEmpty &&
        SupabaseConstants.supabaseAnonKey.isNotEmpty,
    'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via --dart-define-from-file',
  );

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e, st) {
    // Firebase init failure must not block runApp — if this throws the native
    // splash screen will never dismiss and the user sees a frozen launch.
    debugPrint('=== Firebase.initializeApp() error: $e\n$st');
  }

  runApp(const ProviderScope(child: CodarlingApp()));
}

class CodarlingApp extends ConsumerWidget {
  const CodarlingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize push notifications when user is authenticated
    ref.listen(authStateProvider, (prev, next) {
      final wasAuthenticated = prev?.valueOrNull != null;
      final isAuthenticated = next.valueOrNull != null;
      final pushService = ref.read(pushNotificationServiceProvider);

      if (!wasAuthenticated && isAuthenticated) {
        pushService.onNotificationTap = (type, data) {
          if (type == 'photo_uploaded') router.go('/home');
        };
        pushService.initialize();
      } else if (wasAuthenticated && !isAuthenticated) {
        pushService.removeToken();
      }
    });

    return MaterialApp.router(
      title: 'Codarling',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

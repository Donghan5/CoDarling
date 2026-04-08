import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/metrics_provider.dart';
import 'core/theme/app_theme.dart';

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

  runApp(const ProviderScope(child: CodarlingApp()));
}

class CodarlingApp extends ConsumerWidget {
  const CodarlingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Eagerly start the metrics flush timer
    ref.watch(metricsServiceProvider);
    return MaterialApp.router(
      title: 'Codarling',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

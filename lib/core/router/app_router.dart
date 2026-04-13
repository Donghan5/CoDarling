import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/couple/presentation/providers/couple_provider.dart';
import '../../features/couple/presentation/screens/couple_setup_screen.dart';
import '../../features/photo/presentation/screens/home_screen.dart';
import '../../features/photo/presentation/screens/album_screen.dart';
import '../../features/photo/presentation/screens/calendar_screen.dart';
import '../../features/photo/presentation/screens/upload_photo_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    onException: (_, GoRouterState state, GoRouter router) {
      // Supabase OAuth callback URLs (e.g. io.supabase.xxx://login-callback/)
      // arrive as deep links that GoRouter cannot match. Fall back to /login and
      // let the authStateProvider redirect once the session is established.
      debugPrint('[Router] No route for ${state.uri} — falling back to /login');
      router.go('/login');
    },
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final isAuthenticated = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isCoupleSetupRoute = state.matchedLocation == '/couple-setup';

      if (!isAuthenticated) return isLoginRoute ? null : '/login';

      // Authenticated — check couple status
      final coupleState = ref.read(currentCoupleProvider);
      if (coupleState.isLoading) return null;

      final hasCouple = coupleState.valueOrNull?.isActive == true;

      if (!hasCouple && !isCoupleSetupRoute) return '/couple-setup';
      if (hasCouple && (isLoginRoute || isCoupleSetupRoute)) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/couple-setup',
        builder: (_, __) => const CoupleSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/album',
        builder: (_, __) => const AlbumScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (_, __) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/upload',
        builder: (_, __) => const UploadPhotoScreen(),
      ),
    ],
  );

  // Re-evaluate redirects when auth or couple state changes.
  ref.listen(authStateProvider, (_, __) => router.refresh());
  ref.listen(currentCoupleProvider, (_, __) => router.refresh());

  ref.onDispose(router.dispose);

  return router;
});

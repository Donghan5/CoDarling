import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/couple/presentation/providers/couple_provider.dart';
import '../../features/couple/presentation/screens/couple_setup_screen.dart';
import '../../features/photo/presentation/screens/home_screen.dart';
import '../../features/photo/presentation/screens/album_screen.dart';
import '../../features/photo/presentation/screens/upload_photo_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // Still loading — don't redirect yet
      if (authState.isLoading) return null;

      final isAuthenticated = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';

      // Guard: already-coupled users cannot navigate to couple-setup
      if (isAuthenticated && state.matchedLocation == '/couple-setup') {
        final couple = ref.read(currentCoupleProvider).valueOrNull;
        if (couple != null && couple.isActive) return '/home';
      }

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
        path: '/upload',
        builder: (_, __) => const UploadPhotoScreen(),
      ),
    ],
  );

  // When auth state changes, tell router to re-evaluate redirects.
  // This avoids recreating the GoRouter (which would reset navigation).
  ref.listen(authStateProvider, (_, __) => router.refresh());

  ref.onDispose(router.dispose);

  return router;
});

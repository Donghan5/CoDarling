import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final authDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => SupabaseAuthDataSource(ref.watch(supabaseClientProvider)),
);

final authRepositoryProvider = Provider(
  (ref) => AuthRepositoryImpl(ref.watch(authDataSourceProvider)),
);

final signInWithGoogleProvider = Provider(
  (ref) => SignInWithGoogle(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

/// Stream of the current authenticated user (null = signed out).
final authStateProvider = StreamProvider<UserEntity?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

/// Convenience provider for the current user (throws if not authenticated).
final currentUserProvider = Provider<UserEntity>(
  (ref) => ref.watch(authStateProvider).requireValue!,
);

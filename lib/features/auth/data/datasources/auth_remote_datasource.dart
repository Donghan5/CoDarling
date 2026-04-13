import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();

  /// Debug only — email/password sign-in for test accounts.
  Future<void> signInWithEmailPassword(String email, String password);
}

class SupabaseAuthDataSource implements AuthRemoteDataSource {
  SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  @override
  Stream<UserModel?> get authStateChanges async* {
    // Seed the stream immediately with the current session state.
    // On iOS, onAuthStateChange sometimes delays the INITIAL_SESSION event,
    // leaving the router in a perpetual loading state. Reading currentUser
    // synchronously avoids this race condition.
    try {
      yield await _fetchOrCreateUserModel(_client.auth.currentUser);
    } catch (e, st) {
      debugPrint('=== authStateChanges initial error: $e\n$st');
      yield null;
    }
    yield* _client.auth.onAuthStateChange
        .map((event) => event.session?.user)
        .asyncMap((user) async {
          try {
            return await _fetchOrCreateUserModel(user);
          } catch (e, st) {
            debugPrint('=== authStateChanges error: $e\n$st');
            return null;
          }
        });
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConstants.oauthRedirectUri,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    // Browser launched; auth completion arrives via onAuthStateChange stream.
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    // Session established; authStateChanges stream fires automatically.
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchOrCreateUserModel(user);
  }

  Future<UserModel?> _fetchOrCreateUserModel(User? user) async {
    if (user == null) return null;

    final rows = await _client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', user.id)
        .limit(1);

    if (rows.isNotEmpty) {
      return UserModel.fromJson(rows.first);
    }

    // First sign-in (or race recovery) — upsert to avoid TOCTOU duplicate insert.
    // onConflict 'id' makes this idempotent if two auth events fire concurrently.
    final email = user.email ?? '';
    final rawName =
        user.userMetadata?['full_name'] as String? ?? email.split('@').first;
    final displayName = rawName
        .trim()
        .substring(0, rawName.trim().length.clamp(0, AppConstants.maxDisplayNameLength));
    final avatarUrl = user.userMetadata?['avatar_url'] as String?;

    final upserted = await _client
        .from(AppConstants.usersTable)
        .upsert(
          {
            'id': user.id,
            'email': email,
            'display_name': displayName,
            'avatar_url': avatarUrl,
          },
          onConflict: 'id',
          ignoreDuplicates: false,
        )
        .select()
        .single();

    return UserModel.fromJson(upserted);
  }
}

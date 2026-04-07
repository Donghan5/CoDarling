import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class SupabaseAuthDataSource implements AuthRemoteDataSource {
  SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  @override
  Stream<UserModel?> get authStateChanges => _client.auth.onAuthStateChange
      .map((event) => event.session?.user)
      .asyncMap(_fetchOrCreateUserModel);

  @override
  Future<UserModel> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Google sign-in failed');
    return _fetchOrCreateUserModel(user).then((u) => u!);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

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

    // First sign-in — insert user row
    final email = user.email ?? '';
    final displayName =
        user.userMetadata?['full_name'] as String? ?? email.split('@').first;
    final avatarUrl = user.userMetadata?['avatar_url'] as String?;

    final inserted = await _client
        .from(AppConstants.usersTable)
        .insert({
          'id': user.id,
          'email': email,
          'display_name': displayName,
          'avatar_url': avatarUrl,
        })
        .select()
        .single();

    return UserModel.fromJson(inserted);
  }
}

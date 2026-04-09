import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/invite_code.dart';
import '../models/couple_model.dart';

abstract class CoupleRemoteDataSource {
  Future<CoupleModel> createCouple(String userId);
  Future<CoupleModel> joinCouple(String inviteCode, String userId);
  Future<CoupleModel?> getCoupleForUser(String userId);
}

class SupabaseCoupleDataSource implements CoupleRemoteDataSource {
  SupabaseCoupleDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<CoupleModel> createCouple(String userId) async {
    if (_client.auth.currentUser?.id != userId) {
      throw Exception('createCouple: userId must match the authenticated user');
    }
    final code = InviteCodeGenerator.generate();
    final expiresAt = DateTime.now().toUtc().add(AppConstants.inviteCodeExpiry);
    final result = await _client
        .from(AppConstants.couplesTable)
        .insert({
          'user_id_1': userId,
          'invite_code': code,
          'status': 'pending',
          'invite_code_expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();
    return CoupleModel.fromJson(result);
  }

  @override
  Future<CoupleModel> joinCouple(String inviteCode, String userId) async {
    if (_client.auth.currentUser?.id != userId) {
      throw Exception('joinCouple: userId must match the authenticated user');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from(AppConstants.couplesTable)
        .select()
        .eq('invite_code', inviteCode)
        .eq('status', 'pending')
        .or('invite_code_expires_at.is.null,invite_code_expires_at.gt.$now')
        .limit(1);

    if (rows.isEmpty) throw Exception('Invalid or expired invite code.');

    final couple = CoupleModel.fromJson(rows.first);
    if (couple.userId1 == userId) throw Exception('Cannot join your own invite.');

    final updated = await _client
        .from(AppConstants.couplesTable)
        .update({'user_id_2': userId, 'status': 'active'})
        .eq('id', couple.id)
        .select()
        .single();

    return CoupleModel.fromJson(updated);
  }

  @override
  Future<CoupleModel?> getCoupleForUser(String userId) async {
    final rows = await _client
        .from(AppConstants.couplesTable)
        .select()
        .or('user_id_1.eq.$userId,user_id_2.eq.$userId')
        .limit(1);

    if (rows.isEmpty) return null;
    return CoupleModel.fromJson(rows.first );
  }
}

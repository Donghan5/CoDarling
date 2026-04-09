import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/reaction_model.dart';

abstract class ReactionRemoteDataSource {
  Future<List<ReactionModel>> getReactions({
    required String targetType,
    required String targetId,
  });

  Future<ReactionModel> addReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  });

  Future<void> removeReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  });

  Stream<List<ReactionModel>> watchReactions({
    required String targetType,
    required String targetId,
  });
}

class SupabaseReactionDataSource implements ReactionRemoteDataSource {
  SupabaseReactionDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ReactionModel>> getReactions({
    required String targetType,
    required String targetId,
  }) async {
    final rows = await _client
        .from(AppConstants.reactionsTable)
        .select()
        .eq('target_type', targetType)
        .eq('target_id', targetId)
        .order('created_at');
    return (rows as List)
        .map((r) => ReactionModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReactionModel> addReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  }) async {
    if (_client.auth.currentUser?.id != userId) {
      throw Exception('addReaction: userId must match the authenticated user');
    }
    final result = await _client
        .from(AppConstants.reactionsTable)
        .insert({
          'user_id': userId,
          'target_type': targetType,
          'target_id': targetId,
          'emoji': emoji,
        })
        .select()
        .single();
    return ReactionModel.fromJson(result);
  }

  @override
  Future<void> removeReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  }) async {
    if (_client.auth.currentUser?.id != userId) {
      throw Exception('removeReaction: userId must match the authenticated user');
    }
    await _client
        .from(AppConstants.reactionsTable)
        .delete()
        .eq('user_id', userId)
        .eq('target_type', targetType)
        .eq('target_id', targetId)
        .eq('emoji', emoji);
  }

  @override
  Stream<List<ReactionModel>> watchReactions({
    required String targetType,
    required String targetId,
  }) {
    final controller = StreamController<List<ReactionModel>>();

    // Fetch initial data
    getReactions(targetType: targetType, targetId: targetId).then((initial) {
      if (!controller.isClosed) controller.add(initial);
    }).catchError((Object e) {
      if (!controller.isClosed) controller.addError(e);
    });

    // Subscribe to realtime changes
    final channel = _client
        .channel('reactions:$targetType:$targetId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.reactionsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_id',
            value: targetId,
          ),
          callback: (_) async {
            if (controller.isClosed) return;
            try {
              final updated = await getReactions(
                targetType: targetType,
                targetId: targetId,
              );
              if (!controller.isClosed) controller.add(updated);
            } catch (e) {
              if (!controller.isClosed) controller.addError(e);
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    return controller.stream;
  }
}

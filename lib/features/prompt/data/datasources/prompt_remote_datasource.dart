import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/prompt_model.dart';

abstract class PromptRemoteDataSource {
  /// Returns null if no prompt has been set for today.
  Future<PromptModel?> getTodayPrompt({
    required String coupleId,
    required String date,
  });

  Future<PromptReplyModel> submitReply({
    required String promptId,
    required String userId,
    required String replyText,
  });

  Future<List<PromptReplyModel>> getReplies({required String promptId});
}

class SupabasePromptDataSource implements PromptRemoteDataSource {
  const SupabasePromptDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<PromptModel?> getTodayPrompt({
    required String coupleId,
    required String date,
  }) async {
    final row = await _client
        .from(AppConstants.promptsTable)
        .select()
        .eq('couple_id', coupleId)
        .eq('date', date)
        .maybeSingle();

    return row == null ? null : PromptModel.fromJson(row);
  }

  @override
  Future<PromptReplyModel> submitReply({
    required String promptId,
    required String userId,
    required String replyText,
  }) async {
    final row = await _client
        .from(AppConstants.promptRepliesTable)
        .insert({
          'prompt_id': promptId,
          'user_id': userId,
          'reply_text': replyText,
        })
        .select()
        .single();

    return PromptReplyModel.fromJson(row);
  }

  @override
  Future<List<PromptReplyModel>> getReplies({required String promptId}) async {
    final rows = await _client
        .from(AppConstants.promptRepliesTable)
        .select()
        .eq('prompt_id', promptId)
        .order('created_at');

    return rows.map((r) => PromptReplyModel.fromJson(r)).toList();
  }
}

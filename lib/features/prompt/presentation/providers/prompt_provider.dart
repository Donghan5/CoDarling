import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../couple/presentation/providers/couple_provider.dart';
import '../../data/datasources/prompt_remote_datasource.dart';
import '../../data/repositories/prompt_repository_impl.dart';
import '../../domain/entities/prompt_entity.dart';
import '../../domain/usecases/get_today_prompt.dart';
import '../../domain/usecases/submit_reply.dart';

// ── Infra providers ─────────────────────────────────────────────────────────

final promptDataSourceProvider = Provider<PromptRemoteDataSource>(
  (ref) => SupabasePromptDataSource(ref.watch(supabaseClientProvider)),
);

final promptRepositoryProvider = Provider(
  (ref) => PromptRepositoryImpl(ref.watch(promptDataSourceProvider)),
);

// ── UseCase providers ────────────────────────────────────────────────────────

final getTodayPromptProvider = Provider(
  (ref) => GetTodayPrompt(ref.watch(promptRepositoryProvider)),
);

final submitReplyProvider = Provider(
  (ref) => SubmitReply(ref.watch(promptRepositoryProvider)),
);

// ── State ────────────────────────────────────────────────────────────────────

/// Snapshot of today's prompt state for the couple.
class TodayPromptState {
  const TodayPromptState({
    required this.prompt,
    required this.myReply,
    required this.partnerReply,
  });

  final PromptEntity prompt;
  final PromptReplyEntity? myReply;
  final PromptReplyEntity? partnerReply;

  bool get hasMyReply => myReply != null;
  bool get hasPartnerReply => partnerReply != null;

  /// Both have answered → answers are revealed to each other.
  bool get isRevealed => hasMyReply && hasPartnerReply;
}

/// Loads today's prompt and both replies.
/// Returns null if the couple is not active yet.
final todayPromptStateProvider =
    FutureProvider.autoDispose<TodayPromptState?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final couple = await ref.watch(currentCoupleProvider.future);

  if (user == null || couple == null || !couple.isActive) return null;

  final today = AppDateUtils.todayIso();
  final repo = ref.read(promptRepositoryProvider);

  final promptResult = await ref
      .read(getTodayPromptProvider)
      .call(coupleId: couple.id, date: today);

  return promptResult.fold(
    (_) => null,
    (prompt) async {
      // No prompt set for today — card is hidden
      if (prompt == null) return null;

      final repliesResult = await repo.getReplies(promptId: prompt.id);

      return repliesResult.fold(
        (_) => TodayPromptState(
          prompt: prompt,
          myReply: null,
          partnerReply: null,
        ),
        (replies) {
          final myReply =
              replies.where((r) => r.userId == user.id).firstOrNull;
          final partnerReply =
              replies.where((r) => r.userId != user.id).firstOrNull;
          return TodayPromptState(
            prompt: prompt,
            myReply: myReply,
            partnerReply: partnerReply,
          );
        },
      );
    },
  );
});

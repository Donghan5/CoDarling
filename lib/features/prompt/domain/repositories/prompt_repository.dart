import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/prompt_entity.dart';

abstract class PromptRepository {
  /// Fetch today's prompt for the couple. Returns null if none has been set.
  Future<Either<Failure, PromptEntity?>> getTodayPrompt({
    required String coupleId,
    required String date,
  });

  /// Submit the current user's reply for a prompt.
  Future<Either<Failure, PromptReplyEntity>> submitReply({
    required String promptId,
    required String userId,
    required String replyText,
  });

  /// Fetch both replies for a prompt. Returns up to 2 entries.
  Future<Either<Failure, List<PromptReplyEntity>>> getReplies({
    required String promptId,
  });
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/prompt_entity.dart';
import '../repositories/prompt_repository.dart';

class SubmitReply {
  const SubmitReply(this._repository);

  final PromptRepository _repository;

  Future<Either<Failure, PromptReplyEntity>> call({
    required String promptId,
    required String userId,
    required String replyText,
  }) =>
      _repository.submitReply(
        promptId: promptId,
        userId: userId,
        replyText: replyText,
      );
}

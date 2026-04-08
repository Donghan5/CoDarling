import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/reaction_repository.dart';

class RemoveReaction {
  const RemoveReaction(this._repo);

  final ReactionRepository _repo;

  Future<Either<Failure, Unit>> call({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  }) =>
      _repo.removeReaction(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        emoji: emoji,
      );
}

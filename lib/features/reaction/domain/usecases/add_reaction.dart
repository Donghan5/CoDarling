import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reaction_entity.dart';
import '../repositories/reaction_repository.dart';

class AddReaction {
  const AddReaction(this._repo);

  final ReactionRepository _repo;

  Future<Either<Failure, ReactionEntity>> call({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  }) =>
      _repo.addReaction(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        emoji: emoji,
      );
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reaction_entity.dart';

abstract class ReactionRepository {
  Future<Either<Failure, List<ReactionEntity>>> getReactions({
    required String targetType,
    required String targetId,
  });

  Future<Either<Failure, ReactionEntity>> addReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  });

  Future<Either<Failure, Unit>> removeReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  });

  Stream<List<ReactionEntity>> watchReactions({
    required String targetType,
    required String targetId,
  });
}

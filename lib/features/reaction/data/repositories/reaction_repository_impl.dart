import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/reaction_entity.dart';
import '../../domain/repositories/reaction_repository.dart';
import '../datasources/reaction_remote_datasource.dart';

class ReactionRepositoryImpl implements ReactionRepository {
  const ReactionRepositoryImpl(this._dataSource);

  final ReactionRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, List<ReactionEntity>>> getReactions({
    required String targetType,
    required String targetId,
  }) async {
    try {
      return Right(await _dataSource.getReactions(
        targetType: targetType,
        targetId: targetId,
      ));
    } catch (e) {
      debugPrint('[ReactionRepo] getReactions error: $e');
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ReactionEntity>> addReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  }) async {
    try {
      return Right(await _dataSource.addReaction(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        emoji: emoji,
      ));
    } catch (e) {
      debugPrint('[ReactionRepo] addReaction error: $e');
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeReaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String emoji,
  }) async {
    try {
      await _dataSource.removeReaction(
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        emoji: emoji,
      );
      return const Right(unit);
    } catch (e) {
      debugPrint('[ReactionRepo] removeReaction error: $e');
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Stream<List<ReactionEntity>> watchReactions({
    required String targetType,
    required String targetId,
  }) =>
      _dataSource.watchReactions(
        targetType: targetType,
        targetId: targetId,
      );

  static String _toUserMessage(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') return 'You already reacted with that emoji.';
      return 'A server error occurred. Please try again.';
    }
    if (e is Exception) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('Exception') && !msg.contains('Error:')) return msg;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

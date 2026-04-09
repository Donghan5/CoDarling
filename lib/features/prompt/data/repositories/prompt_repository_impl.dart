import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/prompt_entity.dart';
import '../../domain/repositories/prompt_repository.dart';
import '../datasources/prompt_remote_datasource.dart';

class PromptRepositoryImpl implements PromptRepository {
  const PromptRepositoryImpl(this._dataSource);

  final PromptRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, PromptEntity?>> getTodayPrompt({
    required String coupleId,
    required String date,
  }) async {
    try {
      return Right(await _dataSource.getTodayPrompt(
        coupleId: coupleId,
        date: date,
      ));
    } catch (e) {
      debugPrint('[PromptRepo] getTodayPrompt error: $e');
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, PromptReplyEntity>> submitReply({
    required String promptId,
    required String userId,
    required String replyText,
  }) async {
    try {
      return Right(await _dataSource.submitReply(
        promptId: promptId,
        userId: userId,
        replyText: replyText,
      ));
    } catch (e) {
      debugPrint('[PromptRepo] submitReply error: $e');
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<PromptReplyEntity>>> getReplies({
    required String promptId,
  }) async {
    try {
      return Right(await _dataSource.getReplies(promptId: promptId));
    } catch (e) {
      debugPrint('[PromptRepo] getReplies error: $e');
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  static String _toUserMessage(Object e) {
    if (e is PostgrestException) return 'A server error occurred. Please try again.';
    if (e is Exception) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('Exception') && !msg.contains('Error:')) return msg;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

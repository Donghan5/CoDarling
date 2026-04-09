import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/couple_entity.dart';
import '../../domain/repositories/couple_repository.dart';
import '../datasources/couple_remote_datasource.dart';

class CoupleRepositoryImpl implements CoupleRepository {
  const CoupleRepositoryImpl(this._dataSource);

  final CoupleRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, CoupleEntity>> createCouple(String userId) async {
    try {
      return Right(await _dataSource.createCouple(userId));
    } catch (e) {
      debugPrint('[CoupleRepo] createCouple error: $e');
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, CoupleEntity>> joinCouple(
      String inviteCode, String userId) async {
    try {
      return Right(await _dataSource.joinCouple(inviteCode, userId));
    } catch (e) {
      debugPrint('[CoupleRepo] joinCouple error: $e');
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, CoupleEntity?>> getCoupleForUser(
      String userId) async {
    try {
      return Right(await _dataSource.getCoupleForUser(userId));
    } catch (e) {
      debugPrint('[CoupleRepo] getCoupleForUser error: $e');
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

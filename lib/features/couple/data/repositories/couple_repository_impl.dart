import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/metrics_service.dart';
import '../../domain/entities/couple_entity.dart';
import '../../domain/repositories/couple_repository.dart';
import '../datasources/couple_remote_datasource.dart';

class CoupleRepositoryImpl implements CoupleRepository {
  const CoupleRepositoryImpl(this._dataSource, this._metrics);

  final CoupleRemoteDataSource _dataSource;
  final MetricsService _metrics;

  @override
  Future<Either<Failure, CoupleEntity>> createCouple(String userId) async {
    try {
      return Right(await _metrics.measure(
        table: 'couples',
        operation: 'insert',
        action: () => _dataSource.createCouple(userId),
      ));
    } catch (e) {
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, CoupleEntity>> joinCouple(
      String inviteCode, String userId) async {
    try {
      return Right(await _metrics.measure(
        table: 'couples',
        operation: 'update',
        action: () => _dataSource.joinCouple(inviteCode, userId),
      ));
    } catch (e) {
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, CoupleEntity?>> getCoupleForUser(
      String userId) async {
    try {
      return Right(await _metrics.measure(
        table: 'couples',
        operation: 'select',
        action: () => _dataSource.getCoupleForUser(userId),
      ));
    } catch (e) {
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

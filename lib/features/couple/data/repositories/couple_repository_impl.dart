import 'package:dartz/dartz.dart';
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
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CoupleEntity>> joinCouple(
      String inviteCode, String userId) async {
    try {
      return Right(await _dataSource.joinCouple(inviteCode, userId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CoupleEntity?>> getCoupleForUser(
      String userId) async {
    try {
      return Right(await _dataSource.getCoupleForUser(userId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

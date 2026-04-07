import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/couple_entity.dart';

abstract class CoupleRepository {
  Future<Either<Failure, CoupleEntity>> createCouple(String userId);
  Future<Either<Failure, CoupleEntity>> joinCouple(
      String inviteCode, String userId);
  Future<Either<Failure, CoupleEntity?>> getCoupleForUser(String userId);
}

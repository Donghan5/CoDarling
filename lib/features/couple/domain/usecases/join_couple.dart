import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/couple_entity.dart';
import '../repositories/couple_repository.dart';

class JoinCouple {
  const JoinCouple(this._repository);

  final CoupleRepository _repository;

  Future<Either<Failure, CoupleEntity>> call(
          String inviteCode, String userId) =>
      _repository.joinCouple(inviteCode, userId);
}

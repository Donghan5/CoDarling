import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/couple_entity.dart';
import '../repositories/couple_repository.dart';

class CreateCouple {
  const CreateCouple(this._repository);

  final CoupleRepository _repository;

  Future<Either<Failure, CoupleEntity>> call(String userId) =>
      _repository.createCouple(userId);
}

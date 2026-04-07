import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo_entity.dart';
import '../repositories/photo_repository.dart';

class GetTodayPhotos {
  const GetTodayPhotos(this._repository);

  final PhotoRepository _repository;

  Future<Either<Failure, List<PhotoEntity>>> call({
    required String coupleId,
    required String date,
  }) =>
      _repository.getTodayPhotos(coupleId: coupleId, date: date);
}

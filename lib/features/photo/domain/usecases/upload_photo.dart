import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo_entity.dart';
import '../repositories/photo_repository.dart';

class UploadPhoto {
  const UploadPhoto(this._repository);

  final PhotoRepository _repository;

  Future<Either<Failure, PhotoEntity>> call({
    required File file,
    required String coupleId,
    required String userId,
    String? caption,
  }) =>
      _repository.uploadPhoto(
        file: file,
        coupleId: coupleId,
        userId: userId,
        caption: caption,
      );
}

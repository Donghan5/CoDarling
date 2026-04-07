import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo_entity.dart';

abstract class PhotoRepository {
  /// Upload photo and save to DB. Returns the saved entity.
  Future<Either<Failure, PhotoEntity>> uploadPhoto({
    required File file,
    required String coupleId,
    required String userId,
    String? caption,
  });

  /// Fetch today's photos for the couple (max 2: one per user).
  Future<Either<Failure, List<PhotoEntity>>> getTodayPhotos({
    required String coupleId,
    required String date,
  });

  /// Fetch all photos for the shared album.
  Future<Either<Failure, List<PhotoEntity>>> getAlbumPhotos({
    required String coupleId,
  });

  /// Whether the current user has posted today.
  Future<Either<Failure, bool>> hasPostedToday({
    required String coupleId,
    required String userId,
    required String date,
  });
}

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/repositories/photo_repository.dart';
import '../datasources/photo_remote_datasource.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  const PhotoRepositoryImpl(this._dataSource);

  final PhotoRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, PhotoEntity>> uploadPhoto({
    required File file,
    required String coupleId,
    required String userId,
    String? caption,
  }) async {
    try {
      return Right(await _dataSource.uploadPhoto(
          file: file, coupleId: coupleId, userId: userId, caption: caption));
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PhotoEntity>>> getTodayPhotos({
    required String coupleId,
    required String date,
  }) async {
    try {
      return Right(
          await _dataSource.getTodayPhotos(coupleId: coupleId, date: date));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PhotoEntity>>> getAlbumPhotos({
    required String coupleId,
  }) async {
    try {
      return Right(await _dataSource.getAlbumPhotos(coupleId: coupleId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasPostedToday({
    required String coupleId,
    required String userId,
    required String date,
  }) async {
    try {
      return Right(await _dataSource.hasPostedToday(
          coupleId: coupleId, userId: userId, date: date));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

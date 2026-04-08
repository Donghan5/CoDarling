import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/metrics_service.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/repositories/photo_repository.dart';
import '../datasources/photo_remote_datasource.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  const PhotoRepositoryImpl(this._dataSource, this._metrics);

  final PhotoRemoteDataSource _dataSource;
  final MetricsService _metrics;

  @override
  Future<Either<Failure, PhotoEntity>> uploadPhoto({
    required File file,
    required String coupleId,
    required String userId,
    String? caption,
  }) async {
    try {
      return Right(await _metrics.measure(
        table: 'photos',
        operation: 'upload',
        action: () => _dataSource.uploadPhoto(
            file: file, coupleId: coupleId, userId: userId, caption: caption),
      ));
    } catch (e) {
      return Left(StorageFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<PhotoEntity>>> getTodayPhotos({
    required String coupleId,
    required String date,
  }) async {
    try {
      return Right(await _metrics.measure(
        table: 'photos',
        operation: 'select',
        action: () => _dataSource.getTodayPhotos(coupleId: coupleId, date: date),
      ));
    } catch (e) {
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<PhotoEntity>>> getAlbumPhotos({
    required String coupleId,
  }) async {
    try {
      return Right(await _metrics.measure(
        table: 'photos',
        operation: 'select_album',
        action: () => _dataSource.getAlbumPhotos(coupleId: coupleId),
      ));
    } catch (e) {
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> hasPostedToday({
    required String coupleId,
    required String userId,
    required String date,
  }) async {
    try {
      return Right(await _metrics.measure(
        table: 'photos',
        operation: 'check_posted',
        action: () => _dataSource.hasPostedToday(
            coupleId: coupleId, userId: userId, date: date),
      ));
    } catch (e) {
      return Left(ServerFailure(_toUserMessage(e)));
    }
  }

  static String _toUserMessage(Object e) {
    if (e is StorageException) return 'File upload failed. Please try again.';
    if (e is PostgrestException) return 'A server error occurred. Please try again.';
    if (e is Exception) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('Exception') && !msg.contains('Error:')) return msg;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

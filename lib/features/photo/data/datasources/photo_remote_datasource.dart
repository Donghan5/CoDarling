import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../models/photo_model.dart';

abstract class PhotoRemoteDataSource {
  Future<PhotoModel> uploadPhoto({
    required File file,
    required String coupleId,
    required String userId,
    String? caption,
  });

  Future<List<PhotoModel>> getTodayPhotos({
    required String coupleId,
    required String date,
  });

  Future<List<PhotoModel>> getAlbumPhotos({required String coupleId});

  Future<bool> hasPostedToday({
    required String coupleId,
    required String userId,
    required String date,
  });
}

class SupabasePhotoDataSource implements PhotoRemoteDataSource {
  SupabasePhotoDataSource(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  @override
  Future<PhotoModel> uploadPhoto({
    required File file,
    required String coupleId,
    required String userId,
    String? caption,
  }) async {
    final ext = file.path.split('.').last;
    final path = '$coupleId/$userId/${_uuid.v4()}.$ext';

    await _client.storage
        .from(AppConstants.photosBucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: false));

    final imageUrl = _client.storage
        .from(AppConstants.photosBucket)
        .getPublicUrl(path);

    final today = AppDateUtils.todayIso();
    final result = await _client
        .from(AppConstants.photosTable)
        .insert({
          'couple_id': coupleId,
          'user_id': userId,
          'image_url': imageUrl,
          'caption': caption,
          'date': today,
        })
        .select()
        .single();

    return PhotoModel.fromJson(result );
  }

  @override
  Future<List<PhotoModel>> getTodayPhotos({
    required String coupleId,
    required String date,
  }) async {
    final rows = await _client
        .from(AppConstants.photosTable)
        .select()
        .eq('couple_id', coupleId)
        .eq('date', date);
    return (rows as List)
        .map((r) => PhotoModel.fromJson(r ))
        .toList();
  }

  @override
  Future<List<PhotoModel>> getAlbumPhotos({required String coupleId}) async {
    final rows = await _client
        .from(AppConstants.photosTable)
        .select()
        .eq('couple_id', coupleId)
        .order('date', ascending: false);
    return (rows as List)
        .map((r) => PhotoModel.fromJson(r ))
        .toList();
  }

  @override
  Future<bool> hasPostedToday({
    required String coupleId,
    required String userId,
    required String date,
  }) async {
    final rows = await _client
        .from(AppConstants.photosTable)
        .select('id')
        .eq('couple_id', coupleId)
        .eq('user_id', userId)
        .eq('date', date)
        .limit(1);
    return (rows as List).isNotEmpty;
  }
}

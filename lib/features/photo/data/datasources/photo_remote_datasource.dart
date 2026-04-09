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

  // Signed URL validity: 7 days (seconds)
  static const _signedUrlExpiry = 60 * 60 * 24 * 7;

  @override
  Future<PhotoModel> uploadPhoto({
    required File file,
    required String coupleId,
    required String userId,
    String? caption,
  }) async {
    if (_client.auth.currentUser?.id != userId) {
      throw Exception('uploadPhoto: userId must match the authenticated user');
    }

    final ext = file.path.split('.').last.toLowerCase();
    if (!AppConstants.allowedPhotoExtensions.contains(ext)) {
      throw Exception(
          'Unsupported file type. Please use JPG, PNG, WEBP, or HEIC.');
    }
    final fileSize = await file.length();
    if (fileSize > AppConstants.maxPhotoSizeBytes) {
      throw Exception('Photo exceeds the 10 MB size limit.');
    }

    final storagePath = '$coupleId/$userId/${_uuid.v4()}.$ext';

    await _client.storage
        .from(AppConstants.photosBucket)
        .upload(storagePath, file, fileOptions: const FileOptions(upsert: false));

    final today = AppDateUtils.todayIso();
    final result = await _client
        .from(AppConstants.photosTable)
        .insert({
          'couple_id': coupleId,
          'user_id': userId,
          'image_url': storagePath, // store path; signed URLs generated on fetch
          'caption': caption,
          'date': today,
        })
        .select()
        .single();

    final signedUrl = await _client.storage
        .from(AppConstants.photosBucket)
        .createSignedUrl(storagePath, _signedUrlExpiry);

    return PhotoModel.fromJson({...result, 'image_url': signedUrl});
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
    return _withSignedUrls(rows);
  }

  @override
  Future<List<PhotoModel>> getAlbumPhotos({required String coupleId}) async {
    final rows = await _client
        .from(AppConstants.photosTable)
        .select()
        .eq('couple_id', coupleId)
        .order('date', ascending: false);
    return _withSignedUrls(rows);
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

  Future<List<PhotoModel>> _withSignedUrls(List<dynamic> rows) async {
    if (rows.isEmpty) return [];
    final data = rows.cast<Map<String, dynamic>>();
    final paths = data.map((r) => r['image_url'] as String).toList();

    final signedUrls = await _client.storage
        .from(AppConstants.photosBucket)
        .createSignedUrls(paths, _signedUrlExpiry);

    return data.asMap().entries.map((entry) {
      final row = Map<String, dynamic>.from(entry.value);
      row['image_url'] = signedUrls[entry.key].signedUrl;
      return PhotoModel.fromJson(row);
    }).toList();
  }
}

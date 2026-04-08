import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/metrics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../couple/presentation/providers/couple_provider.dart';
import '../../data/datasources/photo_remote_datasource.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/usecases/get_today_photos.dart';
import '../../domain/usecases/upload_photo.dart';
import '../../../../core/utils/date_utils.dart';

final photoDataSourceProvider = Provider<PhotoRemoteDataSource>(
  (ref) => SupabasePhotoDataSource(ref.watch(supabaseClientProvider)),
);

final photoRepositoryProvider = Provider(
  (ref) => PhotoRepositoryImpl(
    ref.watch(photoDataSourceProvider),
    ref.watch(metricsServiceProvider),
  ),
);

final uploadPhotoProvider = Provider(
  (ref) => UploadPhoto(ref.watch(photoRepositoryProvider)),
);

final getTodayPhotosProvider = Provider(
  (ref) => GetTodayPhotos(ref.watch(photoRepositoryProvider)),
);

final todayPhotosProvider =
    FutureProvider.autoDispose<List<PhotoEntity>>((ref) async {
  final couple = await ref.watch(currentCoupleProvider.future);
  if (couple == null) return [];
  final today = AppDateUtils.todayIso();
  final result = await ref
      .read(getTodayPhotosProvider)
      .call(coupleId: couple.id, date: today);
  return result.fold((_) => [], (photos) => photos);
});

final hasPostedTodayProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final couple = await ref.watch(currentCoupleProvider.future);
  if (user == null || couple == null) return false;
  final today = AppDateUtils.todayIso();
  final result = await ref.read(photoRepositoryProvider).hasPostedToday(
      coupleId: couple.id, userId: user.id, date: today);
  return result.fold((_) => false, (v) => v);
});

final albumPhotosProvider =
    FutureProvider.autoDispose<List<PhotoEntity>>((ref) async {
  final couple = await ref.watch(currentCoupleProvider.future);
  if (couple == null) return [];
  final result = await ref
      .read(photoRepositoryProvider)
      .getAlbumPhotos(coupleId: couple.id);
  return result.fold((_) => [], (photos) => photos);
});

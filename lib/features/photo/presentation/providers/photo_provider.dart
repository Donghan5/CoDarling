import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../couple/presentation/providers/couple_provider.dart';
import '../../data/datasources/photo_remote_datasource.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/usecases/get_today_photos.dart';
import '../../domain/usecases/upload_photo.dart';
import '../../../../core/utils/date_utils.dart';

/// Currently viewed month on the calendar screen (year + month only).
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// All album photos grouped by ISO date string ('yyyy-MM-dd').
final photosByDateProvider = Provider<Map<String, List<PhotoEntity>>>((ref) {
  return ref.watch(albumPhotosProvider).maybeWhen(
    data: (photos) {
      final map = <String, List<PhotoEntity>>{};
      for (final p in photos) {
        final key = AppDateUtils.toIsoDate(p.date);
        (map[key] ??= []).add(p);
      }
      return map;
    },
    orElse: () => const {},
  );
});

final photoDataSourceProvider = Provider<PhotoRemoteDataSource>(
  (ref) => SupabasePhotoDataSource(ref.watch(supabaseClientProvider)),
);

final photoRepositoryProvider = Provider(
  (ref) => PhotoRepositoryImpl(ref.watch(photoDataSourceProvider)),
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

/// Derived from [todayPhotosProvider] — no extra network call needed.
final hasPostedTodayProvider = Provider.autoDispose<AsyncValue<bool>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return ref.watch(todayPhotosProvider).whenData(
    (photos) => photos.any((p) => p.userId == user?.id),
  );
});

/// Album photos kept alive across navigations so signed URLs are reused.
final albumPhotosProvider =
    FutureProvider<List<PhotoEntity>>((ref) async {
  final couple = await ref.watch(currentCoupleProvider.future);
  if (couple == null) return [];
  final result = await ref
      .read(photoRepositoryProvider)
      .getAlbumPhotos(coupleId: couple.id);
  return result.fold((_) => [], (photos) => photos);
});

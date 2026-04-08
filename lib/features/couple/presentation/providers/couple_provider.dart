import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/metrics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/couple_remote_datasource.dart';
import '../../data/repositories/couple_repository_impl.dart';
import '../../domain/entities/couple_entity.dart';
import '../../domain/usecases/create_couple.dart';
import '../../domain/usecases/join_couple.dart';

final coupleDataSourceProvider = Provider<CoupleRemoteDataSource>(
  (ref) => SupabaseCoupleDataSource(ref.watch(supabaseClientProvider)),
);

final coupleRepositoryProvider = Provider(
  (ref) => CoupleRepositoryImpl(
    ref.watch(coupleDataSourceProvider),
    ref.watch(metricsServiceProvider),
  ),
);

final createCoupleProvider = Provider(
  (ref) => CreateCouple(ref.watch(coupleRepositoryProvider)),
);

final joinCoupleProvider = Provider(
  (ref) => JoinCouple(ref.watch(coupleRepositoryProvider)),
);

final currentCoupleProvider =
    FutureProvider.autoDispose<CoupleEntity?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final result =
      await ref.read(coupleRepositoryProvider).getCoupleForUser(user.id);
  return result.fold((_) => null, (couple) => couple);
});

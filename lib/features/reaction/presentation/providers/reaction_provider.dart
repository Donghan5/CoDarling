import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/metrics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/reaction_remote_datasource.dart';
import '../../data/repositories/reaction_repository_impl.dart';
import '../../domain/entities/reaction_entity.dart';
import '../../domain/usecases/add_reaction.dart';
import '../../domain/usecases/remove_reaction.dart';

final reactionDataSourceProvider = Provider<ReactionRemoteDataSource>(
  (ref) => SupabaseReactionDataSource(ref.watch(supabaseClientProvider)),
);

final reactionRepositoryProvider = Provider(
  (ref) => ReactionRepositoryImpl(
    ref.watch(reactionDataSourceProvider),
    ref.watch(metricsServiceProvider),
  ),
);

final addReactionProvider = Provider(
  (ref) => AddReaction(ref.watch(reactionRepositoryProvider)),
);

final removeReactionProvider = Provider(
  (ref) => RemoveReaction(ref.watch(reactionRepositoryProvider)),
);

/// Realtime stream of reactions for a given [targetId].
/// [targetType] is 'photo' or 'prompt_reply'.
final reactionsStreamProvider = StreamProvider.autoDispose
    .family<List<ReactionEntity>, ({String targetType, String targetId})>(
  (ref, params) => ref.watch(reactionRepositoryProvider).watchReactions(
        targetType: params.targetType,
        targetId: params.targetId,
      ),
);

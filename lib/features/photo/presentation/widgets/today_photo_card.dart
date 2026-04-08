import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../features/reaction/presentation/widgets/reaction_bar.dart';
import '../../domain/entities/photo_entity.dart';

class TodayPhotoCard extends StatelessWidget {
  const TodayPhotoCard({
    super.key,
    required this.photo,
    required this.label,
    this.showReactions = false,
  });

  final PhotoEntity photo;
  final String label;
  /// Whether to show the reaction bar below the photo.
  final bool showReactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
          if (photo.caption != null || label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                          )),
                  if (photo.caption != null) ...[
                    const SizedBox(height: 4),
                    Text(photo.caption!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          if (showReactions)
            ReactionBar(targetType: 'photo', targetId: photo.id),
        ],
      ),
    );
  }
}

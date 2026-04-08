import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/reaction_entity.dart';
import '../providers/reaction_provider.dart';

/// Predefined emoji set users can react with.
const _kEmojiOptions = ['❤️', '😍', '😂', '😮', '😢', '👏'];

class ReactionBar extends ConsumerWidget {
  const ReactionBar({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  final String targetType;
  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionsAsync = ref.watch(
      reactionsStreamProvider((targetType: targetType, targetId: targetId)),
    );
    final user = ref.watch(authStateProvider).valueOrNull;

    return reactionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reactions) => _ReactionBarContent(
        reactions: reactions,
        currentUserId: user?.id,
        onToggle: (emoji) => _handleToggle(ref, emoji, reactions, user?.id),
        onPickEmoji: () => _showEmojiPicker(context, ref, reactions, user?.id),
      ),
    );
  }

  Future<void> _handleToggle(
    WidgetRef ref,
    String emoji,
    List<ReactionEntity> reactions,
    String? userId,
  ) async {
    if (userId == null) return;
    final alreadyReacted = reactions.any(
      (r) => r.userId == userId && r.emoji == emoji,
    );
    if (alreadyReacted) {
      await ref.read(removeReactionProvider).call(
            userId: userId,
            targetType: targetType,
            targetId: targetId,
            emoji: emoji,
          );
    } else {
      await ref.read(addReactionProvider).call(
            userId: userId,
            targetType: targetType,
            targetId: targetId,
            emoji: emoji,
          );
    }
  }

  void _showEmojiPicker(
    BuildContext context,
    WidgetRef ref,
    List<ReactionEntity> reactions,
    String? userId,
  ) {
    if (userId == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmojiPickerSheet(
        reactions: reactions,
        currentUserId: userId,
        onEmojiTap: (emoji) {
          Navigator.of(context).pop();
          _handleToggle(ref, emoji, reactions, userId);
        },
      ),
    );
  }
}

class _ReactionBarContent extends StatelessWidget {
  const _ReactionBarContent({
    required this.reactions,
    required this.currentUserId,
    required this.onToggle,
    required this.onPickEmoji,
  });

  final List<ReactionEntity> reactions;
  final String? currentUserId;
  final void Function(String emoji) onToggle;
  final VoidCallback onPickEmoji;

  @override
  Widget build(BuildContext context) {
    // Group reactions by emoji
    final grouped = <String, List<ReactionEntity>>{};
    for (final r in reactions) {
      grouped.putIfAbsent(r.emoji, () => []).add(r);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: grouped.entries.map((entry) {
                final emoji = entry.key;
                final count = entry.value.length;
                final iMine = entry.value.any((r) => r.userId == currentUserId);
                return _EmojiChip(
                  emoji: emoji,
                  count: count,
                  isMine: iMine,
                  onTap: () => onToggle(emoji),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onPickEmoji,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('＋', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({
    required this.emoji,
    required this.count,
    required this.isMine,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isMine ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMine ? cs.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isMine ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({
    required this.reactions,
    required this.currentUserId,
    required this.onEmojiTap,
  });

  final List<ReactionEntity> reactions;
  final String currentUserId;
  final void Function(String emoji) onEmojiTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final myEmojis = reactions
        .where((r) => r.userId == currentUserId)
        .map((r) => r.emoji)
        .toSet();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'React with an emoji',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _kEmojiOptions.map((emoji) {
                final selected = myEmojis.contains(emoji);
                return GestureDetector(
                  onTap: () => onEmojiTap(emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? cs.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

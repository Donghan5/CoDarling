class ReactionEntity {
  const ReactionEntity({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.emoji,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String targetType; // 'photo' | 'prompt_reply'
  final String targetId;
  final String emoji;
  final DateTime createdAt;

  ReactionEntity copyWith({
    String? id,
    String? userId,
    String? targetType,
    String? targetId,
    String? emoji,
    DateTime? createdAt,
  }) =>
      ReactionEntity(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        targetType: targetType ?? this.targetType,
        targetId: targetId ?? this.targetId,
        emoji: emoji ?? this.emoji,
        createdAt: createdAt ?? this.createdAt,
      );
}

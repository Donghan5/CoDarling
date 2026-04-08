import '../../domain/entities/reaction_entity.dart';

class ReactionModel extends ReactionEntity {
  const ReactionModel({
    required super.id,
    required super.userId,
    required super.targetType,
    required super.targetId,
    required super.emoji,
    required super.createdAt,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) => ReactionModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        targetType: json['target_type'] as String,
        targetId: json['target_id'] as String,
        emoji: json['emoji'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'target_type': targetType,
        'target_id': targetId,
        'emoji': emoji,
        'created_at': createdAt.toIso8601String(),
      };
}

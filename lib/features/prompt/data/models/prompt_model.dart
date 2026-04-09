import '../../domain/entities/prompt_entity.dart';

class PromptModel extends PromptEntity {
  const PromptModel({
    required super.id,
    required super.coupleId,
    required super.questionText,
    required super.date,
    required super.createdAt,
  });

  factory PromptModel.fromJson(Map<String, dynamic> json) => PromptModel(
        id: json['id'] as String,
        coupleId: json['couple_id'] as String,
        questionText: json['question_text'] as String,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'couple_id': coupleId,
        'question_text': questionText,
        'date': '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        'created_at': createdAt.toIso8601String(),
      };
}

class PromptReplyModel extends PromptReplyEntity {
  const PromptReplyModel({
    required super.id,
    required super.promptId,
    required super.userId,
    required super.replyText,
    required super.createdAt,
  });

  factory PromptReplyModel.fromJson(Map<String, dynamic> json) =>
      PromptReplyModel(
        id: json['id'] as String,
        promptId: json['prompt_id'] as String,
        userId: json['user_id'] as String,
        replyText: json['reply_text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt_id': promptId,
        'user_id': userId,
        'reply_text': replyText,
        'created_at': createdAt.toIso8601String(),
      };
}

class PromptEntity {
  const PromptEntity({
    required this.id,
    required this.coupleId,
    required this.questionText,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String questionText;
  final DateTime date;
  final DateTime createdAt;

  PromptEntity copyWith({
    String? id,
    String? coupleId,
    String? questionText,
    DateTime? date,
    DateTime? createdAt,
  }) =>
      PromptEntity(
        id: id ?? this.id,
        coupleId: coupleId ?? this.coupleId,
        questionText: questionText ?? this.questionText,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
      );
}

class PromptReplyEntity {
  const PromptReplyEntity({
    required this.id,
    required this.promptId,
    required this.userId,
    required this.replyText,
    required this.createdAt,
  });

  final String id;
  final String promptId;
  final String userId;
  final String replyText;
  final DateTime createdAt;
}

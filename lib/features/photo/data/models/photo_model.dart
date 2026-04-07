import '../../domain/entities/photo_entity.dart';

class PhotoModel extends PhotoEntity {
  const PhotoModel({
    required super.id,
    required super.coupleId,
    required super.userId,
    required super.imageUrl,
    super.caption,
    required super.date,
    required super.createdAt,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) => PhotoModel(
        id: json['id'] as String,
        coupleId: json['couple_id'] as String,
        userId: json['user_id'] as String,
        imageUrl: json['image_url'] as String,
        caption: json['caption'] as String?,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'couple_id': coupleId,
        'user_id': userId,
        'image_url': imageUrl,
        'caption': caption,
        'date': date.toIso8601String().split('T').first,
        'created_at': createdAt.toIso8601String(),
      };
}

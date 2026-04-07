class PhotoEntity {
  const PhotoEntity({
    required this.id,
    required this.coupleId,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime date;
  final DateTime createdAt;

  PhotoEntity copyWith({
    String? id,
    String? coupleId,
    String? userId,
    String? imageUrl,
    String? caption,
    DateTime? date,
    DateTime? createdAt,
  }) =>
      PhotoEntity(
        id: id ?? this.id,
        coupleId: coupleId ?? this.coupleId,
        userId: userId ?? this.userId,
        imageUrl: imageUrl ?? this.imageUrl,
        caption: caption ?? this.caption,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
      );
}

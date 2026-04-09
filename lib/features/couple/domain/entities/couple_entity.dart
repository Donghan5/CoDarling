enum CoupleStatus {
  pending,
  active;

  static CoupleStatus fromJson(String value) => switch (value) {
        'active' => CoupleStatus.active,
        _ => CoupleStatus.pending,
      };

  String toJson() => name; // 'pending' | 'active'
}

class CoupleEntity {
  const CoupleEntity({
    required this.id,
    required this.userId1,
    this.userId2,
    required this.inviteCode,
    required this.status,
    this.anniversary,
    this.coupleName,
    required this.createdAt,
  });

  final String id;
  final String userId1;
  final String? userId2;
  final String inviteCode;
  final CoupleStatus status;
  final DateTime? anniversary;
  final String? coupleName;
  final DateTime createdAt;

  bool get isActive => status == CoupleStatus.active;

  CoupleEntity copyWith({
    String? id,
    String? userId1,
    String? userId2,
    String? inviteCode,
    CoupleStatus? status,
    DateTime? anniversary,
    String? coupleName,
    DateTime? createdAt,
  }) =>
      CoupleEntity(
        id: id ?? this.id,
        userId1: userId1 ?? this.userId1,
        userId2: userId2 ?? this.userId2,
        inviteCode: inviteCode ?? this.inviteCode,
        status: status ?? this.status,
        anniversary: anniversary ?? this.anniversary,
        coupleName: coupleName ?? this.coupleName,
        createdAt: createdAt ?? this.createdAt,
      );
}

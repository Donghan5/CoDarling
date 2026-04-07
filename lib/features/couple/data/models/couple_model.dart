import '../../domain/entities/couple_entity.dart';

class CoupleModel extends CoupleEntity {
  const CoupleModel({
    required super.id,
    required super.userId1,
    super.userId2,
    required super.inviteCode,
    required super.status,
    super.anniversary,
    super.coupleName,
    required super.createdAt,
  });

  factory CoupleModel.fromJson(Map<String, dynamic> json) => CoupleModel(
        id: json['id'] as String,
        userId1: json['user_id_1'] as String,
        userId2: json['user_id_2'] as String?,
        inviteCode: json['invite_code'] as String,
        status: json['status'] as String,
        anniversary: json['anniversary'] != null
            ? DateTime.parse(json['anniversary'] as String)
            : null,
        coupleName: json['couple_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id_1': userId1,
        'user_id_2': userId2,
        'invite_code': inviteCode,
        'status': status,
        'anniversary': anniversary?.toIso8601String(),
        'couple_name': coupleName,
        'created_at': createdAt.toIso8601String(),
      };
}

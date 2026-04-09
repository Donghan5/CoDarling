import 'package:codarling/features/auth/domain/entities/user_entity.dart';
import 'package:codarling/features/couple/domain/entities/couple_entity.dart';
import 'package:codarling/features/photo/domain/entities/photo_entity.dart';
import 'package:codarling/features/prompt/domain/entities/prompt_entity.dart';

/// Shared test data — reused across widget and integration tests.

UserEntity get testUser => UserEntity(
      id: 'user-alice',
      email: 'alice@test.codarling',
      displayName: 'Alice',
      createdAt: DateTime(2026, 1, 1),
    );

UserEntity get testPartner => UserEntity(
      id: 'user-bob',
      email: 'bob@test.codarling',
      displayName: 'Bob',
      createdAt: DateTime(2026, 1, 1),
    );

CoupleEntity get testCoupleActive => CoupleEntity(
      id: 'couple-1',
      userId1: 'user-alice',
      userId2: 'user-bob',
      inviteCode: 'LOVE-AB1234',
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
    );

CoupleEntity get testCouplePending => CoupleEntity(
      id: 'couple-2',
      userId1: 'user-alice',
      inviteCode: 'LOVE-XY9999',
      status: 'pending',
      createdAt: DateTime(2026, 1, 1),
    );

PhotoEntity get testMyPhoto => PhotoEntity(
      id: 'photo-alice',
      coupleId: 'couple-1',
      userId: 'user-alice',
      imageUrl: 'photos/couple-1/2026-04-09/photo-alice.jpg',
      date: DateTime(2026, 4, 9),
      createdAt: DateTime(2026, 4, 9),
    );

PhotoEntity get testPartnerPhoto => PhotoEntity(
      id: 'photo-bob',
      coupleId: 'couple-1',
      userId: 'user-bob',
      imageUrl: 'photos/couple-1/2026-04-09/photo-bob.jpg',
      date: DateTime(2026, 4, 9),
      createdAt: DateTime(2026, 4, 9),
    );

PromptEntity get testPrompt => PromptEntity(
      id: 'prompt-1',
      coupleId: 'couple-1',
      questionText: '오늘 가장 기억에 남는 순간은 뭐야?',
      date: DateTime(2026, 4, 9),
      createdAt: DateTime(2026, 4, 9),
    );

PromptReplyEntity get testMyReply => PromptReplyEntity(
      id: 'reply-alice',
      promptId: 'prompt-1',
      userId: 'user-alice',
      replyText: '오늘 같이 커피 마신 순간!',
      createdAt: DateTime(2026, 4, 9),
    );

PromptReplyEntity get testPartnerReply => PromptReplyEntity(
      id: 'reply-bob',
      promptId: 'prompt-1',
      userId: 'user-bob',
      replyText: '네가 웃던 순간 ❤️',
      createdAt: DateTime(2026, 4, 9),
    );

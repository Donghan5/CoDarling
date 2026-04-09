import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codarling/features/auth/presentation/providers/auth_provider.dart';
import 'package:codarling/features/couple/presentation/providers/couple_provider.dart';
import 'package:codarling/features/photo/presentation/providers/photo_provider.dart';
import 'package:codarling/features/photo/presentation/screens/home_screen.dart';
import 'package:codarling/features/prompt/presentation/providers/prompt_provider.dart';

import '../../fixtures/test_fixtures.dart';

void main() {
  /// Wrap HomeScreen with all required provider overrides.
  Widget buildSubject({
    required List<Override> overrides,
  }) =>
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: HomeScreen()),
      );

  group('HomeScreen — no couple', () {
    testWidgets('shows set-up button when user has no couple', (tester) async {
      await tester.pumpWidget(buildSubject(overrides: [
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        currentCoupleProvider.overrideWith((_) async => null),
        hasPostedTodayProvider.overrideWith((_) => const AsyncValue.data(false)),
        todayPhotosProvider.overrideWith((_) async => []),
        todayPromptStateProvider.overrideWith((_) async => null),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Set up your couple'), findsOneWidget);
    });
  });

  group('HomeScreen — pending couple', () {
    testWidgets('shows invite code while waiting for partner', (tester) async {
      await tester.pumpWidget(buildSubject(overrides: [
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        currentCoupleProvider
            .overrideWith((_) async => testCouplePending),
        hasPostedTodayProvider.overrideWith((_) => const AsyncValue.data(false)),
        todayPhotosProvider.overrideWith((_) async => []),
        todayPromptStateProvider.overrideWith((_) async => null),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for your partner...'), findsOneWidget);
      expect(find.text(testCouplePending.inviteCode), findsOneWidget);
    });
  });

  group('HomeScreen — active couple', () {
    testWidgets('shows lock screen when user has not posted today',
        (tester) async {
      await tester.pumpWidget(buildSubject(overrides: [
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        currentCoupleProvider
            .overrideWith((_) async => testCoupleActive),
        hasPostedTodayProvider.overrideWith((_) => const AsyncValue.data(false)),
        todayPhotosProvider.overrideWith((_) async => []),
        todayPromptStateProvider.overrideWith((_) async => null),
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Post today\'s photo'), findsOneWidget);
    });

    // Note: photo-card rendering with CachedNetworkImage is covered by
    // integration tests (real device) to avoid HTTP mock complications.

    testWidgets('shows today prompt card when user has not posted yet',
        (tester) async {
      // Test the prompt card on the lock screen state — avoids network image
      // rendering issues caused by CachedNetworkImage in TodayPhotoCard.
      final promptState = TodayPromptState(
        prompt: testPrompt,
        myReply: null,
        partnerReply: null,
      );

      await tester.pumpWidget(buildSubject(overrides: [
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        currentCoupleProvider
            .overrideWith((_) async => testCoupleActive),
        hasPostedTodayProvider.overrideWith((_) => const AsyncValue.data(false)),
        todayPhotosProvider.overrideWith((_) async => []),
        todayPromptStateProvider.overrideWith((_) async => promptState),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 질문'), findsOneWidget);
      expect(find.text(testPrompt.questionText), findsOneWidget);
    });
  });
}

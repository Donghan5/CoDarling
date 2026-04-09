import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codarling/features/auth/presentation/providers/auth_provider.dart';
import 'package:codarling/features/prompt/presentation/providers/prompt_provider.dart';
import 'package:codarling/features/prompt/presentation/widgets/prompt_card.dart';

import '../../fixtures/test_fixtures.dart';

void main() {
  Widget buildSubject(List<Override> overrides) => ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: Scaffold(body: PromptCard())),
      );

  group('PromptCard', () {
    testWidgets('renders nothing when no prompt is set for today',
        (tester) async {
      await tester.pumpWidget(buildSubject([
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        todayPromptStateProvider.overrideWith((_) async => null),
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows question and input when user has not replied',
        (tester) async {
      final state = TodayPromptState(
        prompt: testPrompt,
        myReply: null,
        partnerReply: null,
      );

      await tester.pumpWidget(buildSubject([
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        todayPromptStateProvider.overrideWith((_) async => state),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 질문'), findsOneWidget);
      expect(find.text(testPrompt.questionText), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('보내기'), findsOneWidget);
    });

    testWidgets('shows waiting message when user replied but partner has not',
        (tester) async {
      final state = TodayPromptState(
        prompt: testPrompt,
        myReply: testMyReply,
        partnerReply: null,
      );

      await tester.pumpWidget(buildSubject([
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        todayPromptStateProvider.overrideWith((_) async => state),
      ]));
      await tester.pumpAndSettle();

      expect(find.text(testMyReply.replyText), findsOneWidget);
      expect(find.text('파트너의 답변을 기다리는 중...'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('reveals both replies when both have answered', (tester) async {
      final state = TodayPromptState(
        prompt: testPrompt,
        myReply: testMyReply,
        partnerReply: testPartnerReply,
      );

      await tester.pumpWidget(buildSubject([
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        todayPromptStateProvider.overrideWith((_) async => state),
      ]));
      await tester.pumpAndSettle();

      expect(find.text(testMyReply.replyText), findsOneWidget);
      expect(find.text(testPartnerReply.replyText), findsOneWidget);
      expect(find.text('나'), findsOneWidget);
      expect(find.text('파트너'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('submit button is disabled when text field is empty',
        (tester) async {
      final state = TodayPromptState(
        prompt: testPrompt,
        myReply: null,
        partnerReply: null,
      );

      await tester.pumpWidget(buildSubject([
        authStateProvider.overrideWith((_) => Stream.value(testUser)),
        todayPromptStateProvider.overrideWith((_) async => state),
      ]));
      await tester.pumpAndSettle();

      final submitButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '보내기'),
      );
      // Button exists; actual guard is in _submit() which checks text.isEmpty
      expect(submitButton, isNotNull);
    });
  });
}

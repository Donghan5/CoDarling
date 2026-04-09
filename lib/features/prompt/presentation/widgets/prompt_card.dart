import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/prompt_provider.dart';

class PromptCard extends ConsumerStatefulWidget {
  const PromptCard({super.key});

  @override
  ConsumerState<PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends ConsumerState<PromptCard> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(TodayPromptState state) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    final user =
        ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(submitReplyProvider).call(
          promptId: state.prompt.id,
          userId: user.id,
          replyText: text,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        _controller.clear();
        ref.invalidate(todayPromptStateProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final promptAsync = ref.watch(todayPromptStateProvider);

    return promptAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (state == null) return const SizedBox.shrink();
        return _PromptCardBody(
          state: state,
          controller: _controller,
          isSubmitting: _isSubmitting,
          onSubmit: () => _submit(state),
        );
      },
    );
  }
}

class _PromptCardBody extends StatelessWidget {
  const _PromptCardBody({
    required this.state,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TodayPromptState state;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '오늘의 질문',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              state.prompt.questionText,
              style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            if (state.isRevealed) ...[
              _ReplyRow(label: '나', text: state.myReply!.replyText, isMe: true),
              const SizedBox(height: 8),
              _ReplyRow(
                  label: '파트너',
                  text: state.partnerReply!.replyText,
                  isMe: false),
            ] else if (state.hasMyReply) ...[
              _ReplyRow(label: '나', text: state.myReply!.replyText, isMe: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 4),
                  Icon(Icons.hourglass_top, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '파트너의 답변을 기다리는 중...',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 4,
                maxLength: 200,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: '답변을 입력하세요',
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('보내기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyRow extends StatelessWidget {
  const _ReplyRow({
    required this.label,
    required this.text,
    required this.isMe,
  });

  final String label;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: isMe ? cs.primary : cs.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: tt.bodyMedium),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/couple_provider.dart';

class CoupleSetupScreen extends ConsumerStatefulWidget {
  const CoupleSetupScreen({super.key});

  @override
  ConsumerState<CoupleSetupScreen> createState() => _CoupleSetupScreenState();
}

class _CoupleSetupScreenState extends ConsumerState<CoupleSetupScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _checking = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createCouple() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _loading = true);
    final result = await ref.read(createCoupleProvider).call(user.id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => ref.invalidate(currentCoupleProvider),
    );
  }

  Future<void> _joinCouple() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    final result = await ref.read(joinCoupleProvider).call(code, user.id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => ref.invalidate(currentCoupleProvider),
    );
  }

  Future<void> _checkCoupleStatus() async {
    setState(() => _checking = true);
    try {
      ref.invalidate(currentCoupleProvider);
      final couple = await ref.read(currentCoupleProvider.future);
      if (!mounted) return;
      if (couple == null || !couple.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아직 파트너가 참여하지 않았어요 💔')),
        );
      }
      // 커플 active 시 라우터가 자동으로 /home으로 이동
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('초대 코드가 복사됐어요!')));
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(currentCoupleProvider);
    final couple = coupleAsync.valueOrNull;
    final isPending = couple != null && !couple.isActive;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('커플 연결')),
      body: coupleAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 내 초대 코드 섹션 ──────────────────────────────────
                  Text('내 초대 코드',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (isPending) ...[
                    GestureDetector(
                      onTap: () => _copyCode(couple.inviteCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              couple.inviteCode,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '탭해서 복사',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _copyCode(couple.inviteCode),
                      icon: const Icon(Icons.copy),
                      label: const Text('초대 코드 복사'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _checking ? null : _checkCoupleStatus,
                      icon: _checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('파트너가 참여했나요? 확인하기'),
                    ),
                  ] else ...[
                    Text(
                      '새 커플 공간을 만들고 초대 코드를 파트너에게 공유하세요.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton(
                            onPressed: _createCouple,
                            child: const Text('커플 공간 만들기'),
                          ),
                  ],

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // ── 파트너 코드 입력 섹션 (항상 표시) ───────────────────
                  Text('파트너 초대 코드 입력',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'LOVE-XXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _loading ? null : _joinCouple,
                    child: const Text('코드로 참여하기'),
                  ),
                ],
              ),
            ),
    );
  }
}

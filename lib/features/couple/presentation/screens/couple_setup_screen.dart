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
      // Couple is now active — invalidate so router re-evaluates and goes to /home.
      (_) => ref.invalidate(currentCoupleProvider),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('초대 코드가 복사됐어요!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(currentCoupleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('커플 연결')),
      body: coupleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildSetupUI(),
        data: (couple) {
          if (couple != null && !couple.isActive) {
            return _buildPendingUI(couple.inviteCode);
          }
          return _buildSetupUI();
        },
      ),
    );
  }

  // ── 커플 없음: 생성 또는 참여 ──────────────────────────────────────────────

  Widget _buildSetupUI() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '새 커플 공간을 만들고 초대 코드를 파트너에게 공유하세요.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: _createCouple,
                  child: const Text('커플 공간 만들기'),
                ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            '또는 파트너의 초대 코드를 입력하세요:',
            textAlign: TextAlign.center,
          ),
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
    );
  }

  // ── 커플 pending: 초대 코드 표시, 파트너 대기 ──────────────────────────────

  Widget _buildPendingUI(String inviteCode) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('💌', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text(
            '파트너를 기다리는 중...',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '아래 초대 코드를 파트너에게 공유하세요.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _copyCode(inviteCode),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    inviteCode,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '탭해서 복사',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _copyCode(inviteCode),
            icon: const Icon(Icons.copy),
            label: const Text('초대 코드 복사'),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(currentCoupleProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('파트너가 참여했나요? 확인하기'),
          ),
        ],
      ),
    );
  }
}

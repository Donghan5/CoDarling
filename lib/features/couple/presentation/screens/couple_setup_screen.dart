import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      (couple) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Your invite code'),
            content: SelectableText(
              couple.inviteCode,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: couple.inviteCode));
                  Navigator.pop(context);
                  context.go('/home');
                },
                child: const Text('Copy & continue'),
              ),
            ],
          ),
        );
      },
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
      (_) => context.go('/home'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your couple')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create a new couple space and share your invite code with your partner.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _createCouple,
                    child: const Text('Create couple space'),
                  ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Or enter your partner\'s invite code:',
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
              child: const Text('Join with code'),
            ),
          ],
        ),
      ),
    );
  }
}

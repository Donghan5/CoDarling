import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final result = await ref.read(signInWithGoogleProvider).call();
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        // Browser opened; keep spinner — router redirects when auth completes.
      },
    );
  }

  // Test password is injected at build time via --dart-define=DEV_TEST_PASSWORD=...
  // Never hardcoded in source.
  static const _devTestPassword =
      String.fromEnvironment('DEV_TEST_PASSWORD');

  Future<void> _devSignIn(String email) async {
    assert(_devTestPassword.isNotEmpty,
        'DEV_TEST_PASSWORD must be set via --dart-define for dev login');
    setState(() => _loading = true);
    try {
      final signIn = ref.read(devSignInProvider);
      await signIn(email, _devTestPassword);
      // authStateChanges fires → router redirects automatically.
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dev login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '💌',
                style: TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 24),
              Text(
                'Codarling',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Stay close, one photo at a time.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _loading
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: _signIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                    ),
              if (kDebugMode) ...[
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'DEV LOGIN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () => _devSignIn('alice@test.codarling'),
                        child: const Text('Alice'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () => _devSignIn('bob@test.codarling'),
                        child: const Text('Bob'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class LockScreenWidget extends StatelessWidget {
  const LockScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Post your photo first to see your partner\'s!',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The lock opens once you share your moment for today.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

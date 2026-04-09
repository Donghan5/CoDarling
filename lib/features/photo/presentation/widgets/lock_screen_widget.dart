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
            '내 사진을 먼저 올리면 파트너 사진이 열려요!',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '오늘의 순간을 공유하면 자물쇠가 열려요.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

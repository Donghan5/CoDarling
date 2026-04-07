import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../couple/presentation/providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/today_photo_card.dart';
import '../widgets/lock_screen_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleAsync = ref.watch(currentCoupleProvider);
    final hasPostedAsync = ref.watch(hasPostedTodayProvider);
    final todayPhotosAsync = ref.watch(todayPhotosProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => context.push('/album'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(signOutProvider).call();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: coupleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (couple) {
          if (couple == null) {
            return Center(
              child: FilledButton(
                onPressed: () => context.go('/couple-setup'),
                child: const Text('Set up your couple'),
              ),
            );
          }

          return hasPostedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (hasPosted) => todayPhotosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (photos) {
                final partnerPhoto = photos.where(
                    (p) => p.userId != user?.id).firstOrNull;
                final myPhoto = photos.where(
                    (p) => p.userId == user?.id).firstOrNull;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (hasPosted && partnerPhoto != null)
                        Expanded(
                          child: TodayPhotoCard(
                            photo: partnerPhoto,
                            label: 'Partner\'s photo',
                          ),
                        )
                      else if (!hasPosted)
                        const Expanded(child: LockScreenWidget()),
                      if (myPhoto != null) ...[
                        const SizedBox(height: 12),
                        TodayPhotoCard(photo: myPhoto, label: 'Your photo'),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: hasPostedAsync.valueOrNull == false
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/upload'),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Post today\'s photo'),
            )
          : null,
    );
  }
}

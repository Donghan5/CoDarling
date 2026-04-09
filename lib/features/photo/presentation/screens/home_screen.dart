import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../couple/presentation/providers/couple_provider.dart';
import '../../../prompt/presentation/widgets/prompt_card.dart';
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
        title: const Text('오늘'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.push('/calendar'),
          ),
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
        error: (e, _) => const Center(child: Text('오류가 발생했어요. 다시 시도해주세요.')),
        data: (couple) {
          if (couple == null) {
            return Center(
              child: FilledButton(
                onPressed: () => context.go('/couple-setup'),
                child: const Text('커플 연결하기'),
              ),
            );
          }

          // Couple created but partner hasn't joined yet
          if (!couple.isActive) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      '파트너를 기다리는 중...',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '파트너에게 이 코드를 공유하세요:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: couple.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('초대 코드가 복사됐어요!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              couple.inviteCode,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.copy,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '탭해서 복사',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return hasPostedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('오류가 발생했어요. 다시 시도해주세요.')),
            data: (hasPosted) => todayPhotosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('오류가 발생했어요. 다시 시도해주세요.')),
              data: (photos) {
                final partnerPhoto = photos.where(
                    (p) => p.userId != user?.id).firstOrNull;
                final myPhoto = photos.where(
                    (p) => p.userId == user?.id).firstOrNull;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 320,
                        child: hasPosted && partnerPhoto != null
                            ? TodayPhotoCard(
                                photo: partnerPhoto,
                                label: '파트너의 사진',
                                showReactions: true,
                              )
                            : const LockScreenWidget(),
                      ),
                      if (myPhoto != null) ...[
                        const SizedBox(height: 12),
                        TodayPhotoCard(photo: myPhoto, label: '내 사진'),
                      ],
                      const SizedBox(height: 16),
                      const PromptCard(),
                      const SizedBox(height: 80), // FAB clearance
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
              label: const Text('오늘의 사진 올리기'),
            )
          : null,
    );
  }
}

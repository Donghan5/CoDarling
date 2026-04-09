import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/photo_provider.dart';

class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumPhotosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Our Album')),
      body: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Something went wrong. Please try again.')),
        data: (photos) => photos.isEmpty
            ? const Center(child: Text('No photos yet. Start sharing!'))
            : GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: photos.length,
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: photos[i].imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                ),
              ),
      ),
    );
  }
}

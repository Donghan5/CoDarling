import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/photo_entity.dart';
import '../providers/photo_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final photosByDate = ref.watch(photosByDateProvider);
    final isLoading = ref.watch(albumPhotosProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('달력')),
      body: Column(
        children: [
          _MonthHeader(month: month),
          const _WeekdayLabels(),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: _CalendarGrid(month: month, photosByDate: photosByDate),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month navigation header
// ---------------------------------------------------------------------------

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = DateFormat('yyyy년 M월', 'ko').format(month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                ref.read(calendarMonthProvider.notifier).state =
                    DateTime(month.year, month.month - 1),
          ),
          Expanded(
            child: Center(
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () =>
                ref.read(calendarMonthProvider.notifier).state =
                    DateTime(month.year, month.month + 1),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekday label row (Mon … Sun)
// ---------------------------------------------------------------------------

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: _labels
            .map(
              (l) => Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar grid
// ---------------------------------------------------------------------------

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.month, required this.photosByDate});

  final DateTime month;
  final Map<String, List<PhotoEntity>> photosByDate;

  @override
  Widget build(BuildContext context) {
    // Monday = weekday 1 → 0 leading blanks; Sunday = weekday 7 → 6 blanks
    final firstDay = DateTime(month.year, month.month, 1);
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final rows = ((leadingBlanks + totalDays) / 7).ceil();

    // Cache today once so _isToday doesn't call DateTime.now() per cell.
    final today = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayIndex = index - leadingBlanks;
        if (dayIndex < 0 || dayIndex >= totalDays) return const SizedBox.shrink();

        final day = dayIndex + 1;
        final date = DateTime(month.year, month.month, day);
        final key = AppDateUtils.toIsoDate(date);
        final photos = photosByDate[key] ?? [];
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        return _DayCell(
          day: day,
          hasPhotos: photos.isNotEmpty,
          isToday: isToday,
          onTap: photos.isNotEmpty
              ? () => _showDayPhotos(context, date, photos)
              : null,
        );
      },
    );
  }

  static void _showDayPhotos(
    BuildContext context,
    DateTime date,
    List<PhotoEntity> photos,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DayPhotosSheet(date: date, photos: photos),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual day cell
// ---------------------------------------------------------------------------

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.hasPhotos,
    required this.isToday,
    this.onTap,
  });

  final int day;
  final bool hasPhotos;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: isToday
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 1.5),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? colorScheme.primary : null,
              ),
            ),
            if (hasPhotos)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet — photos for a selected day
// ---------------------------------------------------------------------------

class _DayPhotosSheet extends StatelessWidget {
  const _DayPhotosSheet({required this.date, required this.photos});

  final DateTime date;
  final List<PhotoEntity> photos;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('yyyy년 M월 d일', 'ko').format(date);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final caption = photos[i].caption;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: photos[i].imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox(
                          height: 220,
                          child: Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                    if (caption != null && caption.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          caption,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/event.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/filter_chip_row.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final invitees = ref.watch(allInviteesProvider).valueOrNull ?? [];
    final filter = ref.watch(eventsFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المناسبات')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/events/new'),
        child: const Icon(Icons.add),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('حدث خطأ: $e')),
        data: (allEvents) {
          var events = List<EventItem>.from(allEvents)
            ..sort((a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)));
          final now = DateTime.now();
          if (filter == 'upcoming') {
            events = events.where((e) => e.date != null && e.date!.isAfter(now) && !e.archived).toList();
          } else if (filter == 'ongoing') {
            events = events.where((e) => e.date != null && e.date!.difference(now).inDays.abs() <= 0 && !e.archived).toList();
          } else if (filter == 'finished') {
            events = events.where((e) => e.archived || e.isOver).toList();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilterChipRow(
                options: const [
                  FilterOption('all', 'الكل'),
                  FilterOption('upcoming', 'مقبلة'),
                  FilterOption('ongoing', 'جارية'),
                  FilterOption('finished', 'منتهية'),
                ],
                selected: filter,
                onSelected: (v) => ref.read(eventsFilterProvider.notifier).state = v,
              ),
              const SizedBox(height: 14),
              if (events.isEmpty)
                const EmptyState(icon: Icons.event_busy, message: 'لا توجد مناسبات في هذه القائمة')
              else
                ...events.map((e) {
                  final evInvitees = invitees.where((i) => i.eventId == e.id).toList();
                  final expected = evInvitees.fold<int>(0, (s, i) => s + i.companions);
                  final (statusLabel, statusColor) = e.archived || e.isOver
                      ? ('منتهية', Colors.grey)
                      : (e.date != null && e.date!.difference(now).inDays == 0)
                          ? ('جارية', AppColors.secondary)
                          : ('مقبلة', AppColors.success);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push('/events/${e.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                SizedBox(
                                  height: 150,
                                  width: double.infinity,
                                  child: e.coverImagePath != null
                                      ? Image.file(File(e.coverImagePath!), fit: BoxFit.cover)
                                      : Container(
                                          color: AppColors.eventColors[e.colorIndex % AppColors.eventColors.length].withOpacity(0.25),
                                          alignment: Alignment.center,
                                          child: const Text('🎉', style: TextStyle(fontSize: 44)),
                                        ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.85), borderRadius: BorderRadius.circular(100)),
                                    child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                                    onSelected: (v) async {
                                      if (v == 'edit') context.push('/events/${e.id}/edit');
                                      if (v == 'duplicate') await ref.read(eventsProvider.notifier).duplicate(e);
                                      if (v == 'delete') await ref.read(eventsProvider.notifier).remove(e.id);
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                      PopupMenuItem(value: 'duplicate', child: Text('نسخ')),
                                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                                  const SizedBox(height: 4),
                                  Text(formatDate(e.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.groups, size: 14, color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Text('${evInvitees.length} ضيف', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                      const SizedBox(width: 12),
                                      const Text('👥', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text('$expected متوقع', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

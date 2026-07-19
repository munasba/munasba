import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/invitees_repository.dart';
import '../../data/services/excel_service.dart';
import '../../data/services/pdf_service.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stat_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final invitees = ref.watch(allInviteesProvider).valueOrNull ?? [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];

    final stats = AttendeeStats.fromInvitees(invitees);
    final upcoming = events.where((e) => e.date != null && !e.isOver).length;
    final finished = events.where((e) => e.archived || e.isOver).length;
    final completedTasks = tasks.where((t) => t.status.name == 'completed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => PdfService.printAppReport(people: people, categories: categories, events: events, allInvitees: invitees),
          ),
          IconButton(
            icon: const Icon(Icons.table_view_outlined),
            onPressed: () {
              final statsByEventId = {
                for (final e in events) e.id: AttendeeStats.fromInvitees(invitees.where((i) => i.eventId == e.id).toList()),
              };
              ExcelService.exportEventsWithStats(events, statsByEventId);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(value: '${people.length}', label: 'الأشخاص', icon: Icons.people, color: AppColors.primary),
              StatCard(value: '${categories.length}', label: 'الفئات', icon: Icons.folder, color: AppColors.secondary),
              StatCard(value: '${events.length}', label: 'المناسبات', icon: Icons.event, color: AppColors.success),
              StatCard(value: '$upcoming', label: 'مقبلة', icon: Icons.schedule, color: AppColors.warning),
              StatCard(value: '$finished', label: 'منتهية', icon: Icons.check_circle_outline, color: AppColors.pending),
              StatCard(value: '$completedTasks / ${tasks.length}', label: 'المهام المنجزة', icon: Icons.task_alt, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                const Align(alignment: Alignment.centerRight, child: Text('ملخص الحضور على مستوى كل المناسبات', style: TextStyle(fontWeight: FontWeight.bold))),
                const Divider(),
                _row('👤 إجمالي المدعوين', '${stats.invited}'),
                _row('👥 إجمالي الحضور المتوقع', '${stats.expected}'),
                _row('✅ مؤكدون', '${stats.confirmed}'),
                _row('❌ معتذرون', '${stats.declined}'),
                _row('⌛ قيد الانتظار', '${stats.pending}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade400)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

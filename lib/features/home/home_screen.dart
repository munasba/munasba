import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/event.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stat_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final invitees = ref.watch(allInviteesProvider).valueOrNull ?? [];
    final categoryCounts = ref.watch(categoryPeopleCountProvider).valueOrNull ?? {};

    final upcoming = events.where((e) => e.date != null && !e.isOver).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً 👋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('إدارة مناسباتك أصبحت أسهل', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث عن شخص أو مناسبة...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              StatCard(value: '${people.length}', label: 'إجمالي الأشخاص', icon: Icons.people_alt, color: AppColors.primary),
              StatCard(value: '${categories.length}', label: 'إجمالي الأقسام', icon: Icons.folder, color: AppColors.secondary),
              StatCard(value: '${events.length}', label: 'إجمالي المناسبات', icon: Icons.event, color: AppColors.success),
              StatCard(value: '${upcoming.length}', label: 'المناسبات القادمة', icon: Icons.calendar_month, color: AppColors.warning),
              StatCard(value: '${invitees.length}', label: 'إجمالي المدعوين', icon: Icons.groups, color: AppColors.gold),
              StatCard(
                value: '${invitees.fold<int>(0, (s, i) => s + i.companions)}',
                label: 'الحضور المتوقع',
                icon: Icons.emoji_people,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (categories.isNotEmpty) _CategoryDonut(categories: categories, counts: categoryCounts),
          const SizedBox(height: 20),
          _EventsMonthChart(events: events),
          const SizedBox(height: 20),
          const Text('المناسبات القادمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            const Text('لا توجد مناسبات قادمة', style: TextStyle(color: Colors.grey))
          else
            ...upcoming.take(3).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () => context.push('/events/${e.id}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.eventColors[e.colorIndex % AppColors.eventColors.length].withOpacity(0.2),
                          child: const Text('🎉'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(formatDate(e.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                        Text(daysRemainingLabel(e.date), style: TextStyle(fontSize: 12, color: AppColors.gold)),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 20),
          const Text('إجراءات سريعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              _QuickAction(icon: Icons.person_add, label: 'إضافة شخص', onTap: () => context.push('/people/new')),
              _QuickAction(icon: Icons.pie_chart, label: 'تقرير شامل', onTap: () => context.push('/reports')),
              _QuickAction(icon: Icons.event_available, label: 'إضافة مناسبة', onTap: () => context.push('/events/new')),
              _QuickAction(icon: Icons.checklist, label: 'إدارة المهام', onTap: () => context.push('/tasks')),
              _QuickAction(icon: Icons.category, label: 'الفئات', onTap: () => context.push('/categories')),
              _QuickAction(icon: Icons.settings, label: 'الإعدادات', onTap: () => context.push('/settings')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryDonut extends StatelessWidget {
  final List categories;
  final Map<String, int> counts;
  const _CategoryDonut({required this.categories, required this.counts});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return GlassCard(
      child: Column(
        children: [
          const Align(alignment: Alignment.centerRight, child: Text('الأشخاص حسب القسم', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: total == 0
                ? const Center(child: Text('لا توجد بيانات بعد', style: TextStyle(color: Colors.grey)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        for (var i = 0; i < categories.length; i++)
                          if ((counts[categories[i].id] ?? 0) > 0)
                            PieChartSectionData(
                              value: (counts[categories[i].id] ?? 0).toDouble(),
                              color: AppColors.categoryGradients[i % AppColors.categoryGradients.length][0],
                              title: '',
                              radius: 34,
                            ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    );
  }
}

const _arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

/// "المناسبات هذا الشهر" — a day-by-day line/area chart of how many events
/// fall on each day of the selected month, with a month picker dropdown.
class _EventsMonthChart extends ConsumerWidget {
  final List<EventItem> events;
  const _EventsMonthChart({required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedReportMonthProvider);
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    final countsByDay = List<int>.filled(daysInMonth, 0);
    for (final e in events) {
      final date = e.date;
      if (date != null && date.year == selectedMonth.year && date.month == selectedMonth.month) {
        countsByDay[date.day - 1]++;
      }
    }
    final maxCount = countsByDay.isEmpty ? 0 : countsByDay.reduce((a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المناسبات هذا الشهر', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: selectedMonth.month,
                underline: const SizedBox.shrink(),
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(value: m, child: Text(_arabicMonths[m - 1])))
                    .toList(),
                onChanged: (m) {
                  if (m != null) {
                    ref.read(selectedReportMonthProvider.notifier).state = DateTime(selectedMonth.year, m);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: maxCount == 0
                ? const Center(child: Text('لا توجد مناسبات هذا الشهر', style: TextStyle(color: Colors.grey)))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (daysInMonth / 6).ceilToDouble(),
                            getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}', style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: (maxCount + 1).toDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [for (var i = 0; i < daysInMonth; i++) FlSpot(i.toDouble(), countsByDay[i].toDouble())],
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.18)),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}


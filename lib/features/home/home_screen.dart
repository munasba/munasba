import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/event.dart';
import '../../data/models/invitee.dart';
import '../../data/models/person.dart';
import '../../data/models/task.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'صباح الخير';
    if (h >= 12 && h < 17) return 'نهارك سعيد';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final invitees = ref.watch(allInviteesProvider).valueOrNull ?? [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final name = ref.watch(displayNameProvider).valueOrNull;

    final upcoming = events.where((e) => e.date != null && !e.isOver).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
    final nextEvent = upcoming.isEmpty ? null : upcoming.first;

    final calledCount = people.where((p) => p.lastCallStatus == 'called').length;
    final pendingInvites = invitees
        .where((i) => i.rsvpStatus == RsvpStatus.pending || i.rsvpStatus == RsvpStatus.notContacted)
        .length;
    final pendingTasks = tasks.where((t) => t.effectiveStatus != TaskStatus.completed).length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1438), Color(0xFF160F2E)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Header(greeting: _greeting(), name: name, pendingTasks: pendingTasks)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 18),
            const _SearchBar().animate().fadeIn(delay: 80.ms, duration: 350.ms),
            const SizedBox(height: 18),
            _StatsGrid(
              peopleCount: people.length,
              eventsCount: events.length,
              calledCount: calledCount,
              pendingInvites: pendingInvites,
              pendingTasks: pendingTasks,
              categoriesCount: categories.length,
            ).animate().fadeIn(delay: 140.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 20),
            if (nextEvent != null)
              _NextEventCard(event: nextEvent, invitees: invitees, tasks: tasks)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),
            const _SectionTitle('إجراءات سريعة'),
            const SizedBox(height: 10),
            const _QuickActionsGrid().animate().fadeIn(delay: 260.ms, duration: 400.ms),
            const SizedBox(height: 20),
            const _SectionTitle('آخر النشاطات'),
            const SizedBox(height: 10),
            _RecentActivity(people: people, events: events, tasks: tasks)
                .animate()
                .fadeIn(delay: 320.ms, duration: 400.ms),
            const SizedBox(height: 20),
            _EventsMonthChart(events: events).animate().fadeIn(delay: 380.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Colors.white));
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String? name;
  final int pendingTasks;
  const _Header({required this.greeting, required this.name, required this.pendingTasks});

  @override
  Widget build(BuildContext context) {
    final displayName = (name == null || name!.isEmpty) ? 'صديقنا' : name!;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF9B6BF3), Color(0xFF4C6FFF)]),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            displayName.isNotEmpty ? displayName.substring(0, 1) : '👋',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting، $displayName 👋',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 2),
              Text('نتمنى لك يوماً رائعاً ومليئاً بالإنجاز ✨',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
            ],
          ),
        ),
        _NotificationBell(count: pendingTasks),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(11),
          borderRadius: 16,
          onTap: () {},
          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
        ),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              alignment: Alignment.center,
              child: Text('$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            borderRadius: 16,
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'ابحث عن شخص، مناسبة أو مهمة...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GlassCard(
          padding: const EdgeInsets.all(13),
          borderRadius: 16,
          onTap: () {},
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _StatDef {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatDef(this.value, this.label, this.icon, this.color);
}

class _StatsGrid extends StatelessWidget {
  final int peopleCount;
  final int eventsCount;
  final int calledCount;
  final int pendingInvites;
  final int pendingTasks;
  final int categoriesCount;

  const _StatsGrid({
    required this.peopleCount,
    required this.eventsCount,
    required this.calledCount,
    required this.pendingInvites,
    required this.pendingTasks,
    required this.categoriesCount,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatDef('$peopleCount', 'إجمالي الأشخاص', Icons.groups_rounded, AppColors.primary),
      _StatDef('$eventsCount', 'المناسبات', Icons.calendar_month_rounded, AppColors.secondary),
      _StatDef('$calledCount', 'تم الاتصال بهم', Icons.phone_in_talk_rounded, AppColors.success),
      _StatDef('$pendingInvites', 'دعوات متبقية', Icons.person_add_alt_1_rounded, AppColors.warning),
      _StatDef('$pendingTasks', 'مهام معلقة', Icons.checklist_rounded, const Color(0xFFE84FA0)),
      _StatDef('$categoriesCount', 'التصنيفات', Icons.folder_rounded, AppColors.gold),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) => _AnimatedStatCard(stat: stats[i]),
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final _StatDef stat;
  const _AnimatedStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final targetValue = int.tryParse(stat.value) ?? 0;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 19, backgroundColor: stat.color.withOpacity(0.2), child: Icon(stat.icon, color: stat.color, size: 19)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: targetValue),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) =>
                Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }
}

class _NextEventCard extends StatelessWidget {
  final EventItem event;
  final List<Invitee> invitees;
  final List<TaskItem> tasks;
  const _NextEventCard({required this.event, required this.invitees, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final guestCount = invitees.where((i) => i.eventId == event.id).fold<int>(0, (s, i) => s + i.companions);
    final eventTasks = tasks.where((t) => t.eventId == event.id).toList();
    final completion = eventTasks.isEmpty
        ? 0.0
        : eventTasks.where((t) => t.effectiveStatus == TaskStatus.completed).length / eventTasks.length;
    final color = AppColors.eventColors[event.colorIndex % AppColors.eventColors.length];
    final days = event.date!.difference(DateTime.now()).inDays;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.35), color.withOpacity(0.12)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('قادمة', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(event.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(formatDate(event.date), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MiniStat(icon: Icons.groups_rounded, value: '$guestCount', label: 'مدعو'),
                  const SizedBox(width: 20),
                  _MiniStat(icon: Icons.calendar_today_rounded, value: days < 0 ? '0' : '$days', label: 'يوم متبقي'),
                  const Spacer(),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: completion),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => CircularProgressIndicator(
                            value: value,
                            strokeWidth: 5,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                        Text('${(completion * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                  onPressed: () => context.push('/events/${event.id}'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('عرض المناسبة', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MiniStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10.5)),
          ],
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.person_add_alt_1_rounded, 'إضافة شخص', AppColors.primary, () => context.push('/people/new')),
      (Icons.event_available_rounded, 'إضافة مناسبة', AppColors.secondary, () => context.push('/events/new')),
      (Icons.checklist_rounded, 'إضافة مهمة', const Color(0xFFE84FA0), () => context.push('/tasks')),
      (Icons.phone_in_talk_rounded, 'اتصال سريع', AppColors.success, () => context.push('/people')),
      (Icons.category_rounded, 'التصنيفات', AppColors.warning, () => context.push('/categories')),
      (Icons.bar_chart_rounded, 'التقارير', AppColors.gold, () => context.push('/reports')),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, i) {
        final (icon, label, color, onTap) = actions[i];
        return GlassCard(
          padding: const EdgeInsets.all(10),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 20)),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white)),
            ],
          ),
        );
      },
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List<Person> people;
  final List<EventItem> events;
  final List<TaskItem> tasks;
  const _RecentActivity({required this.people, required this.events, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, Color, String, DateTime)>[
      for (final p in people) (Icons.person_add_alt_1_rounded, AppColors.primary, 'تم إضافة شخص جديد: ${p.fullName}', p.createdAt),
      for (final e in events) (Icons.event_rounded, AppColors.secondary, 'تم إنشاء مناسبة جديدة: ${e.name}', e.createdAt),
      for (final t in tasks)
        if (t.effectiveStatus == TaskStatus.completed)
          (Icons.check_circle_rounded, AppColors.success, 'تم إكمال مهمة: ${t.title}', t.createdAt),
    ]..sort((a, b) => b.$4.compareTo(a.$4));

    final top = items.take(3).toList();

    if (top.isEmpty) {
      return GlassCard(
        child: Text('لا توجد نشاطات بعد', style: TextStyle(color: Colors.white.withOpacity(0.5))),
      );
    }

    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) Divider(color: Colors.white.withOpacity(0.08), height: 20),
            Row(
              children: [
                CircleAvatar(radius: 17, backgroundColor: top[i].$2.withOpacity(0.2), child: Icon(top[i].$1, color: top[i].$2, size: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(top[i].$3, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                Text(_timeAgo(top[i].$4), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
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
              const Text('المناسبات هذا الشهر', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              DropdownButton<int>(
                value: selectedMonth.month,
                underline: const SizedBox.shrink(),
                dropdownColor: AppColors.darkSurface,
                style: const TextStyle(color: Colors.white),
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
                ? Center(child: Text('لا توجد مناسبات هذا الشهر', style: TextStyle(color: Colors.white.withOpacity(0.5))))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 1,
                            getTitlesWidget: (value, meta) =>
                                Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (daysInMonth / 6).ceilToDouble(),
                            getTitlesWidget: (value, meta) =>
                                Text('${value.toInt() + 1}', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
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

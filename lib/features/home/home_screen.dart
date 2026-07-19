import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/event.dart';
import '../../data/models/invitee.dart';
import '../../data/models/person.dart';
import '../../data/models/task.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';

/// Premium dashboard-style Home Screen.
///
/// This file only *presents* data already exposed by the existing Riverpod
/// providers — no provider, repository or model was touched. Every stat,
/// card and list below is computed straight from `peopleProvider`,
/// `eventsProvider`, `categoriesProvider`, `tasksProvider` and
/// `allInviteesProvider`, exactly like the previous implementation did.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final inviteesAsync = ref.watch(allInviteesProvider);
    final categoryCounts = ref.watch(categoryPeopleCountProvider).valueOrNull ?? const <String, int>{};

    // True only on the very first load (no cached data yet for a core
    // provider) — later refreshes keep showing the previous data instead of
    // flashing the skeleton again.
    final isFirstLoad = (peopleAsync.isLoading && peopleAsync.valueOrNull == null) ||
        (eventsAsync.isLoading && eventsAsync.valueOrNull == null) ||
        (categoriesAsync.isLoading && categoriesAsync.valueOrNull == null) ||
        (tasksAsync.isLoading && tasksAsync.valueOrNull == null);

    if (isFirstLoad) {
      return const _HomeSkeleton();
    }

    final people = peopleAsync.valueOrNull ?? const <Person>[];
    final categories = categoriesAsync.valueOrNull ?? const <Category>[];
    final events = eventsAsync.valueOrNull ?? const <EventItem>[];
    final tasks = tasksAsync.valueOrNull ?? const <TaskItem>[];
    final invitees = inviteesAsync.valueOrNull ?? const <Invitee>[];

    final upcoming = events.where((e) => e.date != null && !e.isOver).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
    final nextEvent = upcoming.isNotEmpty ? upcoming.first : null;

    final contactedCount = people.where((p) => p.lastCallStatus == 'called').length;
    final remainingCount = people.length - contactedCount;
    final pendingTasksCount = tasks.where((t) => t.effectiveStatus != TaskStatus.completed).length;
    final overdueTasksCount = tasks.where((t) => t.effectiveStatus == TaskStatus.overdue).length;

    final totalInvitees = invitees.length;
    final calledInvitees = invitees.where((i) => i.called).length;
    final invitationProgress = totalInvitees == 0 ? 0.0 : calledInvitees / totalInvitees;

    final activity = _buildRecentActivity(people: people, events: events, tasks: tasks);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(peopleProvider.notifier).refresh(),
            ref.read(eventsProvider.notifier).refresh(),
            ref.read(categoriesProvider.notifier).refresh(),
            ref.read(tasksProvider.notifier).refresh(),
            ref.refresh(allInviteesProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _FadeSlideIn(
              delay: Duration.zero,
              child: _HomeHeader(notificationCount: overdueTasksCount),
            ),
            const SizedBox(height: 22),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _SectionHeader(title: 'نظرة عامة'),
            ),
            const SizedBox(height: 10),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: _StatsGrid(
                peopleCount: people.length,
                eventsCount: events.length,
                contactedCount: contactedCount,
                remainingCount: remainingCount,
                pendingTasksCount: pendingTasksCount,
                categoriesCount: categories.length,
              ),
            ),
            const SizedBox(height: 26),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _SectionHeader(title: 'المناسبة القادمة'),
            ),
            const SizedBox(height: 10),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: nextEvent == null
                  ? _EmptyStateCard(
                      icon: Icons.celebration_outlined,
                      message: 'لا توجد مناسبات قادمة بعد',
                      actionLabel: 'إضافة مناسبة',
                      onAction: () => context.push('/events/new'),
                    )
                  : _UpcomingEventCard(
                      event: nextEvent,
                      invitedCount: invitees.where((i) => i.eventId == nextEvent.id).length,
                      calledCount:
                          invitees.where((i) => i.eventId == nextEvent.id && i.called).length,
                    ),
            ),
            const SizedBox(height: 26),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _SectionHeader(title: 'إجراءات سريعة'),
            ),
            const SizedBox(height: 10),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 210),
              child: _QuickActionsGrid(
                onAddPerson: () => context.push('/people/new'),
                onAddEvent: () => context.push('/events/new'),
                onAddTask: () => context.push('/tasks'),
                onCallGuests: () => context.push('/people'),
                onCategories: () => context.push('/categories'),
                onReports: () => context.push('/reports'),
              ),
            ),
            const SizedBox(height: 26),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: _SectionHeader(title: 'تقدم الدعوات'),
            ),
            const SizedBox(height: 10),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 270),
              child: totalInvitees == 0
                  ? _EmptyStateCard(
                      icon: Icons.pie_chart_outline_rounded,
                      message: 'لم تتم إضافة مدعوين لأي مناسبة بعد',
                      actionLabel: 'إضافة مناسبة',
                      onAction: () => context.push('/events/new'),
                    )
                  : _InvitationProgressCard(
                      progress: invitationProgress,
                      completed: calledInvitees,
                      remaining: totalInvitees - calledInvitees,
                    ),
            ),
            const SizedBox(height: 26),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: _SectionHeader(title: 'التحليلات'),
            ),
            const SizedBox(height: 10),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 330),
              child: categories.isEmpty
                  ? _EmptyStateCard(
                      icon: Icons.category_outlined,
                      message: 'أضف أقساماً لعرض توزيع الأشخاص عليها',
                      actionLabel: 'إضافة قسم',
                      onAction: () => context.push('/categories'),
                    )
                  : _CategoryDonut(categories: categories, counts: categoryCounts),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 360),
              child: _EventsMonthChart(events: events),
            ),
            const SizedBox(height: 26),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 390),
              child: _SectionHeader(title: 'أحدث النشاطات'),
            ),
            const SizedBox(height: 10),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 420),
              child: activity.isEmpty
                  ? const _EmptyStateCard(
                      icon: Icons.history_toggle_off_rounded,
                      message: 'لا توجد نشاطات بعد، ابدأ بإضافة شخص أو مناسبة',
                    )
                  : _RecentActivityList(items: activity),
            ),
          ],
        ),
      ),
    );
  }

  List<_ActivityEntry> _buildRecentActivity({
    required List<Person> people,
    required List<EventItem> events,
    required List<TaskItem> tasks,
  }) {
    final entries = <_ActivityEntry>[
      ...people.map(
        (p) => _ActivityEntry(
          title: p.fullName,
          subtitle: p.phone?.isNotEmpty == true ? p.phone! : 'بدون رقم هاتف',
          date: p.createdAt,
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.primary,
        ),
      ),
      ...events.map(
        (e) => _ActivityEntry(
          title: e.name,
          subtitle: kEventTypes[e.type] ?? e.type,
          date: e.createdAt,
          icon: Icons.event_rounded,
          color: AppColors.eventColors[e.colorIndex % AppColors.eventColors.length],
        ),
      ),
      ...tasks.map(
        (t) => _ActivityEntry(
          title: t.title,
          subtitle: t.effectiveStatus.label,
          date: t.createdAt,
          icon: Icons.task_alt_rounded,
          color: AppColors.success,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return entries.take(5).toList();
  }
}

// ============================================================================
// Header
// ============================================================================

class _HomeHeader extends StatelessWidget {
  final int notificationCount;
  const _HomeHeader({required this.notificationCount});

  ({String greeting, String emoji}) get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) return (greeting: 'صباح الخير', emoji: '☀️');
    return (greeting: 'مساء الخير', emoji: '🌙');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = _greeting;

    return Row(
      children: [
        _GradientAvatar(onTap: () => context.push('/settings')),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${g.greeting} ${g.emoji}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'دعواتي — إدارة مناسباتك أصبحت أسهل',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _NotificationBell(count: notificationCount),
      ],
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 26),
      ),
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
        _Tappable(
          onTap: () => context.push('/tasks'),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 22),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// Section header
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

// ============================================================================
// Stats grid
// ============================================================================

const List<List<Color>> _statGradients = [
  [AppColors.primary, AppColors.primaryDark],
  [Color(0xFF3F6FE0), Color(0xFF2A4FBF)],
  [AppColors.success, Color(0xFF15803D)],
  [AppColors.warning, Color(0xFFB45309)],
  [AppColors.danger, Color(0xFF9F1D1D)],
  [AppColors.gold, Color(0xFF8A6D3B)],
];

class _StatsGrid extends StatelessWidget {
  final int peopleCount;
  final int eventsCount;
  final int contactedCount;
  final int remainingCount;
  final int pendingTasksCount;
  final int categoriesCount;

  const _StatsGrid({
    required this.peopleCount,
    required this.eventsCount,
    required this.contactedCount,
    required this.remainingCount,
    required this.pendingTasksCount,
    required this.categoriesCount,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_StatSpec>[
      _StatSpec('إجمالي الأشخاص', peopleCount, Icons.people_alt_rounded, _statGradients[0], '/people'),
      _StatSpec('إجمالي المناسبات', eventsCount, Icons.event_rounded, _statGradients[1], '/events'),
      _StatSpec('تم التواصل معهم', contactedCount, Icons.call_rounded, _statGradients[2], '/people'),
      _StatSpec('دعوات متبقية', remainingCount, Icons.phone_missed_rounded, _statGradients[3], '/people'),
      _StatSpec('مهام قيد الإنجاز', pendingTasksCount, Icons.pending_actions_rounded, _statGradients[4], '/tasks'),
      _StatSpec('الأقسام', categoriesCount, Icons.category_rounded, _statGradients[5], '/categories'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, i) => _PremiumStatCard(spec: items[i]),
    );
  }
}

class _StatSpec {
  final String label;
  final int value;
  final IconData icon;
  final List<Color> gradient;
  final String route;
  const _StatSpec(this.label, this.value, this.icon, this.gradient, this.route);
}

class _PremiumStatCard extends StatelessWidget {
  final _StatSpec spec;
  const _PremiumStatCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: () => context.push(spec.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: spec.gradient,
          ),
          boxShadow: [
            BoxShadow(color: spec.gradient.last.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
              child: Icon(spec.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            _AnimatedCount(
              value: spec.value,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle style;
  const _AnimatedCount({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) => Text('$animatedValue', style: style),
    );
  }
}

// ============================================================================
// Upcoming event card
// ============================================================================

class _UpcomingEventCard extends StatelessWidget {
  final EventItem event;
  final int invitedCount;
  final int calledCount;

  const _UpcomingEventCard({required this.event, required this.invitedCount, required this.calledCount});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.eventColors[event.colorIndex % AppColors.eventColors.length];
    final days = event.date == null ? 0 : event.date!.difference(DateTime.now()).inDays;
    final progress = invitedCount == 0 ? 0.0 : calledCount / invitedCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [accent, accent.withOpacity(0.65)],
        ),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kEventTypes[event.type] ?? event.type,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDate(event.date),
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              _CountdownBadge(days: days),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text('$invitedCount مدعو', style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(progress * 100).round()}% تم التواصل',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/events/${event.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              label: const Text('فتح المناسبة', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final int days;
  const _CountdownBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Text(
            days <= 0 ? '🎉' : '$days',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            days <= 0 ? 'اليوم' : 'يوم متبقي',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Quick actions
// ============================================================================

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onAddPerson;
  final VoidCallback onAddEvent;
  final VoidCallback onAddTask;
  final VoidCallback onCallGuests;
  final VoidCallback onCategories;
  final VoidCallback onReports;

  const _QuickActionsGrid({
    required this.onAddPerson,
    required this.onAddEvent,
    required this.onAddTask,
    required this.onCallGuests,
    required this.onCategories,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (icon: Icons.person_add_alt_1_rounded, label: 'إضافة شخص', onTap: onAddPerson),
      (icon: Icons.event_available_rounded, label: 'إضافة مناسبة', onTap: onAddEvent),
      (icon: Icons.checklist_rtl_rounded, label: 'إضافة مهمة', onTap: onAddTask),
      (icon: Icons.call_rounded, label: 'اتصال بالمدعوين', onTap: onCallGuests),
      (icon: Icons.category_rounded, label: 'الفئات', onTap: onCategories),
      (icon: Icons.pie_chart_rounded, label: 'التقارير', onTap: onReports),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        final a = actions[i];
        return _QuickActionButton(icon: a.icon, label: a.label, onTap: a.onTap);
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Tappable(
      onTap: onTap,
      child: Hero(
        tag: 'quick_action_$label',
        child: Material(
          color: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            borderRadius: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Invitation progress card
// ============================================================================

class _InvitationProgressCard extends StatelessWidget {
  final double progress;
  final int completed;
  final int remaining;

  const _InvitationProgressCard({required this.progress, required this.completed, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress * 100).round();

    return GlassCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تقدم التواصل مع المدعوين', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '$value%',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ProgressStat(label: 'تم التواصل', value: completed, color: AppColors.success)),
              Container(width: 1, height: 30, color: theme.colorScheme.onSurface.withOpacity(0.08)),
              Expanded(child: _ProgressStat(label: 'متبقٍ', value: remaining, color: AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ProgressStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AnimatedCount(value: value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
      ],
    );
  }
}

// ============================================================================
// Recent activity
// ============================================================================

class _ActivityEntry {
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;
  const _ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
  });
}

class _RecentActivityList extends StatelessWidget {
  final List<_ActivityEntry> items;
  const _RecentActivityList({required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _FadeSlideIn(
              delay: Duration(milliseconds: 60 * i),
              beginOffset: const Offset(0, 0.15),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: _ActivityRow(entry: items[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityEntry entry;
  const _ActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: entry.color.withOpacity(0.16),
          child: Icon(entry.icon, color: entry.color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.65))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(formatShortDate(entry.date), style: TextStyle(fontSize: 10.5, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5))),
      ],
    );
  }
}

// ============================================================================
// Charts (unchanged data logic — restyled containers only)
// ============================================================================

class _CategoryDonut extends StatelessWidget {
  final List<Category> categories;
  final Map<String, int> counts;
  const _CategoryDonut({required this.categories, required this.counts});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return GlassCard(
      borderRadius: 24,
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text('الأشخاص حسب القسم', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: total == 0
                ? const _InlineEmptyHint(icon: Icons.donut_large_rounded, message: 'لا توجد بيانات بعد')
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 44,
                      sections: [
                        for (var i = 0; i < categories.length; i++)
                          if ((counts[categories[i].id] ?? 0) > 0)
                            PieChartSectionData(
                              value: (counts[categories[i].id] ?? 0).toDouble(),
                              color: AppColors.categoryGradients[i % AppColors.categoryGradients.length][0],
                              title: '',
                              radius: 36,
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
      borderRadius: 24,
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
            height: 170,
            child: maxCount == 0
                ? const _InlineEmptyHint(icon: Icons.show_chart_rounded, message: 'لا توجد مناسبات هذا الشهر')
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

// ============================================================================
// Reusable helpers
// ============================================================================

/// Fades and slides its child in once, after an optional [delay] — used to
/// stagger every dashboard section on first build.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset beginOffset;
  const _FadeSlideIn({required this.child, this.delay = Duration.zero, this.beginOffset = const Offset(0, 0.08)});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : widget.beginOffset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Wraps [child] with a subtle press-down scale animation for a tactile,
/// premium feel on any tappable dashboard element.
class _Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Tappable({required this.child, required this.onTap});

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A friendly, never-blank placeholder for any section with no data yet.
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyStateCard({required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: theme.colorScheme.primary.withOpacity(0.7)),
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A minimal empty-state hint for a chart that already lives inside its own
/// [GlassCard] — avoids nesting a second card inside the first.
class _InlineEmptyHint extends StatelessWidget {
  final IconData icon;
  final String message;
  const _InlineEmptyHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: theme.textTheme.bodySmall?.color?.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.55))),
        ],
      ),
    );
  }
}

// ============================================================================
// Skeleton loading state (shown only on first cold load)
// ============================================================================


class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(
            children: [
              _ShimmerBox(width: 52, height: 52, borderRadius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ShimmerBox(width: 140, height: 16, borderRadius: 8),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 200, height: 12, borderRadius: 6),
                  ],
                ),
              ),
              _ShimmerBox(width: 46, height: 46, borderRadius: 23),
            ],
          ),
          const SizedBox(height: 26),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, i) => const _ShimmerBox(height: 110, borderRadius: 22),
          ),
          const SizedBox(height: 26),
          const _ShimmerBox(height: 210, borderRadius: 26),
          const SizedBox(height: 26),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, i) => const _ShimmerBox(borderRadius: 20),
          ),
          const SizedBox(height: 26),
          const _ShimmerBox(height: 140, borderRadius: 24),
        ],
      ),
    );
  }
}

/// A lightweight shimmering placeholder built purely with [AnimatedContainer]
/// — no external shimmer package, no spinning [CircularProgressIndicator].
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  const _ShimmerBox({this.width, this.height = 60, this.borderRadius = 16});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> {
  bool _bright = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) setState(() => _bright = !_bright);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withOpacity(0.06);
    final bright = Theme.of(context).colorScheme.onSurface.withOpacity(0.11);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: _bright ? bright : base,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }
}

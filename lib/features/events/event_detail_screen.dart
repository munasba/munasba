import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/invitee.dart';
import '../../data/models/person.dart';
import '../../data/repositories/invitees_repository.dart';
import '../../data/services/excel_service.dart';
import '../../data/services/pdf_service.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/stepper_control.dart';
import '../tasks/tasks_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final event = events.where((e) => e.id == eventId).toList();
    if (event.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final e = event.first;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 96,
          leading: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                tooltip: 'خيارات',
                onSelected: (v) async {
                  if (v == 'duplicate') {
                    await ref.read(eventsProvider.notifier).duplicate(e);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ المناسبة')));
                    }
                  } else if (v == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('حذف المناسبة'),
                        content: Text('هل تريد حذف "${e.name}"؟'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(eventsProvider.notifier).remove(eventId);
                      if (context.mounted) context.pop();
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'duplicate', child: Text('نسخ المناسبة')),
                  PopupMenuItem(value: 'delete', child: Text('حذف المناسبة')),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'تعديل',
                onPressed: () => context.push('/events/$eventId/edit'),
              ),
            ],
          ),
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatDate(e.date), style: TextStyle(fontSize: 11, color: Colors.grey.shade300)),
                    const SizedBox(width: 4),
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'رجوع',
              onPressed: () => context.pop(),
            ),
          ],
          bottom: TabBar(
            tabs: [
              _tab('نظرة عامة', Icons.bar_chart_rounded),
              _tab('المدعوين', Icons.people_alt_rounded),
              _tab('المهام', Icons.checklist_rounded),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(eventId: eventId),
            _InviteesTab(eventId: eventId),
            TasksScreen(eventId: eventId, embedded: true),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, IconData icon) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Icon(icon, size: 16),
          ],
        ),
      );
}

class _OverviewTab extends ConsumerStatefulWidget {
  final String eventId;
  const _OverviewTab({required this.eventId});

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  // 'invited' يحسب المتبقي والنسبة على عدد سجلات المدعوين، و'expected' يحسبها
  // على إجمالي الحضور المتوقع (شامل المرافقين) — تبديل حقيقي يغيّر الأرقام.
  String _metric = 'invited';

  @override
  Widget build(BuildContext context) {
    final invitees = ref.watch(inviteesProvider(widget.eventId)).valueOrNull ?? [];
    final stats = AttendeeStats.fromInvitees(invitees);
    final matchingEvents = (ref.watch(eventsProvider).valueOrNull ?? []).where((e) => e.id == widget.eventId).toList();
    final event = matchingEvents.isEmpty ? null : matchingEvents.first;
    final List<Person> people = ref.watch(peopleProvider).valueOrNull ?? <Person>[];
    final Map<String, Person> peopleById = {for (final p in people) p.id: p};

    final confirmedExpected = invitees.where((i) => i.rsvpStatus == RsvpStatus.invited).fold<int>(0, (sum, i) => sum + i.companions);
    final int total = _metric == 'invited' ? stats.invited : stats.expected;
    final int confirmedForMetric = _metric == 'invited' ? stats.confirmed : confirmedExpected;
    final int remaining = total - confirmedForMetric;
    final int percent = total == 0 ? 0 : ((confirmedForMetric / total) * 100).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _metricToggle(
                label: 'الأشخاص المدعوون',
                icon: Icons.person_rounded,
                selected: _metric == 'invited',
                onTap: () => setState(() => _metric = 'invited'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricToggle(
                label: 'الحضور المتوقع',
                icon: Icons.groups_rounded,
                selected: _metric == 'expected',
                onTap: () => setState(() => _metric = 'expected'),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.06, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            StatCard(value: '$confirmedForMetric', label: '✅ مؤكدون', icon: Icons.check_circle, color: AppColors.success)
                .animate()
                .fadeIn(delay: 60.ms, duration: 320.ms)
                .scaleXY(begin: 0.85, end: 1, curve: Curves.easeOutBack),
            StatCard(value: '$remaining', label: '⏳ المتبقون', icon: Icons.hourglass_bottom, color: AppColors.warning)
                .animate()
                .fadeIn(delay: 120.ms, duration: 320.ms)
                .scaleXY(begin: 0.85, end: 1, curve: Curves.easeOutBack),
            StatCard(value: '$percent%', label: '📈 نسبة الإنجاز', icon: Icons.percent, color: AppColors.secondary)
                .animate()
                .fadeIn(delay: 180.ms, duration: 320.ms)
                .scaleXY(begin: 0.85, end: 1, curve: Curves.easeOutBack),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            children: [
              const Align(alignment: Alignment.centerRight, child: Text('📋 ملخص الحضور', style: TextStyle(fontWeight: FontWeight.bold))),
              const Divider(),
              _summaryRow('👤 المدعوون', '${stats.invited}'),
              _summaryRow('👥 الحضور المتوقع', '${stats.expected}', highlight: true),
              _summaryRow('✅ مؤكدون', '${stats.confirmed}'),
              _summaryRow('📵 لم يتم التواصل', '${stats.notContacted}'),
              _summaryRow('❌ معتذرون', '${stats.declined}'),
              _summaryRow('⌛ قيد الانتظار', '${stats.pending}'),
              _summaryRow('📈 نسبة الإنجاز', '${stats.percent}%'),
            ],
          ),
        ).animate().fadeIn(delay: 220.ms, duration: 350.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        if (event != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => PdfService.printEventReport(event: event, invitees: invitees, peopleById: peopleById),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('تصدير PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ExcelService.exportEventInvitees(event, invitees, peopleById),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.table_view_outlined, size: 18),
                  label: const Text('تصدير Excel'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _metricToggle({required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        color: selected ? AppColors.primary.withOpacity(0.22) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 6),
            Icon(icon, size: 17, color: selected ? AppColors.primary : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: highlight ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6) : EdgeInsets.zero,
        decoration: highlight ? BoxDecoration(color: AppColors.gold.withOpacity(0.14), borderRadius: BorderRadius.circular(10)) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade400)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: highlight ? 18 : 15, color: highlight ? AppColors.gold : null)),
          ],
        ),
      ),
    );
  }
}

class _InviteesTab extends ConsumerStatefulWidget {
  final String eventId;
  const _InviteesTab({required this.eventId});

  @override
  ConsumerState<_InviteesTab> createState() => _InviteesTabState();
}

class _InviteesTabState extends ConsumerState<_InviteesTab> {
  String _filter = 'all';

  Future<void> _contact(Uri uri, Invitee inv) async {
    await launchUrl(uri);
    if (!mounted) return;
    await _showCallOutcomeSheet(inv);
  }

  /// Applies [status] to [inv] and shows a snackbar with a "تراجع" action
  /// that restores the previous status — so a wrong tap never needs a
  /// second trip through the status buttons to fix.
  Future<void> _applyStatus(Invitee inv, RsvpStatus status) async {
    final previous = inv.rsvpStatus;
    await ref.read(inviteesProvider(widget.eventId).notifier).updateStatus(inv.id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تحديث الحالة إلى "${status.label}"'),
        action: previous == status
            ? null
            : SnackBarAction(
                label: 'تراجع',
                onPressed: () => ref.read(inviteesProvider(widget.eventId).notifier).updateStatus(inv.id, previous),
              ),
      ),
    );
  }

  Future<void> _showCallOutcomeSheet(Invitee inv) async {
    final status = await showModalBottomSheet<RsvpStatus>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ما نتيجة التواصل؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('حدّد حالة هذا المدعو بعد الاتصال به', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle, color: AppColors.success),
                title: const Text('تم الاتصال به وأكّد الحضور'),
                onTap: () => Navigator.pop(ctx, RsvpStatus.invited),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: AppColors.danger),
                title: const Text('اعتذر عن الحضور'),
                onTap: () => Navigator.pop(ctx, RsvpStatus.declined),
              ),
              ListTile(
                leading: const Icon(Icons.hourglass_bottom, color: AppColors.pending),
                title: const Text('لم يتم الرد بعد'),
                onTap: () => Navigator.pop(ctx, RsvpStatus.notContacted),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ],
          ),
        ),
      ),
    );
    if (status != null && mounted) {
      await _applyStatus(inv, status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitees = ref.watch(inviteesProvider(widget.eventId)).valueOrNull ?? [];
    final List<Person> people = ref.watch(peopleProvider).valueOrNull ?? <Person>[];

    final Map<String, Person> peopleById = {for (final p in people) p.id: p};

    var filtered = invitees;
    switch (_filter) {
      case 'remaining':
        filtered = invitees.where((i) => i.rsvpStatus != RsvpStatus.invited).toList();
        break;
      case 'confirmed':
        filtered = invitees.where((i) => i.rsvpStatus == RsvpStatus.invited).toList();
        break;
      case 'declined':
        filtered = invitees.where((i) => i.rsvpStatus == RsvpStatus.declined).toList();
        break;
      case 'notContacted':
        filtered = invitees.where((i) => i.rsvpStatus == RsvpStatus.notContacted).toList();
        break;
      case 'pending':
        filtered = invitees.where((i) => i.rsvpStatus == RsvpStatus.pending).toList();
        break;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('all', 'الكل'),
                      _chip('confirmed', 'مؤكدون'),
                      _chip('notContacted', 'لم يتم التواصل'),
                      _chip('declined', 'معتذرون'),
                      _chip('pending', 'قيد الانتظار'),
                      _chip('remaining', 'المتبقون'),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_add_alt),
                onPressed: () => context.push('/events/${widget.eventId}/invitees'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('لا يوجد أحد في هذه القائمة', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final inv = filtered[i];
                    final p = peopleById[inv.personId];
                    if (p == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (p.phone != null) Text(p.phone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                      if (inv.calledAt != null)
                                        Text('آخر تواصل: ${formatShortDate(inv.calledAt)}',
                                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                StepperControl(
                                  value: inv.companions,
                                  onChanged: (v) => ref.read(inviteesProvider(widget.eventId).notifier).updateCompanions(inv.id, v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  inv.companions <= 1 ? '👥 سيأتي وحده' : '👥 سيأتي معه: ${inv.companions} أشخاص',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                ),
                                Wrap(
                                  spacing: 6,
                                  children: RsvpStatus.values.map((s) {
                                    final active = inv.rsvpStatus == s;
                                    return GestureDetector(
                                      onTap: () => _applyStatus(inv, s),
                                      child: Opacity(
                                        opacity: active ? 1 : 0.4,
                                        child: StatusChip(label: s.label, color: AppColors.rsvpColor(s.key))
                                            .animate(target: active ? 1 : 0)
                                            .scaleXY(begin: 1, end: 1.12, curve: Curves.easeOutBack, duration: 220.ms)
                                            .then()
                                            .scaleXY(begin: 1.12, end: 1, duration: 120.ms),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            if (p.phone != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chat, color: Colors.green, size: 20),
                                      tooltip: 'واتساب',
                                      onPressed: () => _contact(Uri.parse('https://wa.me/${p.phone!.replaceAll('+', '')}'), inv),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.call, color: AppColors.primary, size: 20),
                                      tooltip: 'اتصال',
                                      onPressed: () => _contact(Uri.parse('tel:${p.phone}'), inv),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (i * 35).clamp(0, 350).ms, duration: 260.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String value, String label) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(label: Text(label), selected: _filter == value, onSelected: (_) => setState(() => _filter = value)),
      );
}

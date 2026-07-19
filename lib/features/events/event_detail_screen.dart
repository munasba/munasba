import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/invitee.dart';
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
          title: Text(e.name),
          actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/events/$eventId/edit')),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'duplicate') {
                  await ref.read(eventsProvider.notifier).duplicate(e);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ المناسبة')));
                } else if (v == 'delete') {
                  await ref.read(eventsProvider.notifier).remove(eventId);
                  if (context.mounted) context.pop();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'duplicate', child: Text('نسخ المناسبة')),
                PopupMenuItem(value: 'delete', child: Text('حذف المناسبة')),
              ],
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'المدعوين'),
            Tab(text: 'المهام'),
          ]),
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
}

class _OverviewTab extends ConsumerWidget {
  final String eventId;
  const _OverviewTab({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitees = ref.watch(inviteesProvider(eventId)).valueOrNull ?? [];
    final stats = AttendeeStats.fromInvitees(invitees);
    final matchingEvents = (ref.watch(eventsProvider).valueOrNull ?? []).where((e) => e.id == eventId).toList();
    final event = matchingEvents.isEmpty ? null : matchingEvents.first;
    final peopleById = {for (final p in ref.watch(peopleProvider).valueOrNull ?? []) p.id: p};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            StatCard(value: '${stats.invited}', label: '👤 الأشخاص المدعوون', icon: Icons.people, color: AppColors.primary),
            StatCard(value: '${stats.expected}', label: '👥 الحضور المتوقع', icon: Icons.groups, color: AppColors.gold),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            StatCard(value: '${stats.confirmed}', label: '✅ مؤكدون', icon: Icons.check_circle, color: AppColors.success),
            StatCard(value: '${stats.remaining}', label: '⏳ المتبقون', icon: Icons.hourglass_bottom, color: AppColors.warning),
            StatCard(value: '${stats.percent}%', label: '📈 نسبة الإنجاز', icon: Icons.percent, color: AppColors.secondary),
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
        ),
        const SizedBox(height: 16),
        if (event != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ExcelService.exportEventInvitees(event, invitees, peopleById),
                  icon: const Icon(Icons.table_view_outlined, size: 18),
                  label: const Text('تصدير Excel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => PdfService.printEventReport(event: event, invitees: invitees, peopleById: peopleById),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('تصدير PDF'),
                ),
              ),
            ],
          ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final invitees = ref.watch(inviteesProvider(widget.eventId)).valueOrNull ?? [];
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final peopleById = {for (final p in people) p.id: p};

    var filtered = invitees;
    switch (_filter) {
      case 'remaining':
        filtered = invitees.where((i) => i.rsvpStatus != RsvpStatus.invited).toList();
        break;
      case 'confirmed':
        filtered = invitees.where((i) => i.rsvpStatus == RsvpStatus.invited).toList();
        break;
      case 'alone':
        filtered = invitees.where((i) => i.companions == 1).toList();
        break;
      case 'withGuests':
        filtered = invitees.where((i) => i.companions > 1).toList();
        break;
      case 'large':
        filtered = invitees.where((i) => i.companions >= 5).toList();
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
                      _chip('remaining', 'المتبقون'),
                      _chip('confirmed', 'مؤكدون'),
                      _chip('alone', 'بمفرده'),
                      _chip('withGuests', 'مع مرافقين'),
                      _chip('large', 'مجموعات كبيرة'),
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
                                      onTap: () => ref.read(inviteesProvider(widget.eventId).notifier).updateStatus(inv.id, s),
                                      child: Opacity(
                                        opacity: active ? 1 : 0.4,
                                        child: StatusChip(label: s.label, color: AppColors.rsvpColor(s.key)),
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
                                      onPressed: () => launchUrl(Uri.parse('https://wa.me/${p.phone!.replaceAll('+', '')}')),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.call, color: AppColors.primary, size: 20),
                                      onPressed: () => launchUrl(Uri.parse('tel:${p.phone}')),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
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

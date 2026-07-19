import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/invitee.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/stepper_control.dart';

class InviteePickerScreen extends ConsumerStatefulWidget {
  final String eventId;
  const InviteePickerScreen({super.key, required this.eventId});

  @override
  ConsumerState<InviteePickerScreen> createState() => _InviteePickerScreenState();
}

class _InviteePickerScreenState extends ConsumerState<InviteePickerScreen> {
  final Set<String> _selected = {};
  final Map<String, int> _companions = {};
  final Map<String, RsvpStatus> _rsvp = {};
  String _query = '';
  String? _categoryFilter;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final existingInvitees = ref.watch(inviteesProvider(widget.eventId)).valueOrNull ?? [];

    if (!_initialized && people.isNotEmpty) {
      for (final inv in existingInvitees) {
        _selected.add(inv.personId);
        _companions[inv.personId] = inv.companions;
        _rsvp[inv.personId] = inv.rsvpStatus;
      }
      _initialized = true;
    }

    var filtered = people;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where((p) => p.fullName.toLowerCase().contains(q) || (p.phone ?? '').contains(q)).toList();
    }
    if (_categoryFilter != null) {
      filtered = filtered.where((p) => p.categoryId == _categoryFilter).toList();
    }

    final expectedTotal = _selected.fold<int>(0, (s, pid) => s + (_companions[pid] ?? 1));

    return Scaffold(
      appBar: AppBar(title: const Text('اختيار المدعوين')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text('تحديد الكل (${filtered.length})'),
                        selected: filtered.every((p) => _selected.contains(p.id)) && filtered.isNotEmpty,
                        onSelected: (v) => setState(() {
                          for (final p in filtered) {
                            if (v) {
                              _selected.add(p.id);
                              _companions.putIfAbsent(p.id, () => p.familyMembersCount);
                              _rsvp.putIfAbsent(p.id, () => RsvpStatus.pending);
                            } else {
                              _selected.remove(p.id);
                            }
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String?>(
                      value: _categoryFilter,
                      hint: const Text('الفئة'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('الكل')),
                        ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _categoryFilter = v),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم أو رقم هاتف...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final p = filtered[i];
                final selected = _selected.contains(p.id);
                final comp = _companions[p.id] ?? p.familyMembersCount;
                final rsvp = _rsvp[p.id] ?? RsvpStatus.pending;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: selected,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selected.add(p.id);
                                  _companions.putIfAbsent(p.id, () => p.familyMembersCount);
                                  _rsvp.putIfAbsent(p.id, () => RsvpStatus.pending);
                                } else {
                                  _selected.remove(p.id);
                                }
                              }),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (p.phone != null) Text(p.phone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                ],
                              ),
                            ),
                            _RsvpDropdown(
                              value: rsvp,
                              enabled: selected,
                              onChanged: (v) => setState(() => _rsvp[p.id] = v),
                            ),
                          ],
                        ),
                        if (selected)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('عدد المرافقين', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                                StepperControl(value: comp, onChanged: (v) => setState(() => _companions[p.id] = v)),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text('${_selected.length} شخص محدد · متوقع حضور $expectedTotal')),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(inviteesProvider(widget.eventId).notifier)
                          .setSelected(_selected, _companions, statusByPersonId: _rsvp);
                      ref.invalidate(allInviteesProvider);
                      if (context.mounted) context.go('/events/${widget.eventId}');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('تأكيد الاختيار'),
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

/// Small dropdown chip matching the mockup's "مدعو ⌄" style RSVP selector,
/// shown next to each row in the invitee picker.
class _RsvpDropdown extends StatelessWidget {
  final RsvpStatus value;
  final bool enabled;
  final ValueChanged<RsvpStatus> onChanged;

  const _RsvpDropdown({required this.value, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rsvpColor(value.key);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(100)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<RsvpStatus>(
              value: value,
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, color: color, size: 18),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              dropdownColor: Theme.of(context).cardTheme.color,
              items: RsvpStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: TextStyle(color: AppColors.rsvpColor(s.key)))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ),
    );
  }
}

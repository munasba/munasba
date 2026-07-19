import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/invitee.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../../core/theme/app_colors.dart';

class PersonDetailScreen extends ConsumerWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final person = people.where((p) => p.id == personId).firstOrNull;
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final allInvitees = ref.watch(allInviteesProvider).valueOrNull ?? [];

    if (person == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final history = allInvitees.where((i) => i.personId == personId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(person.fullName),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/people/$personId/edit')),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('حذف الشخص'),
                  content: const Text('هل أنت متأكد من حذف هذا الشخص؟ سيتم حذفه من جميع المناسبات أيضًا.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(peopleProvider.notifier).remove(personId);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundImage: person.photoPath != null ? FileImage(File(person.photoPath!)) : null),
                const SizedBox(height: 10),
                Text(person.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (person.phone != null) Text(person.phone!, style: TextStyle(color: Colors.grey.shade400)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (person.phone != null)
                      IconButton(
                        icon: Icon(Icons.call, color: AppColors.primary),
                        onPressed: () => launchUrl(Uri.parse('tel:${person.phone}')),
                      ),
                    if (person.whatsapp != null)
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.green),
                        onPressed: () => launchUrl(Uri.parse('https://wa.me/${person.whatsapp!.replaceAll('+', '')}')),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('سجل المناسبات', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const EmptyState(message: 'لم يُدعَ لأي مناسبة بعد')
          else
            ...history.map((inv) {
              final event = events.where((e) => e.id == inv.eventId).firstOrNull;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  onTap: event == null ? null : () => context.push('/events/${event.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event?.name ?? 'مناسبة محذوفة', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '${formatDate(event?.date)} · 👥 ${inv.companions} ${inv.companions == 1 ? 'شخص' : 'أشخاص'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(label: inv.rsvpStatus.label, color: AppColors.rsvpColor(inv.rsvpStatus.key)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

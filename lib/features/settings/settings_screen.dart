import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/invitees_repository.dart';
import '../../data/services/excel_service.dart';
import '../../data/services/pdf_service.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('التخصيص'),
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الوضع الليلي'),
                  subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
                  value: settings.themeMode == 'dark',
                  onChanged: (v) => ref.read(settingsProvider.notifier).setThemeMode(v ? 'dark' : 'light'),
                ),
                const Divider(),
                const Align(alignment: Alignment.centerRight, child: Text('لغة التطبيق')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _langChip(ref, settings.language, 'ar', 'العربية'),
                    _langChip(ref, settings.language, 'en', 'English'),
                    _langChip(ref, settings.language, 'ku', 'کوردی'),
                  ],
                ),
                const Divider(),
                const Align(alignment: Alignment.centerRight, child: Text('لون التمييز')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [AppColors.primary, AppColors.secondary, AppColors.success, AppColors.danger, AppColors.gold].map((c) {
                    final selected = settings.accentColorValue == c.value;
                    return GestureDetector(
                      onTap: () => ref.read(settingsProvider.notifier).setAccentColor(c.value),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: selected ? Border.all(color: Colors.white, width: 2) : null),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('البيانات والتصدير'),
          GlassCard(
            child: Column(
              children: [
                _tile(context, Icons.upload_file, 'استيراد من Excel', 'استيراد الأسماء والبيانات من ملف Excel', () => _importExcel(context, ref)),
                const Divider(),
                _tile(context, Icons.file_download, 'تصدير إلى Excel', 'تصدير جميع البيانات إلى ملف Excel', () => _exportExcel(context, ref)),
                const Divider(),
                _tile(context, Icons.picture_as_pdf, 'تصدير إلى PDF', 'تصدير التقارير والقوائم إلى PDF', () => _exportPdf(context, ref)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('الأمان والخصوصية'),
          GlassCard(
            child: _tile(context, Icons.shield_outlined, 'الأمان', 'إدارة إعدادات الأمان والخصوصية', () => context.push('/settings/security')),
          ),
          const SizedBox(height: 18),
          _sectionTitle('التنبيهات والدعم'),
          GlassCard(
            child: Column(
              children: [
                _tile(context, Icons.notifications_outlined, 'الإشعارات', 'إدارة التنبيهات والإشعارات', () {}),
                const Divider(),
                _tile(context, Icons.info_outline, 'عن التطبيق', 'معلومات عن التطبيق والإصدار', () => context.push('/settings/about')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  Future<void> _importExcel(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    final path = result?.files.single.path;
    if (path == null) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جارٍ الاستيراد...')));
    try {
      final count = await ExcelService.importPeopleFromFile(path, ref.read(peopleRepoProvider));
      await ref.read(peopleProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استيراد $count شخص بنجاح')));
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذّر الاستيراد: $err')));
      }
    }
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.people), title: const Text('تصدير الأشخاص'), onTap: () => Navigator.pop(ctx, 'people')),
          ListTile(leading: const Icon(Icons.event), title: const Text('تصدير المناسبات'), onTap: () => Navigator.pop(ctx, 'events')),
        ]),
      ),
    );
    if (choice == null) return;

    final people = ref.read(peopleProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final categoriesById = {for (final c in categories) c.id: c};

    if (choice == 'people') {
      await ExcelService.exportPeople(people, categoriesById);
    } else {
      final events = ref.read(eventsProvider).valueOrNull ?? [];
      final invitees = ref.read(allInviteesProvider).valueOrNull ?? [];
      final statsByEventId = {
        for (final e in events) e.id: AttendeeStats.fromInvitees(invitees.where((i) => i.eventId == e.id).toList()),
      };
      await ExcelService.exportEventsWithStats(events, statsByEventId);
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final people = ref.read(peopleProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final events = ref.read(eventsProvider).valueOrNull ?? [];
    final invitees = ref.read(allInviteesProvider).valueOrNull ?? [];
    await PdfService.printAppReport(people: people, categories: categories, events: events, allInvitees: invitees);
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(alignment: Alignment.centerRight, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
      );

  Widget _langChip(WidgetRef ref, String current, String code, String label) => ChoiceChip(
        label: Text(label),
        selected: current == code,
        onSelected: (_) => ref.read(settingsProvider.notifier).setLanguage(code),
      );

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5)),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      );
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/excel_service.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/person_row.dart';

class PeopleListScreen extends ConsumerWidget {
  const PeopleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final categoriesById = {for (final c in categories) c.id: c};
    final query = ref.watch(peopleSearchQueryProvider);
    final filter = ref.watch(peopleFilterProvider);
    final categoryFilter = ref.watch(peopleFilterCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          tooltip: 'خيارات',
          onSelected: (v) async {
            final allPeople = peopleAsync.valueOrNull ?? [];
            if (v == 'export') {
              await ExcelService.exportPeople(allPeople, categoriesById);
            } else if (v == 'import') {
              await _importFromExcel(context, ref);
            } else if (v == 'categories') {
              context.push('/categories');
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'export', child: Text('تصدير إلى Excel')),
            PopupMenuItem(value: 'import', child: Text('استيراد من Excel')),
            PopupMenuItem(value: 'categories', child: Text('إدارة الفئات')),
          ],
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('الأشخاص', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                SizedBox(width: 6),
                Icon(Icons.people_alt_rounded, size: 20),
              ],
            ),
            Text('إدارة جميع الأشخاص بسهولة',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'التذكيرات',
            onPressed: () => context.push('/tasks'),
          ),
        ],
      ),
      body: peopleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('حدث خطأ: $e')),
        data: (allPeople) {
          var people = allPeople;
          if (query.isNotEmpty) {
            final q = query.toLowerCase();
            people = people.where((p) => p.fullName.toLowerCase().contains(q) || (p.phone ?? '').contains(q)).toList();
          }
          if (filter == 'favorite') people = people.where((p) => p.isFavorite).toList();
          if (filter == 'noCategory') people = people.where((p) => p.categoryId == null).toList();
          if (filter == 'category' && categoryFilter != null) {
            people = people.where((p) => p.categoryId == categoryFilter).toList();
          }

          final calledCount = allPeople.where((p) => p.lastCallStatus == 'called').length;
          final favoriteCount = allPeople.where((p) => p.isFavorite).length;
          final familiesCount = allPeople.where((p) => p.familyMembersCount > 1).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                onChanged: (v) => ref.read(peopleSearchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم أو رقم هاتف...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'فلتر متقدم',
                    onPressed: () => _showAdvancedFilterSheet(context, ref),
                  ),
                  Expanded(
                    child: FilterChipRow(
                      options: const [
                        FilterOption('all', 'الكل'),
                        FilterOption('favorite', 'المفضلة'),
                        FilterOption('category', 'الأقسام'),
                      ],
                      selected: filter,
                      onSelected: (v) => ref.read(peopleFilterProvider.notifier).state = v,
                    ),
                  ),
                ],
              ),
              if (filter == 'category') ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((c) {
                      final color = AppColors.categoryGradients[c.colorIndex % AppColors.categoryGradients.length][0];
                      final selected = categoryFilter == c.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: selected,
                          selectedColor: color.withOpacity(0.35),
                          onSelected: (_) => ref.read(peopleFilterCategoryProvider.notifier).state = c.id,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat('$calledCount', 'تم الاتصال', Icons.call, AppColors.success),
                    _miniStat('$favoriteCount', 'المفضلة', Icons.star_rounded, Colors.amber),
                    _miniStat('$familiesCount', 'العائلات', Icons.groups_rounded, AppColors.secondary),
                    _miniStat('${allPeople.length}', 'إجمالي الأشخاص', Icons.people_alt_rounded, AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (people.isEmpty)
                const EmptyState(icon: Icons.people_outline, message: 'لا يوجد أشخاص مطابقون')
              else
                ...people.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PersonRow(
                        person: p,
                        category: categoriesById[p.categoryId],
                        onTap: () => context.push('/people/${p.id}'),
                        onFavoriteToggle: () => ref.read(peopleProvider.notifier).toggleFavorite(p.id, !p.isFavorite),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (p.whatsapp != null)
                              IconButton(
                                icon: const Icon(Icons.chat, color: Colors.green),
                                onPressed: () => launchUrl(Uri.parse('https://wa.me/${p.whatsapp!.replaceAll('+', '')}')),
                              ),
                            if (p.phone != null)
                              IconButton(
                                icon: Icon(Icons.call, color: Theme.of(context).colorScheme.primary),
                                onPressed: () => launchUrl(Uri.parse('tel:${p.phone}')),
                              ),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') context.push('/people/${p.id}/edit');
                                if (v == 'delete') {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('حذف الشخص'),
                                      content: Text('هل تريد حذف ${p.fullName}؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) await ref.read(peopleProvider.notifier).remove(p.id);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                PopupMenuItem(value: 'delete', child: Text('حذف')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _importFromExcel(BuildContext context, WidgetRef ref) async {
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

  void _showAdvancedFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('فلتر متقدم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('المفضلة فقط'),
                onTap: () {
                  ref.read(peopleFilterProvider.notifier).state = 'favorite';
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('بدون فئة'),
                onTap: () {
                  ref.read(peopleFilterProvider.notifier).state = 'noCategory';
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('إعادة تعيين الفلاتر'),
                onTap: () {
                  ref.read(peopleFilterProvider.notifier).state = 'all';
                  ref.read(peopleFilterCategoryProvider.notifier).state = null;
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon, Color color) => Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 4),
              Icon(icon, size: 15, color: color),
            ],
          ),
        ],
      );
}

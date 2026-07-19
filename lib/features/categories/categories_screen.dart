import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import 'category_form_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final counts = ref.watch(categoryPeopleCountProvider).valueOrNull ?? {};
    final query = ref.watch(categorySearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الفئات')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryFormSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('حدث خطأ: $e')),
        data: (allCategories) {
          final categories = query.isEmpty
              ? allCategories
              : allCategories.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();

          final totalPeople = counts.values.fold<int>(0, (a, b) => a + b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                onChanged: (v) => ref.read(categorySearchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'ابحث عن فئة...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              if (categories.isEmpty)
                const EmptyState(icon: Icons.folder_open, message: 'لا توجد فئات مطابقة')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    final gradientColors = AppColors.categoryGradients[c.colorIndex % AppColors.categoryGradients.length];
                    final count = counts[c.id] ?? 0;
                    return GlassCard(
                      gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      onTap: () => showCategoryFormSheet(context, ref, category: c),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -8,
                            left: -8,
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz, color: Colors.white70, size: 20),
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  showCategoryFormSheet(context, ref, category: c);
                                } else if (v == 'delete') {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('حذف الفئة'),
                                      content: Text('هل تريد حذف "${c.name}"؟ لن يُحذف الأشخاص، فقط ارتباطهم بهذه الفئة.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await ref.read(categoriesProvider.notifier).remove(c.id);
                                    ref.invalidate(categoryPeopleCountProvider);
                                  }
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                PopupMenuItem(value: 'delete', child: Text('حذف')),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(radius: 22, backgroundColor: Colors.white.withOpacity(0.2), child: const Icon(Icons.folder, color: Colors.white)),
                              const SizedBox(height: 10),
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text('$count شخص', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _overviewStat('${allCategories.isEmpty ? 0 : (totalPeople / allCategories.length).round()}', 'متوسط الأشخاص'),
                    _overviewStat('$totalPeople', 'إجمالي الأشخاص'),
                    _overviewStat('${allCategories.length}', 'إجمالي الفئات'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _overviewStat(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      );
}

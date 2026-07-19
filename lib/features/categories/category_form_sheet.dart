import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../providers/providers.dart';

Future<void> showCategoryFormSheet(BuildContext context, WidgetRef ref, {Category? category}) {
  final nameController = TextEditingController(text: category?.name ?? '');
  int colorIndex = category?.colorIndex ?? 0;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(category == null ? 'إضافة فئة جديدة' : 'تعديل الفئة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الفئة')),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerRight, child: Text('اللون')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: List.generate(AppColors.categoryGradients.length, (i) {
                  final selected = colorIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => colorIndex = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: AppColors.categoryGradients[i]),
                        border: selected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  if (category == null) {
                    await ref.read(categoriesProvider.notifier).add(name: name, icon: 'folder', colorIndex: colorIndex);
                  } else {
                    await ref.read(categoriesProvider.notifier).update(category.copyWith(name: name, colorIndex: colorIndex));
                  }
                  ref.invalidate(categoryPeopleCountProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('حفظ'),
              ),
              if (category != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await ref.read(categoriesProvider.notifier).remove(category.id);
                    ref.invalidate(categoryPeopleCountProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('حذف الفئة', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        );
      });
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../data/models/task.dart';
import '../../providers/providers.dart';

Future<void> showTaskFormSheet(BuildContext context, WidgetRef ref, {TaskItem? task, String? eventId}) {
  final titleController = TextEditingController(text: task?.title ?? '');
  DateTime? dueDate = task?.dueDate;
  TaskPriority priority = task?.priority ?? TaskPriority.medium;
  TaskStatus status = task?.status ?? TaskStatus.notStarted;
  String? imagePath = task?.imagePath;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(task == null ? 'إضافة مهمة' : 'تعديل المهمة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (image != null) setState(() => imagePath = image.path);
                },
                child: Container(
                  height: 90,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade600),
                  ),
                  child: imagePath == null
                      ? const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 26))
                      : Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان المهمة')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dueDate == null ? 'تاريخ الاستحقاق' : '${dueDate!.year}-${dueDate!.month}-${dueDate!.day}'),
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerRight, child: Text('الأولوية')),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: TaskPriority.values
                    .map((p) => ChoiceChip(label: Text(p.label), selected: priority == p, onSelected: (_) => setState(() => priority = p)))
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerRight, child: Text('الحالة')),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [TaskStatus.notStarted, TaskStatus.inProgress, TaskStatus.completed, TaskStatus.scheduled]
                    .map((s) => ChoiceChip(label: Text(s.label), selected: status == s, onSelected: (_) => setState(() => status = s)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  if (task == null) {
                    await ref.read(tasksProvider.notifier).add(TaskItem(
                          id: '',
                          eventId: eventId,
                          title: title,
                          dueDate: dueDate,
                          imagePath: imagePath,
                          status: status,
                          priority: priority,
                          createdAt: DateTime.now(),
                        ));
                  } else {
                    await ref.read(tasksProvider.notifier).updateTask(
                          task.copyWith(title: title, dueDate: dueDate, status: status, priority: priority, imagePath: imagePath),
                        );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('حفظ'),
              ),
              if (task != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await ref.read(tasksProvider.notifier).remove(task.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('حذف المهمة', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        );
      });
    },
  );
}

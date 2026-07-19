import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/task.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/status_chip.dart';
import 'task_form_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final String? eventId;
  final bool embedded;
  const TasksScreen({super.key, this.eventId, this.embedded = false});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final tasks = widget.eventId == null ? allTasks : allTasks.where((t) => t.eventId == widget.eventId).toList();

    var filtered = tasks;
    if (_filter == 'completed') filtered = tasks.where((t) => t.effectiveStatus == TaskStatus.completed).toList();
    if (_filter == 'inProgress') filtered = tasks.where((t) => t.effectiveStatus == TaskStatus.inProgress).toList();
    if (_filter == 'overdue') filtered = tasks.where((t) => t.effectiveStatus == TaskStatus.overdue).toList();

    final completed = tasks.where((t) => t.effectiveStatus == TaskStatus.completed).length;
    final inProgress = tasks.where((t) => t.effectiveStatus == TaskStatus.inProgress).length;
    final overdue = tasks.where((t) => t.effectiveStatus == TaskStatus.overdue).length;
    final percent = tasks.isEmpty ? 0.0 : completed / tasks.length;

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 42,
                lineWidth: 8,
                percent: percent,
                center: Text('${(percent * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900)),
                progressColor: AppColors.primary,
                backgroundColor: Colors.grey.shade800,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تقدم المهام', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('تم إنجاز $completed من ${tasks.length} مهمة', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _miniStat('${tasks.length}', 'إجمالي', AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('$completed', 'مكتملة', AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('$inProgress', 'قيد التنفيذ', AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('$overdue', 'متأخرة', AppColors.danger)),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('all', 'الكل'),
              _chip('inProgress', 'قيد التنفيذ'),
              _chip('completed', 'مكتملة'),
              _chip('overdue', 'متأخرة'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('لا توجد مهام', style: TextStyle(color: Colors.grey))))
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              final reordered = List<TaskItem>.from(filtered);
              if (newIndex > oldIndex) newIndex -= 1;
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              ref.read(tasksProvider.notifier).reorder(reordered);
            },
            children: filtered.map((t) => _TaskRow(key: ValueKey(t.id), task: t)).toList(),
          ),
      ],
    );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'task-add-${widget.eventId}',
              onPressed: () => showTaskFormSheet(context, ref, eventId: widget.eventId),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('قائمة المهام')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTaskFormSheet(context, ref, eventId: widget.eventId),
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(label: Text(label), selected: _filter == value, onSelected: (_) => setState(() => _filter = value)),
      );
}

class _TaskRow extends ConsumerWidget {
  final TaskItem task;
  const _TaskRow({super.key, required this.task});

  Color get _priorityColor => switch (task.priority) {
        TaskPriority.high => AppColors.danger,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.low => AppColors.secondary,
      };

  Color get _statusColor => switch (task.effectiveStatus) {
        TaskStatus.completed => AppColors.success,
        TaskStatus.inProgress => AppColors.warning,
        TaskStatus.overdue => AppColors.danger,
        TaskStatus.scheduled => AppColors.secondary,
        TaskStatus.notStarted => AppColors.pending,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        onTap: () => showTaskFormSheet(context, ref, task: task),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Colors.grey),
            const SizedBox(width: 6),
            if (task.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(task.imagePath!), width: 44, height: 44, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (task.dueDate != null)
                    Text('${task.dueDate!.year}-${task.dueDate!.month}-${task.dueDate!.day}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [
                    StatusChip(label: task.effectiveStatus.label, color: _statusColor),
                    StatusChip(label: task.priority.label, color: _priorityColor),
                  ]),
                ],
              ),
            ),
            Checkbox(
              value: task.status == TaskStatus.completed,
              onChanged: (v) => ref
                  .read(tasksProvider.notifier)
                  .updateTask(task.copyWith(status: v == true ? TaskStatus.completed : TaskStatus.inProgress)),
            ),
          ],
        ),
      ),
    );
  }
}

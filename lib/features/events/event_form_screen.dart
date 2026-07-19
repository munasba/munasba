import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/event.dart';
import '../../providers/providers.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const EventFormScreen({super.key, this.eventId});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'wedding';
  DateTime? _date;
  TimeOfDay? _time;
  int _colorIndex = 0;
  String? _coverImagePath;
  bool _loaded = false;
  EventItem? _editing;

  bool get isEdit => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      Future.microtask(() async {
        final event = await ref.read(eventsRepoProvider).getById(widget.eventId!);
        if (event != null && mounted) {
          setState(() {
            _editing = event;
            _nameController.text = event.name;
            _locationController.text = event.location ?? '';
            _notesController.text = event.notes ?? '';
            _type = event.type;
            _date = event.date;
            if (event.time != null) {
              final parts = event.time!.split(':');
              if (parts.length == 2) {
                _time = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
              }
            }
            _colorIndex = event.colorIndex;
            _coverImagePath = event.coverImagePath;
            _loaded = true;
          });
        }
      });
    } else {
      _loaded = true;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _coverImagePath = image.path);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم المناسبة')));
      return;
    }
    final timeStr = _time == null ? null : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

    final draft = EventItem(
      id: _editing?.id ?? '',
      name: name,
      type: _type,
      date: _date,
      time: timeStr,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      colorIndex: _colorIndex,
      coverImagePath: _coverImagePath,
      archived: _editing?.archived ?? false,
      createdAt: _editing?.createdAt ?? DateTime.now(),
    );

    if (isEdit && _editing != null) {
      await ref.read(eventsProvider.notifier).updateEvent(draft);
      if (mounted) context.pop();
    } else {
      final created = await ref.read(eventsProvider.notifier).add(draft);
      if (mounted) context.pushReplacement('/events/${created.id}/invitees');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'تعديل المناسبة' : 'إنشاء مناسبة جديدة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم المناسبة *')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'نوع المناسبة'),
            items: kEventTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_date == null ? 'اختر التاريخ' : '${_date!.year}-${_date!.month}-${_date!.day}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_time == null ? 'اختر الوقت' : _time!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'الموقع')),
          const SizedBox(height: 12),
          TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات إضافية')),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerRight, child: Text('لون المناسبة')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: List.generate(AppColors.eventColors.length, (i) {
              final selected = _colorIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = i),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.eventColors[i],
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickCover,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: _coverImagePath == null
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.add_photo_alternate_outlined, size: 30), SizedBox(height: 6), Text('اضغط لإضافة صورة الغلاف')],
                    )
                  : Text('تم اختيار صورة: ${_coverImagePath!.split('/').last}', textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('حفظ المناسبة')),
        ],
      ),
    );
  }
}

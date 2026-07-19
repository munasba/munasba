import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/person.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/stepper_control.dart';

class PersonFormScreen extends ConsumerStatefulWidget {
  final String? personId;
  const PersonFormScreen({super.key, this.personId});

  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen> {
  final _fullNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String? _categoryId;
  int _familyMembersCount = 1;
  String? _photoPath;
  bool _loaded = false;
  Person? _editing;

  bool get isEdit => widget.personId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      Future.microtask(() async {
        final person = await ref.read(peopleRepoProvider).getById(widget.personId!);
        if (person != null && mounted) {
          setState(() {
            _editing = person;
            _fullNameController.text = person.fullName;
            _shortNameController.text = person.shortName ?? '';
            _phoneController.text = person.phone ?? '';
            _whatsappController.text = person.whatsapp ?? '';
            _addressController.text = person.address ?? '';
            _notesController.text = person.notes ?? '';
            _categoryId = person.categoryId;
            _familyMembersCount = person.familyMembersCount;
            _photoPath = person.photoPath;
            _loaded = true;
          });
        }
      });
    } else {
      _loaded = true;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => _photoPath = image.path);
  }

  Future<void> _save() async {
    final name = _fullNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال الاسم الكامل')));
      return;
    }
    final draft = Person(
      id: _editing?.id ?? '',
      fullName: name,
      shortName: _shortNameController.text.trim().isEmpty ? null : _shortNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      categoryId: _categoryId,
      familyMembersCount: _familyMembersCount,
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      photoPath: _photoPath,
      isFavorite: _editing?.isFavorite ?? false,
      createdAt: _editing?.createdAt ?? DateTime.now(),
    );

    if (isEdit && _editing != null) {
      await ref.read(peopleProvider.notifier).update(draft);
    } else {
      await ref.read(peopleProvider.notifier).add(draft);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'تعديل شخص' : 'إضافة شخص')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 44,
                backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                child: _photoPath == null ? const Icon(Icons.add_a_photo, size: 28) : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'الاسم الكامل *')),
          const SizedBox(height: 12),
          TextField(controller: _shortNameController, decoration: const InputDecoration(labelText: 'الاسم المختصر (اختياري)')),
          const SizedBox(height: 12),
          TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          const SizedBox(height: 12),
          TextField(controller: _whatsappController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'واتساب')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categoryId,
            decoration: const InputDecoration(labelText: 'الفئة'),
            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('عدد أفراد العائلة'),
              StepperControl(value: _familyMembersCount, onChanged: (v) => setState(() => _familyMembersCount = v)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'العنوان')),
          const SizedBox(height: 12),
          TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('حفظ الشخص')),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../data/models/person.dart';
import '../../data/repositories/people_repository.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stepper_control.dart';
import '../categories/category_form_sheet.dart';

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
  DateTime? _birthday;
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
            _birthday = person.birthday;
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
      birthday: _birthday,
      createdAt: _editing?.createdAt ?? DateTime.now(),
    );

    if (isEdit && _editing != null) {
      await ref.read(peopleProvider.notifier).updatePerson(draft);
      if (mounted) context.pop();
      return;
    }

    // كشف تكرار مبكر: إذا رقم الهاتف يطابق شخصًا موجودًا مسبقًا، نسأل قبل ما
    // ننشئ سجل مكرر يحتاج دمج لاحقًا من شاشة الأشخاص.
    if (draft.phone != null && draft.phone!.isNotEmpty) {
      final existingPeople = ref.read(peopleProvider).valueOrNull ?? [];
      final normalized = PeopleRepository.normalizePhone(draft.phone);
      Person? match;
      for (final p in existingPeople) {
        if (PeopleRepository.normalizePhone(p.phone) == normalized) {
          match = p;
          break;
        }
      }
      if (match != null && mounted) {
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('يوجد شخص بنفس الرقم'),
            content: Text('"${match!.fullName}" مسجّل بنفس رقم الهاتف. هل تريد المتابعة وإضافته كشخص جديد على أي حال، أم فتح ملفه الموجود؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(ctx, 'open'), child: const Text('فتح الملف الموجود')),
              TextButton(onPressed: () => Navigator.pop(ctx, 'continue'), child: const Text('إضافة على أي حال')),
            ],
          ),
        );
        if (choice == 'cancel' || choice == null) return;
        if (choice == 'open') {
          if (mounted) context.pushReplacement('/people/${match.id}/edit');
          return;
        }
        // choice == 'continue' يكمل الحفظ العادي بالأسفل
      }
    }

    await ref.read(peopleProvider.notifier).add(draft);
    if (mounted) context.pop();
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('اختر الفئة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await showCategoryFormSheet(context, ref);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('فئة جديدة'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('بدون فئة'),
                    selected: _categoryId == null,
                    onSelected: (_) => Navigator.pop(ctx, ''),
                  ),
                  ...categories.map((c) {
                    final color = AppColors.categoryGradients[c.colorIndex % AppColors.categoryGradients.length][0];
                    return ChoiceChip(
                      avatar: CircleAvatar(backgroundColor: color, radius: 8),
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      selectedColor: color.withOpacity(0.35),
                      onSelected: (_) => Navigator.pop(ctx, c.id),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) setState(() => _categoryId = chosen.isEmpty ? null : chosen);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    Category? selectedCategory;
    for (final c in categories) {
      if (c.id == _categoryId) {
        selectedCategory = c;
        break;
      }
    }

    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? 'تعديل شخص' : 'إضافة شخص',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text(isEdit ? 'حدّث بيانات هذا الشخص' : 'أضف شخص جديد إلى جهاتك',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _photoPath == null
                          ? LinearGradient(colors: AppColors.categoryGradients[0])
                          : null,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: _photoPath != null
                        ? ClipOval(child: Image.file(File(_photoPath!), fit: BoxFit.cover))
                        : const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الصورة الشخصية', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('اضغط لإضافة صورة شخصية', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('JPG, PNG • حتى 5MB', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          _fieldCard(
            icon: Icons.person_outline,
            label: 'الاسم الكامل',
            required: true,
            child: TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'ادخل الاسم الكامل'),
            ),
          ),
          const SizedBox(height: 10),
          _fieldCard(
            icon: Icons.badge_outlined,
            label: 'الاسم المختصر (اختياري)',
            child: TextField(
              controller: _shortNameController,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'أدخل الاسم المختصر'),
            ),
          ),
          const SizedBox(height: 10),
          _fieldCard(
            icon: Icons.call_outlined,
            label: 'رقم الهاتف',
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'أدخل رقم الهاتف'),
            ),
          ),
          const SizedBox(height: 10),
          _fieldCard(
            icon: Icons.chat,
            iconColor: Colors.green,
            label: 'واتساب',
            child: TextField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'أدخل رقم واتساب'),
            ),
          ),
          const SizedBox(height: 10),
          _fieldCard(
            icon: Icons.folder_outlined,
            label: 'الفئة',
            required: true,
            onTap: () => _pickCategory(categories),
            child: Row(
              children: [
                if (selectedCategory != null) ...[
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: AppColors
                        .categoryGradients[selectedCategory.colorIndex % AppColors.categoryGradients.length][0],
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    selectedCategory?.name ?? 'اختر الفئة',
                    style: TextStyle(color: selectedCategory == null ? Colors.grey.shade500 : null),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _fieldCard(
            icon: Icons.people_alt_outlined,
            label: 'عدد أفراد العائلة',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StepperControl(value: _familyMembersCount, onChanged: (v) => setState(() => _familyMembersCount = v)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _fieldCard(
            icon: Icons.cake_outlined,
            iconColor: Colors.orangeAccent,
            label: 'تاريخ الميلاد (اختياري)',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthday ?? DateTime(DateTime.now().year - 20),
                firstDate: DateTime(1930),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _birthday = picked);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _birthday == null
                        ? 'اختر تاريخ الميلاد'
                        : '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(color: _birthday == null ? Colors.grey.shade500 : null),
                  ),
                ),
                if (_birthday != null)
                  GestureDetector(
                    onTap: () => setState(() => _birthday = null),
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                  )
                else
                  Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade500),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _fieldCard(
            icon: Icons.location_on_outlined,
            iconColor: Colors.pinkAccent,
            label: 'العنوان',
            child: TextField(
              controller: _addressController,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'أدخل العنوان بالتفصيل'),
            ),
          ),
          const SizedBox(height: 10),
          _fieldCard(
            icon: Icons.notes_outlined,
            label: 'ملاحظات (اختياري)',
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'أضف أي ملاحظات إضافية'),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ الشخص', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 350.ms).scaleXY(begin: 0.92, end: 1, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _fieldCard({
    required IconData icon,
    required String label,
    required Widget child,
    Color? iconColor,
    bool required = false,
    VoidCallback? onTap,
  }) {
    final content = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400)),
                    if (required) const Text(' •', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
    return content;
  }
}

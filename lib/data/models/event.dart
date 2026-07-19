class EventItem {
  final String id;
  final String name;
  final String type; // wedding | birthday | graduation | condolence | meeting | other
  final DateTime? date;
  final String? time; // stored as free text "HH:mm" to keep this file dependency-free
  final String? location;
  final String? notes;
  final int colorIndex; // index into AppColors.eventColors
  final String? coverImagePath;
  final bool archived;
  final DateTime createdAt;

  const EventItem({
    required this.id,
    required this.name,
    required this.type,
    this.date,
    this.time,
    this.location,
    this.notes,
    this.colorIndex = 0,
    this.coverImagePath,
    this.archived = false,
    required this.createdAt,
  });

  bool get isOver => date != null && date!.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'date': date?.toIso8601String(),
        'time': time,
        'location': location,
        'notes': notes,
        'colorIndex': colorIndex,
        'coverImagePath': coverImagePath,
        'archived': archived ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory EventItem.fromMap(Map<String, Object?> map) => EventItem(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
        time: map['time'] as String?,
        location: map['location'] as String?,
        notes: map['notes'] as String?,
        colorIndex: (map['colorIndex'] as int?) ?? 0,
        coverImagePath: map['coverImagePath'] as String?,
        archived: (map['archived'] as int?) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  EventItem copyWith({
    String? name,
    String? type,
    DateTime? date,
    String? time,
    String? location,
    String? notes,
    int? colorIndex,
    String? coverImagePath,
    bool? archived,
  }) =>
      EventItem(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        date: date ?? this.date,
        time: time ?? this.time,
        location: location ?? this.location,
        notes: notes ?? this.notes,
        colorIndex: colorIndex ?? this.colorIndex,
        coverImagePath: coverImagePath ?? this.coverImagePath,
        archived: archived ?? this.archived,
        createdAt: createdAt,
      );
}

/// Fixed set of event types shown in the "نوع المناسبة" dropdown.
const kEventTypes = <String, String>{
  'wedding': 'زفاف',
  'birthday': 'عيد ميلاد',
  'graduation': 'تخرج',
  'condolence': 'عزاء',
  'engagement': 'خطوبة',
  'meeting': 'اجتماع',
  'other': 'أخرى',
};

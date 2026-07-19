enum TaskStatus { notStarted, inProgress, completed, scheduled, overdue }

extension TaskStatusX on TaskStatus {
  String get key => toString().split('.').last;

  String get label => switch (this) {
        TaskStatus.notStarted => 'لم تبدأ',
        TaskStatus.inProgress => 'قيد التنفيذ',
        TaskStatus.completed => 'مكتملة',
        TaskStatus.scheduled => 'مجدولة',
        TaskStatus.overdue => 'متأخرة',
      };

  static TaskStatus fromKey(String key) => TaskStatus.values.firstWhere(
        (e) => e.key == key,
        orElse: () => TaskStatus.notStarted,
      );
}

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get key => toString().split('.').last;

  String get label => switch (this) {
        TaskPriority.low => 'منخفضة',
        TaskPriority.medium => 'متوسطة',
        TaskPriority.high => 'عالية',
      };

  static TaskPriority fromKey(String key) => TaskPriority.values.firstWhere(
        (e) => e.key == key,
        orElse: () => TaskPriority.medium,
      );
}

class TaskItem {
  final String id;
  final String? eventId;
  final String title;
  final DateTime? dueDate;
  final String? imagePath;
  final TaskStatus status;
  final TaskPriority priority;
  final int sortOrder;
  final DateTime createdAt;

  const TaskItem({
    required this.id,
    this.eventId,
    required this.title,
    this.dueDate,
    this.imagePath,
    this.status = TaskStatus.notStarted,
    this.priority = TaskPriority.medium,
    this.sortOrder = 0,
    required this.createdAt,
  });

  /// Effective status: a non-completed task past its due date reads as overdue,
  /// without needing a background job to flip the stored value.
  TaskStatus get effectiveStatus {
    if (status == TaskStatus.completed) return TaskStatus.completed;
    if (dueDate != null && dueDate!.isBefore(DateTime.now())) return TaskStatus.overdue;
    return status;
  }

  TaskItem copyWith({
    String? title,
    DateTime? dueDate,
    String? imagePath,
    TaskStatus? status,
    TaskPriority? priority,
    int? sortOrder,
  }) =>
      TaskItem(
        id: id,
        eventId: eventId,
        title: title ?? this.title,
        dueDate: dueDate ?? this.dueDate,
        imagePath: imagePath ?? this.imagePath,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'eventId': eventId,
        'title': title,
        'dueDate': dueDate?.toIso8601String(),
        'imagePath': imagePath,
        'status': status.key,
        'priority': priority.key,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TaskItem.fromMap(Map<String, Object?> map) => TaskItem(
        id: map['id'] as String,
        eventId: map['eventId'] as String?,
        title: map['title'] as String,
        dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
        imagePath: map['imagePath'] as String?,
        status: TaskStatusX.fromKey(map['status'] as String? ?? 'notStarted'),
        priority: TaskPriorityX.fromKey(map['priority'] as String? ?? 'medium'),
        sortOrder: (map['sortOrder'] as int?) ?? 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

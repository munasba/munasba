class Category {
  final String id;
  final String name;
  final String icon; // Material icon name key, resolved in the UI layer
  final int colorIndex; // index into AppColors.categoryGradients
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    required this.createdAt,
  });

  Category copyWith({String? name, String? icon, int? colorIndex}) => Category(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        colorIndex: colorIndex ?? this.colorIndex,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'colorIndex': colorIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String,
        colorIndex: map['colorIndex'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

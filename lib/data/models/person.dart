class Person {
  final String id;
  final String fullName;
  final String? shortName;
  final String? phone;
  final String? whatsapp;
  final String? categoryId;
  final int familyMembersCount; // حجم عائلة الشخص، يُستخدم كقيمة افتراضية للمرافقين بالمناسبات
  final String? address;
  final String? notes;
  final String? photoPath;
  final bool isFavorite;
  final String? lastCallStatus; // 'called' | 'notcalled' | null
  final DateTime? lastCallDate;
  final DateTime? birthday;
  final DateTime createdAt;

  const Person({
    required this.id,
    required this.fullName,
    this.shortName,
    this.phone,
    this.whatsapp,
    this.categoryId,
    this.familyMembersCount = 1,
    this.address,
    this.notes,
    this.photoPath,
    this.isFavorite = false,
    this.lastCallStatus,
    this.lastCallDate,
    this.birthday,
    required this.createdAt,
  });

  Person copyWith({
    String? fullName,
    String? shortName,
    String? phone,
    String? whatsapp,
    String? categoryId,
    int? familyMembersCount,
    String? address,
    String? notes,
    String? photoPath,
    bool? isFavorite,
    String? lastCallStatus,
    DateTime? lastCallDate,
    DateTime? birthday,
  }) =>
      Person(
        id: id,
        fullName: fullName ?? this.fullName,
        shortName: shortName ?? this.shortName,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        categoryId: categoryId ?? this.categoryId,
        familyMembersCount: familyMembersCount ?? this.familyMembersCount,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        photoPath: photoPath ?? this.photoPath,
        isFavorite: isFavorite ?? this.isFavorite,
        lastCallStatus: lastCallStatus ?? this.lastCallStatus,
        lastCallDate: lastCallDate ?? this.lastCallDate,
        birthday: birthday ?? this.birthday,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'fullName': fullName,
        'shortName': shortName,
        'phone': phone,
        'whatsapp': whatsapp,
        'categoryId': categoryId,
        'familyMembersCount': familyMembersCount,
        'address': address,
        'notes': notes,
        'photoPath': photoPath,
        'isFavorite': isFavorite ? 1 : 0,
        'lastCallStatus': lastCallStatus,
        'lastCallDate': lastCallDate?.toIso8601String(),
        'birthday': birthday?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Person.fromMap(Map<String, Object?> map) => Person(
        id: map['id'] as String,
        fullName: map['fullName'] as String,
        shortName: map['shortName'] as String?,
        phone: map['phone'] as String?,
        whatsapp: map['whatsapp'] as String?,
        categoryId: map['categoryId'] as String?,
        familyMembersCount: (map['familyMembersCount'] as int?) ?? 1,
        address: map['address'] as String?,
        notes: map['notes'] as String?,
        photoPath: map['photoPath'] as String?,
        isFavorite: (map['isFavorite'] as int?) == 1,
        lastCallStatus: map['lastCallStatus'] as String?,
        lastCallDate: map['lastCallDate'] != null ? DateTime.parse(map['lastCallDate'] as String) : null,
        birthday: map['birthday'] != null ? DateTime.parse(map['birthday'] as String) : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

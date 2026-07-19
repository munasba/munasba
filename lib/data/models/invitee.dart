/// Four-state RSVP status shown in the "اختيار المدعوين" screen.
enum RsvpStatus { invited, notContacted, declined, pending }

extension RsvpStatusX on RsvpStatus {
  String get key => toString().split('.').last;

  String get label => switch (this) {
        RsvpStatus.invited => 'مدعو',
        RsvpStatus.notContacted => 'لم يتم التواصل',
        RsvpStatus.declined => 'معتذر',
        RsvpStatus.pending => 'قيد الانتظار',
      };

  static RsvpStatus fromKey(String key) => RsvpStatus.values.firstWhere(
        (e) => e.key == key,
        orElse: () => RsvpStatus.pending,
      );
}

class Invitee {
  final String id;
  final String eventId;
  final String personId;
  final RsvpStatus rsvpStatus;
  final int companions; // إجمالي عدد الحاضرين مع هذا المدعو (شامل نفسه)، افتراضي = حجم عائلته
  final DateTime? calledAt;
  final String? notes;

  const Invitee({
    required this.id,
    required this.eventId,
    required this.personId,
    this.rsvpStatus = RsvpStatus.pending,
    this.companions = 1,
    this.calledAt,
    this.notes,
  });

  bool get called => rsvpStatus == RsvpStatus.invited;

  Invitee copyWith({RsvpStatus? rsvpStatus, int? companions, DateTime? calledAt, String? notes}) => Invitee(
        id: id,
        eventId: eventId,
        personId: personId,
        rsvpStatus: rsvpStatus ?? this.rsvpStatus,
        companions: companions ?? this.companions,
        calledAt: calledAt ?? this.calledAt,
        notes: notes ?? this.notes,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'eventId': eventId,
        'personId': personId,
        'rsvpStatus': rsvpStatus.key,
        'companions': companions,
        'calledAt': calledAt?.toIso8601String(),
        'notes': notes,
      };

  factory Invitee.fromMap(Map<String, Object?> map) => Invitee(
        id: map['id'] as String,
        eventId: map['eventId'] as String,
        personId: map['personId'] as String,
        rsvpStatus: RsvpStatusX.fromKey(map['rsvpStatus'] as String? ?? 'pending'),
        companions: (map['companions'] as int?) ?? 1,
        calledAt: map['calledAt'] != null ? DateTime.parse(map['calledAt'] as String) : null,
        notes: map['notes'] as String?,
      );
}

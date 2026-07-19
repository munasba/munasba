import 'package:uuid/uuid.dart';
import '../local/app_database.dart';
import '../models/invitee.dart';

class AttendeeStats {
  final int invited; // عدد المدعوين (سجلات)
  final int expected; // إجمالي الحضور المتوقع (مجموع companions)
  final int confirmed; // عدد من حالتهم "مدعو/مؤكد"
  final int notContacted;
  final int declined;
  final int pending;

  const AttendeeStats({
    required this.invited,
    required this.expected,
    required this.confirmed,
    required this.notContacted,
    required this.declined,
    required this.pending,
  });

  int get remaining => invited - confirmed;
  int get percent => invited == 0 ? 0 : ((confirmed / invited) * 100).round();

  factory AttendeeStats.fromInvitees(List<Invitee> invitees) {
    final invited = invitees.length;
    final expected = invitees.fold<int>(0, (sum, i) => sum + i.companions);
    final confirmed = invitees.where((i) => i.rsvpStatus == RsvpStatus.invited).length;
    final notContacted = invitees.where((i) => i.rsvpStatus == RsvpStatus.notContacted).length;
    final declined = invitees.where((i) => i.rsvpStatus == RsvpStatus.declined).length;
    final pending = invitees.where((i) => i.rsvpStatus == RsvpStatus.pending).length;
    return AttendeeStats(
      invited: invited,
      expected: expected,
      confirmed: confirmed,
      notContacted: notContacted,
      declined: declined,
      pending: pending,
    );
  }
}

class InviteesRepository {
  final _uuid = const Uuid();

  Future<List<Invitee>> getByEvent(String eventId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('invitees', where: 'eventId = ?', whereArgs: [eventId]);
    return rows.map(Invitee.fromMap).toList();
  }

  Future<List<Invitee>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('invitees');
    return rows.map(Invitee.fromMap).toList();
  }

  /// Adds or updates the invitee for [personId] in [eventId], defaulting the
  /// companions count to the person's family size unless overridden.
  Future<Invitee> upsert({
    required String eventId,
    required String personId,
    required int companions,
    RsvpStatus rsvpStatus = RsvpStatus.pending,
  }) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query(
      'invitees',
      where: 'eventId = ? AND personId = ?',
      whereArgs: [eventId, personId],
    );
    if (existing.isNotEmpty) {
      final inv = Invitee.fromMap(existing.first).copyWith(companions: companions, rsvpStatus: rsvpStatus);
      await db.update('invitees', inv.toMap(), where: 'id = ?', whereArgs: [inv.id]);
      return inv;
    }
    final inv = Invitee(
      id: _uuid.v4(),
      eventId: eventId,
      personId: personId,
      companions: companions,
      rsvpStatus: rsvpStatus,
    );
    await db.insert('invitees', inv.toMap());
    return inv;
  }

  Future<void> updateStatus(String inviteeId, RsvpStatus status) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'invitees',
      {
        'rsvpStatus': status.key,
        'calledAt': status == RsvpStatus.invited ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [inviteeId],
    );
  }

  Future<void> updateCompanions(String inviteeId, int companions) async {
    final db = await AppDatabase.instance.database;
    await db.update('invitees', {'companions': companions}, where: 'id = ?', whereArgs: [inviteeId]);
  }

  Future<void> remove(String eventId, String personId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('invitees', where: 'eventId = ? AND personId = ?', whereArgs: [eventId, personId]);
  }

  Future<void> removeById(String inviteeId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('invitees', where: 'id = ?', whereArgs: [inviteeId]);
  }
}

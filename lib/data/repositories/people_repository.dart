import 'package:uuid/uuid.dart';
import '../local/app_database.dart';
import '../models/person.dart';

class PeopleRepository {
  final _uuid = const Uuid();

  Future<List<Person>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('people', orderBy: 'fullName ASC');
    return rows.map(Person.fromMap).toList();
  }

  Future<Person?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('people', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Person.fromMap(rows.first);
  }

  Future<Person> create(Person draft) async {
    final db = await AppDatabase.instance.database;
    final person = Person(
      id: _uuid.v4(),
      fullName: draft.fullName,
      shortName: draft.shortName,
      phone: draft.phone,
      whatsapp: draft.whatsapp,
      categoryId: draft.categoryId,
      familyMembersCount: draft.familyMembersCount,
      address: draft.address,
      notes: draft.notes,
      photoPath: draft.photoPath,
      birthday: draft.birthday,
      createdAt: DateTime.now(),
    );
    await db.insert('people', person.toMap());
    return person;
  }

  Future<void> update(Person person) async {
    final db = await AppDatabase.instance.database;
    await db.update('people', person.toMap(), where: 'id = ?', whereArgs: [person.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('people', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleFavorite(String id, bool value) async {
    final db = await AppDatabase.instance.database;
    await db.update('people', {'isFavorite': value ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  /// Digits-only phone form used to compare numbers regardless of spaces,
  /// dashes, or a leading "+964"/"0" formatting difference.
  static String normalizePhone(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Groups people who share the same phone number (2+ records), so the
  /// "دمج الأشخاص المكررين" tool can offer to merge each group into one.
  static List<List<Person>> findDuplicateGroups(List<Person> people) {
    final byPhone = <String, List<Person>>{};
    for (final p in people) {
      final key = normalizePhone(p.phone);
      if (key.isEmpty) continue;
      byPhone.putIfAbsent(key, () => []).add(p);
    }
    return byPhone.values.where((g) => g.length > 1).toList();
  }

  /// Merges [removeId] into [keepId]: any event invitation the duplicate had
  /// is moved over to the kept person (unless the kept person is already
  /// invited to that same event, in which case the duplicate's invitation is
  /// simply dropped to avoid two rows for one guest), then the duplicate
  /// record itself is deleted. Runs in a single transaction so a crash
  /// mid-merge can't leave an invitee pointing at a person that no longer exists.
  Future<void> mergeInto({required String keepId, required String removeId}) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final theirInvites = await txn.query('invitees', where: 'personId = ?', whereArgs: [removeId]);
      for (final row in theirInvites) {
        final eventId = row['eventId'] as String;
        final alreadyInvited = await txn.query(
          'invitees',
          where: 'personId = ? AND eventId = ?',
          whereArgs: [keepId, eventId],
        );
        if (alreadyInvited.isEmpty) {
          await txn.update('invitees', {'personId': keepId}, where: 'id = ?', whereArgs: [row['id']]);
        } else {
          await txn.delete('invitees', where: 'id = ?', whereArgs: [row['id']]);
        }
      }
      await txn.delete('people', where: 'id = ?', whereArgs: [removeId]);
    });
  }
}

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
}

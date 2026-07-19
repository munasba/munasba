import 'package:uuid/uuid.dart';
import '../local/app_database.dart';
import '../models/event.dart';

class EventsRepository {
  final _uuid = const Uuid();

  Future<List<EventItem>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('events', orderBy: 'date ASC');
    return rows.map(EventItem.fromMap).toList();
  }

  Future<EventItem?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('events', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return EventItem.fromMap(rows.first);
  }

  Future<EventItem> create(EventItem draft) async {
    final db = await AppDatabase.instance.database;
    final event = EventItem(
      id: _uuid.v4(),
      name: draft.name,
      type: draft.type,
      date: draft.date,
      time: draft.time,
      location: draft.location,
      notes: draft.notes,
      colorIndex: draft.colorIndex,
      coverImagePath: draft.coverImagePath,
      createdAt: DateTime.now(),
    );
    await db.insert('events', event.toMap());
    return event;
  }

  Future<void> update(EventItem event) async {
    final db = await AppDatabase.instance.database;
    await db.update('events', event.toMap(), where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<EventItem> duplicate(EventItem source) async {
    final db = await AppDatabase.instance.database;
    final copy = EventItem(
      id: _uuid.v4(),
      name: '${source.name} (نسخة)',
      type: source.type,
      date: source.date,
      time: source.time,
      location: source.location,
      notes: source.notes,
      colorIndex: source.colorIndex,
      coverImagePath: source.coverImagePath,
      createdAt: DateTime.now(),
    );
    await db.insert('events', copy.toMap());
    return copy;
  }
}

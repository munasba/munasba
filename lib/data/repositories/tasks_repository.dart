import 'package:uuid/uuid.dart';
import '../local/app_database.dart';
import '../models/task.dart';

class TasksRepository {
  final _uuid = const Uuid();

  Future<List<TaskItem>> getAll({String? eventId}) async {
    final db = await AppDatabase.instance.database;
    final rows = eventId == null
        ? await db.query('tasks', orderBy: 'sortOrder ASC')
        : await db.query('tasks', where: 'eventId = ?', whereArgs: [eventId], orderBy: 'sortOrder ASC');
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<TaskItem> create(TaskItem draft) async {
    final db = await AppDatabase.instance.database;
    final countResult = await db.rawQuery('SELECT COUNT(*) as c FROM tasks');
    final nextOrder = (countResult.first['c'] as int?) ?? 0;
    final task = TaskItem(
      id: _uuid.v4(),
      eventId: draft.eventId,
      title: draft.title,
      dueDate: draft.dueDate,
      imagePath: draft.imagePath,
      status: draft.status,
      priority: draft.priority,
      sortOrder: nextOrder,
      createdAt: DateTime.now(),
    );
    await db.insert('tasks', task.toMap());
    return task;
  }

  Future<void> update(TaskItem task) async {
    final db = await AppDatabase.instance.database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Persists a new drag-and-drop order for a full task list.
  Future<void> reorder(List<TaskItem> orderedTasks) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (var i = 0; i < orderedTasks.length; i++) {
      batch.update('tasks', {'sortOrder': i}, where: 'id = ?', whereArgs: [orderedTasks[i].id]);
    }
    await batch.commit(noResult: true);
  }
}

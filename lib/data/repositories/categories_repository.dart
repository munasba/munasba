import 'package:uuid/uuid.dart';
import '../local/app_database.dart';
import '../models/category.dart';

class CategoriesRepository {
  final _uuid = const Uuid();

  Future<List<Category>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('categories', orderBy: 'createdAt ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<Category> create({required String name, required String icon, required int colorIndex}) async {
    final db = await AppDatabase.instance.database;
    final category = Category(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
    await db.insert('categories', category.toMap());
    return category;
  }

  Future<void> update(Category category) async {
    final db = await AppDatabase.instance.database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  /// Number of people currently assigned to each category id.
  Future<Map<String, int>> peopleCountByCategory() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT categoryId, COUNT(*) as cnt FROM people WHERE categoryId IS NOT NULL GROUP BY categoryId',
    );
    return {for (final r in rows) r['categoryId'] as String: r['cnt'] as int};
  }
}

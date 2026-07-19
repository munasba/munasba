import '../local/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  Future<AppSettingsModel> get() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('app_settings', where: "id = 'app'");
    if (rows.isEmpty) {
      const defaults = AppSettingsModel();
      await db.insert('app_settings', defaults.toMap());
      return defaults;
    }
    return AppSettingsModel.fromMap(rows.first);
  }

  Future<void> save(AppSettingsModel settings) async {
    final db = await AppDatabase.instance.database;
    await db.update('app_settings', settings.toMap(), where: "id = 'app'");
  }
}

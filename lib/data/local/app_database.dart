import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Thin wrapper around a single sqflite [Database] instance.
/// Deliberately hand-written (no drift/build_runner) so the project builds
/// immediately with `flutter pub get` — no codegen step required.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dawakti.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            colorIndex INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE people(
            id TEXT PRIMARY KEY,
            fullName TEXT NOT NULL,
            shortName TEXT,
            phone TEXT,
            whatsapp TEXT,
            categoryId TEXT,
            familyMembersCount INTEGER NOT NULL DEFAULT 1,
            address TEXT,
            notes TEXT,
            photoPath TEXT,
            isFavorite INTEGER NOT NULL DEFAULT 0,
            lastCallStatus TEXT,
            lastCallDate TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY(categoryId) REFERENCES categories(id) ON DELETE SET NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE events(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            date TEXT,
            time TEXT,
            location TEXT,
            notes TEXT,
            colorIndex INTEGER NOT NULL DEFAULT 0,
            coverImagePath TEXT,
            archived INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE invitees(
            id TEXT PRIMARY KEY,
            eventId TEXT NOT NULL,
            personId TEXT NOT NULL,
            rsvpStatus TEXT NOT NULL DEFAULT 'pending',
            companions INTEGER NOT NULL DEFAULT 1,
            calledAt TEXT,
            notes TEXT,
            FOREIGN KEY(eventId) REFERENCES events(id) ON DELETE CASCADE,
            FOREIGN KEY(personId) REFERENCES people(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            eventId TEXT,
            title TEXT NOT NULL,
            dueDate TEXT,
            imagePath TEXT,
            status TEXT NOT NULL DEFAULT 'notStarted',
            priority TEXT NOT NULL DEFAULT 'medium',
            sortOrder INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            FOREIGN KEY(eventId) REFERENCES events(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE app_settings(
            id TEXT PRIMARY KEY DEFAULT 'app',
            themeMode TEXT NOT NULL DEFAULT 'dark',
            language TEXT NOT NULL DEFAULT 'ar',
            accentColorValue INTEGER NOT NULL DEFAULT ${0xFF6C5CE7},
            pinHash TEXT,
            lockEnabled INTEGER NOT NULL DEFAULT 0,
            biometricEnabled INTEGER NOT NULL DEFAULT 0,
            onboardingSeen INTEGER NOT NULL DEFAULT 0
          );
        ''');

        await db.insert('app_settings', {'id': 'app'});
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/script.dart';

/// Simple local database. No internet, no cloud — everything stays on device.
class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'teleprompter.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scripts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            language TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertScript(ScriptModel script) async {
    final db = await database;
    return db.insert('scripts', script.toMap());
  }

  Future<int> updateScript(ScriptModel script) async {
    final db = await database;
    return db.update('scripts', script.toMap(),
        where: 'id = ?', whereArgs: [script.id]);
  }

  Future<int> deleteScript(int id) async {
    final db = await database;
    return db.delete('scripts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ScriptModel>> getAllScripts() async {
    final db = await database;
    final result = await db.query('scripts', orderBy: 'updatedAt DESC');
    return result.map((e) => ScriptModel.fromMap(e)).toList();
  }
}

/// SQLite 数据库服务 —— trips 表的完整 CRUD 操作。
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static Database? _database;
  static bool _unsupported = false;

  /// 获取数据库实例（单例模式）
  static Future<Database> get database async {
    if (_database != null) return _database!;
    if (_unsupported) throw Exception('SQLite not available on this platform');
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      _unsupported = true;
      rethrow;
    }
  }

  /// 初始化 SQLite 数据库
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'travel_planner.db');
    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  /// 首次创建数据库时建表
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        city TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        image_url TEXT NOT NULL DEFAULT '',
        days INTEGER NOT NULL DEFAULT 1,
        price REAL NOT NULL DEFAULT 0.0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE saved_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT NOT NULL DEFAULT '',
        days INTEGER NOT NULL DEFAULT 0,
        plan_text TEXT NOT NULL DEFAULT '',
        is_favorite INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// 数据库升级
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE trips ADD COLUMN city TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE trips ADD COLUMN days INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE trips ADD COLUMN price REAL NOT NULL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saved_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          city TEXT NOT NULL DEFAULT '',
          days INTEGER NOT NULL DEFAULT 0,
          plan_text TEXT NOT NULL DEFAULT '',
          is_favorite INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ========== CRUD（均有异常保护） ==========

  static Future<int> insertOrUpdate(Map<String, dynamic> row) async {
    if (_unsupported) return 0;
    final db = await database;
    final existing = await db.query('trips', where: 'id = ?', whereArgs: [row['id']]);
    if (existing.isNotEmpty) {
      return await db.update('trips', row, where: 'id = ?', whereArgs: [row['id']]);
    }
    return await db.insert('trips', row);
  }

  static Future<List<Map<String, dynamic>>> queryFavorites() async {
    if (_unsupported) return [];
    final db = await database;
    return await db.query('trips', where: 'is_favorite = ?', whereArgs: [1], orderBy: 'created_at DESC');
  }

  static Future<int> getFavoriteCount() async {
    if (_unsupported) return 0;
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM trips WHERE is_favorite = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<Map<String, dynamic>?> queryTripById(int id) async {
    if (_unsupported) return null;
    final db = await database;
    final results = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<int> toggleFavorite(int id, bool isFavorite) async {
    if (_unsupported) return 0;
    final db = await database;
    return await db.update('trips', {'is_favorite': isFavorite ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> isFavorite(int id) async {
    if (_unsupported) return false;
    final db = await database;
    final results = await db.query('trips', where: 'id = ? AND is_favorite = ?', whereArgs: [id, 1]);
    return results.isNotEmpty;
  }

  static Future<int> deleteTrip(int id) async {
    if (_unsupported) return 0;
    final db = await database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // ========== saved_plans CRUD ==========

  static Future<int> insertPlan(Map<String, dynamic> row) async {
    if (_unsupported) return 0;
    final db = await database;
    return await db.insert('saved_plans', row);
  }

  static Future<List<Map<String, dynamic>>> queryAllPlans() async {
    if (_unsupported) return [];
    final db = await database;
    return await db.query('saved_plans', where: 'is_favorite = ?', whereArgs: [1], orderBy: 'created_at DESC');
  }

  static Future<int> getPlanCount() async {
    if (_unsupported) return 0;
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM saved_plans WHERE is_favorite = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<bool> isPlanSaved(String planText) async {
    if (_unsupported) return false;
    final db = await database;
    final results = await db.query('saved_plans', where: 'plan_text = ?', whereArgs: [planText]);
    return results.isNotEmpty;
  }

  static Future<int> deletePlan(int id) async {
    if (_unsupported) return 0;
    final db = await database;
    return await db.delete('saved_plans', where: 'id = ?', whereArgs: [id]);
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static Database? _db;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized && _db != null) return;
    
    try {
      if (Platform.isWindows) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'cabinet_new.db');
      
      print('📁 مسیر دیتابیس: $path');
      
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          print('🆕 ایجاد دیتابیس جدید...');
          await _createTables(db);
          await _insertInitialData(db);
        },
      );
      
      _isInitialized = true;
      print('✅ دیتابیس محلی با موفقیت ایجاد شد');
    } catch (e) {
      print('❌ خطا در ایجاد دیتابیس: $e');
      rethrow;
    }
  }

  static Future<void> _createTables(Database db) async {
    // جدول کاربران
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        is_admin INTEGER DEFAULT 0
      )
    ''');

    // جدول کمدها (8 کمد ثابت)
    await db.execute('''
      CREATE TABLE cabinets (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        image_path TEXT
      )
    ''');

    // جدول پروژه‌ها
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    // جدول کمدهای پروژه (ارتباط بین پروژه و کمد)
    await db.execute('''
      CREATE TABLE project_cabinets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        cabinet_id INTEGER NOT NULL,
        length REAL DEFAULT 0,
        width REAL DEFAULT 0,
        height REAL DEFAULT 0,
        floors INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
        FOREIGN KEY (cabinet_id) REFERENCES cabinets (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _insertInitialData(Database db) async {
    // کاربر مدیر
    await db.insert('users', {
      'name': 'مدیر',
      'email': 'admin@cabinet.com',
      'is_admin': 1,
    });

    // 8 کمد
    for (int i = 1; i <= 8; i++) {
      await db.insert('cabinets', {
        'id': i,
        'name': 'کمد شماره $i',
        'image_path': 'assets/images/cabinet_$i.png',
      });
    }
    
    print('✅ ۸ کمد ایجاد شدند');
    print('✅ بدون پروژه نمونه');
  }

  static Database get db => _db!;
  static bool get isInitialized => _isInitialized;

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  static Future<int> insert(String table, Map<String, dynamic> values) async {
    return await db.insert(table, values);
  }

  static Future<int> update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  static Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
}
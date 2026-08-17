import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabaseService {
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
      final path = join(directory.path, 'cabinet_app.db');
      
      print('📁 مسیر دیتابیس: $path');
      
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          print('🆕 ایجاد دیتابیس جدید...');
          await _createTables(db);
          await _insertInitialData(db);
        },
        onOpen: (db) async {
          print('✅ دیتابیس باز شد');
        },
      );
      
      _isInitialized = true;
      print('✅ دیتابیس محلی با موفقیت ایجاد شد');
      
      try {
        final test = await _db!.query('users', limit: 1);
        print('✅ تست دیتابیس موفق: ${test.length} کاربر یافت شد');
      } catch (e) {
        print('⚠️ تست دیتابیس با خطا مواجه شد: $e');
      }
      
    } catch (e) {
      print('❌ خطا در ایجاد دیتابیس: $e');
      rethrow;
    }
  }

  static Future<void> _createTables(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          email TEXT,
          is_admin INTEGER DEFAULT 0
        )
      ''');
      print('✅ جدول users ایجاد شد');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cabinets (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          icon_name TEXT,
          color_code TEXT,
          image_url TEXT,
          image_name TEXT,
          created_at TEXT
        )
      ''');
      print('✅ جدول cabinets ایجاد شد');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT
        )
      ''');
      print('✅ جدول projects ایجاد شد');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS project_cabinets (
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
      print('✅ جدول project_cabinets ایجاد شد');
      
      print('✅ همه جداول با موفقیت ایجاد شدند');
    } catch (e) {
      print('❌ خطا در ایجاد جداول: $e');
      rethrow;
    }
  }

  static Future<void> _insertInitialData(Database db) async {
    try {
      final existingUsers = await db.query('users', where: 'email = ?', whereArgs: ['admin@cabinet.com']);
      if (existingUsers.isEmpty) {
        await db.insert('users', {
          'name': 'مدیر',
          'email': 'admin@cabinet.com',
          'is_admin': 1,
        });
        print('✅ کاربر مدیر ایجاد شد');
      } else {
        print('✅ کاربر مدیر قبلاً وجود دارد');
      }

      final existingCabinets = await db.query('cabinets', limit: 1);
      if (existingCabinets.isEmpty) {
        final defaultCabinets = [
          {'id': 1, 'name': 'کمد زمینی ساده', 'icon': 'king_bed', 'color': '#2196F3'},
          {'id': 2, 'name': 'کمد زیر سینک', 'icon': 'kitchen', 'color': '#4CAF50'},
          {'id': 3, 'name': 'کمد کشو دار', 'icon': 'chair', 'color': '#FF9800'},
          {'id': 4, 'name': 'کمد آبچک', 'icon': 'bed', 'color': '#9C27B0'},
          {'id': 5, 'name': 'کمد پکیج', 'icon': 'weekend', 'color': '#F44336'},
          {'id': 6, 'name': 'کمد دیواری', 'icon': 'library_books', 'color': '#009688'},
          {'id': 7, 'name': 'کمد سوپری', 'icon': 'business_center', 'color': '#3F51B5'},
          {'id': 8, 'name': 'کمد بالای یخچال', 'icon': 'shopping_bag', 'color': '#E91E63'},
        ];
        
        for (var cabinet in defaultCabinets) {
          await db.insert('cabinets', {
            'id': cabinet['id'],
            'name': cabinet['name'],
            'icon_name': cabinet['icon'],
            'color_code': cabinet['color'],
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        print('✅ ۸ کمد ایجاد شدند');
      } else {
        print('✅ کمدها قبلاً وجود دارند');
      }
      
      print('✅ داده‌های اولیه با موفقیت ایجاد شدند');
      
    } catch (e) {
      print('❌ خطا در ایجاد داده‌های اولیه: $e');
    }
  }

  static Database get db => _db!;
  static bool get isInitialized => _isInitialized;

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    try {
      return await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );
    } catch (e) {
      print('❌ خطا در query: $e');
      rethrow;
    }
  }

  static Future<int> insert(String table, Map<String, dynamic> values) async {
    try {
      return await db.insert(table, values);
    } catch (e) {
      print('❌ خطا در insert: $e');
      rethrow;
    }
  }

  static Future<int> update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    try {
      return await db.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
      );
    } catch (e) {
      print('❌ خطا در update: $e');
      rethrow;
    }
  }

  static Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    try {
      return await db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
    } catch (e) {
      print('❌ خطا در delete: $e');
      rethrow;
    }
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _isInitialized = false;
    }
  }
}
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/card_model.dart';
import '../models/settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'network_hunter.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. جدول الكروت المكتشفة الصحيحة
        await db.execute('''
          CREATE TABLE IF NOT EXISTS found_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_number TEXT UNIQUE NOT NULL,
            login_url TEXT,
            found_at TEXT,
            is_used INTEGER DEFAULT 0,
            notes TEXT
          )
        ''');

        // 2. جدول حالة الفحص والاستئناف
        await db.execute('''
          CREATE TABLE IF NOT EXISTS hunter_state (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        // 3. جدول حفظ الإعدادات المخصصة
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  // ==================== الكروت (Found Cards) ====================

  Future<bool> saveFoundCard(String cardNumber, String loginUrl, {String notes = ''}) async {
    final db = await database;
    try {
      final now = DateTime.now().toIso8601String().replaceAll('T', ' ').split('.').first;
      final id = await db.insert(
        'found_cards',
        {
          'card_number': cardNumber,
          'login_url': loginUrl,
          'found_at': now,
          'is_used': 0,
          'notes': notes,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return id > 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<CardModel>> getAllFoundCards() async {
    final db = await database;
    final maps = await db.query('found_cards', orderBy: 'id DESC');
    return maps.map((m) => CardModel.fromMap(m)).toList();
  }

  Future<bool> toggleCardUsed(int cardId) async {
    final db = await database;
    final res = await db.query('found_cards', columns: ['is_used'], where: 'id = ?', whereArgs: [cardId]);
    if (res.isNotEmpty) {
      final current = (res.first['is_used'] as int? ?? 0);
      final newVal = current == 1 ? 0 : 1;
      await db.update('found_cards', {'is_used': newVal}, where: 'id = ?', whereArgs: [cardId]);
      return newVal == 1;
    }
    return false;
  }

  Future<void> deleteCard(int cardId) async {
    final db = await database;
    await db.delete('found_cards', where: 'id = ?', whereArgs: [cardId]);
  }

  Future<void> clearAllCards() async {
    final db = await database;
    await db.delete('found_cards');
  }

  // ==================== حالة الفحص (Hunter State) ====================

  Future<void> setState(String key, String value) async {
    final db = await database;
    await db.insert(
      'hunter_state',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getState(String key, [String? defaultValue]) async {
    final db = await database;
    final res = await db.query('hunter_state', columns: ['value'], where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return defaultValue;
  }

  // ==================== الإعدادات (Settings) ====================

  Future<void> saveSettings(SettingsModel settings) async {
    final db = await database;
    final batch = db.batch();
    final map = settings.toMap();
    for (final entry in map.entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<SettingsModel> loadSettings() async {
    final db = await database;
    final res = await db.query('settings');
    final map = <String, String>{};
    for (final row in res) {
      final k = row['key'] as String;
      final v = row['value'] as String;
      map[k] = v;
    }
    return SettingsModel.fromMap(map);
  }
}

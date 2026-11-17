import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/data/models/settings_model.dart';
import 'package:networking/data/models/tested_card_model.dart';
import 'package:networking/domain/engine/hunter_interfaces.dart';

class DatabaseHelper implements HunterDatabase {
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
      version: 2,
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

        // 4. جدول سجل الكروت المختبرة
        await _createTestedCardsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTestedCardsTable(db);
        }
      },
    );
  }

  static Future<void> _createTestedCardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tested_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_number TEXT NOT NULL,
        tested_at TEXT NOT NULL,
        status TEXT NOT NULL,
        portal_message TEXT,
        is_last_tested INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tested_card_number ON tested_cards (card_number)
    ''');
  }

  // ==================== الكروت (Found Cards) ====================

  @override
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

  Future<void> setCardUsedStatus(int cardId, bool isUsed) async {
    final db = await database;
    await db.update('found_cards', {'is_used': isUsed ? 1 : 0}, where: 'id = ?', whereArgs: [cardId]);
  }

  Future<void> updateCardNotes(int cardId, String notes) async {
    final db = await database;
    await db.update('found_cards', {'notes': notes}, where: 'id = ?', whereArgs: [cardId]);
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

  @override
  Future<void> setState(String key, String value) async {
    final db = await database;
    await db.insert(
      'hunter_state',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
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

  // ==================== الكروت المختبرة (Tested Cards) ====================

  @override
  Future<void> recordTestedCard({
    required String cardNumber,
    required String status,
    required String portalMessage,
    bool isLast = true,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String().replaceAll('T', ' ').split('.').first;

    await db.transaction((txn) async {
      if (isLast) {
        await txn.update(
          'tested_cards',
          {'is_last_tested': 0},
          where: 'is_last_tested = 1',
        );
      }

      await txn.insert(
        'tested_cards',
        {
          'card_number': cardNumber,
          'tested_at': now,
          'status': status,
          'portal_message': portalMessage,
          'is_last_tested': isLast ? 1 : 0,
        },
      );

      if (isLast) {
        await txn.insert(
          'hunter_state',
          {'key': 'last_tested_number', 'value': cardNumber},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<TestedCardModel>> getAllTestedCards({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      res = await db.query(
        'tested_cards',
        where: 'card_number LIKE ? OR portal_message LIKE ?',
        whereArgs: [q, q],
        orderBy: 'id DESC',
      );
    } else {
      res = await db.query('tested_cards', orderBy: 'id DESC');
    }
    return res.map((m) => TestedCardModel.fromMap(m)).toList();
  }

  @override
  Future<bool> isCardAlreadyTested(String cardNumber) async {
    final db = await database;
    final res = await db.query(
      'tested_cards',
      columns: ['id'],
      where: 'card_number = ?',
      whereArgs: [cardNumber],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  Future<TestedCardModel?> getLastTestedCard() async {
    final db = await database;
    final res = await db.query(
      'tested_cards',
      where: 'is_last_tested = 1',
      limit: 1,
    );
    if (res.isNotEmpty) {
      return TestedCardModel.fromMap(res.first);
    }
    final fallback = await db.query(
      'tested_cards',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (fallback.isNotEmpty) {
      return TestedCardModel.fromMap(fallback.first);
    }
    return null;
  }

  Future<void> clearAllTestedCards() async {
    final db = await database;
    await db.delete('tested_cards');
  }
}

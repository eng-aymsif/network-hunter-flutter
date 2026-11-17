import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/data/models/settings_model.dart';
import 'package:networking/data/models/tested_card_model.dart';
import 'package:networking/domain/engine/hunter_interfaces.dart';

/// إدارة التخزين وقاعدة البيانات المحلية باستخدام NoSQL Hive
class HiveHelper implements HunterDatabase {
  static final HiveHelper instance = HiveHelper._internal();
  HiveHelper._internal();

  static const String foundCardsBoxName = 'found_cards_box';
  static const String hunterStateBoxName = 'hunter_state_box';
  static const String settingsBoxName = 'settings_box';
  static const String testedCardsBoxName = 'tested_cards_box';
  static const String subscriptionBoxName = 'subscription_box';

  bool _isInitialized = false;

  late Box<CardModel> _foundCardsBox;
  late Box<dynamic> _hunterStateBox;
  late Box<dynamic> _settingsBox;
  late Box<TestedCardModel> _testedCardsBox;
  late Box<dynamic> _subscriptionBox;

  final Set<String> _testedNumbersCache = {};

  bool get isInitialized => _isInitialized;

  /// تهيئة Hive وتسجيل الـ Adapters وفتح الصناديق (Boxes)
  Future<void> init([String? customPath]) async {
    if (_isInitialized) return;

    if (customPath != null) {
      Hive.init(customPath);
    } else {
      try {
        await Hive.initFlutter();
      } catch (_) {
        final temp = Directory.systemTemp.createTempSync('hive_testing_');
        Hive.init(temp.path);
      }
    }

    _registerAdapters();
    await _openBoxes();
    _populateCaches();

    _isInitialized = true;
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CardModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TestedCardModelAdapter());
    }
  }

  Future<void> _openBoxes() async {
    _foundCardsBox = await Hive.openBox<CardModel>(foundCardsBoxName);
    _hunterStateBox = await Hive.openBox<dynamic>(hunterStateBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    _testedCardsBox = await Hive.openBox<TestedCardModel>(testedCardsBoxName);
    _subscriptionBox = await Hive.openBox<dynamic>(subscriptionBoxName);
  }

  void _populateCaches() {
    _testedNumbersCache.clear();
    for (final card in _testedCardsBox.values) {
      if (card.cardNumber.isNotEmpty) {
        _testedNumbersCache.add(card.cardNumber);
      }
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // ===========================================================================
  // العمليات على الكروت المصطادة (Found Cards CRUD)
  // ===========================================================================

  @override
  Future<bool> saveFoundCard(
    String cardNumber,
    String loginUrl, {
    String notes = '',
  }) async {
    await _ensureInitialized();

    // التحقق من عدم التكرار
    final alreadyExists = _foundCardsBox.values.any((c) => c.cardNumber == cardNumber);
    if (alreadyExists) return false;

    try {
      final now = DateTime.now().toIso8601String().replaceAll('T', ' ').split('.').first;
      final card = CardModel(
        cardNumber: cardNumber,
        loginUrl: loginUrl,
        foundAt: now,
        isUsed: false,
        notes: notes,
      );

      // box.add() لإدراج الكرت وتوليد مفتاح رقمي تلقائي
      final key = await _foundCardsBox.add(card);
      // تحديث الكائن لحفظ المفتاح كـ id
      await _foundCardsBox.put(key, card.copyWith(id: key));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<CardModel>> getAllFoundCards() async {
    await _ensureInitialized();
    // قراءة البيانات من الـ Box وترتيبها من الأحدث للأقدم
    final list = _foundCardsBox.values.toList();
    return list.reversed.toList();
  }

  Future<bool> toggleCardUsed(int cardId) async {
    await _ensureInitialized();
    final card = _foundCardsBox.get(cardId);
    if (card != null) {
      final newStatus = !card.isUsed;
      // box.put() لتحديث حالة الكرت
      await _foundCardsBox.put(cardId, card.copyWith(isUsed: newStatus));
      return newStatus;
    }
    return false;
  }

  Future<void> setCardUsedStatus(int cardId, bool isUsed) async {
    await _ensureInitialized();
    final card = _foundCardsBox.get(cardId);
    if (card != null) {
      await _foundCardsBox.put(cardId, card.copyWith(isUsed: isUsed));
    }
  }

  Future<void> updateCardNotes(int cardId, String notes) async {
    await _ensureInitialized();
    final card = _foundCardsBox.get(cardId);
    if (card != null) {
      await _foundCardsBox.put(cardId, card.copyWith(notes: notes));
    }
  }

  Future<void> deleteCard(int cardId) async {
    await _ensureInitialized();
    // box.delete() لحذف الكرت بمفتاحه
    await _foundCardsBox.delete(cardId);
  }

  Future<void> clearAllCards() async {
    await _ensureInitialized();
    // box.clear() لمسح جميع الكروت
    await _foundCardsBox.clear();
  }

  // ===========================================================================
  // العمليات على حالة الفحص (Hunter State CRUD)
  // ===========================================================================

  @override
  Future<void> setState(String key, String value) async {
    await _ensureInitialized();
    // box.put() لحفظ القيمة
    await _hunterStateBox.put(key, value);
  }

  @override
  Future<String?> getState(String key, [String? defaultValue]) async {
    await _ensureInitialized();
    // box.get() لقراءة القيمة
    final val = _hunterStateBox.get(key, defaultValue: defaultValue);
    return val?.toString();
  }

  // ===========================================================================
  // العمليات على الإعدادات (Settings CRUD)
  // ===========================================================================

  Future<void> saveSettings(SettingsModel settings) async {
    await _ensureInitialized();
    final map = settings.toMap();
    for (final entry in map.entries) {
      await _settingsBox.put(entry.key, entry.value);
    }
  }

  Future<SettingsModel> loadSettings() async {
    await _ensureInitialized();
    final map = <String, String>{};
    for (final key in _settingsBox.keys) {
      final v = _settingsBox.get(key);
      if (v != null) {
        map[key.toString()] = v.toString();
      }
    }
    return SettingsModel.fromMap(map);
  }

  // ===========================================================================
  // العمليات على الكروت المختبرة (Tested Cards CRUD)
  // ===========================================================================

  @override
  Future<void> recordTestedCard({
    required String cardNumber,
    required String status,
    required String portalMessage,
    bool isLast = true,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toIso8601String().replaceAll('T', ' ').split('.').first;

    if (isLast) {
      // إزالة علامة آخر مفحوص عن السجلات السابقة
      for (final key in _testedCardsBox.keys) {
        final item = _testedCardsBox.get(key);
        if (item != null && item.isLastTested) {
          await _testedCardsBox.put(key, item.copyWith(isLastTested: false));
        }
      }
    }

    final model = TestedCardModel(
      cardNumber: cardNumber,
      testedAt: now,
      status: status,
      portalMessage: portalMessage,
      isLastTested: isLast,
    );

    // box.add() لإضافة سجل الاختبار
    final key = await _testedCardsBox.add(model);
    // box.put() لتثبيت الـ id
    await _testedCardsBox.put(key, model.copyWith(id: key));
    _testedNumbersCache.add(cardNumber);

    if (isLast) {
      await setState('last_tested_number', cardNumber);
    }
  }

  Future<List<TestedCardModel>> getAllTestedCards({String? query}) async {
    await _ensureInitialized();
    var list = _testedCardsBox.values.toList().reversed.toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((c) =>
        c.cardNumber.toLowerCase().contains(q) ||
        c.portalMessage.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  @override
  Future<bool> isCardAlreadyTested(String cardNumber) async {
    await _ensureInitialized();
    return _testedNumbersCache.contains(cardNumber);
  }

  Future<TestedCardModel?> getLastTestedCard() async {
    await _ensureInitialized();
    final last = _testedCardsBox.values.where((c) => c.isLastTested).firstOrNull;
    if (last != null) return last;
    return _testedCardsBox.values.isNotEmpty ? _testedCardsBox.values.last : null;
  }

  Future<void> clearAllTestedCards() async {
    await _ensureInitialized();
    // box.clear() لمسح سجل الكروت المختبرة
    await _testedCardsBox.clear();
    _testedNumbersCache.clear();
  }

  // ===========================================================================
  // بيانات الاشتراك والأمان وحماية التوقيت (Subscription & Anti-Tamper)
  // ===========================================================================

  Future<void> saveSubscriptionData(Map<String, dynamic> data) async {
    await _ensureInitialized();
    for (final entry in data.entries) {
      await _subscriptionBox.put(entry.key, entry.value);
    }
  }

  dynamic getSubscriptionValue(String key, [dynamic defaultValue]) {
    if (!_isInitialized) return defaultValue;
    return _subscriptionBox.get(key, defaultValue: defaultValue);
  }

  Map<String, dynamic> getAllSubscriptionData() {
    if (!_isInitialized) return {};
    final map = <String, dynamic>{};
    for (final key in _subscriptionBox.keys) {
      map[key.toString()] = _subscriptionBox.get(key);
    }
    return map;
  }

  Future<void> clearSubscriptionData() async {
    await _ensureInitialized();
    await _subscriptionBox.clear();
  }

  int getHighestSeenTimestamp() {
    return (getSubscriptionValue('highest_seen_timestamp_ms', 0) as num).toInt();
  }

  Future<void> setHighestSeenTimestamp(int timestampMs) async {
    await _ensureInitialized();
    final current = getHighestSeenTimestamp();
    if (timestampMs > current) {
      await _subscriptionBox.put('highest_seen_timestamp_ms', timestampMs);
    }
  }
}

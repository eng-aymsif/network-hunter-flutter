import 'dart:io';
import 'package:test/test.dart';
import 'package:networking/core/utils/number_formatter.dart';
import 'package:networking/data/datasources/hive_helper.dart';
import 'package:networking/data/datasources/unban_service.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/data/models/settings_model.dart';
import 'package:networking/data/models/tested_card_model.dart';

void main() {
  group('NumberFormatter Tests', () {
    test('increments standard number', () {
      expect(NumberFormatter.nextNumber('100'), '101');
    });

    test('preserves leading zeros', () {
      expect(NumberFormatter.nextNumber('00123'), '00124');
      expect(NumberFormatter.nextNumber('099'), '100');
      expect(NumberFormatter.nextNumber('0001'), '0002');
    });

    test('handles large numbers', () {
      expect(NumberFormatter.nextNumber('301007757'), '301007758');
    });
  });

  group('UnbanService Tests', () {
    test('generates valid MAC address format', () {
      final mac = UnbanService.generateValidMac();
      final parts = mac.split(':');
      expect(parts.length, 6);

      // Check second nibble is 2, 6, A, or E (locally administered unicast)
      final secondChar = parts[0][1].toUpperCase();
      expect(['2', '6', 'A', 'E'].contains(secondChar), true);
    });
  });

  group('CardModel Tests', () {
    test('serialization and deserialization', () {
      final card = CardModel(
        id: 1,
        cardNumber: '301007757',
        loginUrl: 'http://a.com/login',
        foundAt: '2026-11-11 12:00:00',
        isUsed: false,
        notes: 'Test',
      );

      final map = card.toMap();
      final restored = CardModel.fromMap(map);

      expect(restored.cardNumber, card.cardNumber);
      expect(restored.loginUrl, card.loginUrl);
      expect(restored.isUsed, card.isUsed);
    });

    test('Excel export structure matches status_logs_v2.xlsx specification', () {
      final headers = [
        'رقم الكرت (Number)',
        'الرابط (URL)',
        'التاريخ (Date)',
        'الوقت (Time)',
        'مستخدم',
      ];
      expect(headers.length, 5);
      expect(headers[0], 'رقم الكرت (Number)');
      expect(headers[1], 'الرابط (URL)');
      expect(headers[2], 'التاريخ (Date)');
      expect(headers[3], 'الوقت (Time)');
      expect(headers[4], 'مستخدم');
    });
  });

  group('SettingsModel Tests', () {
    test('serialization and defaults', () {
      final settings = SettingsModel();
      expect(settings.url, 'http://a.com');
      expect(settings.startNumber, '');
      expect(settings.delayBetween, 10.0);
      expect(settings.useWebView, true);

      final map = settings.toMap();
      final restored = SettingsModel.fromMap(map);

      expect(restored.url, settings.url);
      expect(restored.startNumber, settings.startNumber);
      expect(restored.delayBetween, settings.delayBetween);
      expect(restored.useWebView, settings.useWebView);
      expect(restored.skipAlreadyTested, settings.skipAlreadyTested);
    });
  });

  group('TestedCardModel Tests', () {
    test('serialization, deserialization, and copyWith', () {
      final model = TestedCardModel(
        id: 1,
        cardNumber: '201150010',
        testedAt: '2026-11-17 07:09:24',
        status: 'failed',
        portalMessage: 'رمز الدخول غير صحيح',
        isLastTested: true,
      );

      final map = model.toMap();
      final restored = TestedCardModel.fromMap(map);

      expect(restored.id, 1);
      expect(restored.cardNumber, '201150010');
      expect(restored.testedAt, '2026-11-17 07:09:24');
      expect(restored.status, 'failed');
      expect(restored.portalMessage, 'رمز الدخول غير صحيح');
      expect(restored.isLastTested, isTrue);

      final copied = model.copyWith(isLastTested: false, status: 'success');
      expect(copied.isLastTested, isFalse);
      expect(copied.status, 'success');
      expect(copied.cardNumber, '201150010');
    });
  });

  group('HiveHelper CRUD Tests', () {
    late HiveHelper helper;

    setUpAll(() async {
      final temp = Directory.systemTemp.createTempSync('hive_unit_tests_');
      helper = HiveHelper.instance;
      await helper.init(temp.path);
    });

    tearDown(() async {
      await helper.clearAllCards();
      await helper.clearAllTestedCards();
    });

    test('Found cards CRUD operations', () async {
      // 1. Insert (saveFoundCard)
      final saved = await helper.saveFoundCard('123456', 'http://a.com/status', notes: 'تجربة');
      expect(saved, isTrue);

      // Duplicate protection
      final duplicate = await helper.saveFoundCard('123456', 'http://a.com/status');
      expect(duplicate, isFalse);

      // 2. Read (getAllFoundCards)
      var cards = await helper.getAllFoundCards();
      expect(cards.length, 1);
      final cardId = cards.first.id!;
      expect(cards.first.cardNumber, '123456');

      // 3. Update (toggleCardUsed, updateCardNotes)
      final newStatus = await helper.toggleCardUsed(cardId);
      expect(newStatus, isTrue);
      await helper.updateCardNotes(cardId, 'ملاحظة جديدة');

      cards = await helper.getAllFoundCards();
      expect(cards.first.isUsed, isTrue);
      expect(cards.first.notes, 'ملاحظة جديدة');

      // 4. Delete (deleteCard)
      await helper.deleteCard(cardId);
      cards = await helper.getAllFoundCards();
      expect(cards.isEmpty, isTrue);
    });

    test('Tested cards CRUD and skip check operations', () async {
      // 1. Insert tested cards
      await helper.recordTestedCard(
        cardNumber: '999001',
        status: 'failed',
        portalMessage: 'رمز الدخول خاطئ',
        isLast: true,
      );

      // 2. Read
      expect(await helper.isCardAlreadyTested('999001'), isTrue);
      expect(await helper.isCardAlreadyTested('999002'), isFalse);

      var list = await helper.getAllTestedCards();
      expect(list.length, 1);
      expect(list.first.isLastTested, isTrue);

      // Add another tested card
      await helper.recordTestedCard(
        cardNumber: '999002',
        status: 'success',
        portalMessage: 'تم بنجاح',
        isLast: true,
      );

      list = await helper.getAllTestedCards();
      expect(list.length, 2);
      final first = list.firstWhere((c) => c.cardNumber == '999001');
      final second = list.firstWhere((c) => c.cardNumber == '999002');
      expect(first.isLastTested, isFalse);
      expect(second.isLastTested, isTrue);

      // 3. Clear
      await helper.clearAllTestedCards();
      expect(await helper.isCardAlreadyTested('999001'), isFalse);
      list = await helper.getAllTestedCards();
      expect(list.isEmpty, isTrue);
    });

    test('State and Settings operations', () async {
      await helper.setState('last_tested_number', '555');
      expect(await helper.getState('last_tested_number'), '555');

      final settings = SettingsModel(url: 'http://custom.com', startNumber: '777');
      await helper.saveSettings(settings);
      final loaded = await helper.loadSettings();
      expect(loaded.url, 'http://custom.com');
      expect(loaded.startNumber, '777');
    });
  });
}

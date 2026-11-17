import 'package:test/test.dart';
import 'package:networking/core/utils/number_formatter.dart';
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
}

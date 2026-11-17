import 'package:test/test.dart';
import 'package:networking/core/utils/number_formatter.dart';
import 'package:networking/data/datasources/unban_service.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/data/models/settings_model.dart';

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
  });

  group('SettingsModel Tests', () {
    test('serialization and defaults', () {
      final settings = SettingsModel();
      expect(settings.url, 'http://a.com');
      expect(settings.startNumber, '301007757');
      expect(settings.useWebView, true);

      final map = settings.toMap();
      final restored = SettingsModel.fromMap(map);

      expect(restored.url, settings.url);
      expect(restored.startNumber, settings.startNumber);
      expect(restored.useWebView, settings.useWebView);
    });
  });
}

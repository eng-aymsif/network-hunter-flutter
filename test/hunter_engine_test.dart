import 'package:flutter_test/flutter_test.dart';
import 'package:networking/core/utils/number_formatter.dart';
import 'package:networking/data/models/settings_model.dart';
import 'package:networking/domain/engine/hunter_engine.dart';

class TestMockDatabase implements HunterDatabase {
  final Map<String, String> state = {};
  final List<String> foundCards = [];

  @override
  Future<String?> getState(String key) async => state[key];

  @override
  Future<void> setState(String key, String value) async => state[key] = value;

  @override
  Future<bool> saveFoundCard(String cardNumber, String loginUrl, {String notes = ''}) async {
    foundCards.add(cardNumber);
    return true;
  }
}

class TestMockConnectivityChecker implements ConnectivityChecker {
  bool connected;
  TestMockConnectivityChecker({this.connected = true});

  @override
  Future<bool> isConnected(String targetUrl) async => connected;
}

class TestMockSoundPlayer implements HunterSoundPlayer {
  @override
  Future<void> playAlert({bool isError = false}) async {}
}

class TestMockUnbanHandler implements HunterUnbanHandler {
  @override
  Future<Map<String, dynamic>> performUnban({void Function(String)? log}) async =>
      {'success': true};
}

class TestMockDelayer implements HunterDelayer {
  @override
  Future<void> delay(Duration duration) async {}
}

class TestMockHttpClient implements HunterHttpClient {
  final List<String> requestedCards = [];
  String Function(String card)? onCardCheck;

  @override
  Future<HunterHttpResponse> get(String url, {Map<String, dynamic>? queryParameters}) async {
    return HunterHttpResponse(
      statusCode: 200,
      data: '<html><input name="username" /><input type="submit" /></html>',
    );
  }

  @override
  Future<HunterHttpResponse> post(String url, {Map<String, dynamic>? data}) async {
    final card = data?['username']?.toString() ?? '';
    requestedCards.add(card);

    if (onCardCheck != null) {
      final res = onCardCheck!(card);
      if (res == 'SUCCESS') {
        return HunterHttpResponse(
          statusCode: 302,
          data: '',
          headers: {
            'location': ['http://a.com/status'],
          },
        );
      } else if (res == 'INVALID') {
        return HunterHttpResponse(
          statusCode: 200,
          data: '<html>رمز الدخول غير صحيح أو انتهت صلاحية الكرت</html>',
        );
      }
    }

    return HunterHttpResponse(statusCode: 200, data: 'غير صحيح');
  }
}

void main() {
  group('Hunter Engine Rejection & Advancement Tests', () {
    test('advances to next number immediately when portal rejects credentials', () async {
      final db = TestMockDatabase();
      final conn = TestMockConnectivityChecker(connected: true);
      final sound = TestMockSoundPlayer();
      final unban = TestMockUnbanHandler();
      final delayer = TestMockDelayer();
      final http = TestMockHttpClient();

      // Card 100 is rejected, Card 101 is rejected, Card 102 succeeds
      http.onCardCheck = (card) {
        if (card == '100' || card == '101') return 'INVALID';
        if (card == '102') return 'SUCCESS';
        return 'INVALID';
      };

      final engine = HunterEngine(
        db: db,
        connectivityChecker: conn,
        soundPlayer: sound,
        unbanHandler: unban,
        delayer: delayer,
        httpClient: http,
      );

      final settings = SettingsModel(
        url: 'http://a.com',
        startNumber: '100',
        useWebView: false,
        maxAttempts: 3,
        delayBetween: 0,
      );

      await engine.start(settings);

      // Verify that all 3 cards were evaluated in sequence: 100, 101, 102
      expect(http.requestedCards, ['100', '101', '102']);
      expect(db.foundCards, ['102']);
      expect(await db.getState('last_tested_number'), '103');
    });

    test('preserves leading zeros when advancing after rejection', () {
      expect(NumberFormatter.nextNumber('201122590'), '201122591');
      expect(NumberFormatter.nextNumber('0050'), '0051');
    });
  });
}

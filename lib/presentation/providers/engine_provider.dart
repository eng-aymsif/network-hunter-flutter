import 'package:flutter/foundation.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/native_bridge.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/unban_service.dart';
import '../../domain/engine/hunter_engine.dart';
import 'cards_provider.dart';
import 'logs_provider.dart';
import 'settings_provider.dart';

class EngineProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  HunterEngine? _engine;
  LogsProvider? _logsProvider;
  CardsProvider? _cardsProvider;
  SettingsProvider? _settingsProvider;

  EngineStatus _status = EngineStatus.ready;
  String _statusText = AppStrings.statusReady;

  String _currentNumber = '-';
  int _totalAttempts = 0;
  int _foundCount = 0;
  int _unbanCount = 0;
  bool _isRootAvailable = false;

  EngineStatus get status => _status;
  String get statusText => _statusText;
  String get currentNumber => _currentNumber;
  int get totalAttempts => _totalAttempts;
  int get foundCount => _foundCount;
  int get unbanCount => _unbanCount;
  bool get isRunning => _engine?.isRunning ?? false;
  bool get isPaused => _engine?.isPaused ?? false;
  bool get isRootAvailable => _isRootAvailable;

  EngineProvider() {
    _checkRoot();
  }

  Future<void> _checkRoot() async {
    _isRootAvailable = await UnbanService.isRootAvailable();
    notifyListeners();
  }

  void initDependencies({
    required LogsProvider logs,
    required CardsProvider cards,
    required SettingsProvider settings,
  }) {
    _logsProvider = logs;
    _cardsProvider = cards;
    _settingsProvider = settings;

    _engine = HunterEngine(
      db: _db,
      onLog: (msg) {
        _logsProvider?.addLog(msg);
      },
      onStats: (curNum, attempts, found, unbans) {
        _currentNumber = curNum;
        _totalAttempts = attempts;
        _foundCount = found;
        _unbanCount = unbans;
        notifyListeners();
      },
      onFound: (cardNumber, loginUrl) {
        _cardsProvider?.loadCards();
      },
      onStatusChange: (status, message) {
        _status = status;
        _statusText = message;
        notifyListeners();
      },
      onFinished: () {
        _status = EngineStatus.ready;
        _statusText = AppStrings.statusReady;
        NativeBridge.setKeepScreenOn(false);
        notifyListeners();
      },
    );
  }

  Future<void> startHunting() async {
    if (_engine == null || _settingsProvider == null) return;
    if (_engine!.isRunning) return;

    await NativeBridge.setKeepScreenOn(true);
    await _engine!.start(_settingsProvider!.settings);
    notifyListeners();
  }

  void pauseHunting() {
    _engine?.pause();
    notifyListeners();
  }

  void resumeHunting() {
    _engine?.resume();
    notifyListeners();
  }

  void stopHunting() {
    _engine?.stop();
    notifyListeners();
  }

  Future<void> manualUnban() async {
    _status = EngineStatus.unbanning;
    _statusText = AppStrings.statusUnbanning;
    notifyListeners();

    _logsProvider?.addLog('🔓 بدء تنفيذ فك الحظر يدوياً الآن...');
    final res = await UnbanService.performUnban(log: (m) => _logsProvider?.addLog(m));

    if (res['success'] == true) {
      _unbanCount++;
      _status = EngineStatus.ready;
      _statusText = AppStrings.statusReady;
      notifyListeners();
    } else {
      _status = EngineStatus.error;
      _statusText = AppStrings.statusError;
      notifyListeners();
    }
  }
}

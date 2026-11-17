import 'package:flutter/foundation.dart';

import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/core/utils/native_bridge.dart';
import 'package:networking/core/utils/sound_helper.dart';
import 'package:networking/data/datasources/database_helper.dart';
import 'package:networking/data/datasources/unban_service.dart';
import 'package:networking/domain/engine/hunter_engine.dart';
import 'package:networking/presentation/providers/cards_provider.dart';
import 'package:networking/presentation/providers/logs_provider.dart';
import 'package:networking/presentation/providers/settings_provider.dart';

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

  String _huntingSsid = '';
  String _currentWifiSsid = '';
  String? _pendingPreviousSsid;
  String? _pendingNewSsid;

  EngineStatus get status => _status;
  String get statusText => _statusText;
  String get currentNumber => _currentNumber;
  int get totalAttempts => _totalAttempts;
  int get foundCount => _foundCount;
  int get unbanCount => _unbanCount;
  bool get isRunning => _engine?.isRunning ?? false;
  bool get isPaused => _engine?.isPaused ?? false;
  bool get isRootAvailable => _isRootAvailable;
  String get huntingSsid => _huntingSsid;
  String get currentWifiSsid => _currentWifiSsid;
  String? get pendingPreviousSsid => _pendingPreviousSsid;
  String? get pendingNewSsid => _pendingNewSsid;
  bool get hasNetworkChangePrompt =>
      _pendingPreviousSsid != null && _pendingNewSsid != null;

  EngineProvider() {
    _checkRoot();
    _initWifiMonitor();
  }

  Future<void> _checkRoot() async {
    _isRootAvailable = await UnbanService.isRootAvailable();
    notifyListeners();
  }

  Future<void> _initWifiMonitor() async {
    _currentWifiSsid = await NativeBridge.getCurrentWifiSsid();
    final savedSsid = await _db.getState('last_hunting_ssid');
    if (savedSsid != null && savedSsid.isNotEmpty) {
      _huntingSsid = savedSsid;
    }

    NativeBridge.setWifiNetworkChangeListener((newSsid) async {
      _currentWifiSsid = newSsid;
      if (_huntingSsid.isEmpty) {
        final stored = await _db.getState('last_hunting_ssid');
        if (stored != null && stored.isNotEmpty) {
          _huntingSsid = stored;
        }
      }

      // إذا كانت هناك شبكة مسجلة سابقاً وتغيرت الشبكة عن الشبكة التي بدأنا الاصطياد منها
      if (_huntingSsid.isNotEmpty &&
          newSsid.isNotEmpty &&
          newSsid != _huntingSsid) {
        // إيقاف مؤقت للفحص لحين قرار المستخدم
        if (isRunning && !isPaused) {
          pauseHunting();
        }

        _pendingPreviousSsid = _huntingSsid;
        _pendingNewSsid = newSsid;

        final alertMsg =
            'الشبكة الحالية المتصل بها هي: "$newSsid"\n'
            'والشبكة السابقة التي كان يجري الاصطياد منها هي: "$_huntingSsid"\n'
            'هل تريد المتابعة على الشبكة الجديدة؟';

        _logsProvider?.addLog('⚠️ [تنبيه تغير الشبكة]: تغيرت الشبكة من "$_huntingSsid" إلى "$newSsid". بانتظار قرارك للمتابعة.');

        // إطلاق صوت تنبيه عالي وإشعار مستقل خاص بتغير الشبكة
        await SoundHelper.playAlert(isError: true);
        await NativeBridge.showAlertNotification(
          title: '📡 تنبيه: تغيرت شبكة الواي فاي!',
          body: alertMsg,
          isError: true,
          alertType: 'wifi',
        );

        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  /// موافقة المستخدم على المتابعة في الشبكة الجديدة
  Future<void> confirmContinueOnNewNetwork() async {
    if (_pendingNewSsid != null && _pendingNewSsid!.isNotEmpty) {
      _huntingSsid = _pendingNewSsid!;
      await _db.setState('last_hunting_ssid', _huntingSsid);
      _logsProvider?.addLog('✅ تمت الموافقة على متابعة الفحص والاصطياد على الشبكة الجديدة: "$_huntingSsid"');
    }
    _pendingPreviousSsid = null;
    _pendingNewSsid = null;
    if (isRunning && isPaused) {
      resumeHunting();
    }
    notifyListeners();
  }

  /// رفض المتابعة على الشبكة الجديدة وإيقاف الفحص أو فتح إعدادات الواي فاي للعودة للشبكة السابقة
  Future<void> cancelOnNetworkChange({bool openWifi = false}) async {
    final prev = _pendingPreviousSsid ?? _huntingSsid;
    _pendingPreviousSsid = null;
    _pendingNewSsid = null;
    _logsProvider?.addLog('🛑 تم إيقاف المتابعة بسبب تغير الشبكة. الشبكة المستهدفة: "$prev"');
    if (openWifi) {
      await NativeBridge.openWifiSettings();
    } else {
      stopHunting();
    }
    notifyListeners();
  }

  String _latestLogLine = 'جاري تهيئة الفحص...';

  void _syncLiveForegroundNotification() {
    if (!isRunning) return;
    final title = 'Network Hunter • $_statusText';
    final body =
        'الكرت الحالي: $_currentNumber | المحاولات: $_totalAttempts | المكتشفة: $_foundCount\n'
        'آخر عملية: $_latestLogLine';
    final subText = 'فك الحظر: $_unbanCount';
    NativeBridge.updateForegroundNotification(
      title: title,
      body: body,
      subText: subText,
    );
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
        _latestLogLine = msg.trim();
        _syncLiveForegroundNotification();

        // إذا حدث تنبيه صوتي لتعثر مستمر أو خلل حرج، نطلق إشعاراً مستقلاً عالي الصوت
        if (msg.contains('🔔 تنبيه صوتي:') || msg.contains('⛔ توقفت العملية')) {
          NativeBridge.showAlertNotification(
            title: '⚠️ تنبيه خلل / تعثر في الفحص!',
            body: msg.trim(),
            isError: true,
            alertType: 'error',
          );
        }
      },
      onStats: (curNum, attempts, found, unbans) {
        _currentNumber = curNum;
        _totalAttempts = attempts;
        _foundCount = found;
        _unbanCount = unbans;
        _syncLiveForegroundNotification();
        notifyListeners();
      },
      onFound: (cardNumber, loginUrl) {
        _cardsProvider?.loadCards();
        // إشعار مستقل منفصل بصوت عالٍ جداً عند اصطياد كرت صحيح
        NativeBridge.showAlertNotification(
          title: '🎉 تم اصطياد كرت شبكة صحيح بنجاح!',
          body: 'رقم الكرت المكتشف: $cardNumber\nالرابط: $loginUrl',
          isError: false,
          alertType: 'success',
        );
      },
      onStatusChange: (status, message) {
        _status = status;
        _statusText = message;
        _syncLiveForegroundNotification();
        notifyListeners();
      },
      onFinished: () {
        _status = _engine?.status ?? EngineStatus.ready;
        _statusText = _engine?.statusMessage ?? AppStrings.statusReady;
        NativeBridge.setKeepScreenOn(false);
        NativeBridge.stopForegroundService();
        notifyListeners();
      },
    );
  }

  Future<void> startHunting() async {
    if (_engine == null || _settingsProvider == null) return;
    if (_engine!.isRunning) return;

    // التأكد من استثناء البطارية ليعمل في الخلفية بلا انقطاع
    final ignoringBattery = await NativeBridge.isIgnoringBatteryOptimizations();
    if (!ignoringBattery) {
      await NativeBridge.requestIgnoreBatteryOptimizations();
    }

    // حفظ اسم الشبكة الحالية التي بدأ منها الاصطياد
    final currentSsid = await NativeBridge.getCurrentWifiSsid();
    if (currentSsid.isNotEmpty) {
      _huntingSsid = currentSsid;
      _currentWifiSsid = currentSsid;
      await _db.setState('last_hunting_ssid', currentSsid);
      _logsProvider?.addLog('📡 الشبكة المستهدفة للفحص والاصطياد: "$currentSsid"');
    }

    await NativeBridge.setKeepScreenOn(true);
    await NativeBridge.startForegroundService(
      title: 'Network Hunter • قيد الفحص والاصطياد 🚀',
      body: 'الشبكة: ${_huntingSsid.isNotEmpty ? _huntingSsid : "الافتراضية"} | الرقم الابتدائي: ${_settingsProvider!.settings.startNumber}',
      subText: 'يعمل في الخلفية بلا توقف',
    );
    await _engine!.start(_settingsProvider!.settings);
    notifyListeners();
  }

  void pauseHunting() {
    _engine?.pause();
    _syncLiveForegroundNotification();
    notifyListeners();
  }

  void resumeHunting() {
    _engine?.resume();
    _syncLiveForegroundNotification();
    notifyListeners();
  }

  void stopHunting() {
    _engine?.stop();
    NativeBridge.stopForegroundService();
    notifyListeners();
  }

  Future<void> manualUnban() async {
    // حفظ اسم الشبكة الحالية قبل بدء فك الحظر لمقارنتها بعد إعادة الاتصال
    final currentSsid = await NativeBridge.getCurrentWifiSsid();
    if (currentSsid.isNotEmpty) {
      _huntingSsid = currentSsid;
      _currentWifiSsid = currentSsid;
      await _db.setState('last_hunting_ssid', currentSsid);
      _logsProvider?.addLog('📡 حفظ اسم الشبكة قبل فك الحظر: "$currentSsid"');
    }

    _status = EngineStatus.unbanning;
    _statusText = AppStrings.statusUnbanning;
    notifyListeners();

    _logsProvider?.addLog('🔓 بدء تنفيذ فك الحظر يدوياً الآن...');
    final res = await UnbanService.performUnban(
      log: (m) => _logsProvider?.addLog(m),
    );

    if (res['success'] == true) {
      _unbanCount++;
      _status = EngineStatus.ready;
      _statusText = AppStrings.statusReady;
      notifyListeners();
    } else {
      // للمستخدم بدون روت، ننتظر قيامه بتبديل الواي فاي أو العودة للتطبيق
      _statusText = 'بانتظار تجديد الاتصال بالشبكة... 🔄';
      notifyListeners();
    }
  }
}

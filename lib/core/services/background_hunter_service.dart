import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:networking/core/utils/native_bridge.dart';
import 'package:networking/core/utils/sound_helper.dart';
import 'package:networking/data/datasources/database_helper.dart';
import 'package:networking/data/datasources/hive_helper.dart';
import 'package:networking/data/models/settings_model.dart';
import 'package:networking/domain/engine/hunter_engine.dart';

class BackgroundHunterService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static FlutterBackgroundService get instance => _service;

  /// تهيئة خدمة الخلفية المستقلة
  static Future<void> initializeService() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'hunter_live_status_channel',
        initialNotificationTitle: 'Network Hunter • الخلفية',
        initialNotificationContent: 'جاري تهيئة خدمة الفحص والاصطياد...',
        foregroundServiceNotificationId: 1001,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onBackgroundServiceStart,
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await HiveHelper.instance.init();

  final db = DatabaseHelper.instance;
  HunterEngine? engine;
  String currentStatus = 'ready';
  String currentStatusMessage = 'جاهز ومستعد 🟢';
  String currentNumber = '-';
  int totalAttempts = 0;
  int foundCount = 0;
  int unbanCount = 0;
  String lastLog = 'بدء تشغيل خدمة الخلفية المستقلة بنجاح.';

  void updateNotification() {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Network Hunter • $currentStatusMessage',
        content:
            'الكرت: $currentNumber | المحاولات: $totalAttempts | المكتشفة: $foundCount\n$lastLog',
      );
    }
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }

  // الاستماع لأمر بدء الفحص
  service.on('startHunting').listen((event) async {
    final settingsMap = (event?['settings'] as Map?)?.cast<String, dynamic>();
    final settings = settingsMap != null
        ? SettingsModel.fromMap(
            settingsMap.map((k, v) => MapEntry(k, v.toString())),
          )
        : SettingsModel();

    // في خدمة الخلفية المستقلة، نستخدم وضع HTTP الصارم والموثوق لضمان العمل بعد إغلاق التطبيق نهائياً
    final effectiveSettings = settings.copyWith(useWebView: false);

    engine = HunterEngine(
      db: db,
      onLog: (msg) {
        lastLog = msg.trim();
        updateNotification();
        service.invoke('logUpdate', {'message': msg});
      },
      onStats: (curNum, attempts, found, unbans) {
        currentNumber = curNum;
        totalAttempts = attempts;
        foundCount = found;
        unbanCount = unbans;
        updateNotification();
        service.invoke('statsUpdate', {
          'currentNumber': curNum,
          'totalAttempts': attempts,
          'foundCount': found,
          'unbanCount': unbans,
        });
      },
      onStatusChange: (status, message) {
        currentStatus = status.name;
        currentStatusMessage = message;
        updateNotification();
        service.invoke('statusUpdate', {
          'status': status.name,
          'message': message,
        });
      },
      onFound: (cardNumber, loginUrl) {
        service.invoke('cardFound', {
          'cardNumber': cardNumber,
          'loginUrl': loginUrl,
        });
        SoundHelper.playAlert(isError: false);
        NativeBridge.showAlertNotification(
          title: '🎉 تم اصطياد كرت شبكة صحيح بنجاح!',
          body: 'رقم الكرت: $cardNumber\nالرابط: $loginUrl',
          isError: false,
          alertType: 'success',
        );
      },
      onFinished: () {
        currentStatus = 'ready';
        currentStatusMessage = 'جاهز ومستعد 🟢';
        updateNotification();
        service.invoke('engineFinished');
      },
    );

    updateNotification();
    await engine!.start(effectiveSettings);
  });

  // الاستماع لأمر الإيقاف المؤقت
  service.on('pauseHunting').listen((_) {
    engine?.pause();
    currentStatus = 'paused';
    currentStatusMessage = 'متوقف مؤقتاً ⏸️';
    updateNotification();
  });

  // الاستماع لأمر الاستئناف
  service.on('resumeHunting').listen((_) {
    engine?.resume();
    currentStatus = 'running';
    currentStatusMessage = 'قيد الفحص والاصطياد... 🚀';
    updateNotification();
  });

  // الاستماع لأمر الإيقاف الكامل
  service.on('stopHunting').listen((_) {
    engine?.stop();
    currentStatus = 'stopping';
    currentStatusMessage = 'جاري الإيقاف... ⏳';
    updateNotification();
    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
  });

  // مزامنة الإعدادات لحظياً أثناء عمل الفحص في الخلفية
  service.on('syncSettings').listen((event) {
    final settingsMap = (event?['settings'] as Map?)?.cast<String, dynamic>();
    if (settingsMap != null) {
      final s = SettingsModel.fromMap(
        settingsMap.map((k, v) => MapEntry(k, v.toString())),
      );
      engine?.updateConfig(s);
    }
  });

  // الرد على استعلام الواجهة عن الحالة الحالية عند إعادة فتح التطبيق
  service.on('requestStatus').listen((_) {
    service.invoke('statusResponse', {
      'isRunning': engine?.isRunning ?? false,
      'isPaused': engine?.isPaused ?? false,
      'status': currentStatus,
      'statusMessage': currentStatusMessage,
      'currentNumber': currentNumber,
      'totalAttempts': totalAttempts,
      'foundCount': foundCount,
      'unbanCount': unbanCount,
      'lastLog': lastLog,
    });
  });
}

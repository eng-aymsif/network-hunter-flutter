import 'dart:async';
import 'package:flutter/services.dart';
import 'package:networking/core/utils/platform_env.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.example.networking/native',
  );
  static void Function(String newSsid)? _onWifiChangedCallback;
  static void Function(String ssid, bool isCaptive)? _onCaptivePortalCallback;
  static bool _handlerInitialized = false;
  static Timer? _windowsWifiPollTimer;
  static String _lastWindowsSsid = '';

  static void _ensureMethodCallHandler() {
    if (PlatformEnv.isWeb) return;

    if (PlatformEnv.isWindows) {
      _startWindowsWifiPollingIfNeeded();
      return;
    }

    if (!_handlerInitialized) {
      _handlerInitialized = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onWifiNetworkChanged') {
          final map = call.arguments as Map?;
          final ssid = map?['ssid']?.toString() ?? '';
          if (ssid.isNotEmpty) {
            _onWifiChangedCallback?.call(ssid);
          }
        } else if (call.method == 'onCaptivePortalDetected') {
          final map = call.arguments as Map?;
          final ssid = map?['ssid']?.toString() ?? '';
          final isCaptive = map?['isCaptive'] == true;
          _onCaptivePortalCallback?.call(ssid, isCaptive);
        }
      });
    }
  }

  static void _startWindowsWifiPollingIfNeeded() {
    if (_windowsWifiPollTimer != null) return;
    if (PlatformEnv.isFlutterTest) return;

    _windowsWifiPollTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) async {
        final ssid = await PlatformEnv.getWindowsWifiSsid();
        if (ssid.isNotEmpty && ssid != _lastWindowsSsid) {
          _lastWindowsSsid = ssid;
          _onWifiChangedCallback?.call(ssid);
        }
      },
    );
  }

  /// الاستماع الفوري لأحداث تغير اسم شبكة الواي فاي المتصل بها (أندرويد + ويندوز)
  static void setWifiNetworkChangeListener(
    void Function(String newSsid) onWifiChanged,
  ) {
    _onWifiChangedCallback = onWifiChanged;
    _ensureMethodCallHandler();
  }

  /// الاستماع الفوري لحالة بوابة الشبكة (Captive Portal / Sign in to network)
  static void setCaptivePortalListener(
    void Function(String ssid, bool isCaptive) onCaptivePortal,
  ) {
    _onCaptivePortalCallback = onCaptivePortal;
    _ensureMethodCallHandler();
  }

  /// التحقق الفوري مما إذا كانت شبكة الواي فاي الحالية في وضع Captive Portal (تتطلب تسجيل الدخول)
  static Future<bool> checkIsCaptivePortal() async {
    if (PlatformEnv.isWeb || PlatformEnv.isWindows) {
      return false;
    }
    try {
      final res = await _channel.invokeMethod<bool>('checkIsCaptivePortal');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// مسح كافة الكوكيز وبيانات WebStorage والكاش من النظام الأصلي (أندرويد + ويندوز + ويب)
  static Future<void> clearWebStorageAndCache() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      await PlatformEnv.clearSystemNetworkAndWebCache();
      return;
    }
    try {
      await _channel.invokeMethod('clearWebStorageAndCache');
    } catch (_) {}
  }

  /// جلب اسم شبكة الواي فاي المتصل بها حالياً (SSID)
  static Future<String> getCurrentWifiSsid() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      return await PlatformEnv.getWindowsWifiSsid();
    }
    try {
      final res = await _channel.invokeMethod<String>('getCurrentWifiSsid');
      return res ?? '';
    } catch (_) {
      return '';
    }
  }

  /// مشاركة النصوص وتصديرها عبر قائمة المشاركة أو الحافظة في سطح المكتب والويب
  static Future<void> shareText({required String text, String? subject}) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      await Clipboard.setData(ClipboardData(text: text));
      return;
    }
    try {
      await _channel.invokeMethod('shareText', {
        'text': text,
        'subject': subject,
      });
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  /// جلب مسار تخزين الملفات الخاص بالتطبيق
  static Future<String> getAppStoragePath() async {
    if (PlatformEnv.isWeb || PlatformEnv.isWindows) {
      return '';
    }
    try {
      final res = await _channel.invokeMethod<String>('getAppStoragePath');
      return res ?? '';
    } catch (_) {
      return '';
    }
  }

  /// مشاركة ملف عبر نافذة المشاركة القياسية أو فتح المجلد في ويندوز
  static Future<bool> shareFile({
    required String path,
    String? mimeType,
    String? title,
  }) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      return await PlatformEnv.openExportedFile(path, mimeType ?? '');
    }
    try {
      final res = await _channel.invokeMethod<bool>('shareFile', {
        'path': path,
        'mimeType': mimeType,
        'title': title,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// التحقق من منح إذن الوصول إلى الملفات لحفظ الإكسل في مجلدات الجهاز
  static Future<bool> checkStoragePermission() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      return true;
    }
    try {
      final res = await _channel.invokeMethod<bool>('checkStoragePermission');
      return res ?? false;
    } catch (_) {
      return true;
    }
  }

  /// طلب إذن الوصول إلى الملفات من نظام أندرويد
  static Future<void> requestStoragePermission() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('requestStoragePermission');
    } catch (_) {}
  }

  /// حفظ ملف في مجلد عام داخل تطبيق الملفات (أندرويد + ويندوز + تنزيل مباشر في الويب)
  static Future<Map<String, dynamic>> saveFileToPublicFolder({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final effectiveMime = mimeType ??
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      return await PlatformEnv.saveExportedFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: effectiveMime,
      );
    }

    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'saveFileToPublicFolder',
        {
          'fileName': fileName,
          'bytes': bytes,
          'mimeType': effectiveMime,
        },
      );
      if (res != null && res['success'] == true) {
        return res;
      }
    } catch (_) {}

    return await PlatformEnv.saveExportedFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: effectiveMime,
    );
  }

  /// فتح ملف مُصدر مباشرة عبر تطبيقات العرض في الجهاز (مثل Excel أو Sheets)
  static Future<bool> openFile({
    required String path,
    String? mimeType,
  }) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      return await PlatformEnv.openExportedFile(path, mimeType ?? '');
    }
    try {
      final res = await _channel.invokeMethod<bool>('openFile', {
        'path': path,
        'mimeType': mimeType,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// إبقاء الشاشة مفعلة أثناء الفحص لمنع سكون المعالج
  static Future<void> setKeepScreenOn(bool enable) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('setKeepScreenOn', {
        'enable': enable,
      });
    } catch (_) {}
  }

  /// التحقق من توفر صلاحيات التحكم بالشبكة (Root في أندرويد، أو PowerShell/Netsh في ويندوز)
  static Future<bool> checkRoot() async {
    if (PlatformEnv.isWindows) {
      return true;
    }
    if (PlatformEnv.isWeb) {
      return false;
    }
    try {
      final res = await _channel.invokeMethod<bool>('checkRoot');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// تنفيذ تغيير الماك الفعلي وتفريغ الكاش (عبر الروت في أندرويد، أو PowerShell/NetAdapter في ويندوز)
  static Future<Map<String, dynamic>> executeRootMacChange(String mac) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      return await PlatformEnv.executeWindowsMacChange(mac);
    }
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'executeRootMacChange',
        {'mac': mac},
      );
      return res ?? {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// إعادة الاتصال بالواي فاي لتوليد ماك عشوائي جديد أو تجديد الجلسة
  static Future<bool> reconnectWifi() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) {
      return await PlatformEnv.reconnectWindowsWifi();
    }
    try {
      final res = await _channel.invokeMethod<bool>('reconnectWifi');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// فتح إعدادات أو لوحة الواي فاي السريعة (أندرويد + ويندوز)
  static Future<void> openWifiSettings() async {
    if (PlatformEnv.isWindows) {
      await PlatformEnv.openSystemWifiSettings();
      return;
    }
    if (PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('openWifiSettings');
    } catch (_) {}
  }

  /// طلب أذونات النظام الديناميكية (الواي فاي والموقع والإشعارات)
  static Future<void> requestAppPermissions() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('requestAppPermissions');
    } catch (_) {}
  }

  /// التحقق من منح الأذونات
  static Future<bool> checkPermissions() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return true;
    try {
      final res = await _channel.invokeMethod<bool>('checkPermissions');
      return res ?? false;
    } catch (_) {
      return true;
    }
  }

  /// تشغيل خدمة الخلفية الدائمة مع إشعار المعاينة الحية
  static Future<void> startForegroundService({
    required String title,
    required String body,
    String? subText,
  }) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('startForegroundService', {
        'title': title,
        'body': body,
        'subText': subText,
      });
    } catch (_) {}
  }

  /// تحديث محتوى إشعار المعاينة الحية في الخلفية
  static Future<void> updateForegroundNotification({
    required String title,
    required String body,
    String? subText,
  }) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('updateForegroundNotification', {
        'title': title,
        'body': body,
        'subText': subText,
      });
    } catch (_) {}
  }

  /// إيقاف خدمة الخلفية الدائمة
  static Future<void> stopForegroundService() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('stopForegroundService');
    } catch (_) {}
  }

  /// إطلاق إشعار تنبيهي مستقل عالي الصوت والأولوية (للنجاح أو الخلل الحرج أو تغير الشبكة)
  static Future<void> showAlertNotification({
    required String title,
    required String body,
    bool isError = false,
    String alertType = 'success',
  }) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('showAlertNotification', {
        'title': title,
        'body': body,
        'isError': isError,
        'alertType': alertType,
      });
    } catch (_) {}
  }

  /// رفع مستوى صوت الجهاز لأقصى درجة للتنبيهات
  static Future<void> maximizeVolume() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('maximizeVolume');
    } catch (_) {}
  }

  /// تشغيل ملفات الصوت المخصصة في الخلفية من assets/sounds/alert.mp3 أو alert_error.mp3
  static Future<void> playCustomAlertSound({bool isError = false}) async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('playCustomAlertSound', {
        'isError': isError,
      });
    } catch (_) {}
  }

  /// التحقق من استثناء التطبيق من قيود تحسين البطارية (Unrestricted Battery)
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return true;
    try {
      final res = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// طلب استثناء التطبيق من قيود البطارية ليعمل في الخلفية دون انقطاع
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (PlatformEnv.isWindows || PlatformEnv.isWeb) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }
}

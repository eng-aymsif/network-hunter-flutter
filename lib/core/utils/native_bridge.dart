import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.example.networking/native');
  static void Function(String newSsid)? _onWifiChangedCallback;
  static bool _handlerInitialized = false;

  /// الاستماع الفوري لأحداث BroadcastReceiver عند تغير اسم شبكة الواي فاي المتصل بها
  static void setWifiNetworkChangeListener(void Function(String newSsid) onWifiChanged) {
    _onWifiChangedCallback = onWifiChanged;
    if (!_handlerInitialized) {
      _handlerInitialized = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onWifiNetworkChanged') {
          final map = call.arguments as Map?;
          final ssid = map?['ssid']?.toString() ?? '';
          if (ssid.isNotEmpty) {
            _onWifiChangedCallback?.call(ssid);
          }
        }
      });
    }
  }

  /// جلب اسم شبكة الواي فاي المتصل بها حالياً (SSID)
  static Future<String> getCurrentWifiSsid() async {
    try {
      final res = await _channel.invokeMethod<String>('getCurrentWifiSsid');
      return res ?? '';
    } catch (_) {
      return '';
    }
  }

  /// مشاركة النصوص وتصديرها عبر قائمة المشاركة القياسية في أندرويد
  static Future<void> shareText({required String text, String? subject}) async {
    try {
      await _channel.invokeMethod('shareText', {
        'text': text,
        'subject': subject,
      });
    } catch (_) {}
  }

  /// إبقاء الشاشة مفعلة أثناء الفحص لمنع سكون المعالج
  static Future<void> setKeepScreenOn(bool enable) async {
    try {
      await _channel.invokeMethod('setKeepScreenOn', {
        'enable': enable,
      });
    } catch (_) {}
  }

  /// التحقق الفعلي من توفر صلاحيات الروت في النظام
  static Future<bool> checkRoot() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkRoot');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// تنفيذ تغيير الماك الفعلي عبر الروت
  static Future<Map<String, dynamic>> executeRootMacChange(String mac) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('executeRootMacChange', {'mac': mac});
      return res ?? {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// إعادة الاتصال بالواي فاي لتوليد ماك عشوائي جديد
  static Future<bool> reconnectWifi() async {
    try {
      final res = await _channel.invokeMethod<bool>('reconnectWifi');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// فتح إعدادات أو لوحة الواي فاي السريعة
  static Future<void> openWifiSettings() async {
    try {
      await _channel.invokeMethod('openWifiSettings');
    } catch (_) {}
  }

  /// طلب أذونات النظام الديناميكية (الواي فاي والموقع والإشعارات)
  static Future<void> requestAppPermissions() async {
    try {
      await _channel.invokeMethod('requestAppPermissions');
    } catch (_) {}
  }

  /// التحقق من منح الأذونات
  static Future<bool> checkPermissions() async {
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
    try {
      await _channel.invokeMethod('maximizeVolume');
    } catch (_) {}
  }

  /// تشغيل ملفات الصوت المخصصة في الخلفية من assets/sounds/alert.mp3 أو alert_error.mp3
  static Future<void> playCustomAlertSound({bool isError = false}) async {
    try {
      await _channel.invokeMethod('playCustomAlertSound', {
        'isError': isError,
      });
    } catch (_) {}
  }

  /// التحقق من استثناء التطبيق من قيود تحسين البطارية (Unrestricted Battery)
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final res = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// طلب استثناء التطبيق من قيود تحسين البطارية
  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }
}

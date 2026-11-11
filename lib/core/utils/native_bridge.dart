import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.example.networking/native');

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
}

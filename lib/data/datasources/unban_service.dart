import 'dart:math';
import 'package:networking/core/utils/native_bridge.dart';
import 'package:networking/core/utils/platform_env.dart';

class UnbanService {
  static final Random _random = Random();

  /// توليد عنوان MAC أدرس عشوائي متوافق مع معايير Unicast/Local
  static String generateValidMac() {
    const validSecondHex = ['2', '6', 'A', 'E'];
    const hexChars = '0123456789ABCDEF';

    final first = hexChars[_random.nextInt(hexChars.length)];
    final second = validSecondHex[_random.nextInt(validSecondHex.length)];
    final byte1 = '$first$second';

    final otherBytes = List.generate(5, (_) {
      final b = _random.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase();
      return b;
    });

    return [byte1, ...otherBytes].join(':');
  }

  /// التحقق الفعلي من توفر صلاحيات التحكم التلقائي بالشبكة (Root في أندرويد أو PowerShell في ويندوز)
  static Future<bool> isRootAvailable() async {
    return await NativeBridge.checkRoot();
  }

  /// تنفيذ عملية فك الحظر الحقيقية والشفافة بحسب بيئة التشغيل (Windows / Android / Web)
  static Future<Map<String, dynamic>> performUnban({void Function(String)? log}) async {
    final newMac = generateValidMac();

    // 1. بيئة ويندوز (Windows Desktop): تغيير الماك وتفريغ كاش DNS و ARP وإعادة ربط الواي فاي آلياً بدون قيود
    if (PlatformEnv.isWindows) {
      log?.call(
        '🖥️ [بيئة ويندوز المتقدمة]: بدء فك الحظر الآلي وتغيير MAC محول الشبكة إلى ($newMac) وتفريغ الكاش...',
      );
      final res = await PlatformEnv.executeWindowsMacChange(
        newMac,
        onLog: log,
      );
      if (res['success'] == true) {
        return {
          'success': true,
          'mac': newMac,
          'method': res['method'] ?? 'windows_auto',
        };
      } else {
        log?.call(
          '⚠️ تعذر إعادة الضبط التلقائي الكامل في ويندوز — يرجى تشغيل التطبيق كمسؤول (Run as Administrator) لتغيير MAC المحول.',
        );
        return {'success': false, 'mac': newMac, 'method': 'windows_failed'};
      }
    }

    // 2. بيئة الويب (Web Browser): تطهير الكوكيز والجلسة المحلية
    if (PlatformEnv.isWeb) {
      final res = await PlatformEnv.executeWindowsMacChange(
        newMac,
        onLog: log,
      );
      return res;
    }

    // 3. بيئة أندرويد (Root / Non-Root)
    final hasRoot = await isRootAvailable();

    if (hasRoot) {
      log?.call('🔓 تم اكتشاف صلاحية الروت (Root): جاري تنفيذ تغيير الماك الفعلي إلى: $newMac...');
      final res = await NativeBridge.executeRootMacChange(newMac);
      if (res['success'] == true) {
        log?.call('✓ تم تغيير MAC كارت الشبكة wlan0 بنجاح عبر أوامر الروت إلى: $newMac');
        return {'success': true, 'mac': newMac, 'method': 'root'};
      } else {
        log?.call('⚠️ فشل أمر الروت في تغيير الماك: ${res['error'] ?? "Unknown"}');
      }
    }

    // الأجهزة بدون روت في أندرويد
    log?.call('ℹ️ تنبيه: هذا الهاتف لا يمتلك صلاحيات الروت (Non-Root).');
    log?.call('📱 في نظام أندرويد الحديث، يمنع النظام التطبيقات من تغيير الماك أو إيقاف الواي فاي بالخلفية بدون روت.');
    log?.call('🔄 تم فتح لوحة الواي فاي السريعة: يرجى إيقاف الواي فاي وتشغيله يدوياً لتجديد الماك العشوائي.');
    await NativeBridge.openWifiSettings();

    return {'success': false, 'mac': 'يتطلب تبديل يدوي', 'method': 'manual_toggle'};
  }
}

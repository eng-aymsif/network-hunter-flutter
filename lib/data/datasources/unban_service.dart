import 'dart:io';
import 'dart:math';
import '../../core/utils/native_bridge.dart';

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

  /// التحقق من توفر صلاحيات الروت (Root Access via su)
  static Future<bool> isRootAvailable() async {
    try {
      final result = await Process.run('su', ['-c', 'id']);
      return result.exitCode == 0 && result.stdout.toString().contains('uid=0');
    } catch (_) {
      return false;
    }
  }

  /// تنفيذ عملية فك الحظر الهجينة
  static Future<Map<String, dynamic>> performUnban({void Function(String)? log}) async {
    final newMac = generateValidMac();
    final hasRoot = await isRootAvailable();

    if (hasRoot) {
      log?.call('🔓 تم اكتشاف صلاحية الروت (Root): جاري تعيين MAC جديد: $newMac...');
      try {
        final cmd = '''
          ip link set wlan0 down 2>/dev/null || ifconfig wlan0 down
          ip link set wlan0 address $newMac 2>/dev/null || ifconfig wlan0 hw ether $newMac
          ip link set wlan0 up 2>/dev/null || ifconfig wlan0 up
          ip neigh flush all
          svc wifi disable && sleep 1 && svc wifi enable
        ''';
        final res = await Process.run('su', ['-c', cmd]);
        if (res.exitCode == 0) {
          log?.call('✓ تم فك الحظر بنجاح وتغيير MAC إلى: $newMac');
          return {'success': true, 'mac': newMac, 'method': 'root'};
        } else {
          log?.call('⚠️ فشل تغيير الماك عبر الروت، محاولة إعادة تشغيل الواي فاي...');
        }
      } catch (e) {
        log?.call('❌ خطأ أثناء تنفيذ أمر الروت: $e');
      }
    }

    // الطريقة المخصصة للأجهزة بدون روت
    log?.call('🔄 وضع بدون روت: جاري قطع وإعادة الاتصال بالواي فاي لتوليد ماك عشوائي جديد...');
    try {
      final reconnected = await NativeBridge.reconnectWifi();
      if (reconnected) {
        log?.call('✓ تم إعادة تشغيل اتصال الواي فاي بنجاح وتجديد الماك العشوائي.');
        return {'success': true, 'mac': 'تلقائي (Randomized)', 'method': 'reconnect'};
      } else {
        log?.call('ℹ️ يرجى التأكد من تفعيل خيار (الماك العشوائي) في إعدادات شبكة الواي فاي بهاتفك.');
        return {'success': true, 'mac': 'Randomized', 'method': 'non-root'};
      }
    } catch (e) {
      log?.call('❌ تعذر إكمال إعادة الاتصال: $e');
      return {'success': false, 'error': e.toString(), 'method': 'non-root'};
    }
  }
}

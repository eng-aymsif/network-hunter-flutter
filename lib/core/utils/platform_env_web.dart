import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('eval')
external JSAny? _jsEval(JSString script);

class PlatformEnv {
  static bool get isFlutterTest =>
      const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  static bool get isAndroid => false;
  static bool get isWindows => false;
  static bool get isWeb => true;
  static bool get isDesktop => true;
  static String get platformName => 'Web Edition';

  static bool get isBrowserOnline {
    try {
      final res = _jsEval('Boolean(window.navigator.onLine)'.toJS);
      if (res != null && res.isA<JSBoolean>()) {
        return (res as JSBoolean).toDart;
      }
    } catch (_) {}
    return true;
  }

  static String getPersistentWebDeviceId() {
    try {
      final item =
          _jsEval('window.localStorage.getItem("nh_web_device_id")'.toJS);
      if (item != null && item.isA<JSString>()) {
        final val = (item as JSString).toDart.trim();
        if (val.isNotEmpty) return val;
      }
      final newId = 'WEB_${DateTime.now().millisecondsSinceEpoch}';
      _jsEval(
        'window.localStorage.setItem("nh_web_device_id", "$newId")'.toJS,
      );
      return newId;
    } catch (_) {
      return 'WEB_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  static Future<bool> lookupHost(
    String host, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    return true;
  }

  static Future<bool> probePort(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    return true;
  }

  static String createTempDirectorySync(String prefix) => '';

  static Future<String> getWindowsWifiSsid() async => 'شبكة المتصفح (Web)';

  static Future<bool> isWindowsElevatedOrCapable() async => false;

  static Future<Map<String, dynamic>> executeWindowsMacChange(
    String mac, {
    void Function(String msg)? onLog,
  }) async {
    onLog?.call(
      '🌐 [Web]: تم تطهير الجلسة والكوكيز المحلية في المتصفح لإعادة المحاولة.',
    );
    await clearSystemNetworkAndWebCache();
    return {'success': true, 'mac': mac, 'method': 'web_session_reset'};
  }

  static Future<bool> reconnectWindowsWifi({
    void Function(String msg)? onLog,
  }) async {
    await clearSystemNetworkAndWebCache();
    return true;
  }

  static Future<void> clearSystemNetworkAndWebCache() async {
    try {
      _jsEval(
        '(function(){ try { document.cookie.split(";").forEach(function(c) { document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/"); }); } catch(e){} })()'
            .toJS,
      );
    } catch (_) {}
  }

  static Future<void> openSystemWifiSettings() async {}

  /// تنزيل ملف الإكسل مباشرة في متصفح الويب (Chrome / Edge / Safari)
  static Future<Map<String, dynamic>> saveExportedFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? fallbackBaseDir,
  }) async {
    try {
      final b64 = base64Encode(bytes);
      final safeName = fileName.replaceAll("'", '').replaceAll('"', '');
      final jsDownload = '''
(function() {
  var a = document.createElement('a');
  a.href = 'data:$mimeType;base64,$b64';
  a.download = '$safeName';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
})();
''';
      _jsEval(jsDownload.toJS);
      return {
        'success': true,
        'fileName': fileName,
        'filePath': 'Downloads/$fileName',
        'sharePath': 'Downloads/$fileName',
        'displayFolder': 'تنزيلات المتصفح (Browser Downloads)',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<bool> openExportedFile(String path, String mimeType) async =>
      true;
}

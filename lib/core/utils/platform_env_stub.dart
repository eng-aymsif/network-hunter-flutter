import 'dart:typed_data';

class PlatformEnv {
  static bool get isFlutterTest => false;
  static bool get isAndroid => false;
  static bool get isWindows => false;
  static bool get isWeb => false;
  static bool get isDesktop => false;
  static String get platformName => 'Unknown';

  static Future<bool> lookupHost(
    String host, {
    Duration timeout = const Duration(seconds: 3),
  }) async => false;

  static Future<bool> probePort(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async => false;

  static String createTempDirectorySync(String prefix) => '';

  static Future<String> getWindowsWifiSsid() async => '';

  static Future<bool> isWindowsElevatedOrCapable() async => false;

  static Future<Map<String, dynamic>> executeWindowsMacChange(
    String mac, {
    void Function(String msg)? onLog,
  }) async => {'success': false};

  static Future<bool> reconnectWindowsWifi({
    void Function(String msg)? onLog,
  }) async => false;

  static Future<void> clearSystemNetworkAndWebCache() async {}

  static Future<void> openSystemWifiSettings() async {}

  static Future<Map<String, dynamic>> saveExportedFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? fallbackBaseDir,
  }) async => {'success': false};

  static Future<bool> openExportedFile(String path, String mimeType) async =>
      false;
}

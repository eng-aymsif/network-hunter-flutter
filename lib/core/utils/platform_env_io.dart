import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class PlatformEnv {
  static bool get isFlutterTest =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  static bool get isAndroid => Platform.isAndroid;
  static bool get isWindows => Platform.isWindows;
  static bool get isWeb => false;
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  static bool get isBrowserOnline => true;
  static String getPersistentWebDeviceId() => '';

  static String get platformName {
    if (Platform.isWindows) return 'Windows Pro';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Native';
  }

  static Future<bool> lookupHost(
    String host, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final parsed = InternetAddress.tryParse(host);
      if (parsed != null) return true;
      final res = await InternetAddress.lookup(host).timeout(timeout);
      return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> probePort(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      String targetHost = host;
      final parsed = InternetAddress.tryParse(host);
      if (parsed == null) {
        final lookup = await InternetAddress.lookup(host).timeout(timeout);
        if (lookup.isNotEmpty) {
          targetHost = lookup.first.address;
        }
      }
      final socket = await Socket.connect(
        targetHost,
        port,
        timeout: timeout,
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static String createTempDirectorySync(String prefix) {
    final temp = Directory.systemTemp.createTempSync(prefix);
    return temp.path;
  }

  /// جلب اسم شبكة الواي فاي المتصل بها في نظام ويندوز عبر netsh
  static Future<String> getWindowsWifiSsid() async {
    if (!Platform.isWindows || isFlutterTest) return '';
    try {
      final res = await Process.run(
        'netsh',
        ['wlan', 'show', 'interfaces'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 4));

      final output = res.stdout.toString();
      for (final rawLine in output.split('\n')) {
        final line = rawLine.trim();
        if (line.startsWith('SSID') &&
            !line.startsWith('BSSID') &&
            line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final ssid = parts.sublist(1).join(':').trim();
            if (ssid.isNotEmpty) return ssid;
          }
        }
      }
    } catch (_) {}
    return '';
  }

  /// التحقق مما إذا كان التطبيق يعمل بصلاحيات مسؤول (Administrator) في ويندوز أو إمكانية تعديل محول الشبكة
  static Future<bool> isWindowsElevatedOrCapable() async {
    if (!Platform.isWindows || isFlutterTest) return false;
    try {
      final res = await Process.run('net', ['session'])
          .timeout(const Duration(seconds: 3));
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// تغيير عنوان الـ MAC وتفريغ كاش DNS و ARP وإعادة تشغيل محول الواي فاي تلقائياً في ويندوز
  static Future<Map<String, dynamic>> executeWindowsMacChange(
    String mac, {
    void Function(String msg)? onLog,
  }) async {
    if (!Platform.isWindows) return {'success': false};

    final cleanMac = mac.replaceAll(':', '').replaceAll('-', '').toUpperCase();
    final currentSsid = await getWindowsWifiSsid();

    try {
      onLog?.call(
        '🖥️ [Windows Unban]: جاري تفريغ كاش DNS وجدول ARP وتغيير عنوان الـ MAC إلى $mac...',
      );

      // 1. تفريغ DNS و ARP
      try {
        await Process.run('ipconfig', ['/flushdns']);
        await Process.run('arp', ['-d', '*']);
      } catch (_) {}

      // 2. سكريبت PowerShell لتحديد محول الواي فاي وتغيير NetworkAddress وإعادة تشغيله
      final psScript = '''
\$ErrorActionPreference = 'SilentlyContinue'
\$adapter = Get-NetAdapter | Where-Object { \$_.Name -like '*Wi-Fi*' -or \$_.Name -like '*Wireless*' -or \$_.InterfaceDescription -like '*Wireless*' -or \$_.InterfaceDescription -like '*802.11*' -or \$_.Status -eq 'Up' } | Select-Object -First 1
if (\$null -ne \$adapter) {
  \$name = \$adapter.Name
  Set-NetAdapterAdvancedProperty -Name \$name -RegistryKeyword "NetworkAddress" -RegistryValue "$cleanMac" -ErrorAction SilentlyContinue
  Set-NetAdapter -Name \$name -MacAddress "$cleanMac" -Confirm:\$false -ErrorAction SilentlyContinue
  Restart-NetAdapter -Name \$name -Confirm:\$false -ErrorAction SilentlyContinue
  Write-Output "OK:\$name"
} else {
  Write-Output "NO_ADAPTER"
}
''';

      final psRes = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', psScript],
        stdoutEncoding: utf8,
      ).timeout(const Duration(seconds: 12));

      final out = psRes.stdout.toString().trim();

      // 3. إعادة الاتصال بالواي فاي إذا كان هناك SSID محفوظ
      if (currentSsid.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        await Process.run('netsh', [
          'wlan',
          'connect',
          'name=$currentSsid',
        ]);
      }

      if (out.contains('OK:')) {
        final adapterName = out.split('OK:').last.trim();
        onLog?.call(
          '✅ [Windows Unban]: تم تحديث عنوان الـ MAC وتفريغ الكاش وإعادة تشغيل المحول ($adapterName) بنجاح!',
        );
        return {
          'success': true,
          'mac': mac,
          'method': 'windows_powershell',
          'adapter': adapterName,
        };
      }

      // حتى لو لم يمتلك صلاحية تغيير الريجستري، ننفذ قطع وإعادة اتصال بالواي فاي وتفريغ الكاش
      final reconnected = await reconnectWindowsWifi(onLog: onLog);
      return {
        'success': reconnected,
        'mac': mac,
        'method': 'windows_netsh_reset',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// فصل وإعادة ربط شبكة الواي فاي وتجديد الـ IP في ويندوز تلقائياً
  static Future<bool> reconnectWindowsWifi({
    void Function(String msg)? onLog,
  }) async {
    if (!Platform.isWindows) return false;
    try {
      final ssid = await getWindowsWifiSsid();
      onLog?.call(
        '🔄 [Windows Wi-Fi]: جاري تفريغ كاش الشبكة وفصل وإعادة الاتصال بالواي فاي${ssid.isNotEmpty ? ' ($ssid)' : ''}...',
      );

      await Process.run('ipconfig', ['/flushdns']);
      await Process.run('arp', ['-d', '*']);

      if (ssid.isNotEmpty) {
        await Process.run('netsh', ['wlan', 'disconnect']);
        await Future.delayed(const Duration(milliseconds: 1200));
        final conn = await Process.run('netsh', [
          'wlan',
          'connect',
          'name=$ssid',
        ]);
        await Future.delayed(const Duration(seconds: 2));
        return conn.exitCode == 0;
      } else {
        await Process.run('ipconfig', ['/release']);
        await Future.delayed(const Duration(milliseconds: 800));
        await Process.run('ipconfig', ['/renew']);
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  /// مسح كاش نظام ويندوز (DNS + ARP + WinINet Cookies/Cache)
  static Future<void> clearSystemNetworkAndWebCache() async {
    if (!Platform.isWindows) return;
    try {
      await Process.run('ipconfig', ['/flushdns']);
      await Process.run('arp', ['-d', '*']);
      // مسح كوكيز وكاش WinINet / Edge WebView المحلي إن وجد
      await Process.run('RunDll32.exe', [
        'InetCpl.cpl,ClearMyTracksByProcess',
        '255',
      ]);
    } catch (_) {}
  }

  /// فتح إعدادات الواي فاي في نظام ويندوز
  static Future<void> openSystemWifiSettings() async {
    if (!Platform.isWindows) return;
    try {
      await Process.run('cmd', ['/c', 'start', 'ms-settings:network-wifi']);
    } catch (_) {}
  }

  /// حفظ ملف الإكسل في مجلد واضح داخل نظام التشغيل (Windows Downloads / Network_Hunter)
  static Future<Map<String, dynamic>> saveExportedFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? fallbackBaseDir,
  }) async {
    try {
      Directory targetDir;
      String displayFolder;

      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? '';
        if (userProfile.isNotEmpty) {
          targetDir = Directory('$userProfile\\Downloads\\Network_Hunter');
          displayFolder = 'التنزيلات (Downloads) > Network_Hunter';
        } else {
          targetDir = Directory(
            '${Directory.current.path}\\Exports\\Network_Hunter',
          );
          displayFolder = targetDir.path;
        }
      } else {
        final base = fallbackBaseDir != null && fallbackBaseDir.isNotEmpty
            ? fallbackBaseDir
            : Directory.systemTemp.path;
        targetDir = Directory('$base/Network_Hunter');
        displayFolder = targetDir.path;
      }

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final sep = Platform.isWindows ? '\\' : '/';
      final filePath = '${targetDir.path}$sep$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      return {
        'success': true,
        'fileName': fileName,
        'filePath': filePath,
        'sharePath': filePath,
        'displayFolder': displayFolder,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// فتح ملف الإكسل أو إظهاره في مستكشف الملفات في ويندوز
  static Future<bool> openExportedFile(String path, String mimeType) async {
    if (path.isEmpty) return false;
    if (Platform.isWindows) {
      try {
        final f = File(path);
        if (!f.existsSync()) return false;
        await Process.run('cmd', ['/c', 'start', '', path]);
        return true;
      } catch (_) {
        try {
          await Process.run('explorer.exe', ['/select,$path']);
          return true;
        } catch (_) {
          return false;
        }
      }
    }
    return false;
  }
}

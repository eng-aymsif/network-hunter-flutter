import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:networking/data/datasources/hive_helper.dart';
import 'package:networking/data/models/subscription_model.dart';

class TimeIntegrityResult {
  final bool isValid;
  final String? errorMessage;

  const TimeIntegrityResult({required this.isValid, this.errorMessage});
}

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._internal();
  SubscriptionService._internal();

  /// الإصدار الحالي للتطبيق ورقم البناء الداخلي
  static const String currentAppVersion = '1.1.0';
  static const int currentVersionCode = 2;

  static const String serverBaseUrl = 'https://main.terhabb.com';
  static const String checkSubEndpoint = '/api/method/network_hunter.api.check_subscription';
  static const String requestSubEndpoint = '/api/method/network_hunter.api.request_subscription';
  static const String syncHuntedEndpoint = '/api/method/network_hunter.api.sync_card_hunted';
  static const String serverInfoEndpoint = '/api/method/network_hunter.api.get_server_info';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: serverBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'NetworkHunter-Flutter/$currentAppVersion',
      },
    ),
  );

  SubscriptionModel? _currentSubscription;
  String? _cachedDeviceId;
  Duration _serverTimeOffset = Duration.zero;

  SubscriptionModel? get currentSubscription => _currentSubscription;
  String? get deviceId => _cachedDeviceId;

  /// الحصول على بيانات الاشتراك المحفوظة محلياً في قواعد البيانات إن وجدت
  SubscriptionModel? getLocalSubscription() {
    if (_currentSubscription != null) return _currentSubscription;
    final localData = HiveHelper.instance.getAllSubscriptionData();
    if (localData.isNotEmpty && localData.containsKey('status')) {
      _currentSubscription = SubscriptionModel.fromJson(localData);
      return _currentSubscription;
    }
    return null;
  }

  /// الحصول على معرف فريد ومستقر للجهاز (Device ID)
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    // التحقق أولاً من القيمة المحفوظة محلياً في Hive
    final savedId = HiveHelper.instance.getSubscriptionValue('device_id');
    if (savedId != null && savedId.toString().trim().isNotEmpty) {
      _cachedDeviceId = savedId.toString().trim();
      return _cachedDeviceId!;
    }

    String detectedId = '';
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        detectedId = androidInfo.id;
        if (detectedId.isEmpty) {
          detectedId = '${androidInfo.manufacturer}_${androidInfo.model}_${androidInfo.device}';
        }
      } else if (!kIsWeb && Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        detectedId = windowsInfo.deviceId.replaceAll('{', '').replaceAll('}', '');
      } else {
        detectedId = 'DEV_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {
      detectedId = 'DEV_${DateTime.now().millisecondsSinceEpoch}';
    }

    // تنظيف المعرف وضمان تخزينه
    detectedId = detectedId.trim().replaceAll(' ', '_');
    _cachedDeviceId = detectedId;
    await HiveHelper.instance.saveSubscriptionData({'device_id': detectedId});
    // تسجيل رقم إصدار التطبيق المثبت محلياً للحماية من الـ Downgrade
    await HiveHelper.instance.recordInstalledVersionCode(currentVersionCode);
    return detectedId;
  }

  /// التحقق من الاتصال بالإنترنت العام
  Future<bool> checkInternetConnection() async {
    try {
      final res = await _dio.get(
        serverInfoEndpoint,
        options: Options(receiveTimeout: const Duration(seconds: 6)),
      );
      if (res.statusCode == 200) {
        _recordServerTime(res.data);
        return true;
      }
    } catch (_) {}

    try {
      final result = await InternetAddress.lookup('main.terhabb.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// فحص حالة الاشتراك من سيرفر Frappe
  Future<SubscriptionModel> checkSubscription({bool forceRefresh = false}) async {
    final devId = await getDeviceId();

    // استرجاع البيانات المحفوظة محلياً كـ fallback
    final localData = HiveHelper.instance.getAllSubscriptionData();
    if (!forceRefresh && localData.isNotEmpty && localData.containsKey('status')) {
      _currentSubscription = SubscriptionModel.fromJson(localData);
    }

    try {
      final response = await _dio.get(
        checkSubEndpoint,
        queryParameters: {
          'device_id': devId,
          'app_version': currentAppVersion,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        Map<String, dynamic>? msgMap;

        if (data is Map && data.containsKey('message')) {
          final m = data['message'];
          if (m is Map) {
            msgMap = Map<String, dynamic>.from(m);
          }
        } else if (data is Map) {
          msgMap = Map<String, dynamic>.from(data);
        }

        if (msgMap != null) {
          _recordServerTime(msgMap);

          final exists = msgMap['exists'] == true;
          if (exists) {
            final model = SubscriptionModel.fromJson(msgMap);
            _currentSubscription = model;
            await HiveHelper.instance.saveSubscriptionData(model.toJson());
            return model;
          } else {
            final model = SubscriptionModel(
              requestId: '',
              fullName: '',
              phoneNumber: '',
              deviceId: devId,
              status: 'NotFound',
            );
            _currentSubscription = model;
            await HiveHelper.instance.saveSubscriptionData(model.toJson());
            return model;
          }
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Error checking subscription: $e');
    }

    // إذا فشل الاتصال بالسيرفر، نعتمد على الكاش المحلي إن وجد
    if (_currentSubscription != null) {
      return _currentSubscription!;
    }

    return SubscriptionModel(
      requestId: '',
      fullName: '',
      phoneNumber: '',
      deviceId: devId,
      status: 'NotFound',
    );
  }

  /// إرسال طلب اشتراك جديد إلى سيرفر Frappe
  Future<Map<String, dynamic>> requestSubscription({
    required String fullName,
    required String phoneNumber,
  }) async {
    final devId = await getDeviceId();

    try {
      final formData = FormData.fromMap({
        'full_name': fullName.trim(),
        'phone_number': phoneNumber.trim(),
        'device_id': devId,
        'app_version': currentAppVersion,
      });

      final response = await _dio.post(
        requestSubEndpoint,
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        Map<String, dynamic>? msg;

        if (data is Map && data.containsKey('message')) {
          final m = data['message'];
          if (m is Map) msg = Map<String, dynamic>.from(m);
        } else if (data is Map) {
          msg = Map<String, dynamic>.from(data);
        }

        if (msg != null) {
          _recordServerTime(msg);
          final success = msg['success'] == true;
          final alreadyExists = msg['already_exists'] == true;
          final reqId = msg['request_id']?.toString() ?? '';
          final status = msg['status']?.toString() ?? 'Pending';

          final model = SubscriptionModel(
            requestId: reqId,
            fullName: fullName.trim(),
            phoneNumber: phoneNumber.trim(),
            deviceId: devId,
            status: status,
          );
          _currentSubscription = model;
          await HiveHelper.instance.saveSubscriptionData(model.toJson());

          return {
            'success': success || alreadyExists,
            'already_exists': alreadyExists,
            'message': msg['message']?.toString() ?? 'تم إرسال الطلب بنجاح',
            'request_id': reqId,
            'status': status,
          };
        }
      }
      return {
        'success': false,
        'message': 'حدث خطأ أثناء التواصل مع السيرفر (${response.statusCode})',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر: $e',
      };
    }
  }

  /// مزامنة الكروت المصطادة مع السيرفر وتحديث العدادات
  Future<void> onCardHunted({int count = 1}) async {
    final devId = await getDeviceId();
    final sub = _currentSubscription;
    if (sub == null) return;

    final updatedToday = sub.cardsHuntedToday + count;
    final updatedTotal = sub.totalCardsHunted + count;

    _currentSubscription = sub.copyWith(
      cardsHuntedToday: updatedToday,
      totalCardsHunted: updatedTotal,
      lastHuntDate: DateTime.now().toIso8601String().split('T').first,
    );
    await HiveHelper.instance.saveSubscriptionData(_currentSubscription!.toJson());

    // إرسال المزامنة للسيرفر في الخلفية
    unawaited(
      _dio.get(
        syncHuntedEndpoint,
        queryParameters: {'device_id': devId, 'count': count},
      ).catchError((_) => Response(requestOptions: RequestOptions())),
    );
  }

  // ===========================================================================
  // آليات الحماية من التلاعب في وقت وتاريخ الجهاز (Anti-Tampering)
  // ===========================================================================

  void _recordServerTime(dynamic data) {
    if (data is! Map) return;
    try {
      final st = data['server_time']?.toString();
      if (st != null && st.isNotEmpty) {
        final serverDt = DateTime.parse(st);
        _serverTimeOffset = serverDt.difference(DateTime.now());
        // تحديث أعلى توقيت موثوق تمت رؤيته
        HiveHelper.instance.setHighestSeenTimestamp(serverDt.millisecondsSinceEpoch);
      }
    } catch (_) {}
  }

  /// الحصول على التوقيت الموثوق للنظام مع احتساب انحراف السيرفر
  DateTime getTrustedDateTime() {
    final now = DateTime.now();
    return now.add(_serverTimeOffset);
  }

  /// فحص سلامة إصدار التطبيق ومكافحة تثبيت نسخ قديمة (Anti-Downgrade & Server Min Version)
  ({bool isAllowed, String? message}) verifyVersionIntegrity(SubscriptionModel? sub) {
    // 1. فحص محلي ضد محاولة الـ Downgrade (تثبيت APK بإصدار أقدم من الإصدار الذي كان يعمل في الجهاز)
    final highestInstalled = HiveHelper.instance.getHighestInstalledVersionCode();
    if (highestInstalled > 0 && currentVersionCode < highestInstalled) {
      return (
        isAllowed: false,
        message: 'تم اكتشاف محاولة تثبيت نسخة أقدم ملغاة من التطبيق (Downgrade Attack)! يرجى تثبيت أحدث إصدار لمتابعة الاستخدام بأمان.',
      );
    }

    // 2. فحص السيرفر: هل النسخة الحالية مدعومة في Hunter Settings؟
    if (sub != null && !sub.isVersionSupported) {
      final notes = sub.updateNotes.isNotEmpty
          ? sub.updateNotes
          : 'إصدار التطبيق الحالي (v$currentAppVersion) قديم ولم يعد مدعوماً من السيرفر. يلزم التحديث إلى الإصدار (v${sub.serverAppVersion}) للاستمرار.';
      return (isAllowed: false, message: notes);
    }

    return (isAllowed: true, message: null);
  }

  /// التحقق الصارم من سلامة الوقت والتأكد من عدم التلاعب بتأخير أو تقديم وقت الجهاز
  TimeIntegrityResult verifyTimeIntegrity() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final highestSeen = HiveHelper.instance.getHighestSeenTimestamp();

    // إذا كان التوقيت الحالي للجهاز أقل من أعلى توقيت تم تسجيله سابقاً بأكثر من دقيقتين:
    // هذا يعني أن المستخدم دخل إلى إعدادات الهاتف وأرجع التاريخ/الوقت إلى الوراء للتحايل على الحد اليومي!
    if (highestSeen > 0 && nowMs < (highestSeen - 120000)) {
      return const TimeIntegrityResult(
        isValid: false,
        errorMessage: '⚠️ تم اكتشاف تلاعب أو تأخير في وقت وتاريخ الهاتف! يرجى ضبط الوقت التلقائي (Automatic Date & Time) في إعدادات جهازك.',
      );
    }

    // تحديث أعلى علامة مائية للتوقيت
    HiveHelper.instance.setHighestSeenTimestamp(nowMs);
    return const TimeIntegrityResult(isValid: true);
  }

  /// التحقق الشامل من إمكانية الصيد والاصطياد (صلاحية الاشتراك + الحصة + التوقيت)
  (bool canHunt, String? reason) canHunt() {
    // السماح بالاصطياد تلقائياً أثناء تشغيل الاختبارات الآلية
    if (const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
      return (true, null);
    }

    // 1. فحص سلامة التوقيت من التلاعب
    final timeCheck = verifyTimeIntegrity();
    if (!timeCheck.isValid) {
      return (false, timeCheck.errorMessage);
    }

    // 2. التحقق من وجود اشتراك متاح
    final sub = _currentSubscription;
    if (sub == null || !sub.isAvailable) {
      if (sub?.isPending == true) {
        return (false, 'طلب اشتراكك ما زال قيد الانتظار والاعتماد.');
      } else if (sub?.isStopped == true) {
        return (false, 'حسابك متوقف حالياً. يرجى التواصل مع المطور.');
      }
      return (false, 'يلزم تفعيل الاشتراك لاستخدام أداة الفحص والاصطياد.');
    }

    // 3. التحقق من تجديد الحد اليومي بحسب التوقيت الموثوق
    final trustedDate = getTrustedDateTime().toIso8601String().split('T').first;
    if (sub.isDaily && sub.lastHuntDate != null && sub.lastHuntDate != trustedDate) {
      // بدأ يوم جديد -> إعادة تصفير العداد اليومي محلياً
      _currentSubscription = sub.copyWith(
        cardsHuntedToday: 0,
        lastHuntDate: trustedDate,
      );
      HiveHelper.instance.saveSubscriptionData(_currentSubscription!.toJson());
    }

    // 4. التحقق من استنفاد الحصة المسموح بها (Daily or Lifetime)
    if (_currentSubscription!.isQuotaExhausted) {
      if (_currentSubscription!.isDaily) {
        return (
          false,
          '🚫 استنفدت الحد اليومي المسموح به لاصطياد الكروت (${_currentSubscription!.allowedCards} كرت/يوم). يتجدد الرصيد غداً بإذن الله.',
        );
      } else {
        return (
          false,
          '🚫 استنفدت إجمالي الكروت المسموح باصطيادها (${_currentSubscription!.allowedCards} كرت). يرجى الترقية والتواصل مع المطور.',
        );
      }
    }

    return (true, null);
  }
}

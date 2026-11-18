import 'dart:io';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:networking/core/utils/native_bridge.dart';
import 'package:networking/data/datasources/database_helper.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/data/models/settings_model.dart';
import 'package:networking/data/models/tested_card_model.dart';
import 'package:networking/domain/engine/hunter_adapters.dart';

class CardsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CardModel> _cards = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final Set<int> _selectedIds = {};
  bool _isCheckingBatch = false;
  String _batchCheckStatus = '';

  List<TestedCardModel> _testedCards = [];
  bool _isLoadingTested = false;
  String _testedSearchQuery = '';

  bool _isAutoLoggingIn = false;
  bool _isLoggingOut = false;
  String _autoLoginStatus = '';
  String? _lastAutoConnectedCard;
  Map<String, dynamic>? _lastExportResult;

  List<CardModel> get cards {
    if (_searchQuery.isEmpty) return _cards;
    return _cards.where((c) => c.cardNumber.contains(_searchQuery)).toList();
  }

  /// قائمة الكروت غير المستخدمة مرتبة تصاعدياً حسب أولوية الاتصال التلقائي
  List<CardModel> get unusedQueue {
    final list = _cards.where((c) => !c.isUsed).toList();
    list.sort((a, b) {
      final pa = a.priorityOrder <= 0 ? 999999 : a.priorityOrder;
      final pb = b.priorityOrder <= 0 ? 999999 : b.priorityOrder;
      if (pa != pb) return pa.compareTo(pb);
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return list;
  }

  bool get isAutoLoggingIn => _isAutoLoggingIn;
  bool get isLoggingOut => _isLoggingOut;
  String get autoLoginStatus => _autoLoginStatus;
  String? get lastAutoConnectedCard => _lastAutoConnectedCard;
  Map<String, dynamic>? get lastExportResult => _lastExportResult;

  List<TestedCardModel> get testedCards {
    if (_testedSearchQuery.isEmpty) return _testedCards;
    return _testedCards
        .where((c) =>
            c.cardNumber.contains(_testedSearchQuery) ||
            c.portalMessage.contains(_testedSearchQuery) ||
            c.status.contains(_testedSearchQuery))
        .toList();
  }

  bool get isLoading => _isLoading;
  bool get isLoadingTested => _isLoadingTested;
  int get totalCount => _cards.length;
  int get totalTestedCount => _testedCards.length;
  int get unusedCount => _cards.where((c) => !c.isUsed).length;

  Set<int> get selectedIds => _selectedIds;
  bool get isSelectionMode => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;
  bool get isCheckingBatch => _isCheckingBatch;
  String get batchCheckStatus => _batchCheckStatus;

  CardsProvider() {
    loadCards();
    loadTestedCards();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTestedSearchQuery(String query) {
    _testedSearchQuery = query;
    notifyListeners();
  }

  // ==================== إدارة التحديد المتعدد ====================

  void toggleSelectCard(int cardId) {
    if (_selectedIds.contains(cardId)) {
      _selectedIds.remove(cardId);
    } else {
      _selectedIds.add(cardId);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.clear();
    for (final c in cards) {
      if (c.id != null) _selectedIds.add(c.id!);
    }
    notifyListeners();
  }

  void selectUnused() {
    _selectedIds.clear();
    for (final c in cards) {
      if (!c.isUsed && c.id != null) {
        _selectedIds.add(c.id!);
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  // ==================== تحميل وتعديل البيانات ====================

  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cards = await _db.getAllFoundCards();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTestedCards({bool silent = false}) async {
    if (!silent) {
      _isLoadingTested = true;
      notifyListeners();
    }
    try {
      _testedCards = await _db.getAllTestedCards();
    } finally {
      if (!silent) {
        _isLoadingTested = false;
      }
      notifyListeners();
    }
  }

  /// إضافة أو تحديث كرت تم اختباره بشكل فوري ولحظي دون وميض تحميل
  void onTestedCardRecorded({
    required String cardNumber,
    required String status,
    required String portalMessage,
  }) {
    final now = DateTime.now();
    final nowStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final newItem = TestedCardModel(
      cardNumber: cardNumber,
      testedAt: nowStr,
      status: status,
      portalMessage: portalMessage,
      isLastTested: true,
    );

    // إلغاء وسم isLastTested من باقي الكروت في الذاكرة
    for (int i = 0; i < _testedCards.length; i++) {
      if (_testedCards[i].isLastTested) {
        _testedCards[i] = _testedCards[i].copyWith(isLastTested: false);
      }
    }

    final index = _testedCards.indexWhere((c) => c.cardNumber == cardNumber);
    if (index >= 0) {
      _testedCards[index] = newItem;
    } else {
      _testedCards.insert(0, newItem);
    }
    notifyListeners();
  }

  Future<void> clearAllTestedCards() async {
    await _db.clearAllTestedCards();
    await loadTestedCards();
  }

  Future<void> toggleUsed(int cardId) async {
    await _db.toggleCardUsed(cardId);
    await loadCards();
  }

  Future<void> setUsedStatus(int cardId, bool isUsed) async {
    await _db.setCardUsedStatus(cardId, isUsed);
    await loadCards();
  }

  Future<void> updateNotes(int cardId, String notes) async {
    await _db.updateCardNotes(cardId, notes);
    await loadCards();
  }

  /// إعادة ترتيب الكروت غير المستخدمة عبر السحب والإفلات وحفظ الأولوية في قاعدة البيانات
  Future<void> reorderUnusedCards(int oldIndex, int newIndex) async {
    final queue = unusedQueue;
    if (oldIndex < 0 || oldIndex >= queue.length) return;
    final targetIndex = newIndex.clamp(0, queue.length - 1);

    final moved = queue.removeAt(oldIndex);
    queue.insert(targetIndex, moved);

    final orderedIds = <int>[];
    for (int i = 0; i < queue.length; i++) {
      final id = queue[i].id;
      if (id != null) {
        orderedIds.add(id);
      }
    }

    // تحديث فوري في الذاكرة لمنع أي تأخير بصري أثناء السحب والإفلات
    final priorityMap = <int, int>{};
    for (int i = 0; i < orderedIds.length; i++) {
      priorityMap[orderedIds[i]] = i + 1;
    }
    _cards = _cards.map((c) {
      if (c.id != null && priorityMap.containsKey(c.id)) {
        return c.copyWith(priorityOrder: priorityMap[c.id]);
      }
      return c;
    }).toList();
    notifyListeners();

    await _db.updateCardsPriorityOrder(orderedIds);
    await loadCards();
  }

  /// رفع كرت مباشرة إلى صدارة رتل الاتصال التلقائي (الأولوية #1)
  Future<void> moveCardToTopPriority(int cardId) async {
    final queue = unusedQueue;
    final idx = queue.indexWhere((c) => c.id == cardId);
    if (idx <= 0) return;
    await reorderUnusedCards(idx, 0);
  }

  Future<void> deleteCard(int cardId) async {
    await _db.deleteCard(cardId);
    _selectedIds.remove(cardId);
    await loadCards();
  }

  Future<void> deleteSelectedCards() async {
    for (final id in _selectedIds.toList()) {
      await _db.deleteCard(id);
    }
    _selectedIds.clear();
    await loadCards();
  }

  Future<void> clearAllCards() async {
    await _db.clearAllCards();
    _selectedIds.clear();
    await loadCards();
  }

  Future<void> copyCardNumber(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
  }

  // ==================== تصدير إكسل (مطابق 100% لملف status_logs_v2.xlsx) ====================

  Future<bool> exportCardsToExcel() async {
    if (_cards.isEmpty) return false;

    try {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'سجل العمليات');
      final sheet = excel['سجل العمليات'];

      // ترويسة الجدول بتنسيق الكحلي الغامق والخط الأبيض العريض بمحاذاة وسطية
      final headerStyle = CellStyle(
        bold: true,
        fontFamily: 'Arial',
        fontSize: 12,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1F4E78'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headers = [
        'رقم الكرت (Number)',
        'الرابط (URL)',
        'التاريخ (Date)',
        'الوقت (Time)',
        'مستخدم',
      ];

      final colWidths = [20.0, 30.0, 15.0, 13.0, 13.0];

      for (int col = 0; col < headers.length; col++) {
        sheet.setColumnWidth(col, colWidths[col]);
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      final dataStyle = CellStyle(
        fontFamily: 'Arial',
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final listToExport = _selectedIds.isNotEmpty
          ? _cards.where((c) => _selectedIds.contains(c.id)).toList()
          : _cards;

      for (int i = 0; i < listToExport.length; i++) {
        final c = listToExport[i];
        final rowIndex = i + 1;

        // استخراج التاريخ والوقت
        final parts = c.foundAt.split(' ');
        final dateStr = parts.isNotEmpty ? parts[0] : c.foundAt;
        final timeStr = parts.length > 1 ? parts[1] : '';

        // عمود 0: رقم الكرت
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        )
          ..value = TextCellValue(c.cardNumber)
          ..cellStyle = dataStyle;

        // عمود 1: الرابط
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        )
          ..value = TextCellValue(c.loginUrl)
          ..cellStyle = dataStyle;

        // عمود 2: التاريخ
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        )
          ..value = TextCellValue(dateStr)
          ..cellStyle = dataStyle;

        // عمود 3: الوقت
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        )
          ..value = TextCellValue(timeStr)
          ..cellStyle = dataStyle;

        // عمود 4: مستخدم (1 أو 0)
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
        )
          ..value = IntCellValue(c.isUsed ? 1 : 0)
          ..cellStyle = dataStyle;
      }

      final bytes = excel.encode();
      if (bytes == null) return false;

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      final fileName = 'Hunted_Cards_${dateStr}_$timeStr.xlsx';
      const excelMime =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      // 1. الحفظ الذكي في مجلد الملفات العام في أندرويد (Download/Network_Hunter أو Network_Hunter)
      final nativeRes = await NativeBridge.saveFileToPublicFolder(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: excelMime,
      );

      if (nativeRes['success'] == true) {
        _lastExportResult = {
          'success': true,
          'fileName': fileName,
          'filePath': nativeRes['filePath']?.toString() ?? '',
          'sharePath': nativeRes['sharePath']?.toString() ??
              nativeRes['filePath']?.toString() ??
              '',
          'displayFolder': nativeRes['displayFolder']?.toString() ??
              'الملفات > التنزيلات (Download) > Network_Hunter',
          'exportedCount': listToExport.length,
        };
        notifyListeners();
        return true;
      }

      // 2. مسار احتياطي لسطح المكتب أو بيئات الاختبار
      final storagePath = await NativeBridge.getAppStoragePath();
      final baseDir = storagePath.isNotEmpty
          ? Directory('$storagePath/Network_Hunter')
          : Directory('${Directory.systemTemp.path}/Network_Hunter');
      if (!baseDir.existsSync()) {
        baseDir.createSync(recursive: true);
      }

      final filePath = '${baseDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      _lastExportResult = {
        'success': true,
        'fileName': fileName,
        'filePath': filePath,
        'sharePath': filePath,
        'displayFolder': baseDir.path,
        'exportedCount': listToExport.length,
      };
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Export to Excel error: $e');
      return false;
    }
  }

  // ==================== مشاركة نصية منسقة بدقة ====================

  Future<void> shareFormattedCards({List<CardModel>? targetList}) async {
    final list = targetList ??
        (_selectedIds.isNotEmpty
            ? _cards.where((c) => _selectedIds.contains(c.id)).toList()
            : _cards);

    if (list.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    if (list.length == 1) {
      final c = list.first;
      buffer.writeln('تمت مشاركة الكرت بالبيانات التالية:');
      buffer.writeln('رقم الكرت : ${c.cardNumber}');
      buffer.writeln('رابط تسجيل الدخول : ${c.loginUrl}');
      buffer.writeln('وقت وتاريخ الاصطياد : ${c.foundAt}');
      if (c.notes.isNotEmpty) {
        buffer.writeln('حالة الكرت : ${c.notes}');
      }
    } else {
      buffer.writeln('تمت مشاركة الكروت بالبيانات التالية:');
      buffer.writeln('========================================');
      for (int i = 0; i < list.length; i++) {
        final c = list[i];
        buffer.writeln('رقم الكرت : ${c.cardNumber}');
        buffer.writeln('رابط تسجيل الدخول : ${c.loginUrl}');
        buffer.writeln('وقت وتاريخ الاصطياد : ${c.foundAt}');
        if (c.notes.isNotEmpty) {
          buffer.writeln('حالة الكرت : ${c.notes}');
        }
        if (i < list.length - 1) {
          buffer.writeln('----------------------------------------');
        }
      }
    }

    await NativeBridge.shareText(
      text: buffer.toString(),
      subject: 'كروت شبكة الواي فاي المصطادة',
    );
  }

  // ==================== فحص توفر وصلاحية الكروت ====================

  Dio _createDio(int timeoutMs) {
    return Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: timeoutMs),
        receiveTimeout: Duration(milliseconds: timeoutMs),
        sendTimeout: Duration(milliseconds: timeoutMs),
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ),
    );
  }

  bool _isSuccessBody(String body) {
    final lower = body.toLowerCase();
    const successKeywords = [
      'logged in',
      'welcome',
      'you are logged in',
      'log off',
      'logout',
      'bytes up',
      'bytes down',
      'uptime',
      'session time',
      'connected',
      'مرحباً',
      'تم تسجيل الدخول',
      'تسجيل الخروج',
      'الوقت المتبقي',
      'الرصيد المتبقي',
    ];
    return successKeywords.any(lower.contains);
  }

  bool _isRejectionBody(String body) {
    final lower = body.toLowerCase();
    const rejectKeywords = [
      'invalid username or password',
      'user not found',
      'invalid credentials',
      'expired',
      'no more traffic',
      'login failed',
      'خطأ في كلمة المرور',
      'المستخدم غير موجود',
      'انتهى رصيد',
      'انتهت صلاحية',
      'كرت غير صحيح',
      'رمز الدخول غير صحيح',
    ];
    return rejectKeywords.any(lower.contains);
  }

  /// فحص توفر كرت مفرد دون تزايد (مع تسجيل خروج فوري للحفاظ على الجلسة)
  Future<bool> checkSingleCardAvailability(
    CardModel card,
    SettingsModel config,
  ) async {
    final baseUrl = config.url.replaceAll(RegExp(r'/+$'), '');
    final loginUrl = '$baseUrl${config.loginPath}';
    final logoutUrl = '$baseUrl${config.logoutPath}';

    final dio = _createDio(config.navTimeout);
    final data = <String, dynamic>{
      config.usernameField: card.cardNumber,
    };
    if (config.customPassword.isNotEmpty) {
      data[config.passwordField] = config.customPassword;
    }

    try {
      final response = await dio.post(
        loginUrl,
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      final body = response.data.toString();
      final location = response.headers.value('location') ?? '';

      bool isValid = false;
      if (statusCode == 302 || statusCode == 303 || statusCode == 301) {
        if (location.toLowerCase().contains('status') ||
            !location.toLowerCase().contains('login')) {
          isValid = true;
        }
      } else if (statusCode == 200) {
        if (_isSuccessBody(body)) {
          isValid = true;
        } else if (_isRejectionBody(body)) {
          isValid = false;
        }
      }

      if (isValid) {
        // تسجيل خروج فوري لعدم حجز الجلسة
        try {
          await dio.get(logoutUrl).timeout(const Duration(seconds: 4));
        } catch (_) {}

        if (card.id != null) {
          await _db.updateCardNotes(card.id!, 'متاح وصالح ✓');
        }
        await loadCards();
        return true;
      } else {
        if (card.id != null) {
          await _db.updateCardNotes(card.id!, 'غير متاح ❌');
        }
        await loadCards();
        return false;
      }
    } catch (_) {
      if (card.id != null) {
        await _db.updateCardNotes(card.id!, 'تعذر الفحص (انقطاع الاتصال)');
      }
      await loadCards();
      return false;
    }
  }

  /// فحص دفعة من الكروت بشكل تتابعي وتحديث حالتها
  Future<void> checkBatchAvailability(
    List<CardModel> targetCards,
    SettingsModel config,
  ) async {
    if (targetCards.isEmpty) return;

    _isCheckingBatch = true;
    notifyListeners();

    try {
      for (int i = 0; i < targetCards.length; i++) {
        final card = targetCards[i];
        _batchCheckStatus =
            'جاري فحص الكرت (${i + 1}/${targetCards.length}): ${card.cardNumber}...';
        notifyListeners();

        await checkSingleCardAvailability(card, config);

        // تأخير بسيط بين كل فحص والآخر لتفادي حظر الميكروتيك
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } finally {
      _isCheckingBatch = false;
      _batchCheckStatus = '';
      notifyListeners();
    }
  }

  /// الاتصال وتسجيل الدخول بالكرت الآن (وإبقاء الجلسة نشطة للتصفح)
  Future<bool> loginAndConnectWithCard(
    CardModel card,
    SettingsModel config, {
    bool isAutoLogin = false,
    Dio? customDio,
  }) async {
    final baseUrl = config.url.replaceAll(RegExp(r'/+$'), '');
    final loginUrl = '$baseUrl${config.loginPath}';

    final dio = customDio ?? _createDio(config.navTimeout);
    final data = <String, dynamic>{
      config.usernameField: card.cardNumber,
    };
    if (config.customPassword.isNotEmpty) {
      data[config.passwordField] = config.customPassword;
    }

    try {
      final response = await dio.post(
        loginUrl,
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      final body = response.data.toString();
      final location = response.headers.value('location') ?? '';

      bool isSuccess = false;
      if (statusCode == 302 || statusCode == 303 || statusCode == 301) {
        if (location.toLowerCase().contains('status') ||
            !location.toLowerCase().contains('login')) {
          isSuccess = true;
        }
      } else if (statusCode == 200) {
        if (_isSuccessBody(body)) {
          isSuccess = true;
        }
      }

      if (isSuccess) {
        if (card.id != null) {
          await _db.setCardUsedStatus(card.id!, true);
          await _db.updateCardNotes(
            card.id!,
            isAutoLogin ? 'تم الاتصال تلقائياً ✓' : 'متصل حالياً ✓',
          );
        }
        await loadCards();
        return true;
      } else {
        if (card.id != null) {
          if (isAutoLogin) {
            await _db.setCardUsedStatus(card.id!, true);
            await _db.updateCardNotes(card.id!, 'منتهي/غير متاح (تخطي تلقائي) ❌');
          } else {
            await _db.updateCardNotes(card.id!, 'غير متاح ❌');
          }
        }
        await loadCards();
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// فحص ما إذا كانت الشبكة الحالية تطلب تسجيل دخول (انتهاء الرصيد أو تسجيل الخروج)
  Future<bool> checkPortalNeedsLogin(
    SettingsModel config, {
    Dio? customDio,
    bool? nativeCaptiveOverride,
  }) async {
    // 1. التحقق من إشارة نظام أندرويد (Captive Portal / Sign in to network)
    final isCaptive =
        nativeCaptiveOverride ?? await NativeBridge.checkIsCaptivePortal();
    if (isCaptive && customDio == null) {
      return true;
    }

    // 2. فحص خفيف لصفحة البوابة للتأكد من حالة الجلسة
    final baseUrl = config.url.replaceAll(RegExp(r'/+$'), '');
    final statusUrl = '$baseUrl/status';
    final loginUrl = '$baseUrl${config.loginPath}';
    final dio = customDio ?? _createDio(6000);

    try {
      final res = await dio.get(
        statusUrl,
        options: Options(followRedirects: false),
      );
      final code = res.statusCode ?? 0;
      final loc = (res.headers.value('location') ?? '').toLowerCase();
      final body = res.data.toString();

      // إذا أعادت البوابة التوجيه إلى صفحة login، فالجلسة منتهية وتحتاج تسجيل دخول
      if (code == 301 || code == 302 || code == 303) {
        if (loc.contains('login')) return true;
      }
      if (code == 200) {
        if (_isSuccessBody(body)) {
          return false; // متصل بالفعل وجلسة نشطة
        }
        final lower = body.toLowerCase();
        if (lower.contains('name="${config.usernameField.toLowerCase()}"') ||
            lower.contains("name='${config.usernameField.toLowerCase()}'") ||
            lower.contains('login')) {
          return true;
        }
      }
    } catch (_) {
      // محاولة فحص صفحة الدخول مباشرة
      try {
        final res = await dio.get(
          loginUrl,
          options: Options(followRedirects: false),
        );
        final code = res.statusCode ?? 0;
        final loc = (res.headers.value('location') ?? '').toLowerCase();
        final body = res.data.toString();
        if (code == 301 || code == 302 || code == 303) {
          if (loc.contains('status')) return false;
        }
        if (code == 200 && !_isSuccessBody(body)) {
          return true;
        }
      } catch (_) {}
    }

    return isCaptive;
  }

  /// تنفيذ الاتصال التلقائي بالسحب المتسلسل من رتل الكروت المصطادة غير المستخدمة
  /// يعمل فقط إذا:
  /// 1. الميزة مفعلة في الإعدادات (config.autoLoginWithHuntedCards == true)
  /// 2. محرك الفحص والاصطياد متوقف تماماً (!isEngineRunning)
  /// 3. توجد كروت مصطادة غير مستخدمة (unusedQueue.isNotEmpty)
  Future<String?> triggerAutoLoginIfNeeded({
    required SettingsModel config,
    required bool isEngineRunning,
    bool forceAttempt = false,
    Dio? customDio,
    void Function(String logMsg)? onLog,
  }) async {
    // التحقق الصارم من الشروط الثلاثة
    if (!config.autoLoginWithHuntedCards) return null;
    if (isEngineRunning) return null;
    final queue = unusedQueue;
    if (queue.isEmpty) return null;
    if (_isAutoLoggingIn) return null;

    _isAutoLoggingIn = true;
    notifyListeners();

    try {
      if (!forceAttempt) {
        final needsLogin = await checkPortalNeedsLogin(
          config,
          customDio: customDio,
        );
        if (!needsLogin) {
          return null;
        }
      }

      onLog?.call(
        '🔌 [الاتصال التلقائي]: تم رصد حاجة الشبكة لتسجيل الدخول — بدء الاتصال حسب ترتيب الأولوية (${queue.length} كرت متاح)...',
      );

      for (int i = 0; i < queue.length; i++) {
        // إذا بدأ المستخدم الفحص والاصطياد أثناء المحاولة، نتوقف فوراً
        if (!config.autoLoginWithHuntedCards) break;

        final card = queue[i];
        _autoLoginStatus =
            'جاري الاتصال التلقائي بالكرت #${i + 1}: ${card.cardNumber}...';
        notifyListeners();

        onLog?.call(
          '  🔄 محاولة الاتصال التلقائي بالكرت #${i + 1}: ${card.cardNumber}...',
        );

        final connected = await loginAndConnectWithCard(
          card,
          config,
          isAutoLogin: true,
          customDio: customDio,
        );

        if (connected) {
          _lastAutoConnectedCard = card.cardNumber;
          _autoLoginStatus = 'تم الاتصال تلقائياً بالكرت: ${card.cardNumber} ✓';
          onLog?.call(
            '  ✅ نجح الاتصال التلقائي بالشبكة عبر الكرت (${card.cardNumber}) وتم تحويل حالته إلى مستخدم.',
          );
          await NativeBridge.showAlertNotification(
            title: '🔌 تم الاتصال التلقائي بالشبكة بنجاح!',
            body:
                'تم تسجيل الدخول تلقائياً بالكرت رقم: ${card.cardNumber} وتحويل حالته إلى مستخدم.',
            isError: false,
            alertType: 'success',
          );
          return card.cardNumber;
        } else {
          onLog?.call(
            '  ❌ فشل الكرت (${card.cardNumber}) (منتهي أو غير صالح) — الانتقال للكرت التالي في قائمة الأولوية...',
          );
        }
      }

      _autoLoginStatus = 'تعذر الاتصال: لم ينجح أي كرت من القائمة';
      return null;
    } finally {
      _isAutoLoggingIn = false;
      notifyListeners();
    }
  }

  /// تسجيل الخروج الفوري من أي كرت متصل في البوابة ومسح كافة الكوكيز والكاش وبيانات التخزين
  Future<bool> logoutAndClearCacheAndCookies(
    SettingsModel config, {
    Dio? customDio,
    void Function(String logMsg)? onLog,
  }) async {
    if (_isLoggingOut) return false;
    _isLoggingOut = true;
    notifyListeners();

    final baseUrl = config.url.replaceAll(RegExp(r'/+$'), '');
    final logoutUrl = '$baseUrl${config.logoutPath}';
    final eraseCookieUrl1 = logoutUrl.contains('?')
        ? '$logoutUrl&erase-cookie=1'
        : '$logoutUrl?erase-cookie=1';
    final eraseCookieUrlOn = logoutUrl.contains('?')
        ? '$logoutUrl&erase-cookie=on'
        : '$logoutUrl?erase-cookie=on';

    try {
      onLog?.call(
        '🚪 [تسجيل الخروج وتطهير الجلسة]: جاري إرسال أوامر الخروج لبوابة الشبكة ومسح الكاش والكوكيز...',
      );

      final dio = customDio ?? _createDio(8000);

      // 1. إرسال طلبات الخروج وحذف الكوكي من راوتر المايكروتك
      for (final targetUrl in [logoutUrl, eraseCookieUrl1, eraseCookieUrlOn]) {
        try {
          await dio
              .get(targetUrl, options: Options(followRedirects: true))
              .timeout(const Duration(seconds: 4));
        } catch (_) {}
      }

      // 2. تطهير الكوكيز والكاش وبيانات التخزين في محرك المتصفح المدمج (WebView)
      try {
        final browser = createPlatformBrowserController();
        if (browser != null) {
          await browser.clearCookies();
          await browser.clearLocalStorage();
          await browser.clearCache();
          browser.dispose();
        }
      } catch (_) {}

      // 3. تطهير الكوكيز وWebStorage والكاش من نظام أندرويد الأصلي
      await NativeBridge.clearWebStorageAndCache();

      // 4. تحديث ملاحظات الكروت التي كانت تحمل حالة "متصل حالياً"
      for (final c in _cards) {
        if (c.id != null &&
            (c.notes.contains('متصل حالياً') ||
                c.notes.contains('تم الاتصال تلقائياً'))) {
          await _db.updateCardNotes(c.id!, 'تم تسجيل الخروج 🚪');
        }
      }
      _lastAutoConnectedCard = null;
      _autoLoginStatus = 'تم تسجيل الخروج ومسح الكوكيز والكاش بنجاح 🧹';
      await loadCards();

      onLog?.call(
        '✅ [تسجيل الخروج وتطهير الجلسة]: تم الخروج من الكرت المتصل وتطهير الكاش والكوكيز بالكامل.',
      );
      return true;
    } catch (e) {
      onLog?.call('⚠️ حدث خطأ أثناء تسجيل الخروج وتطهير الكاش: $e');
      return false;
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }
}

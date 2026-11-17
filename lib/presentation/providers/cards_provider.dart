import 'dart:io';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:networking/core/utils/native_bridge.dart';
import 'package:networking/data/datasources/database_helper.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/data/models/settings_model.dart';

class CardsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CardModel> _cards = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final Set<int> _selectedIds = {};
  bool _isCheckingBatch = false;
  String _batchCheckStatus = '';

  List<CardModel> get cards {
    if (_searchQuery.isEmpty) return _cards;
    return _cards.where((c) => c.cardNumber.contains(_searchQuery)).toList();
  }

  bool get isLoading => _isLoading;
  int get totalCount => _cards.length;
  int get unusedCount => _cards.where((c) => !c.isUsed).length;

  Set<int> get selectedIds => _selectedIds;
  bool get isSelectionMode => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;
  bool get isCheckingBatch => _isCheckingBatch;
  String get batchCheckStatus => _batchCheckStatus;

  CardsProvider() {
    loadCards();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
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

      // حفظ الملف في مسار تخزين التطبيق
      final storagePath = await NativeBridge.getAppStoragePath();
      final targetDir = storagePath.isNotEmpty
          ? Directory(storagePath)
          : Directory.systemTemp;

      final filePath =
          '${targetDir.path}/status_logs_v2.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      // مشاركة الملف عبر Android Intent
      return await NativeBridge.shareFile(
        path: filePath,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        title: 'مشاركة كروت الشبكة كملف إكسل',
      );
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
    SettingsModel config,
  ) async {
    final baseUrl = config.url.replaceAll(RegExp(r'/+$'), '');
    final loginUrl = '$baseUrl${config.loginPath}';

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
          await _db.updateCardNotes(card.id!, 'متصل حالياً ✓');
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
      return false;
    }
  }
}

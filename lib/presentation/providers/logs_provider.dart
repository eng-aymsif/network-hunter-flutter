import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/utils/native_bridge.dart';

class LogEntry {
  final String time;
  final String message;

  LogEntry({required this.time, required this.message});

  @override
  String toString() => '[$time] $message';
}

class LogsProvider extends ChangeNotifier {
  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => List.unmodifiable(_logs);
  String get latestMessage => _logs.isNotEmpty ? _logs.last.message : 'جاهز';

  void addLog(String message) {
    final now = DateFormat('HH:mm:ss').format(DateTime.now());
    _logs.add(LogEntry(time: now, message: message));
    if (_logs.length > 1000) {
      _logs.removeRange(0, 200); // إبقاء الذاكرة خفيفة
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  String getAllLogsText() {
    return _logs.map((e) => e.toString()).join('\n');
  }

  Future<void> copyAllLogs() async {
    final text = getAllLogsText();
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> shareLogs() async {
    final text = getAllLogsText();
    if (text.isNotEmpty) {
      await NativeBridge.shareText(
        text: text,
        subject: 'سجل عمليات Network Hunter',
      );
    }
  }
}

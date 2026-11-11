import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/utils/native_bridge.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/models/card_model.dart';

class CardsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CardModel> _cards = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<CardModel> get cards {
    if (_searchQuery.isEmpty) return _cards;
    return _cards.where((c) => c.cardNumber.contains(_searchQuery)).toList();
  }

  bool get isLoading => _isLoading;
  int get totalCount => _cards.length;
  int get unusedCount => _cards.where((c) => !c.isUsed).length;

  CardsProvider() {
    loadCards();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

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

  Future<void> deleteCard(int cardId) async {
    await _db.deleteCard(cardId);
    await loadCards();
  }

  Future<void> clearAllCards() async {
    await _db.clearAllCards();
    await loadCards();
  }

  Future<void> copyCardNumber(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
  }

  Future<void> exportCards({bool asCsv = false}) async {
    if (_cards.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    if (asCsv) {
      buffer.writeln('ID,Card_Number,Used,Found_At,Login_URL');
      for (final c in _cards) {
        buffer.writeln('${c.id},"${c.cardNumber}",${c.isUsed ? "YES" : "NO"},"${c.foundAt}","${c.loginUrl}"');
      }
    } else {
      buffer.writeln('=== كروت شبكة الواي فاي المكتشفة (Network Hunter) ===');
      for (final c in _cards) {
        final status = c.isUsed ? '[مستخدم]' : '[غير مستخدم]';
        buffer.writeln('الرقم: ${c.cardNumber} | الحالة: $status | التاريخ: ${c.foundAt}');
      }
    }

    await NativeBridge.shareText(
      text: buffer.toString(),
      subject: asCsv ? 'cards.csv' : 'found_cards.txt',
    );
  }
}

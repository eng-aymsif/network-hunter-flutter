import 'dart:async';
import 'package:networking/data/datasources/hive_helper.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/data/models/settings_model.dart';
import 'package:networking/data/models/tested_card_model.dart';
import 'package:networking/domain/engine/hunter_interfaces.dart';

/// DatabaseHelper delegating directly to HiveHelper for backward compatibility
class DatabaseHelper implements HunterDatabase {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  final HiveHelper _hive = HiveHelper.instance;

  Future<void> init() => _hive.init();

  @override
  Future<bool> saveFoundCard(String cardNumber, String loginUrl, {String notes = ''}) =>
      _hive.saveFoundCard(cardNumber, loginUrl, notes: notes);

  Future<List<CardModel>> getAllFoundCards() => _hive.getAllFoundCards();

  Future<bool> toggleCardUsed(int cardId) => _hive.toggleCardUsed(cardId);

  Future<void> setCardUsedStatus(int cardId, bool isUsed) =>
      _hive.setCardUsedStatus(cardId, isUsed);

  Future<void> updateCardNotes(int cardId, String notes) =>
      _hive.updateCardNotes(cardId, notes);

  Future<void> updateCardsPriorityOrder(List<int> orderedCardIds) =>
      _hive.updateCardsPriorityOrder(orderedCardIds);

  Future<void> deleteCard(int cardId) => _hive.deleteCard(cardId);

  Future<void> clearAllCards() => _hive.clearAllCards();

  @override
  Future<void> setState(String key, String value) => _hive.setState(key, value);

  @override
  Future<String?> getState(String key, [String? defaultValue]) =>
      _hive.getState(key, defaultValue);

  Future<void> saveSettings(SettingsModel settings) => _hive.saveSettings(settings);

  Future<SettingsModel> loadSettings() => _hive.loadSettings();

  @override
  Future<void> recordTestedCard({
    required String cardNumber,
    required String status,
    required String portalMessage,
    bool isLast = true,
  }) =>
      _hive.recordTestedCard(
        cardNumber: cardNumber,
        status: status,
        portalMessage: portalMessage,
        isLast: isLast,
      );

  Future<List<TestedCardModel>> getAllTestedCards({String? query}) =>
      _hive.getAllTestedCards(query: query);

  @override
  Future<bool> isCardAlreadyTested(String cardNumber) =>
      _hive.isCardAlreadyTested(cardNumber);

  Future<TestedCardModel?> getLastTestedCard() => _hive.getLastTestedCard();

  Future<void> clearAllTestedCards() => _hive.clearAllTestedCards();
}

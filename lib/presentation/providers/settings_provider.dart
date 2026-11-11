import 'package:flutter/foundation.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/models/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  SettingsModel _settings = SettingsModel();
  bool _isLoaded = false;

  SettingsModel get settings => _settings;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _settings = await _db.loadSettings();
    _isLoaded = true;
    notifyListeners();
  }

  void updateSettings(SettingsModel newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> saveSettings(SettingsModel newSettings) async {
    _settings = newSettings;
    await _db.saveSettings(newSettings);
    notifyListeners();
  }

  Future<void> restoreDefaults() async {
    _settings = SettingsModel();
    await _db.saveSettings(_settings);
    notifyListeners();
  }
}

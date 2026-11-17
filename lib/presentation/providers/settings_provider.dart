import 'package:flutter/foundation.dart';
import 'package:networking/data/datasources/database_helper.dart';
import 'package:networking/data/models/settings_model.dart';

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
    var loaded = await _db.loadSettings();
    // إذا كانت القيمة المحفوظة سابقاً 1 بسبب التقييد القديم، نعيدها إلى 0 (بلا توقف)
    if (loaded.maxAttempts == 1) {
      loaded = loaded.copyWith(maxAttempts: 0);
      await _db.saveSettings(loaded);
    }
    _settings = loaded;
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

import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 1)
class SettingsModel {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String loginPath;

  @HiveField(2)
  final String logoutPath;

  @HiveField(3)
  final String startNumber;

  @HiveField(4)
  final int maxAttempts;

  @HiveField(5)
  final double delayBetween;

  @HiveField(6)
  final int navTimeout;

  @HiveField(7)
  final double postNavWait;

  @HiveField(8)
  final bool unbanOnError;

  @HiveField(9)
  final int unbanMaxRetries;

  @HiveField(10)
  final double unbanCooldown;

  @HiveField(11)
  final int maxConsecutiveErrors;

  @HiveField(12)
  final String usernameField;

  @HiveField(13)
  final String passwordField;

  @HiveField(14)
  final String customPassword;

  @HiveField(15)
  final bool useWebView;

  @HiveField(16)
  final bool injectSaleem;

  @HiveField(17)
  final bool injectSaveUsername;

  @HiveField(18)
  final bool usePopupSubmit;

  @HiveField(19)
  final bool resumeSaved;

  @HiveField(20)
  final bool skipAlreadyTested;

  SettingsModel({
    this.url = 'http://a.com',
    this.loginPath = '/login',
    this.logoutPath = '/logout',
    this.startNumber = '',
    this.maxAttempts = 0,
    this.delayBetween = 10.0,
    this.navTimeout = 30000,
    this.postNavWait = 7.0,
    this.unbanOnError = true,
    this.unbanMaxRetries = 3,
    this.unbanCooldown = 5.0,
    this.maxConsecutiveErrors = 10,
    this.resumeSaved = true,
    this.usernameField = 'username',
    this.passwordField = 'password',
    this.customPassword = '',
    this.useWebView = true,
    this.injectSaleem = true,
    this.injectSaveUsername = true,
    this.usePopupSubmit = true,
    this.skipAlreadyTested = false,
  });

  SettingsModel copyWith({
    String? url,
    String? loginPath,
    String? logoutPath,
    String? startNumber,
    int? maxAttempts,
    double? delayBetween,
    int? navTimeout,
    double? postNavWait,
    bool? unbanOnError,
    int? unbanMaxRetries,
    double? unbanCooldown,
    int? maxConsecutiveErrors,
    bool? resumeSaved,
    String? usernameField,
    String? passwordField,
    String? customPassword,
    bool? useWebView,
    bool? injectSaleem,
    bool? injectSaveUsername,
    bool? usePopupSubmit,
    bool? skipAlreadyTested,
  }) {
    return SettingsModel(
      url: url ?? this.url,
      loginPath: loginPath ?? this.loginPath,
      logoutPath: logoutPath ?? this.logoutPath,
      startNumber: startNumber ?? this.startNumber,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      delayBetween: delayBetween ?? this.delayBetween,
      navTimeout: navTimeout ?? this.navTimeout,
      postNavWait: postNavWait ?? this.postNavWait,
      unbanOnError: unbanOnError ?? this.unbanOnError,
      unbanMaxRetries: unbanMaxRetries ?? this.unbanMaxRetries,
      unbanCooldown: unbanCooldown ?? this.unbanCooldown,
      maxConsecutiveErrors: maxConsecutiveErrors ?? this.maxConsecutiveErrors,
      resumeSaved: resumeSaved ?? this.resumeSaved,
      usernameField: usernameField ?? this.usernameField,
      passwordField: passwordField ?? this.passwordField,
      customPassword: customPassword ?? this.customPassword,
      useWebView: useWebView ?? this.useWebView,
      injectSaleem: injectSaleem ?? this.injectSaleem,
      injectSaveUsername: injectSaveUsername ?? this.injectSaveUsername,
      usePopupSubmit: usePopupSubmit ?? this.usePopupSubmit,
      skipAlreadyTested: skipAlreadyTested ?? this.skipAlreadyTested,
    );
  }

  Map<String, String> toMap() {
    return {
      'URL': url,
      'LOGIN_PATH': loginPath,
      'LOGOUT_PATH': logoutPath,
      'START_NUMBER': startNumber,
      'MAX_ATTEMPTS': maxAttempts.toString(),
      'DELAY_BETWEEN': delayBetween.toString(),
      'NAV_TIMEOUT': navTimeout.toString(),
      'POST_NAV_WAIT': postNavWait.toString(),
      'UNBAN_ON_ERROR': unbanOnError ? '1' : '0',
      'UNBAN_MAX_RETRIES': unbanMaxRetries.toString(),
      'UNBAN_COOLDOWN': unbanCooldown.toString(),
      'MAX_CONSECUTIVE_ERRORS': maxConsecutiveErrors.toString(),
      'RESUME_SAVED': resumeSaved ? '1' : '0',
      'USERNAME_FIELD': usernameField,
      'PASSWORD_FIELD': passwordField,
      'CUSTOM_PASSWORD': customPassword,
      'USE_WEBVIEW': useWebView ? '1' : '0',
      'INJECT_SALEEM': injectSaleem ? '1' : '0',
      'INJECT_SAVE_USERNAME': injectSaveUsername ? '1' : '0',
      'USE_POPUP_SUBMIT': usePopupSubmit ? '1' : '0',
      'SKIP_ALREADY_TESTED': skipAlreadyTested ? '1' : '0',
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic val, bool def) {
      if (val == null) return def;
      if (val is bool) return val;
      final s = val.toString().trim();
      return s == '1' || s.toLowerCase() == 'true';
    }

    int parseInt(dynamic val, int def) {
      if (val == null) return def;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? def;
    }

    double parseDouble(dynamic val, double def) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    return SettingsModel(
      url: map['URL']?.toString() ?? 'http://a.com',
      loginPath: map['LOGIN_PATH']?.toString() ?? '/login',
      logoutPath: map['LOGOUT_PATH']?.toString() ?? '/logout',
      startNumber: map['START_NUMBER']?.toString() ?? '',
      maxAttempts: parseInt(map['MAX_ATTEMPTS'], 0),
      delayBetween: parseDouble(map['DELAY_BETWEEN'], 10.0),
      navTimeout: parseInt(map['NAV_TIMEOUT'], 30000),
      postNavWait: parseDouble(map['POST_NAV_WAIT'], 7.0),
      unbanOnError: parseBool(map['UNBAN_ON_ERROR'], true),
      unbanMaxRetries: parseInt(map['UNBAN_MAX_RETRIES'], 3),
      unbanCooldown: parseDouble(map['UNBAN_COOLDOWN'], 5.0),
      maxConsecutiveErrors: parseInt(map['MAX_CONSECUTIVE_ERRORS'], 10),
      resumeSaved: parseBool(map['RESUME_SAVED'], true),
      usernameField: map['USERNAME_FIELD']?.toString() ?? 'username',
      passwordField: map['PASSWORD_FIELD']?.toString() ?? 'password',
      customPassword: map['CUSTOM_PASSWORD']?.toString() ?? '',
      useWebView: parseBool(map['USE_WEBVIEW'], true),
      injectSaleem: parseBool(map['INJECT_SALEEM'], true),
      injectSaveUsername: parseBool(map['INJECT_SAVE_USERNAME'], true),
      usePopupSubmit: parseBool(map['USE_POPUP_SUBMIT'], true),
      skipAlreadyTested: parseBool(map['SKIP_ALREADY_TESTED'], false),
    );
  }
}

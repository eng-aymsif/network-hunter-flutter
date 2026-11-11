class SettingsModel {
  final String url;
  final String loginPath;
  final String logoutPath;
  final String startNumber;
  final int maxAttempts;
  final double delayBetween;
  final int navTimeout;
  final double postNavWait;
  final bool unbanOnError;
  final int unbanMaxRetries;
  final double unbanCooldown;
  final int maxConsecutiveErrors;
  final bool resumeSaved;
  final String usernameField;
  final String passwordField;
  final String customPassword;
  final bool useWebView;

  SettingsModel({
    this.url = 'http://a.com',
    this.loginPath = '/login',
    this.logoutPath = '/logout',
    this.startNumber = '301007757',
    this.maxAttempts = 0,
    this.delayBetween = 2.0,
    this.navTimeout = 15000,
    this.postNavWait = 3.0,
    this.unbanOnError = true,
    this.unbanMaxRetries = 3,
    this.unbanCooldown = 5.0,
    this.maxConsecutiveErrors = 10,
    this.resumeSaved = true,
    this.usernameField = 'username',
    this.passwordField = 'password',
    this.customPassword = '',
    this.useWebView = true, // الافتراضي هو محاكي المتصفح لمطابقة بايثون 100%
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
      'UNBAN_ON_ERROR': unbanOnError.toString(),
      'UNBAN_MAX_RETRIES': unbanMaxRetries.toString(),
      'UNBAN_COOLDOWN': unbanCooldown.toString(),
      'MAX_CONSECUTIVE_ERRORS': maxConsecutiveErrors.toString(),
      'resume_saved': resumeSaved.toString(),
      'username_field': usernameField,
      'password_field': passwordField,
      'custom_password': customPassword,
      'use_web_view': useWebView.toString(),
    };
  }

  factory SettingsModel.fromMap(Map<String, String> map) {
    return SettingsModel(
      url: map['URL'] ?? 'http://a.com',
      loginPath: map['LOGIN_PATH'] ?? '/login',
      logoutPath: map['LOGOUT_PATH'] ?? '/logout',
      startNumber: map['START_NUMBER'] ?? '301007757',
      maxAttempts: int.tryParse(map['MAX_ATTEMPTS'] ?? '0') ?? 0,
      delayBetween: double.tryParse(map['DELAY_BETWEEN'] ?? '2.0') ?? 2.0,
      navTimeout: int.tryParse(map['NAV_TIMEOUT'] ?? '15000') ?? 15000,
      postNavWait: double.tryParse(map['POST_NAV_WAIT'] ?? '3.0') ?? 3.0,
      unbanOnError: (map['UNBAN_ON_ERROR'] ?? 'true').toLowerCase() == 'true',
      unbanMaxRetries: int.tryParse(map['UNBAN_MAX_RETRIES'] ?? '3') ?? 3,
      unbanCooldown: double.tryParse(map['UNBAN_COOLDOWN'] ?? '5.0') ?? 5.0,
      maxConsecutiveErrors: int.tryParse(map['MAX_CONSECUTIVE_ERRORS'] ?? '10') ?? 10,
      resumeSaved: (map['resume_saved'] ?? 'true').toLowerCase() == 'true',
      usernameField: map['username_field'] ?? 'username',
      passwordField: map['password_field'] ?? 'password',
      customPassword: map['custom_password'] ?? '',
      useWebView: (map['use_web_view'] ?? 'true').toLowerCase() == 'true',
    );
  }
}

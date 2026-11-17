import 'dart:async';

/// Engine high-level execution status
enum EngineStatus { ready, running, paused, stopping, unbanning, error }

/// Strict sequential state machine execution steps
enum HunterStep {
  idle,
  checkingConnectivity,
  preparingLoginPage,
  submittingLogin,
  verifyingResult,
  handlingSuccess,
  loggingOutAndPurging,
  unbanning,
}

/// Abstract database contract for engine persistence
abstract class HunterDatabase {
  Future<String?> getState(String key);
  Future<void> setState(String key, String value);
  Future<bool> saveFoundCard(String cardNumber, String loginUrl, {String notes = ''});
}

/// Abstract contract for network & Wi-Fi connectivity verification
abstract class ConnectivityChecker {
  Future<bool> isConnected(String targetUrl);
}

/// Abstract contract for audio alerts
abstract class HunterSoundPlayer {
  Future<void> playAlert({bool isError = false});
}

/// Abstract contract for unban operations
abstract class HunterUnbanHandler {
  Future<Map<String, dynamic>> performUnban({void Function(String)? log});
}

/// Abstract contract for delayer (for fast unit testing without real delays)
abstract class HunterDelayer {
  Future<void> delay(Duration duration);
}

/// Abstract contract for HTTP client operations
abstract class HunterHttpClient {
  Future<HunterHttpResponse> get(String url, {Map<String, dynamic>? queryParameters});
  Future<HunterHttpResponse> post(String url, {Map<String, dynamic>? data});
}

/// HTTP response abstraction
class HunterHttpResponse {
  final int statusCode;
  final dynamic data;
  final Map<String, List<String>> headers;

  HunterHttpResponse({
    required this.statusCode,
    required this.data,
    this.headers = const {},
  });

  String? get headerLocation {
    final loc = headers['location'];
    if (loc != null && loc.isNotEmpty) return loc.first;
    return null;
  }
}

/// Result of live DOM inspection on captive portal page
class DomInspectionResult {
  final bool isReady;
  final String url;
  final bool isOfflinePage;
  final bool isStatusPage;
  final bool hasUsernameInput;
  final bool hasSubmitButton;
  final String? errorMessage;
  final String? reason;

  const DomInspectionResult({
    required this.isReady,
    this.url = '',
    this.isOfflinePage = false,
    this.isStatusPage = false,
    this.hasUsernameInput = false,
    this.hasSubmitButton = false,
    this.errorMessage,
    this.reason,
  });
}

/// Abstract contract for browser/webview interactions
abstract class HunterBrowserController {
  String? get lastAlertMessage => null;
  void clearLastAlert() {}
  Future<void> init({void Function(String)? onJsAlert});
  Future<void> loadUrl(String url);
  Future<String> currentUrl();
  Future<dynamic> runJavaScript(String script);
  Future<dynamic> runJavaScriptReturningResult(String script);
  Future<DomInspectionResult> inspectLoginPage({required String expectedField});
  Future<bool> submitCredentials({
    required String username,
    required String password,
    required String usernameField,
    required String passwordField,
    bool injectSaleem = true,
    bool injectSaveUsername = true,
    bool usePopupSubmit = true,
  });
  Future<void> executeLogout();
  Future<void> clearCache();
  Future<void> clearLocalStorage();
  Future<void> clearCookies();
  void dispose();
}

/// Result of login verification
class LoginVerificationResult {
  final bool isSuccess;
  final bool isDefinitiveFailure;
  final bool isInconclusive;
  final String finalUrl;
  final String? error;

  const LoginVerificationResult.success(this.finalUrl)
      : isSuccess = true,
        isDefinitiveFailure = false,
        isInconclusive = false,
        error = null;

  const LoginVerificationResult.definitiveFailure([this.finalUrl = ''])
      : isSuccess = false,
        isDefinitiveFailure = true,
        isInconclusive = false,
        error = null;

  const LoginVerificationResult.inconclusive({this.error, this.finalUrl = ''})
      : isSuccess = false,
        isDefinitiveFailure = false,
        isInconclusive = true;
}

/// Result of login page ready verification
class PageVerificationResult {
  final bool isReady;
  final String url;
  final String? error;
  final bool isNetworkError;

  const PageVerificationResult({
    required this.isReady,
    this.url = '',
    this.error,
    this.isNetworkError = false,
  });
}

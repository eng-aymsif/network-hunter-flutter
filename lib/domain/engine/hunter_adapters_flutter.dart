import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:networking/core/utils/platform_env.dart';
import 'package:networking/core/utils/sound_helper.dart';
import 'package:networking/data/datasources/unban_service.dart';
import 'package:networking/domain/engine/hunter_interfaces.dart';

HunterBrowserController? createPlatformBrowserController() =>
    PlatformEnv.isAndroid ? FlutterHunterBrowserController() : null;
HunterSoundPlayer createPlatformSoundPlayer() => FlutterHunterSoundPlayer();
HunterUnbanHandler createPlatformUnbanHandler() => FlutterHunterUnbanHandler();

class FlutterHunterSoundPlayer implements HunterSoundPlayer {
  @override
  Future<void> playAlert({bool isError = false}) async {
    try {
      await SoundHelper.playAlert(isError: isError);
    } catch (_) {}
  }
}

class FlutterHunterUnbanHandler implements HunterUnbanHandler {
  @override
  Future<Map<String, dynamic>> performUnban({void Function(String)? log}) =>
      UnbanService.performUnban(log: log);
}

class FlutterHunterBrowserController implements HunterBrowserController {
  WebViewController? _controller;

  String? _lastAlertMessage;

  @override
  String? get lastAlertMessage => _lastAlertMessage;

  @override
  void clearLastAlert() {
    _lastAlertMessage = null;
  }

  @override
  Future<void> init({void Function(String)? onJsAlert}) async {
    const alertSuppressorScript = '''
      (function() {
        if (window.__alertInterceptionActive) return;
        window.__alertInterceptionActive = true;

        var originalAlert = window.alert;
        window.alert = function(msg) {
          try {
            if (window.BrowserAlertBridge) {
              window.BrowserAlertBridge.postMessage(String(msg || ''));
            }
          } catch(e) {}
          return true;
        };

        window.confirm = function(msg) {
          try {
            if (window.BrowserAlertBridge) {
              window.BrowserAlertBridge.postMessage(String(msg || ''));
            }
          } catch(e) {}
          return true;
        };

        window.prompt = function(msg, defaultText) {
          try {
            if (window.BrowserAlertBridge) {
              window.BrowserAlertBridge.postMessage(String(msg || ''));
            }
          } catch(e) {}
          return defaultText || '';
        };
      })();
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'BrowserAlertBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          _lastAlertMessage = msg.message;
          onJsAlert?.call(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) async {
            try {
              await _controller?.runJavaScript(alertSuppressorScript);
            } catch (_) {}
          },
          onPageFinished: (url) async {
            try {
              await _controller?.runJavaScript(alertSuppressorScript);
            } catch (_) {}
          },
        ),
      );
  }

  @override
  Future<void> loadUrl(String url) async {
    if (_controller == null) await init();
    try {
      await _controller!.loadRequest(Uri.parse(url)).timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
    } catch (_) {}
  }

  @override
  Future<String> currentUrl() async {
    if (_controller == null) return '';
    try {
      return (await _controller!.currentUrl().timeout(
            const Duration(seconds: 4),
            onTimeout: () => '',
          )) ??
          '';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<dynamic> runJavaScript(String script) async {
    if (_controller == null) return null;
    try {
      return await _controller!.runJavaScript(script).timeout(
            const Duration(seconds: 5),
            onTimeout: () {},
          );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> runJavaScriptReturningResult(String script) async {
    if (_controller == null) return '';
    try {
      return await _controller!.runJavaScriptReturningResult(script).timeout(
            const Duration(seconds: 5),
            onTimeout: () => '',
          );
    } catch (_) {
      return '';
    }
  }

  @override
  Future<DomInspectionResult> inspectLoginPage({required String expectedField}) async {
    if (_controller == null) {
      return const DomInspectionResult(isReady: false, reason: 'controller_null');
    }

    try {
      final jsInspect = '''
        (function() {
          try {
            if (!document || !document.body) {
              return JSON.stringify({ ready: false, reason: "document_not_ready" });
            }
            var text = (document.body.innerText || "") + " " + (document.title || "");
            
            // Check for browser network / offline error pages
            if (text.indexOf("ERR_INTERNET_DISCONNECTED") !== -1 ||
                text.indexOf("ERR_NAME_NOT_RESOLVED") !== -1 ||
                text.indexOf("ERR_CONNECTION_REFUSED") !== -1 ||
                text.indexOf("ERR_ADDRESS_UNREACHABLE") !== -1 ||
                text.indexOf("Webpage not available") !== -1 ||
                text.indexOf("الصفحة غير متاحة") !== -1 ||
                text.indexOf("تعذر الاتصال") !== -1) {
              return JSON.stringify({ ready: false, isOfflinePage: true, reason: "browser_offline_error" });
            }

            var href = window.location.href || "";
            var isStatus = window.location.pathname.split('/').some(function(part) {
                             return part.toLowerCase() === "status";
                           }) ||
                           text.indexOf("الوقت المتبقي") !== -1 ||
                           text.indexOf("اضغط هنا لتسجيل الخروج") !== -1;
            if (isStatus) {
              return JSON.stringify({ ready: false, isStatusPage: true, reason: "router_session_active", url: href });
            }

            var u = document.querySelector('#username') ||
                    document.querySelector('input[name="username"]') ||
                    document.querySelector('input[name="$expectedField"]') ||
                    document.querySelector('input[type="text"]');
            var p = document.querySelector('#password') ||
                    document.querySelector('input[name="password"]') ||
                    document.querySelector('input[type="password"]');
            var btn = document.querySelector('input[type="submit"]') ||
                      document.querySelector('button[type="submit"]') ||
                      document.querySelector('input[type="button"]') ||
                      document.querySelector('button');

            if (!u) {
              return JSON.stringify({ ready: false, reason: "username_input_missing", url: href });
            }
            if (!btn) {
              return JSON.stringify({ ready: false, reason: "submit_button_missing", url: href });
            }

            // Clear any residual input values to ensure clean state
            u.value = '';
            if (p) p.value = '';

            return JSON.stringify({
              ready: true,
              url: href,
              hasUsernameInput: true,
              hasSubmitButton: true
            });
          } catch(e) {
            return JSON.stringify({ ready: false, reason: "js_exception: " + e.toString() });
          }
        })();
      ''';

      final raw = (await _controller!.runJavaScriptReturningResult(jsInspect)).toString();
      // On some platforms, result might be surrounded by quotes or escaped JSON
      String cleanJson = raw;
      if (cleanJson.startsWith('"') && cleanJson.endsWith('"')) {
        cleanJson = jsonDecode(cleanJson) as String;
      }
      final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;

      return DomInspectionResult(
        isReady: parsed['ready'] == true,
        url: parsed['url']?.toString() ?? '',
        isOfflinePage: parsed['isOfflinePage'] == true,
        isStatusPage: parsed['isStatusPage'] == true,
        hasUsernameInput: parsed['hasUsernameInput'] == true,
        hasSubmitButton: parsed['hasSubmitButton'] == true,
        reason: parsed['reason']?.toString(),
      );
    } catch (e) {
      return DomInspectionResult(isReady: false, reason: 'inspect_failed: $e');
    }
  }

  @override
  Future<bool> submitCredentials({
    required String username,
    required String password,
    required String usernameField,
    required String passwordField,
    bool injectSaleem = true,
    bool injectSaveUsername = true,
    bool usePopupSubmit = true,
  }) async {
    if (_controller == null) return false;

    final jsSubmit = '''
      (function() {
        var u = document.querySelector('#username') ||
                document.querySelector('input[name="username"]') ||
                document.querySelector('input[name="$usernameField"]') ||
                document.querySelector('input[type="text"]');
        if (!u) return false;

        u.value = '$username';
        u.dispatchEvent(new Event('input', { bubbles: true }));
        u.dispatchEvent(new Event('change', { bubbles: true }));

        if ('$password'.length > 0) {
          var p = document.querySelector('#password') ||
                  document.querySelector('input[name="password"]') ||
                  document.querySelector('input[name="$passwordField"]') ||
                  document.querySelector('input[type="password"]');
          if (p) {
            p.value = '$password';
            p.dispatchEvent(new Event('input', { bubbles: true }));
            p.dispatchEvent(new Event('change', { bubbles: true }));
          }
        }

        // 1. استدعاء دالة saveUsername() إن كان الخيار مفعلاً
        if ($injectSaveUsername) {
          try {
            if (typeof saveUsername === 'function') {
              saveUsername();
            }
          } catch(e) {}
        }

        // 2. استدعاء دالة saleem() إن كان الخيار مفعلاً
        if ($injectSaleem) {
          try {
            if (typeof saleem === 'function') {
              saleem();
            }
          } catch(e) {}
        }

        // 3. تحديد آلية التخطي والإرسال (عبر Popup أو زر Submit مباشر)
        if ($usePopupSubmit) {
          var btn = document.querySelector('input[type="button"]');
          if (btn) btn.click();

          var popup = document.getElementById('popup');
          if (popup) popup.style.display = 'block';

          setTimeout(function() {
            var sub = document.querySelector('#popup input[type="submit"]') ||
                      document.querySelector('input[type="submit"]') ||
                      document.querySelector('button[type="submit"]');
            if (sub) {
              sub.click();
            } else if (document.forms.length > 0) {
              document.forms[0].submit();
            }
          }, 300);
        } else {
          // إرسال مباشر عبر زر Submit أسفل حقل الـ Username
          var directSub = document.querySelector('form input[type="submit"]:not(#popup input)') ||
                          document.querySelector('input[type="submit"]') ||
                          document.querySelector('button[type="submit"]');
          if (directSub) {
            directSub.click();
          } else if (document.forms.length > 0) {
            document.forms[0].submit();
          }
        }

        return true;
      })();
    ''';

    try {
      await _controller!.runJavaScript(jsSubmit);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> executeLogout() async {
    if (_controller == null) {
      throw StateError('Cannot execute logout before initializing the browser.');
    }

    final jsLogout = '''
      (function() {
        try {
          if (typeof deleteAllCookies === 'function') {
            deleteAllCookies();
          }
        } catch(e) {}

        try {
          if (window.sessionStorage) window.sessionStorage.clear();
        } catch(e) {}
        try {
          if (window.localStorage) window.localStorage.clear();
        } catch(e) {}

        try {
          var form = document.forms['logout'] || document.querySelector('form[name="logout"]') || document.querySelector('form[action*="logout"]');
          if (form) {
            var btn = form.querySelector('input[type="submit"].logoff') || form.querySelector('input.logoff') || form.querySelector('input[type="submit"]');
            if (btn) {
              btn.click();
              return "clicked_btn";
            } else {
              form.submit();
              return "submitted_form";
            }
          }
        } catch(e) {}

        try {
          var allInputs = document.querySelectorAll('input[type="submit"], input[type="button"], a');
          for (var i = 0; i < allInputs.length; i++) {
            var el = allInputs[i];
            var val = (el.value || el.innerText || el.textContent || '').trim();
            if (val.indexOf('تسجيل الدخول بكرت جديد') !== -1 || (el.getAttribute('onclick') && el.getAttribute('onclick').indexOf('deleteAllCookies') !== -1)) {
              el.click();
              return "clicked_new_card";
            }
          }
        } catch(e) {}
        return "fallback";
      })();
    ''';

    await _controller!.runJavaScript(jsLogout);
  }

  @override
  Future<void> clearCache() async {
    try {
      await _controller?.clearCache().timeout(
            const Duration(seconds: 4),
            onTimeout: () {},
          );
    } catch (_) {}
  }

  @override
  Future<void> clearLocalStorage() async {
    try {
      await _controller?.clearLocalStorage().timeout(
            const Duration(seconds: 4),
            onTimeout: () {},
          );
    } catch (_) {}
  }

  @override
  Future<void> clearCookies() async {
    try {
      await WebViewCookieManager().clearCookies().timeout(
            const Duration(seconds: 4),
            onTimeout: () => false,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller = null;
  }
}

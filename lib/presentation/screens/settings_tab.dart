import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/core/utils/native_bridge.dart';
import 'package:networking/presentation/providers/settings_provider.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _urlCtrl;
  late TextEditingController _loginPathCtrl;
  late TextEditingController _logoutPathCtrl;
  late TextEditingController _startNumCtrl;
  late TextEditingController _maxAttemptsCtrl;
  late TextEditingController _delayCtrl;
  late TextEditingController _navTimeoutCtrl;
  late TextEditingController _postWaitCtrl;
  late TextEditingController _unbanRetriesCtrl;
  late TextEditingController _unbanCooldownCtrl;
  late TextEditingController _maxErrorsCtrl;
  late TextEditingController _usernameFieldCtrl;
  late TextEditingController _passwordFieldCtrl;
  late TextEditingController _customPasswordCtrl;

  bool _useWebView = true;
  bool _unbanOnError = true;
  bool _injectSaleem = true;
  bool _injectSaveUsername = true;
  bool _usePopupSubmit = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final s = context.read<SettingsProvider>().settings;
      _urlCtrl = TextEditingController(text: s.url);
      _loginPathCtrl = TextEditingController(text: s.loginPath);
      _logoutPathCtrl = TextEditingController(text: s.logoutPath);
      _startNumCtrl = TextEditingController(text: s.startNumber);
      _maxAttemptsCtrl = TextEditingController(text: s.maxAttempts.toString());
      _delayCtrl = TextEditingController(text: s.delayBetween.toString());
      _navTimeoutCtrl = TextEditingController(text: s.navTimeout.toString());
      _postWaitCtrl = TextEditingController(text: s.postNavWait.toString());
      _unbanRetriesCtrl = TextEditingController(
        text: s.unbanMaxRetries.toString(),
      );
      _unbanCooldownCtrl = TextEditingController(
        text: s.unbanCooldown.toString(),
      );
      _maxErrorsCtrl = TextEditingController(
        text: s.maxConsecutiveErrors.toString(),
      );
      _usernameFieldCtrl = TextEditingController(text: s.usernameField);
      _passwordFieldCtrl = TextEditingController(text: s.passwordField);
      _customPasswordCtrl = TextEditingController(text: s.customPassword);
      _useWebView = s.useWebView;
      _unbanOnError = s.unbanOnError;
      _injectSaleem = s.injectSaleem;
      _injectSaveUsername = s.injectSaveUsername;
      _usePopupSubmit = s.usePopupSubmit;

      // ربط التغييرات النصية لحظياً بـ SettingsProvider لضمان تطبيق أي تعديل فوراً
      void syncLive() {
        if (!mounted) return;
        final prov = context.read<SettingsProvider>();
        prov.updateSettings(
          prov.settings.copyWith(
            url: _urlCtrl.text.trim().isNotEmpty
                ? _urlCtrl.text.trim()
                : 'http://a.com',
            loginPath: _loginPathCtrl.text.trim().isNotEmpty
                ? _loginPathCtrl.text.trim()
                : '/login',
            logoutPath: _logoutPathCtrl.text.trim().isNotEmpty
                ? _logoutPathCtrl.text.trim()
                : '/logout',
            startNumber: _startNumCtrl.text.trim(),
            maxAttempts: int.tryParse(_maxAttemptsCtrl.text.trim()) ?? 0,
            delayBetween: double.tryParse(_delayCtrl.text.trim()) ?? 10.0,
            navTimeout: int.tryParse(_navTimeoutCtrl.text.trim()) ?? 30000,
            postNavWait: double.tryParse(_postWaitCtrl.text.trim()) ?? 7.0,
            unbanOnError: _unbanOnError,
            unbanMaxRetries: int.tryParse(_unbanRetriesCtrl.text.trim()) ?? 3,
            unbanCooldown:
                double.tryParse(_unbanCooldownCtrl.text.trim()) ?? 5.0,
            maxConsecutiveErrors:
                int.tryParse(_maxErrorsCtrl.text.trim()) ?? 10,
            usernameField: _usernameFieldCtrl.text.trim().isNotEmpty
                ? _usernameFieldCtrl.text.trim()
                : 'username',
            passwordField: _passwordFieldCtrl.text.trim().isNotEmpty
                ? _passwordFieldCtrl.text.trim()
                : 'password',
            customPassword: _customPasswordCtrl.text.trim(),
            useWebView: _useWebView,
            injectSaleem: _injectSaleem,
            injectSaveUsername: _injectSaveUsername,
            usePopupSubmit: _usePopupSubmit,
          ),
        );
      }

      for (final c in [
        _urlCtrl,
        _loginPathCtrl,
        _logoutPathCtrl,
        _startNumCtrl,
        _maxAttemptsCtrl,
        _delayCtrl,
        _navTimeoutCtrl,
        _postWaitCtrl,
        _unbanRetriesCtrl,
        _unbanCooldownCtrl,
        _maxErrorsCtrl,
        _usernameFieldCtrl,
        _passwordFieldCtrl,
        _customPasswordCtrl,
      ]) {
        c.addListener(syncLive);
      }

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _loginPathCtrl.dispose();
    _logoutPathCtrl.dispose();
    _startNumCtrl.dispose();
    _maxAttemptsCtrl.dispose();
    _delayCtrl.dispose();
    _navTimeoutCtrl.dispose();
    _postWaitCtrl.dispose();
    _unbanRetriesCtrl.dispose();
    _unbanCooldownCtrl.dispose();
    _maxErrorsCtrl.dispose();
    _usernameFieldCtrl.dispose();
    _passwordFieldCtrl.dispose();
    _customPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بطاقة 0: نوع محرك الفحص (WebKit vs HTTP) وخيارات حقن الجافاسكريبت
                _buildSectionCard(
                  title: 'محرك الفحص وديناميكية صفحات الدخول (Captive Portal JS)',
                  icon: Icons.language,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'استخدام محرك المتصفح التفاعلي (WebKit Engine)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'مطابق بنسبة 100% لمحرك Playwright في بايثون؛ يقوم بمحاكاة النقر على الأزرار وتشغيل الجافاسكريبت.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      value: _useWebView,
                      onChanged: (val) {
                        setState(() => _useWebView = val);
                        settingsProv.updateSettings(
                          settingsProv.settings.copyWith(useWebView: val),
                        );
                      },
                    ),
                    const Divider(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'حقن واستدعاء دالة saleem()',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'استدعاء دالة saleem() تلقائياً قبل إرسال النموذج في البوابات التي تعتمد عليها.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                      ),
                      value: _injectSaleem,
                      onChanged: _useWebView
                          ? (val) {
                              setState(() => _injectSaleem = val);
                              settingsProv.updateSettings(
                                settingsProv.settings.copyWith(
                                  injectSaleem: val,
                                ),
                              );
                            }
                          : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'حقن واستدعاء دالة saveUsername()',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'استدعاء دالة saveUsername() لحفظ اسم المستخدم في الكوكيز أو الحقل المخفي.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                      ),
                      value: _injectSaveUsername,
                      onChanged: _useWebView
                          ? (val) {
                              setState(() => _injectSaveUsername = val);
                              settingsProv.updateSettings(
                                settingsProv.settings.copyWith(
                                  injectSaveUsername: val,
                                ),
                              );
                            }
                          : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'آلية التخطي عبر نافذة منبثقة (Popup Submit)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _usePopupSubmit
                            ? 'الوضع الحالي: نقر input[type="button"] ثم إظهار #popup ونقر زر Submit بداخله.'
                            : 'الوضع الحالي: نقر زر Submit المباشر أسفل حقل Username مباشرة بدون Popup.',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.accent,
                        ),
                      ),
                      value: _usePopupSubmit,
                      onChanged: _useWebView
                          ? (val) {
                              setState(() => _usePopupSubmit = val);
                              settingsProv.updateSettings(
                                settingsProv.settings.copyWith(
                                  usePopupSubmit: val,
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // بطاقة 1: إعدادات الشبكة ومسارات البوابة
                _buildSectionCard(
                  title: 'إعدادات الشبكة ومسارات صفحة الدخول',
                  icon: Icons.wifi,
                  children: [
                    TextFormField(
                      controller: _urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'رابط بوابة الدخول (URL) * (إلزامي)',
                        hintText: 'http://a.com أو http://10.0.0.1',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _responsivePair(
                      context,
                      TextFormField(
                        controller: _loginPathCtrl,
                        decoration: const InputDecoration(
                          labelText: 'مسار الدخول (LOGIN_PATH) * (إلزامي)',
                          hintText: '/login',
                        ),
                      ),
                      TextFormField(
                        controller: _logoutPathCtrl,
                        decoration: const InputDecoration(
                          labelText: 'مسار الخروج (LOGOUT_PATH) (اختياري)',
                          hintText: '/logout',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _startNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'رقم كارت البداية (START_NUMBER) * (إلزامي)',
                        hintText: 'أدخل رقم كارت البداية (إلزامي لبدء الفحص)',
                        prefixIcon: Icon(Icons.pin),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // بطاقة 2: خيارات التوقيت والمحاولات
                _buildSectionCard(
                  title: 'إعدادات التوقيت والمحاولات',
                  icon: Icons.timer_outlined,
                  children: [
                    _responsivePair(
                      context,
                      TextFormField(
                        controller: _delayCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'الانتظار بين المحاولات (ثوانٍ) * (إلزامي)',
                          hintText: '10.0',
                        ),
                      ),
                      TextFormField(
                        controller: _maxAttemptsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الحد الأقصى للمحاولات (اختياري - 0 = بلا توقف)',
                          hintText: '0',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _responsivePair(
                      context,
                      TextFormField(
                        controller: _navTimeoutCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مهلة الطلب (ms) (اختياري)',
                          hintText: '30000',
                        ),
                      ),
                      TextFormField(
                        controller: _postWaitCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'انتظار التحقق (ثوانٍ) (اختياري)',
                          hintText: '7.0',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // بطاقة 3: إعدادات فك الحظر التلقائي وأدوات الشبكة
                _buildSectionCard(
                  title: 'إعدادات الأخطاء والواي فاي',
                  icon: Icons.security,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'فك الحظر التلقائي عند خطأ الاتصال',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'يقوم بمحاولة فك الحظر تلقائياً عند انقطاع الاستجابة من الراوتر.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                      ),
                      value: _unbanOnError,
                      onChanged: (val) {
                        setState(() => _unbanOnError = val);
                        settingsProv.updateSettings(
                          settingsProv.settings.copyWith(unbanOnError: val),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _responsivePair(
                      context,
                      TextFormField(
                        controller: _unbanRetriesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'أقصى محاولات فك الحظر المتتالية',
                          hintText: '3',
                        ),
                      ),
                      TextFormField(
                        controller: _unbanCooldownCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'الانتظار بين محاولات فك الحظر (ثوانٍ)',
                          hintText: '5.0',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _maxErrorsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الحد الأقصى للأخطاء المتتالية (لتشغيل التنبيه)',
                        hintText: '10',
                      ),
                    ),
                    const Divider(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.settings_input_antenna,
                            size: 16,
                          ),
                          label: const Text(
                            'فتح إعدادات الواي فاي',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                          ),
                          onPressed: () => NativeBridge.openWifiSettings(),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.security_update_good,
                            size: 16,
                          ),
                          label: const Text(
                            'إعادة طلب أذونات التطبيق',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                          ),
                          onPressed: () => NativeBridge.requestAppPermissions(),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.battery_charging_full,
                            size: 16,
                            color: AppColors.success,
                          ),
                          label: const Text(
                            'استثناء قيود البطارية (Unrestricted)',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                          ),
                          onPressed: () =>
                              NativeBridge.requestIgnoreBatteryOptimizations(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // بطاقة 4: تخصيص حقول النموذج
                _buildSectionCard(
                  title: 'تخصيص أسماء حقول تسجيل الدخول',
                  icon: Icons.text_fields,
                  children: [
                    _responsivePair(
                      context,
                      TextFormField(
                        controller: _usernameFieldCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم حقل المستخدم * (إلزامي)',
                          hintText: 'username',
                        ),
                      ),
                      TextFormField(
                        controller: _passwordFieldCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم حقل كلمة المرور (اختياري)',
                          hintText: 'password',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _customPasswordCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'كلمة مرور مخصصة (اختياري - اتركها فارغة لاستخدام رقم الكرت)',
                        hintText: 'فارغة تلقائياً',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // أزرار الحفظ واستعادة الافتراضيات
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          final current = settingsProv.settings;
                          final updated = current.copyWith(
                            url: _urlCtrl.text.trim().isNotEmpty
                                ? _urlCtrl.text.trim()
                                : 'http://a.com',
                            loginPath: _loginPathCtrl.text.trim().isNotEmpty
                                ? _loginPathCtrl.text.trim()
                                : '/login',
                            logoutPath: _logoutPathCtrl.text.trim().isNotEmpty
                                ? _logoutPathCtrl.text.trim()
                                : '/logout',
                            startNumber: _startNumCtrl.text.trim(),
                            maxAttempts:
                                int.tryParse(_maxAttemptsCtrl.text.trim()) ?? 0,
                            delayBetween:
                                double.tryParse(_delayCtrl.text.trim()) ?? 10.0,
                            navTimeout:
                                int.tryParse(_navTimeoutCtrl.text.trim()) ??
                                30000,
                            postNavWait:
                                double.tryParse(_postWaitCtrl.text.trim()) ??
                                7.0,
                            unbanOnError: _unbanOnError,
                            unbanMaxRetries:
                                int.tryParse(_unbanRetriesCtrl.text.trim()) ??
                                3,
                            unbanCooldown:
                                double.tryParse(
                                  _unbanCooldownCtrl.text.trim(),
                                ) ??
                                5.0,
                            maxConsecutiveErrors:
                                int.tryParse(_maxErrorsCtrl.text.trim()) ?? 10,
                            usernameField:
                                _usernameFieldCtrl.text.trim().isNotEmpty
                                ? _usernameFieldCtrl.text.trim()
                                : 'username',
                            passwordField:
                                _passwordFieldCtrl.text.trim().isNotEmpty
                                ? _passwordFieldCtrl.text.trim()
                                : 'password',
                            customPassword: _customPasswordCtrl.text.trim(),
                            useWebView: _useWebView,
                            injectSaleem: _injectSaleem,
                            injectSaveUsername: _injectSaveUsername,
                            usePopupSubmit: _usePopupSubmit,
                          );
                          settingsProv.saveSettings(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تم حفظ وتفعيل كافة الإعدادات بنجاح في قاعدة البيانات 💾',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text(
                          AppStrings.btnSaveSettings,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await settingsProv.restoreDefaults();
                          final s = settingsProv.settings;
                          _urlCtrl.text = s.url;
                          _loginPathCtrl.text = s.loginPath;
                          _logoutPathCtrl.text = s.logoutPath;
                          _startNumCtrl.text = s.startNumber;
                          _maxAttemptsCtrl.text = s.maxAttempts.toString();
                          _delayCtrl.text = s.delayBetween.toString();
                          _navTimeoutCtrl.text = s.navTimeout.toString();
                          _postWaitCtrl.text = s.postNavWait.toString();
                          _unbanRetriesCtrl.text = s.unbanMaxRetries.toString();
                          _unbanCooldownCtrl.text = s.unbanCooldown.toString();
                          _maxErrorsCtrl.text = s.maxConsecutiveErrors
                              .toString();
                          _usernameFieldCtrl.text = s.usernameField;
                          _passwordFieldCtrl.text = s.passwordField;
                          _customPasswordCtrl.text = s.customPassword;
                          setState(() {
                            _useWebView = s.useWebView;
                            _unbanOnError = s.unbanOnError;
                            _injectSaleem = s.injectSaleem;
                            _injectSaveUsername = s.injectSaveUsername;
                            _usePopupSubmit = s.usePopupSubmit;
                          });

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تمت استعادة الإعدادات الافتراضية بنجاح ↺',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'الافتراضية',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _responsivePair(BuildContext context, Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 10), second],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

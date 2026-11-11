import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/native_bridge.dart';
import '../providers/settings_provider.dart';

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

  bool _unbanOnError = true;
  bool _useWebView = true;
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
      _unbanRetriesCtrl = TextEditingController(text: s.unbanMaxRetries.toString());
      _unbanCooldownCtrl = TextEditingController(text: s.unbanCooldown.toString());
      _maxErrorsCtrl = TextEditingController(text: s.maxConsecutiveErrors.toString());
      _usernameFieldCtrl = TextEditingController(text: s.usernameField);
      _passwordFieldCtrl = TextEditingController(text: s.passwordField);
      _customPasswordCtrl = TextEditingController(text: s.customPassword);
      _unbanOnError = s.unbanOnError;
      _useWebView = s.useWebView;
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة 0: نوع محرك الفحص (WebKit vs HTTP)
            _buildSectionCard(
              title: 'محرك الفحص والأتمتة',
              icon: Icons.language,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'استخدام محرك المتصفح التفاعلي (WebKit Engine)',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'مطابق بنسبة 100% لمحرك Playwright في بايثون؛ يقوم بمحاكاة النقر على الأزرار وفتح نافذة الـ Popup وتشغيل الجافاسكريبت.',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                  ),
                  value: _useWebView,
                  onChanged: (val) {
                    setState(() => _useWebView = val);
                  },
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
                    labelText: 'رابط بوابة الدخول (URL)',
                    hintText: 'http://a.com أو http://10.0.0.1',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _loginPathCtrl,
                        decoration: const InputDecoration(
                          labelText: 'مسار الدخول (LOGIN_PATH)',
                          hintText: '/login',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _logoutPathCtrl,
                        decoration: const InputDecoration(
                          labelText: 'مسار الخروج (LOGOUT_PATH)',
                          hintText: '/logout',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _startNumCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رقم كارت البداية (START_NUMBER)',
                    hintText: '301007757',
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _delayCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'الانتظار بين المحاولات (ثوانٍ)',
                          hintText: '2.0',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _maxAttemptsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'أقصى محاولات (0 = غير محدود)',
                          hintText: '0',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _navTimeoutCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مهلة الطلب (ms)',
                          hintText: '15000',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _postWaitCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'انتظار التحقق (ثوانٍ)',
                          hintText: '3.0',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // بطاقة 3: إعدادات فك الحظر التلقائي وأدوات الشبكة
            _buildSectionCard(
              title: 'إعدادات فك الحظر والواي فاي',
              icon: Icons.security,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تفعيل فك الحظر التلقائي عند مواجهة خطأ', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold)),
                  value: _unbanOnError,
                  onChanged: (val) {
                    setState(() => _unbanOnError = val);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unbanRetriesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'أقصى محاولات فك الحظر',
                          hintText: '3',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _unbanCooldownCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'الانتظار بين المحاولات (ثوانٍ)',
                          hintText: '5.0',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _maxErrorsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الحد الأقصى للأخطاء المتتالية قبل الإيقاف المؤقت',
                    hintText: '10',
                  ),
                ),
                const Divider(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.settings_input_antenna, size: 16),
                      label: const Text('فتح إعدادات الواي فاي', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                      onPressed: () => NativeBridge.openWifiSettings(),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.security_update_good, size: 16),
                      label: const Text('إعادة طلب أذونات التطبيق', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                      onPressed: () => NativeBridge.requestAppPermissions(),
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usernameFieldCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم حقل المستخدم',
                          hintText: 'username',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _passwordFieldCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم حقل كلمة المرور',
                          hintText: 'password',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customPasswordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور مخصصة (اتركها فارغة لاستخدام رقم الكرت)',
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
                        url: _urlCtrl.text.trim(),
                        loginPath: _loginPathCtrl.text.trim(),
                        logoutPath: _logoutPathCtrl.text.trim(),
                        startNumber: _startNumCtrl.text.trim(),
                        maxAttempts: int.tryParse(_maxAttemptsCtrl.text.trim()) ?? 0,
                        delayBetween: double.tryParse(_delayCtrl.text.trim()) ?? 2.0,
                        navTimeout: int.tryParse(_navTimeoutCtrl.text.trim()) ?? 15000,
                        postNavWait: double.tryParse(_postWaitCtrl.text.trim()) ?? 3.0,
                        unbanOnError: _unbanOnError,
                        unbanMaxRetries: int.tryParse(_unbanRetriesCtrl.text.trim()) ?? 3,
                        unbanCooldown: double.tryParse(_unbanCooldownCtrl.text.trim()) ?? 5.0,
                        maxConsecutiveErrors: int.tryParse(_maxErrorsCtrl.text.trim()) ?? 10,
                        usernameField: _usernameFieldCtrl.text.trim().isNotEmpty ? _usernameFieldCtrl.text.trim() : 'username',
                        passwordField: _passwordFieldCtrl.text.trim().isNotEmpty ? _passwordFieldCtrl.text.trim() : 'password',
                        customPassword: _customPasswordCtrl.text.trim(),
                        useWebView: _useWebView,
                      );
                      settingsProv.saveSettings(updated);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم حفظ كافة الإعدادات بنجاح في قاعدة البيانات 💾', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text(AppStrings.btnSaveSettings, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
                      _maxErrorsCtrl.text = s.maxConsecutiveErrors.toString();
                      _usernameFieldCtrl.text = s.usernameField;
                      _passwordFieldCtrl.text = s.passwordField;
                      _customPasswordCtrl.text = s.customPassword;
                      setState(() {
                        _unbanOnError = s.unbanOnError;
                        _useWebView = s.useWebView;
                      });

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تمت استعادة الإعدادات الافتراضية بنجاح ↺', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      );
                    },
                    child: const Text('الافتراضية', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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

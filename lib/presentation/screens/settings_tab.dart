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
  bool _skipAlreadyTested = false;
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
      _skipAlreadyTested = s.skipAlreadyTested;

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
            skipAlreadyTested: _skipAlreadyTested,
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
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'استخدام محرك المتصفح التفاعلي (WebKit Engine)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 19, color: AppColors.accent),
                            tooltip: 'شرح الخاصية',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'محرك المتصفح التفاعلي (WebKit Engine)',
                              description: 'يقوم بتشغيل محرك متصفح حقيقي في الخلفية لتنفيذ جافاسكريبت والتعامل مع صفحات الدخول المعقدة، مثل محرك Playwright في بايثون.',
                              impact: 'أساسي للبوابات التي تعتمد على أزرار JS ونوافذ منبثقة أو حماية ضد روبوتات الفحص البسيطة.',
                              example: 'مُفعل افتراضياً لتوفير أقصى توافقية مع شبكات المايكروتك.',
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'مطابق بنسبة 100% لمحرك Playwright في بايثون؛ يقوم بمحاكاة النقر على الأزرار وتشغيل الجافاسكريبت.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
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
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'حقن واستدعاء دالة saleem()',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 19, color: AppColors.accent),
                            tooltip: 'شرح الخاصية',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'حقن واستدعاء دالة saleem()',
                              description: 'استدعاء دالة saleem() تلقائياً في صفحة الدخول قبل إرسال النموذج في بوابات المايكروتك الشائعة باليمن.',
                              impact: 'يسمح بتخطي التشفير الداخلي أو شروط التحقق في صفحات كروت الشبكة المعدلة.',
                              example: 'اتركه مفعلاً إذا كانت شبكتك تستخدم نظام سليم لتسجيل الدخول.',
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'استدعاء دالة saleem() تلقائياً قبل إرسال النموذج في البوابات التي تعتمد عليها.',
                        style: TextStyle(fontSize: 11),
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
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'حقن واستدعاء دالة saveUsername()',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 19, color: AppColors.accent),
                            tooltip: 'شرح الخاصية',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'حقن واستدعاء دالة saveUsername()',
                              description: 'يقوم بحفظ رقم الكرت في الكوكيز أو التخزين المحلي لصفحة الشبكة كما تفعل الصفحة الأصلية.',
                              impact: 'يثبت جلسة الكرت ويمنع بعض البوابات من طلب تسجيل الدخول مراراً.',
                              example: 'مُفعل تلقائياً كأفضل ممارسة.',
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'استدعاء دالة saveUsername() لحفظ اسم المستخدم في الكوكيز أو الحقل المخفي.',
                        style: TextStyle(fontSize: 11),
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
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'آلية التخطي عبر نافذة منبثقة (Popup Submit)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 19, color: AppColors.accent),
                            tooltip: 'شرح الخاصية',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'إرسال النموذج عبر نافذة منبثقة (Popup Submit)',
                              description: 'يقوم بنقر زر العرض input[type="button"] أولاً ثم البحث عن زر الإرسال Submit داخل النافذة المنبثقة #popup.',
                              impact: 'ضروري للصفحات التي لا تملك زر إرسال مباشر في الواجهة الرئيسية وتخفيه داخل نافذة تأكيد أو شروط.',
                              example: 'إذا كانت صفحة شبكتك تفتح نافذة لتأكيد الدخول، اترك هذا الخيار مفعلاً.',
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        _usePopupSubmit
                            ? 'الوضع الحالي: نقر input[type="button"] ثم إظهار #popup ونقر زر Submit بداخله.'
                            : 'الوضع الحالي: نقر زر Submit المباشر أسفل حقل Username مباشرة بدون Popup.',
                        style: const TextStyle(
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
                      decoration: InputDecoration(
                        labelText: 'رابط بوابة الدخول (URL) * (إلزامي)',
                        hintText: 'http://a.com أو http://10.0.0.1',
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                          tooltip: 'شرح الحقل وتأثيره',
                          onPressed: () => _showFieldHelpDialog(
                            context: context,
                            title: 'رابط بوابة الدخول (URL)',
                            description: 'عنوان الويب أو الآي بي (IP) الخاص بصفحة تسجيل الدخول لبوابة شبكة المايكروتك (Captive Portal).',
                            impact: 'يوجه محرك الفحص إلى صفحة الشبكة للتحقق من الاتصال وإرسال بيانات الكروت.',
                            example: 'http://a.com أو http://10.0.0.1 أو http://192.168.88.1',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _responsivePair(
                      context,
                      TextFormField(
                        controller: _loginPathCtrl,
                        decoration: InputDecoration(
                          labelText: 'مسار الدخول (LOGIN_PATH) *',
                          hintText: '/login',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'مسار تسجيل الدخول (LOGIN_PATH)',
                              description: 'المسار الملحق برابط الشبكة الذي يستقبل بيانات تسجيل الدخول وتتم عملية الـ POST إليه.',
                              impact: 'يحدد نقطة النهاية (Endpoint) التي تستقبل اسم المستخدم وكلمة المرور.',
                              example: '/login أو /login.html',
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _logoutPathCtrl,
                        decoration: InputDecoration(
                          labelText: 'مسار الخروج (LOGOUT_PATH)',
                          hintText: '/logout',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'مسار تسجيل الخروج (LOGOUT_PATH)',
                              description: 'المسار المخصص لتسجيل الخروج الفوري بعد اصطياد الكرت بنجاح.',
                              impact: 'تحرير الكرت فوراً وضمان عدم حجز الجلسة أو استهلاك رصيد الكرت على هاتفك.',
                              example: '/logout',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _startNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'رقم كارت البداية (START_NUMBER) * (إلزامي)',
                        hintText: 'أدخل رقم كارت البداية (إلزامي لبدء الفحص)',
                        prefixIcon: const Icon(Icons.pin),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                          tooltip: 'شرح الحقل وتأثيره',
                          onPressed: () => _showFieldHelpDialog(
                            context: context,
                            title: 'رقم كارت البداية (START_NUMBER)',
                            description: 'الرقم الذي يبدأ منه المحرك عملية التخمين والفحص التتابعي والتصاعدي.',
                            impact: 'إلزامي؛ ينطلق منه العداد بزيادة رقمية (+1) مع الحفاظ على الأصفار البادئة.',
                            example: '201150001',
                          ),
                        ),
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
                        decoration: InputDecoration(
                          labelText: 'الانتظار بين المحاولات (ثوانٍ) *',
                          hintText: '10.0',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'الانتظار بين المحاولات (DELAY_BETWEEN)',
                              description: 'المدة الزمنية بالثواني التي ينتظرها التطبيق بين كل محاولة فحص وأخرى.',
                              impact: 'حماية جوهرية لمنع جدار حماية راوتر المايكروتك من حظر الهاتف بسبب المحاولات المتتالية السريعة.',
                              example: 'القيمة الافتراضية الموصى بها هي 10.0 ثوانٍ (أو 15.0 في الشبكات الصارمة).',
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _maxAttemptsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'الحد الأقصى للمحاولات (0 = مستمر)',
                          hintText: '0',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'الحد الأقصى للمحاولات (MAX_ATTEMPTS)',
                              description: 'العدد الإجمالي للمحاولات قبل أن يتوقف الفحص تلقائياً.',
                              impact: 'عند تعيينه على 0 يعمل المحرك دون توقف حتى تضغط زر الإنهاء يدوياً.',
                              example: '0 (للفحص المستمر) أو 200 لإجراء 200 محاولة ثم التوقف.',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _responsivePair(
                      context,
                      TextFormField(
                        controller: _navTimeoutCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'مهلة الطلب (ms)',
                          hintText: '30000',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'مهلة انتظار الطلب (NAV_TIMEOUT)',
                              description: 'أقصى وقت بالمللي ثانية لانتظار رد السيرفر أو تحميل الصفحة قبل اعتبار المحاولة متعثرة.',
                              impact: 'يمنع التطبيق من التجمد في حالة بطء أو ثقل سيرفر الشبكة.',
                              example: '30000 (أي 30 ثانية).',
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _postWaitCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'انتظار التحقق (ثوانٍ)',
                          hintText: '7.0',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'انتظار التحقق بعد الإرسال (POST_NAV_WAIT)',
                              description: 'مهلة زمنية بالثواني بعد إرسال النموذج لانتظار تحميل صفحة الحالة (Status) أو ظهور رسالة التنبيه.',
                              impact: 'يضمن قراءة الرد النهائي بدقة دون استعجال الحكم على الكرت.',
                              example: '7.0 ثوانٍ (أو 5.0 في الشبكات السريعة).',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'تخطي الكروت التي تم اختبارها مسبقاً',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 19, color: AppColors.accent),
                            tooltip: 'شرح الخاصية',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'تخطي الكروت المختبرة مسبقاً',
                              description: 'يقوم المحرك بالتحقق من قاعدة البيانات وتخطي أي رقم كرت تم اختباره مسبقاً (سواء نجح أو فشل) فوراً في قفزة واحدة.',
                              impact: 'يسرع وتيرة الفحص ويتفادى تضييع الوقت في إعادة فحص أرقام تم التأكد من عدم صلاحيتها.',
                              example: 'مفيد جداً عند استئناف الفحص في مجال أرقام تم فحص معظمه سابقاً.',
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'تخطي أي كرت مسجل في قاعدة البيانات (سواء تم اصطياده بنجاح أو لم ينجح) والقفز للرقم التالي مباشرة لتسريع الفحص.',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _skipAlreadyTested,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _skipAlreadyTested = val);
                        settingsProv.updateSettings(
                          settingsProv.settings.copyWith(
                            skipAlreadyTested: val,
                          ),
                        );
                      },
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
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'فك الحظر التلقائي عند خطأ الاتصال',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 19, color: AppColors.accent),
                            tooltip: 'شرح الخاصية',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'فك الحظر التلقائي عند الخطأ',
                              description: 'محاولة فك الحظر تلقائياً بتغيير عنوان MAC عشوائي جديد أو إعادة تشغيل محول الواي فاي عند انقطاع الرد من الراوتر.',
                              impact: 'يستعيد اتصال الهاتف بالشبكة ويواصل الفحص دون الحاجة لتدخلك يدوياً.',
                              example: 'مُفعل افتراضياً.',
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'يقوم بمحاولة فك الحظر تلقائياً عند انقطاع الاستجابة من الراوتر.',
                        style: TextStyle(fontSize: 11),
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
                        decoration: InputDecoration(
                          labelText: 'أقصى محاولات فك الحظر',
                          hintText: '3',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'أقصى محاولات فك الحظر المتتالية',
                              description: 'العدد الأقصى لمحاولات إعادة ضبط الماك وتجديد الاتصال قبل التوقف وإصدار تنبيه صوتي.',
                              impact: 'يحمي من الدخول في حلقة تكرار لانهائية إذا كانت الشبكة متوقفة بالكامل.',
                              example: '3 محاولات.',
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _unbanCooldownCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'الانتظار بعد فك الحظر (ثوانٍ)',
                          hintText: '5.0',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'فترة التهدئة بعد فك الحظر',
                              description: 'المدة الزمنية بالثواني بعد تغيير الماك أو إعادة تشغيل الواي فاي لانتظار أخذ عنوان IP جديد من DHCP.',
                              impact: 'يمنع بدء الفحص قبل اكتمال الاتصال الفعلي بالراوتر.',
                              example: '5.0 ثوانٍ.',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _maxErrorsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'الحد الأقصى للأخطاء المتتالية',
                        hintText: '10',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                          tooltip: 'شرح الحقل وتأثيره',
                          onPressed: () => _showFieldHelpDialog(
                            context: context,
                            title: 'الحد الأقصى للأخطاء المتتالية',
                            description: 'عدد مرات التعثر أو الأخطاء المتكررة على نفس الكرت التي تستدعي إطلاق التنبيه الصوتي ومحاولة فك الحظر.',
                            impact: 'يمنع الاستسلام عند انقطاع مؤقت ويكرر المحاولة على نفس الكرت حتى استلام نتيجة قطعية.',
                            example: '10 أخطاء.',
                          ),
                        ),
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
                            style: TextStyle(fontSize: 11),
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
                            style: TextStyle(fontSize: 11),
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
                            style: TextStyle(fontSize: 11),
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
                        decoration: InputDecoration(
                          labelText: 'اسم حقل المستخدم * (إلزامي)',
                          hintText: 'username',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'اسم حقل المستخدم (USERNAME_FIELD)',
                              description: 'الخاصية name لحقل إدخال اسم المستخدم في كود صفحة الدخول (HTML input name).',
                              impact: 'ضروري لتمكين المحرك من كتابة رقم الكرت في الموضع الصحيح بالصفحة.',
                              example: 'username في أغلب صفحات المايكروتك.',
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _passwordFieldCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم حقل كلمة المرور (اختياري)',
                          hintText: 'password',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                            tooltip: 'شرح الحقل وتأثيره',
                            onPressed: () => _showFieldHelpDialog(
                              context: context,
                              title: 'اسم حقل كلمة المرور (PASSWORD_FIELD)',
                              description: 'الخاصية name لحقل كلمة المرور في كود صفحة الدخول (HTML input name).',
                              impact: 'يستخدم لتعبئة كلمة المرور إذا كانت الصفحة تتطلب إرسال حقل كلمة مرور منفصل.',
                              example: 'password',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _customPasswordCtrl,
                      decoration: InputDecoration(
                        labelText: 'كلمة مرور مخصصة (اختياري)',
                        hintText: 'اتركها فارغة لاستخدام رقم الكرت تلقائياً',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.help_outline, size: 20, color: AppColors.accent),
                          tooltip: 'شرح الحقل وتأثيره',
                          onPressed: () => _showFieldHelpDialog(
                            context: context,
                            title: 'كلمة المرور المخصصة (CUSTOM_PASSWORD)',
                            description: 'كلمة مرور ثابتة تُرسل مع كل محاولة فحص بدلاً من استخدام رقم الكرت نفسه ككلمة مرور.',
                            impact: 'في معظم شبكات المايكروتك بنظام الكروت، يكون رقم الكرت هو اسم المستخدم وكلمة المرور معاً، لذلك يُترك هذا الحقل فارغاً تلقائياً. أدخل قيمة هنا فقط إذا كانت شبكتك تفرض كلمة مرور موحدة وثابتة لكافة الكروت.',
                            example: 'اتركه فارغاً للاعتماد على رقم الكرت تلقائياً.',
                          ),
                        ),
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
                            skipAlreadyTested: _skipAlreadyTested,
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
                            _skipAlreadyTested = s.skipAlreadyTested;
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
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFieldHelpDialog({
    required BuildContext context,
    required String title,
    required String description,
    required String impact,
    String? example,
    IconData icon = Icons.info_outline,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection(
                title: 'ما هي هذه الخاصية؟',
                content: description,
                color: AppColors.primary,
                icon: Icons.lightbulb_outline,
              ),
              const SizedBox(height: 12),
              _buildHelpSection(
                title: 'التأثير أثناء الفحص',
                content: impact,
                color: AppColors.accent,
                icon: Icons.tune,
              ),
              if (example != null && example.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildHelpSection(
                  title: 'مثال أو القيمة الموصى بها',
                  content: example,
                  color: AppColors.success,
                  icon: Icons.tips_and_updates_outlined,
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'حسناً، فهمت',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection({
    required String title,
    required String content,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
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

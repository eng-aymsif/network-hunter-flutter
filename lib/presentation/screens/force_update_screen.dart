import 'package:flutter/material.dart';
import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/core/services/subscription_service.dart';
import 'package:networking/data/models/subscription_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة الإجبار على التحديث والحماية من الـ Downgrade
/// تمنع استخدام التطبيق تماماً عند تثبيت نسخة ملغاة أو عند طلب السيرفر للتحديث الإلزامي
class ForceUpdateScreen extends StatefulWidget {
  final SubscriptionModel? subscription;
  final String? customErrorMessage;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const ForceUpdateScreen({
    super.key,
    this.subscription,
    this.customErrorMessage,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = widget.subscription;
    final serverVer = sub?.serverAppVersion.isNotEmpty == true
        ? sub!.serverAppVersion
        : '1.1.0';
    final currentVer = SubscriptionService.currentAppVersion;
    final updateTitle = sub?.updateTitle.isNotEmpty == true
        ? sub!.updateTitle
        : 'تحديث أمان وتطوير إلزامي';
    final downloadUrl = sub?.apkDownloadUrl.isNotEmpty == true
        ? sub!.apkDownloadUrl
        : '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'تحديث إلزامي مطلوب',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'تبديل المظهر',
              icon: Icon(
                widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // أيقونة التحديث بنبض جذاب
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.93, end: 1.07).animate(
                        CurvedAnimation(
                          parent: _animCtrl,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.accent,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // عنوان الشاشة
                    Text(
                      updateTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // شارات مقارنة الإصدارات
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'الإصدار المثبت: v$currentVer',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'الإصدار المطلوب: v$serverVer+',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // صندوق شرح التحديث أو رسالة الخطأ
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.security_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ملاحظات الأمان والتحديث',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Text(
                            widget.customErrorMessage ??
                                (sub?.updateNotes.isNotEmpty == true
                                    ? sub!.updateNotes
                                    : 'تم إيقاف هذا الإصدار لأسباب تقنية وأمنية. يجب التحديث للإصدار الجديد لمتابعة اصطياد الكروت والاستفادة من التحسينات وميزات فك الحظر.'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Cairo',
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // زر تنزيل التحديث
                    if (downloadUrl.isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 22),
                          label: const Text(
                            'تنزيل وتثبيت أحدث إصدار الآن',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _launchUrl(downloadUrl),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // زر التواصل مع المطور عبر واتساب
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                        label: const Text(
                          'طلب التحديث عبر واتساب المطور',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          final msg = Uri.encodeComponent(
                            'مرحباً مهندس أيمن، أحتاج تحديث تطبيق Network Hunter إلى الإصدار v$serverVer لجهازي معرف: ${SubscriptionService.instance.deviceId}',
                          );
                          _launchUrl('https://wa.me/967777609160?text=$msg');
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // زر الاتصال المباشر بالمطور
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 20),
                        label: const Text(
                          'اتصال هاتفي بالمطور: 00967777609160',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _launchUrl('tel:${AppStrings.devPhone}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/core/services/subscription_service.dart';
import 'package:networking/presentation/screens/force_update_screen.dart';
import 'package:networking/presentation/screens/home_screen.dart';
import 'package:networking/presentation/screens/subscription_pending_screen.dart';
import 'package:networking/presentation/screens/subscription_stopped_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const SplashScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late Animation<double> _pulseAnimation;

  String _statusMessage = 'جارِ فحص الاتصال بالإنترنت...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // بدء عملية التحقق بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVerificationProcess();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _startVerificationProcess() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _statusMessage = 'جارِ التحقق من الاتصال بالإنترنت...';
    });

    // 1. فحص الاتصال بالإنترنت
    final hasInternet = await SubscriptionService.instance.checkInternetConnection();
    if (!mounted) return;

    if (!hasInternet) {
      // محاولة التحقق إذا كان هناك اشتراك متاح محفوظ محلياً
      final localSub = SubscriptionService.instance.currentSubscription;
      if (localSub != null && localSub.isAvailable) {
        // التحقق من سلامة إصدار التطبيق ومكافحة تثبيت إصدار قديم
        final versionCheck = SubscriptionService.instance.verifyVersionIntegrity(localSub);
        if (!versionCheck.isAllowed) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ForceUpdateScreen(
                subscription: localSub,
                customErrorMessage: versionCheck.message,
                onToggleTheme: widget.onToggleTheme,
                isDark: widget.isDark,
              ),
            ),
          );
          return;
        }

        // التحقق من سلامة التوقيت
        final timeCheck = SubscriptionService.instance.verifyTimeIntegrity();
        if (timeCheck.isValid) {
          _proceedToHome();
          return;
        }
      }

      setState(() {
        _hasError = true;
        _errorMessage =
            'تعذر الاتصال بالإنترنت أو بسيرفر التطبيق (https://main.terhabb.com).\nيرجى التأكد من تشغيل الواي فاي أو بيانات الهاتف والمحاولة مجدداً.';
      });
      return;
    }

    // 2. التحقق من سلامة توقيت الجهاز من التلاعب
    setState(() {
      _statusMessage = 'جارِ فحص توقيت النظام والأمان...';
    });
    final timeCheck = SubscriptionService.instance.verifyTimeIntegrity();
    if (!timeCheck.isValid) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = timeCheck.errorMessage ?? 'خطأ في توقيت النظام';
      });
      return;
    }

    // 3. التحقق من حالة الاشتراك في السيرفر
    setState(() {
      _statusMessage = 'جارِ فحص حالة الاشتراك بالسيرفر...';
    });

    try {
      final sub = await SubscriptionService.instance.checkSubscription(forceRefresh: true);
      if (!mounted) return;

      // 4. التحقق الصارم من إصدار التطبيق (Anti-Downgrade & Server Min Version)
      final versionCheck = SubscriptionService.instance.verifyVersionIntegrity(sub);
      if (!versionCheck.isAllowed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ForceUpdateScreen(
              subscription: sub,
              customErrorMessage: versionCheck.message,
              onToggleTheme: widget.onToggleTheme,
              isDark: widget.isDark,
            ),
          ),
        );
        return;
      }

      if (sub.isNotFound) {
        // لا يوجد اشتراك مسجل لهذا الجهاز -> فتح نافذة طلب الاشتراك
        _showSubscriptionRequestDialog();
      } else if (sub.isPending) {
        // الطلب قيد الانتظار
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SubscriptionPendingScreen(
              subscription: sub,
              onToggleTheme: widget.onToggleTheme,
              isDark: widget.isDark,
            ),
          ),
        );
      } else if (sub.isStopped) {
        // الحساب متوقف
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SubscriptionStoppedScreen(
              subscription: sub,
              onToggleTheme: widget.onToggleTheme,
              isDark: widget.isDark,
            ),
          ),
        );
      } else if (sub.isAvailable) {
        // الحساب متاح -> الدخول للتطبيق الرئيسي
        _proceedToHome();
      } else {
        _showSubscriptionRequestDialog();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'حدث خطأ أثناء فحص الاشتراك: $e';
      });
    }
  }

  void _proceedToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          onToggleTheme: widget.onToggleTheme,
          isDark: widget.isDark,
        ),
      ),
    );
  }

  /// نافذة طلب الاشتراك الاحترافية والمتجاوبة
  Future<void> _showSubscriptionRequestDialog() async {
    final devId = await SubscriptionService.instance.getDeviceId();
    if (!mounted) return;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.app_registration_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'طلب تفعيل الاشتراك',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'أهلاً بك! لاستخدام أداة اصطياد الكروت، يرجى تقديم طلب اشتراك لإدارة النظام لمرة واحدة فقط.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Device ID (Read-only)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'معرف هذا الجهاز (Device ID):',
                                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      devId,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                    tooltip: 'نسخ معرف الجهاز',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: devId));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم نسخ معرف الجهاز بنجاح')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Full Name Field
                        TextFormField(
                          controller: nameController,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            labelText: 'الاسم الكامل *',
                            hintText: 'مثال: محمد علي أحمد',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى كتابة الاسم الكامل';
                            }
                            if (val.trim().length < 3) {
                              return 'الاسم قصير جداً';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone Number Field
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف *',
                            hintText: '777XXXXXX',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى كتابة رقم الهاتف';
                            }
                            if (val.trim().length < 6) {
                              return 'رقم الهاتف غير صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Warning Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade600.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'تنبيه: لا يُسمح بعمل أكثر من طلب اشتراك لنفس الجهاز.',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  // تأكيد نهائي قبل الإرسال
                                  final confirm = await showDialog<bool>(
                                    context: ctx,
                                    builder: (confirmCtx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('تأكيد بيانات الاشتراك'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'هل أنت متأكد من صحة البيانات التالية؟\n(لا يُسمح بعمل أكثر من طلب اشتراك):',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 12),
                                          Text('• الاسم: ${nameController.text.trim()}'),
                                          const SizedBox(height: 4),
                                          Text('• الهاتف: ${phoneController.text.trim()}'),
                                          const SizedBox(height: 4),
                                          Text(
                                            '• المعرف: ${devId.length > 20 ? '${devId.substring(0, 20)}...' : devId}',
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(confirmCtx).pop(false),
                                          child: const Text('مراجعة'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(confirmCtx).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('تأكيد وإرسال'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm != true) return;

                                  setDialogState(() => isSubmitting = true);

                                  final result = await SubscriptionService.instance.requestSubscription(
                                    fullName: nameController.text,
                                    phoneNumber: phoneController.text,
                                  );

                                  setDialogState(() => isSubmitting = false);

                                  if (result['success'] == true) {
                                    if (dialogCtx.mounted) {
                                      Navigator.of(dialogCtx).pop();
                                    }
                                    final currentSub = SubscriptionService.instance.currentSubscription;
                                    if (currentSub != null && mounted) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => SubscriptionPendingScreen(
                                            subscription: currentSub,
                                            onToggleTheme: widget.onToggleTheme,
                                            isDark: widget.isDark,
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.danger,
                                          content: Text(result['message'] ?? 'فشل تقديم الطلب'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'تأكيد وإرسال طلب الاشتراك',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0D1B2A), const Color(0xFF1B263B)]
                : [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Radar Icon with Pulsing Waves
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple ring
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // Middle ripple ring
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  // Core Brand Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      size: 46,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // App Title & Subtitle
              Text(
                AppStrings.appTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.appSubtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Status / Loading / Error Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _hasError
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _startVerificationProcess,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('إعادة المحاولة الآن'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 36),

              // Developer attribution footer
              Text(
                AppStrings.devName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

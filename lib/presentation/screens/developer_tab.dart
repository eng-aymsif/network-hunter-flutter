import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';

class DeveloperTab extends StatefulWidget {
  const DeveloperTab({super.key});

  @override
  State<DeveloperTab> createState() => _DeveloperTabState();
}

class _DeveloperTabState extends State<DeveloperTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _card1Fade;
  late Animation<double> _card2Fade;
  late Animation<double> _card3Fade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _card1Fade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _card2Fade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );
    _card3Fade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(AppStrings.devWhatsappUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر فتح تطبيق واتساب تلقائياً، تم نسخ الرقم إلى الحافظة.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      Clipboard.setData(const ClipboardData(text: AppStrings.devPhone));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. بطاقة الهيدر المتحركة (Hero & Fade/Slide Animation)
              FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF06142E),
                          Color(0xFF0A224E),
                          Color(0xFF1565C0),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Hero(
                          tag: 'developer_avatar_hero',
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF00C853)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF06142E),
                              ),
                              child: const Icon(
                                Icons.radar_rounded,
                                size: 48,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          AppStrings.devName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'مهندس برمجيات ونظم شبكات متقدمة | Full-Stack & Flutter Architect',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              color: Color(0xFF80D8FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // زر التواصل المباشر عبر واتساب
                        ElevatedButton.icon(
                          onPressed: () => _openWhatsApp(context),
                          icon: const Icon(Icons.chat_rounded, size: 22),
                          label: const Text(
                            'التواصل مع المطور عبر واتساب',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. بطاقة بيانات التواصل المباشر
              FadeTransition(
                opacity: _card1Fade,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.contact_phone_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'قنوات التواصل الرسمية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF25D366).withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.phone_android_rounded,
                              color: Color(0xFF25D366),
                            ),
                          ),
                          title: const Text(
                            'رقم الهاتف والواتساب المباشر',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            AppStrings.devPhone,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              letterSpacing: 1.1,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'نسخ الرقم',
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                onPressed: () {
                                  Clipboard.setData(
                                    const ClipboardData(
                                      text: AppStrings.devPhone,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'تم نسخ رقم المطور إلى الحافظة 📋',
                                        style: TextStyle(fontFamily: 'Cairo'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'مراسلة واتساب',
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  color: Color(0xFF25D366),
                                  size: 20,
                                ),
                                onPressed: () => _openWhatsApp(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. بطاقة تفاصيل ومميزات التطبيق الهندسية
              FadeTransition(
                opacity: _card2Fade,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'حول التطبيق والمعمارية الهندسية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildFeatureRow(
                          Icons.memory_rounded,
                          'آلة حالات متسلسلة صارمة (Deterministic State Machine)',
                          'تنفيذ العمليات بتسلسل منطقي محكم يمنع التداخل ويضمن التحقق من الشبكة وشجرة DOM الحية.',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureRow(
                          Icons.javascript_rounded,
                          'ديناميكية كاملة مع بوابات الدخول (Captive Portals)',
                          'دعم حقن دوال saleem() و saveUsername() والتبديل المرن بين نافذة Popup أو زر Submit المباشر.',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureRow(
                          Icons.notifications_active_rounded,
                          'خدمة خلفية مستمرة وإشعارات حية (Foreground Service)',
                          'استمرار الفحص في الخلفية مع معاينة حية وتنبيهات صوتية مخصصة عالية الوضوح.',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureRow(
                          Icons.wifi_protected_setup_rounded,
                          'مراقبة تغير الشبكة الذكية (BroadcastReceiver)',
                          'رصد فوري لتغير الـ SSID أثناء الفحص أو فك الحظر مع تنبيه المستخدم وحفظ الحالة.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. تذييل الإصدار وحقوق الملكية
              FadeTransition(
                opacity: _card3Fade,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Network Voucher Hunter & Auto-Unban • v2.0.0 Pro',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'جميع الحقوق محفوظة © المهندس أيمن محمد سيف المقطري',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

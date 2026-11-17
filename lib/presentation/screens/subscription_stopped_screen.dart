import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/core/services/subscription_service.dart';
import 'package:networking/data/models/subscription_model.dart';
import 'package:networking/presentation/screens/home_screen.dart';

class SubscriptionStoppedScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const SubscriptionStoppedScreen({
    super.key,
    required this.subscription,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<SubscriptionStoppedScreen> createState() => _SubscriptionStoppedScreenState();
}

class _SubscriptionStoppedScreenState extends State<SubscriptionStoppedScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final updated = await SubscriptionService.instance.checkSubscription(forceRefresh: true);
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (updated.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🎉 تم تفعيل حسابك بنجاح! مرحباً بك.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            onToggleTheme: widget.onToggleTheme,
            isDark: widget.isDark,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('ما زال الحساب متوقفاً. يرجى التواصل مع المطور لتفعيله.'),
        ),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final message = Uri.encodeComponent(
      'السلام عليكم مهندس أيمن، حسابي في تطبيق صياد الشبكات متوقف.\n'
      'رقم الطلب: ${widget.subscription.requestId}\n'
      'الاسم: ${widget.subscription.fullName}\n'
      'معرف الجهاز: ${widget.subscription.deviceId}\n'
      'يرجى إعادة تفعيل الحساب، شكراً لك.',
    );
    final url = Uri.parse('${AppStrings.devWhatsappUrl}?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall() async {
    final url = Uri.parse('tel:${AppStrings.devPhone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الحساب متوقف'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.danger, width: 2),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  size: 48,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'حسابك متوقف حالياً',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'تم إيقاف تفعيل هذا الجهاز مؤقتاً من قبل إدارة النظام.\nيرجى التواصل مع المطور لإعادة التفعيل.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Developer Info Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.white12 : Colors.blueGrey.shade100,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 22,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.devName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.devPhone,
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openWhatsApp,
                              icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                              label: const Text('واتساب المطور'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _makeCall,
                              icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                              label: const Text('اتصال مباشر'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Check Status Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isChecking ? null : _checkStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_isChecking ? 'جارِ فحص السيرفر...' : 'إعادة التحقق من الحالة'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

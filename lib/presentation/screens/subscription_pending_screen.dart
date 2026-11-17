import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/core/services/subscription_service.dart';
import 'package:networking/data/models/subscription_model.dart';
import 'package:networking/presentation/screens/home_screen.dart';

class SubscriptionPendingScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const SubscriptionPendingScreen({
    super.key,
    required this.subscription,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<SubscriptionPendingScreen> createState() => _SubscriptionPendingScreenState();
}

class _SubscriptionPendingScreenState extends State<SubscriptionPendingScreen>
    with SingleTickerProviderStateMixin {
  late SubscriptionModel _sub;
  bool _isChecking = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _sub = widget.subscription;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final updated = await SubscriptionService.instance.checkSubscription(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _sub = updated;
      _isChecking = false;
    });

    if (updated.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🎉 تم اعتماد وتفعيل اشتراكك بنجاح! مرحباً بك.'),
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
    } else if (updated.isStopped) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('تم إيقاف حسابك من قبل الإدارة.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('الطلب ما زال قيد الانتظار والمراجعة من قبل الإدارة.'),
        ),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final message = Uri.encodeComponent(
      'السلام عليكم مهندس أيمن، قمت بتقديم طلب اشتراك في تطبيق صياد الشبكات.\n'
      'رقم الطلب: ${_sub.requestId}\n'
      'الاسم: ${_sub.fullName}\n'
      'معرف الجهاز: ${_sub.deviceId}\n'
      'يرجى مراجعة واعتماد الطلب، شكراً لك.',
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
        title: const Text('حالة طلب الاشتراك'),
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
              const SizedBox(height: 16),
              // Animated Hourglass Icon
              ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade600, width: 2),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'طلبك قيد الانتظار والمراجعة',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'تم استلام طلبك بنجاح وهو الآن بانتظار اعتماد الإدارة لتفعيل الحساب.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Request Details Card
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
                      // Request ID highlight
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'رقم الطلب:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Text(
                                  _sub.requestId.isNotEmpty ? _sub.requestId : '---',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _sub.requestId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم نسخ رقم الطلب')),
                                    );
                                  },
                                  child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('الاسم الكامل', _sub.fullName),
                      const SizedBox(height: 10),
                      _buildInfoRow('رقم الهاتف', _sub.phoneNumber),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        'معرف الجهاز',
                        _sub.deviceId.length > 20
                            ? '${_sub.deviceId.substring(0, 20)}...'
                            : _sub.deviceId,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الحالة:', style: TextStyle(color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'قيد الانتظار ⏳',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Action Button: Check Status
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    _isChecking ? 'جارِ فحص السيرفر...' : 'تحديث حالة الطلب الآن',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Contact Dev Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openWhatsApp,
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                      label: const Text('واتساب المطور'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _makeCall,
                      icon: const Icon(Icons.phone_outlined, color: Colors.blue),
                      label: const Text('اتصال هاتفي'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

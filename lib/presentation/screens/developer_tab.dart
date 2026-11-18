import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  /// 0: QR الشامل لكل البيانات | 1: تيليجرام (@AYMSIF) | 2: فيسبوك | 3: واتساب
  int _selectedQrIndex = 0;

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

  Future<void> _openExternalUrl(
    BuildContext context,
    String urlString, {
    required String fallbackCopyText,
    required String platformName,
  }) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (!context.mounted) return;
      Clipboard.setData(ClipboardData(text: fallbackCopyText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر فتح $platformName تلقائياً، تم نسخ ($fallbackCopyText) إلى الحافظة 📋',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }
  }

  void _copyText(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ $label إلى الحافظة 📋',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showQrZoomDialog(BuildContext context, {required int qrIndex}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getQrTitle(qrIndex),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 18),
              const SizedBox(height: 6),
              _buildQrVisualWidget(qrIndex, size: 250),
              const SizedBox(height: 14),
              Text(
                _getQrSubtitle(qrIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'إغلاق المعاينة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getQrTitle(int index) {
    switch (index) {
      case 1:
        return 'رمز QR تيليجرام الرسمي (@AYMSIF)';
      case 2:
        return 'رمز QR حساب فيسبوك الرسمي';
      case 3:
        return 'رمز QR المحادثة المباشرة عبر واتساب';
      case 0:
      default:
        return 'رمز QR الشامل لبيانات المطور (All-in-One)';
    }
  }

  String _getQrSubtitle(int index) {
    switch (index) {
      case 1:
        return 'امسح الرمز عبر كاميرا الهاتف أو تطبيق تيليجرام للوصول المباشر إلى @Aymsif';
      case 2:
        return 'امسح الرمز لفتح صفحة المطور على فيسبوك: facebook.com/aymansifq';
      case 3:
        return 'امسح الرمز لبدء محادثة واتساب مباشرة مع المهندس أيمن المقطري';
      case 0:
      default:
        return 'يحتوي على البطاقة الرقمية الكاملة: الاسم، الهاتف، واتساب، تيليجرام (@Aymsif)، وفيسبوك';
    }
  }

  Widget _buildQrVisualWidget(int index, {double size = 215}) {
    if (index == 1) {
      // عرض صورة الـ QR الرسمية الخاصة بتيليجرام @AYMSIF المرفقة من المستخدم
      return Container(
        width: size + 24,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0088CC).withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/telegram_qr.jpg',
            width: size,
            height: size + 25,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildGeneratedQrCard(
              data: AppStrings.devTelegramUrl,
              badgeText: '@AYMSIF',
              accentColor: const Color(0xFF0088CC),
              icon: Icons.send_rounded,
              size: size,
            ),
          ),
        ),
      );
    }

    switch (index) {
      case 2:
        return _buildGeneratedQrCard(
          data: AppStrings.devFacebookUrl,
          badgeText: 'facebook.com/aymansifq',
          accentColor: const Color(0xFF1877F2),
          icon: Icons.facebook_rounded,
          size: size,
        );
      case 3:
        return _buildGeneratedQrCard(
          data: AppStrings.devWhatsappUrl,
          badgeText: AppStrings.devPhone,
          accentColor: const Color(0xFF25D366),
          icon: Icons.chat_rounded,
          size: size,
        );
      case 0:
      default:
        return _buildGeneratedQrCard(
          data: AppStrings.devQrData,
          badgeText: 'ENG. AYMAN SAIF • @AYMSIF',
          accentColor: const Color(0xFF0A224E),
          icon: Icons.verified_user_rounded,
          size: size,
        );
    }
  }

  Widget _buildGeneratedQrCard({
    required String data,
    required String badgeText,
    required Color accentColor,
    required IconData icon,
    required double size,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              QrImageView(
                data: data,
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: accentColor,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isWideDesktop = outerConstraints.maxWidth >= 880;
        final socialCard = FadeTransition(
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
                              Icons.share_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'روابط التواصل الاجتماعي والقنوات الرسمية',
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

                        // 1) الهاتف والواتساب
                        _buildSocialTile(
                          context: context,
                          icon: Icons.phone_android_rounded,
                          color: const Color(0xFF25D366),
                          title: 'رقم الهاتف والواتساب المباشر',
                          subtitle: AppStrings.devPhone,
                          onCopy: () => _copyText(
                            context,
                            AppStrings.devPhone,
                            'رقم الهاتف',
                          ),
                          onOpen: () => _openExternalUrl(
                            context,
                            AppStrings.devWhatsappUrl,
                            fallbackCopyText: AppStrings.devPhone,
                            platformName: 'واتساب',
                          ),
                          onShowQr: () {
                            setState(() => _selectedQrIndex = 3);
                            _showQrZoomDialog(context, qrIndex: 3);
                          },
                        ),
                        const Divider(height: 12),

                        // 2) تيليجرام
                        _buildSocialTile(
                          context: context,
                          icon: Icons.send_rounded,
                          color: const Color(0xFF0088CC),
                          title: 'حساب التيليجرام الرسمي (Telegram)',
                          subtitle: '${AppStrings.devTelegramHandle}  •  t.me/Aymsif',
                          onCopy: () => _copyText(
                            context,
                            AppStrings.devTelegramHandle,
                            'معرف تيليجرام @Aymsif',
                          ),
                          onOpen: () => _openExternalUrl(
                            context,
                            AppStrings.devTelegramUrl,
                            fallbackCopyText: AppStrings.devTelegramHandle,
                            platformName: 'تيليجرام',
                          ),
                          onShowQr: () {
                            setState(() => _selectedQrIndex = 1);
                            _showQrZoomDialog(context, qrIndex: 1);
                          },
                        ),
                        const Divider(height: 12),

                        // 3) فيسبوك
                        _buildSocialTile(
                          context: context,
                          icon: Icons.facebook_rounded,
                          color: const Color(0xFF1877F2),
                          title: 'صفحة الفيسبوك الرسمية (Facebook)',
                          subtitle: AppStrings.devFacebookUrl,
                          onCopy: () => _copyText(
                            context,
                            AppStrings.devFacebookUrl,
                            'رابط فيسبوك',
                          ),
                          onOpen: () => _openExternalUrl(
                            context,
                            AppStrings.devFacebookUrl,
                            fallbackCopyText: AppStrings.devFacebookUrl,
                            platformName: 'فيسبوك',
                          ),
                          onShowQr: () {
                            setState(() => _selectedQrIndex = 2);
                            _showQrZoomDialog(context, qrIndex: 2);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );

        final qrHubCard = FadeTransition(
                opacity: _card2Fade,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.primary,
                              size: 21,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'بطاقة المسح السريع الذكية (QR Code)',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showQrZoomDialog(
                                context,
                                qrIndex: _selectedQrIndex,
                              ),
                              icon: const Icon(Icons.zoom_in_rounded, size: 18),
                              label: const Text(
                                'تكبير',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),

                        // أزرار اختيار نوع الـ QR
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildQrChoiceChip(
                                index: 0,
                                label: 'البطاقة الشاملة (كل البيانات)',
                                icon: Icons.badge_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              _buildQrChoiceChip(
                                index: 1,
                                label: 'تيليجرام @AYMSIF',
                                icon: Icons.send_rounded,
                                color: const Color(0xFF0088CC),
                              ),
                              const SizedBox(width: 6),
                              _buildQrChoiceChip(
                                index: 2,
                                label: 'فيسبوك',
                                icon: Icons.facebook_rounded,
                                color: const Color(0xFF1877F2),
                              ),
                              const SizedBox(width: 6),
                              _buildQrChoiceChip(
                                index: 3,
                                label: 'واتساب',
                                icon: Icons.chat_rounded,
                                color: const Color(0xFF25D366),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // عرض الـ QR المختار مع إمكانية النقر للتكبير
                        GestureDetector(
                          onTap: () => _showQrZoomDialog(
                            context,
                            qrIndex: _selectedQrIndex,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: KeyedSubtree(
                              key: ValueKey<int>(_selectedQrIndex),
                              child: _buildQrVisualWidget(
                                _selectedQrIndex,
                                size: 205,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          _getQrSubtitle(_selectedQrIndex),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ملخص البيانات المضمنة داخل الـ QR الشامل
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'البيانات المضمنة في البطاقة الرقمية:',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _copyText(
                                      context,
                                      'المهندس أيمن محمد سيف المقطري\n'
                                      'هاتف/واتساب: ${AppStrings.devPhone}\n'
                                      'تيليجرام: ${AppStrings.devTelegramHandle} (${AppStrings.devTelegramUrl})\n'
                                      'فيسبوك: ${AppStrings.devFacebookUrl}',
                                      'كافة بيانات التواصل',
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.copy_all_rounded,
                                            size: 15,
                                            color: AppColors.accent,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'نسخ الكل',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '• الاسم: المهندس أيمن محمد سيف المقطري\n'
                                '• الهاتف والواتساب: 00967777609160\n'
                                '• تيليجرام: @Aymsif (https://t.me/Aymsif)\n'
                                '• فيسبوك: https://www.facebook.com/aymansifq/',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. بطاقة الهيدر المتحركة للمطور
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
                                    colors: [
                                      Color(0xFF00E5FF),
                                      Color(0xFF00C853),
                                    ],
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

                            // أزرار الوصول السريع لحسابات التواصل الاجتماعي
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _openExternalUrl(
                                    context,
                                    AppStrings.devWhatsappUrl,
                                    fallbackCopyText: AppStrings.devPhone,
                                    platformName: 'واتساب',
                                  ),
                                  icon: const Icon(Icons.chat_rounded, size: 19),
                                  label: const Text(
                                    'واتساب',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _openExternalUrl(
                                    context,
                                    AppStrings.devTelegramUrl,
                                    fallbackCopyText:
                                        AppStrings.devTelegramHandle,
                                    platformName: 'تيليجرام',
                                  ),
                                  icon: const Icon(Icons.send_rounded, size: 18),
                                  label: const Text(
                                    'تيليجرام @Aymsif',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0088CC),
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _openExternalUrl(
                                    context,
                                    AppStrings.devFacebookUrl,
                                    fallbackCopyText: AppStrings.devFacebookUrl,
                                    platformName: 'فيسبوك',
                                  ),
                                  icon: const Icon(
                                    Icons.facebook_rounded,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'فيسبوك',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1877F2),
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isWideDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: socialCard),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: qrHubCard),
                      ],
                    )
                  else ...[
                    socialCard,
                    const SizedBox(height: 14),
                    qrHubCard,
                  ],
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
                            'Network Voucher Hunter & Auto-Unban • v1.1.0 Pro',
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
      },
    );
  }

  Widget _buildSocialTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onCopy,
    required VoidCallback onOpen,
    required VoidCallback onShowQr,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'عرض رمز QR',
            icon: Icon(Icons.qr_code_rounded, size: 20, color: color),
            onPressed: onShowQr,
          ),
          IconButton(
            tooltip: 'نسخ',
            icon: const Icon(Icons.copy_rounded, size: 19),
            onPressed: onCopy,
          ),
          IconButton(
            tooltip: 'فتح الرابط المباشر',
            icon: Icon(Icons.open_in_new_rounded, color: color, size: 20),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }

  Widget _buildQrChoiceChip({
    required int index,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedQrIndex == index;
    return ChoiceChip(
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.18),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? color : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? color : null,
        ),
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
      ),
      onSelected: (_) {
        setState(() => _selectedQrIndex = index);
      },
    );
  }
}

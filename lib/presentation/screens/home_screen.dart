import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/native_bridge.dart';
import '../providers/cards_provider.dart';
import '../providers/engine_provider.dart';
import '../providers/logs_provider.dart';
import '../providers/settings_provider.dart';
import 'cards_tab.dart';
import 'dashboard_tab.dart';
import 'logs_tab.dart';
import 'settings_tab.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    CardsTab(),
    SettingsTab(),
    LogsTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final engine = context.read<EngineProvider>();
      final logs = context.read<LogsProvider>();
      final cards = context.read<CardsProvider>();
      final settings = context.read<SettingsProvider>();

      engine.initDependencies(logs: logs, cards: cards, settings: settings);
      logs.addLog('تم بدء تشغيل تطبيق Network Hunter بنجاح.');
      logs.addLog('صلاحيات الروت: ${engine.isRootAvailable ? "مفعلة ✓" : "غير مفعلة (يعمل بالوضع التلقائي)"}');

      // التحقق من الأذونات وإظهار الديالوج إذا لم تكن ممنوحة
      final hasPerms = await NativeBridge.checkPermissions();
      if (!hasPerms && mounted) {
        _showPermissionsDialog(context);
      }
    });
  }

  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.security, size: 48, color: AppColors.primary),
        title: const Text(
          'أذونات الشبكة وفك الحظر',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لكي يعمل فحص الشبكة وفك الحظر التلقائي بكفاءة تامة، يحتاج التطبيق إلى الأذونات التالية:',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.wifi, size: 18, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text('التحكم بالواي فاي (لتجديد الماك أدرس العشوائي)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text('الموقع الجغرافي (شرط أساسي في أندرويد لقراءة تفاصيل الشبكة)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.notifications_active, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text('الإشعارات الدائمة (لاستمرار الفحص في الخلفية)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await NativeBridge.requestAppPermissions();
            },
            child: const Text('منح الأذونات الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsapp() async {
    final uri = Uri.parse(AppStrings.devWhatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<EngineProvider>();
    final cards = context.watch<CardsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.appTitle,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${AppStrings.devName} | ${AppStrings.devPhone}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // زر فتح إعدادات الواي فاي
          IconButton(
            tooltip: 'لوحة الواي فاي السريعة',
            icon: const Icon(Icons.wifi_find),
            onPressed: () => NativeBridge.openWifiSettings(),
          ),

          // شارة الروت
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: engine.isRootAvailable ? AppColors.successLight : Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  engine.isRootAvailable ? Icons.check_circle : Icons.info_outline,
                  size: 13,
                  color: engine.isRootAvailable ? AppColors.success : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  engine.isRootAvailable ? 'Root ✓' : 'Non-Root',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: engine.isRootAvailable ? AppColors.success : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // زر واتساب المطور
          IconButton(
            tooltip: 'تواصل مع المطور عبر واتساب',
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            onPressed: _launchWhatsapp,
          ),

          // زر تبديل الثيم
          IconButton(
            tooltip: 'تبديل الثيم',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: AppStrings.tabDashboard,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cards.totalCount > 0,
              label: Text('${cards.totalCount}'),
              child: const Icon(Icons.confirmation_number_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cards.totalCount > 0,
              label: Text('${cards.totalCount}'),
              child: const Icon(Icons.confirmation_number, color: AppColors.primary),
            ),
            label: AppStrings.tabCards,
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: AppStrings.tabSettings,
          ),
          const NavigationDestination(
            icon: Icon(Icons.terminal_outlined),
            selectedIcon: Icon(Icons.terminal, color: AppColors.primary),
            label: AppStrings.tabLogs,
          ),
        ],
      ),
    );
  }
}

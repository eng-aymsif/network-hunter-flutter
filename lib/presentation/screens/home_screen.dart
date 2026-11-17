import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/core/utils/native_bridge.dart';
import 'package:networking/presentation/providers/cards_provider.dart';
import 'package:networking/presentation/providers/engine_provider.dart';
import 'package:networking/presentation/providers/logs_provider.dart';
import 'package:networking/presentation/providers/settings_provider.dart';
import 'package:networking/presentation/screens/cards_tab.dart';
import 'package:networking/presentation/screens/dashboard_tab.dart';
import 'package:networking/presentation/screens/developer_tab.dart';
import 'package:networking/presentation/screens/logs_tab.dart';
import 'package:networking/presentation/screens/settings_tab.dart';
import 'package:networking/presentation/widgets/modern_bottom_nav_bar.dart';

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
  final PageController _pageController = PageController();
  bool _isShowingNetworkChangeDialog = false;

  final List<Widget> _tabs = const [
    DashboardTab(),
    CardsTab(),
    SettingsTab(),
    LogsTab(),
    DeveloperTab(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
      logs.addLog(
        'صلاحيات الروت: ${engine.isRootAvailable ? "مفعلة ✓" : "غير مفعلة (يعمل بالوضع التلقائي)"}',
      );

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
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                  child: Text(
                    'التحكم بالواي فاي (لتجديد الماك أدرس العشوائي)',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الموقع الجغرافي (شرط أساسي في أندرويد لقراءة تفاصيل الشبكة)',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الإشعارات الدائمة (لعرض المعاينة الحية وتنبيهات الكروت بصوت عالٍ)',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.battery_charging_full,
                  size: 18,
                  color: AppColors.success,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'استثناء تحسين البطارية (Unrestricted Battery) ليعمل في الخلفية بلا توقف',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
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
              Future.delayed(const Duration(milliseconds: 1000), () async {
                final isIgnoring = await NativeBridge.isIgnoringBatteryOptimizations();
                if (!isIgnoring && mounted) {
                  _showBatteryOptimizationDialog();
                }
              });
            },
            child: const Text(
              'منح الأذونات الآن',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBatteryOptimizationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.battery_charging_full_rounded,
          size: 52,
          color: AppColors.warning,
        ),
        title: const Text(
          'استثناء تحسين استهلاك البطارية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'لكي يستمر فحص الشبكة والاصطياد التلقائي بالعمل في الخلفية دون أن يوقفه نظام أندرويد لتوفير الطاقة:',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'يرجى اختيار "غير مقيد" (Unrestricted) أو السماح للتطبيق بالعمل في الخلفية بحرية.',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await NativeBridge.requestIgnoreBatteryOptimizations();
            },
            icon: const Icon(Icons.bolt, size: 18),
            label: const Text(
              'ضبط استثناء البطارية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showNetworkChangeDialog(
    BuildContext context,
    EngineProvider engine,
    String prevSsid,
    String newSsid,
  ) {
    if (_isShowingNetworkChangeDialog) return;
    _isShowingNetworkChangeDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.wifi_off_rounded,
          size: 52,
          color: AppColors.warning,
        ),
        title: const Text(
          'تنبيه: تغيرت شبكة الواي فاي!',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.danger,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تم اكتشاف تغير الشبكة المتصل بها أثناء عملية الفحص / فك الحظر:',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الشبكة الحالية هي: "$newSsid"',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.history, size: 18, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'والسابقة التي كان يجري الاصطياد منها هي: "$prevSsid"',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'هل تريد المتابعة على الشبكة الحالية أم العودة لاختيار الشبكة السابقة؟',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton.icon(
            onPressed: () async {
              _isShowingNetworkChangeDialog = false;
              Navigator.pop(ctx);
              await engine.cancelOnNetworkChange(openWifi: false);
            },
            icon: const Icon(Icons.stop_circle_outlined, color: AppColors.danger),
            label: const Text(
              'إيقاف الفحص',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              _isShowingNetworkChangeDialog = false;
              Navigator.pop(ctx);
              await engine.cancelOnNetworkChange(openWifi: true);
            },
            icon: const Icon(Icons.wifi_find, size: 18),
            label: const Text(
              'تغيير الشبكة',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              _isShowingNetworkChangeDialog = false;
              Navigator.pop(ctx);
              await engine.confirmContinueOnNewNetwork();
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              'نعم، متابعة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      _isShowingNetworkChangeDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<EngineProvider>();
    final cards = context.watch<CardsProvider>();

    if (engine.hasNetworkChangePrompt && !_isShowingNetworkChangeDialog) {
      final prev = engine.pendingPreviousSsid!;
      final curr = engine.pendingNewSsid!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && engine.hasNetworkChangePrompt) {
          _showNetworkChangeDialog(context, engine, prev, curr);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppStrings.appTitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${AppStrings.devName} | ${AppStrings.devPhone}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              color: engine.isRootAvailable
                  ? AppColors.successLight
                  : Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  engine.isRootAvailable
                      ? Icons.check_circle
                      : Icons.info_outline,
                  size: 13,
                  color: engine.isRootAvailable
                      ? AppColors.success
                      : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  engine.isRootAvailable ? 'Root ✓' : 'Non-Root',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: engine.isRootAvailable
                        ? AppColors.success
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // زر تبديل الثيم
          IconButton(
            tooltip: 'تبديل الثيم',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final useRail = constraints.maxWidth >= 900;
          final extendedRail = constraints.maxWidth >= 1200;

          return Row(
            children: [
              if (useRail) ...[
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _selectTab,
                  extended: extendedRail,
                  labelType: extendedRail
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  minWidth: 80,
                  minExtendedWidth: 232,
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text(AppStrings.tabDashboard),
                    ),
                    NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: cards.totalCount > 0,
                        label: Text('${cards.totalCount}'),
                        child: const Icon(Icons.confirmation_number_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: cards.totalCount > 0,
                        label: Text('${cards.totalCount}'),
                        child: const Icon(Icons.confirmation_number),
                      ),
                      label: const Text(AppStrings.tabCards),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text(AppStrings.tabSettings),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.terminal_outlined),
                      selectedIcon: Icon(Icons.terminal),
                      label: Text(AppStrings.tabLogs),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text(AppStrings.tabDeveloper),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        if (_currentIndex != index) {
                          setState(() => _currentIndex = index);
                        }
                      },
                      children: [
                        for (final tab in _tabs) _KeepAlivePage(child: tab),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? ModernBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _selectTab,
              items: [
                const ModernNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'التحكم',
                ),
                ModernNavItem(
                  icon: Icons.confirmation_number_outlined,
                  activeIcon: Icons.confirmation_number_rounded,
                  label: 'الكروت',
                  badgeCount: cards.totalCount,
                ),
                const ModernNavItem(
                  icon: Icons.tune_outlined,
                  activeIcon: Icons.tune_rounded,
                  label: 'الإعدادات',
                ),
                const ModernNavItem(
                  icon: Icons.terminal_outlined,
                  activeIcon: Icons.terminal_rounded,
                  label: 'السجلات',
                ),
                const ModernNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'المطور',
                ),
              ],
            )
          : null,
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin<_KeepAlivePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:networking/core/services/background_hunter_service.dart';
import 'package:networking/core/theme/app_theme.dart';
import 'package:networking/data/datasources/hive_helper.dart';
import 'package:networking/presentation/providers/cards_provider.dart';
import 'package:networking/presentation/providers/engine_provider.dart';
import 'package:networking/presentation/providers/logs_provider.dart';
import 'package:networking/presentation/providers/settings_provider.dart';
import 'package:networking/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Hive وتسجيل الـ Adapters وفتح الصناديق محلياً
  await HiveHelper.instance.init();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await BackgroundHunterService.initializeService();
    } catch (_) {}
  }
  runApp(const NetworkHunterApp());
}

class NetworkHunterApp extends StatefulWidget {
  final Widget? home;
  const NetworkHunterApp({super.key, this.home});

  @override
  State<NetworkHunterApp> createState() => _NetworkHunterAppState();
}

class _NetworkHunterAppState extends State<NetworkHunterApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LogsProvider()),
        ChangeNotifierProvider(create: (_) => CardsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => EngineProvider()),
      ],
      child: MaterialApp(
        title: 'Network Voucher Hunter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        builder: (context, child) {
          // ضمان توجيه كافة الواجهات من اليمين إلى اليسار (RTL) بشكل أصيل
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: widget.home ??
            SplashScreen(
              onToggleTheme: _toggleTheme,
              isDark: _themeMode == ThemeMode.dark,
            ),
      ),
    );
  }
}

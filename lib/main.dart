import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:networking/core/theme/app_theme.dart';
import 'package:networking/presentation/providers/cards_provider.dart';
import 'package:networking/presentation/providers/engine_provider.dart';
import 'package:networking/presentation/providers/logs_provider.dart';
import 'package:networking/presentation/providers/settings_provider.dart';
import 'package:networking/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NetworkHunterApp());
}

class NetworkHunterApp extends StatefulWidget {
  const NetworkHunterApp({super.key});

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
        home: HomeScreen(
          onToggleTheme: _toggleTheme,
          isDark: _themeMode == ThemeMode.dark,
        ),
      ),
    );
  }
}

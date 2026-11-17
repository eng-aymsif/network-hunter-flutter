import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/domain/engine/hunter_engine.dart';
import 'package:networking/main.dart';
import 'package:networking/presentation/widgets/engine_status_badge.dart';
import 'package:networking/presentation/widgets/stat_card.dart';
import 'package:networking/core/constants/app_colors.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const NetworkHunterApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NetworkHunterApp), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Status badge wraps long messages on a narrow screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: _LargeTextBuilder.build,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: const EngineStatusBadge(
                status: EngineStatus.error,
                statusText:
                    'توقفت العملية بسبب خطأ اتصال طويل جداً أثناء التحقق من صفحة الدخول '
                    'ERR_INTERNET_DISCONNECTED، يرجى التحقق من اتصال الشبكة ثم إعادة المحاولة.',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EngineStatusBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Statistics card fits a narrow cell with enlarged text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: _LargeTextBuilder.build,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 150,
              height: 104,
              child: const StatCard(
                title: 'إجمالي المحاولات',
                value: '12345',
                valueColor: AppColors.primary,
                icon: Icons.sync,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('tab transitions preserve unsaved settings', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const NetworkHunterApp());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text(AppStrings.tabSettings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('إعدادات الشبكة ومسارات صفحة الدخول'), findsOneWidget);

    final urlField = find.byType(TextFormField).first;
    await tester.enterText(urlField, 'https://network.local');

    await tester.tap(find.text(AppStrings.tabDashboard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(AppStrings.tabSettings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final settingsField = tester.widget<TextFormField>(urlField);
    expect(settingsField.controller!.text, 'https://network.local');

    await tester.tap(find.text(AppStrings.tabCards));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.tabLogs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}

class _LargeTextBuilder {
  static Widget build(BuildContext context, Widget? child) {
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.25)),
      child: child!,
    );
  }
}

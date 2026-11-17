import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/data/datasources/hive_helper.dart';
import 'package:networking/domain/engine/hunter_engine.dart';
import 'package:networking/main.dart';
import 'package:networking/presentation/widgets/engine_status_badge.dart';
import 'package:networking/presentation/widgets/stat_card.dart';
import 'package:networking/core/constants/app_colors.dart';

void main() {
  setUpAll(() async {
    final temp = Directory.systemTemp.createTempSync('widget_test_hive_');
    await HiveHelper.instance.init(temp.path);
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

    await tester.tap(find.text('الإعدادات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('إعدادات الشبكة ومسارات صفحة الدخول'), findsOneWidget);

    final urlField = find.byType(TextFormField).first;
    await tester.enterText(urlField, 'https://network.local');

    await tester.tap(find.text('التحكم'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('الإعدادات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final settingsField = tester.widget<TextFormField>(urlField);
    expect(settingsField.controller!.text, 'https://network.local');

    await tester.tap(find.text('الكروت'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('السجلات'));
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/engine_provider.dart';
import '../providers/logs_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/engine_status_badge.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_log_viewer.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<EngineProvider>();
    final logs = context.watch<LogsProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final settings = settingsProv.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. شبكة كروت الإحصائيات الأربعة
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 104,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final stat = switch (index) {
                    0 => (
                      title: AppStrings.statCurrentNumber,
                      value: engine.currentNumber,
                      color: AppColors.primary,
                      icon: Icons.confirmation_number_outlined,
                    ),
                    1 => (
                      title: AppStrings.statTotalAttempts,
                      value: engine.totalAttempts.toString(),
                      color: AppColors.accent,
                      icon: Icons.sync,
                    ),
                    2 => (
                      title: AppStrings.statFoundCards,
                      value: engine.foundCount.toString(),
                      color: AppColors.success,
                      icon: Icons.verified,
                    ),
                    _ => (
                      title: AppStrings.statUnbanCount,
                      value: engine.unbanCount.toString(),
                      color: AppColors.purple,
                      icon: Icons.lock_open,
                    ),
                  };
                  return StatCard(
                    title: stat.title,
                    value: stat.value,
                    valueColor: stat.color,
                    icon: stat.icon,
                  );
                },
              ),
              const SizedBox(height: 12),

              // 2. بطاقة أزرار التحكم وحالة المحرك
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 560;
                          final status = ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isCompact
                                  ? constraints.maxWidth
                                  : constraints.maxWidth * 0.58,
                            ),
                            child: EngineStatusBadge(
                              status: engine.status,
                              statusText: engine.statusText,
                            ),
                          );

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'أزرار التحكم وحالة الفحص',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: status,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'أزرار التحكم وحالة الفحص',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              status,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // أزرار التحكم الرئيسية
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          // زر البدء
                          ElevatedButton.icon(
                            onPressed: engine.isRunning
                                ? null
                                : () {
                                    engine.startHunting();
                                  },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(AppStrings.btnStart),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // زر الإيقاف المؤقت / الاستئناف
                          ElevatedButton.icon(
                            onPressed: !engine.isRunning
                                ? null
                                : () {
                                    if (engine.isPaused) {
                                      engine.resumeHunting();
                                    } else {
                                      engine.pauseHunting();
                                    }
                                  },
                            icon: Icon(
                              engine.isPaused ? Icons.play_arrow : Icons.pause,
                            ),
                            label: Text(
                              engine.isPaused
                                  ? AppStrings.btnResume
                                  : AppStrings.btnPause,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // زر الإنهاء والتوقف
                          ElevatedButton.icon(
                            onPressed: !engine.isRunning
                                ? null
                                : () {
                                    engine.stopHunting();
                                  },
                            icon: const Icon(Icons.stop),
                            label: const Text(AppStrings.btnStop),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // زر فك الحظر اليدوي
                          OutlinedButton.icon(
                            onPressed: () {
                              engine.manualUnban();
                            },
                            icon: const Icon(
                              Icons.lock_open,
                              color: AppColors.purple,
                            ),
                            label: const Text(
                              AppStrings.btnManualUnban,
                              style: TextStyle(
                                color: AppColors.purple,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.purple),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // خيار الاستئناف التلقائي
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'الاستئناف التلقائي من آخر رقم تم حفظه في قاعدة البيانات',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        ),
                        value: settings.resumeSaved,
                        onChanged: (val) {
                          if (val != null) {
                            settingsProv.saveSettings(
                              settings.copyWith(resumeSaved: val),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. معاينة حية سريعة للسجل (Live Activity Console)
              LayoutBuilder(
                builder: (context, constraints) {
                  const title = Text(
                    'المعاينة الحية للعمليات المباشرة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  );
                  final latestMessage = Text(
                    'آخر رسالة: ${logs.latestMessage}',
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: constraints.maxWidth < 560 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  );

                  if (constraints.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const SizedBox(height: 4),
                        latestMessage,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Flexible(child: title),
                      const SizedBox(width: 8),
                      Expanded(child: latestMessage),
                    ],
                  );
                },
              ),
              const SizedBox(height: 6),
              SizedBox(height: 220, child: CustomLogViewer(logs: logs.logs)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/core/services/subscription_service.dart';
import 'package:networking/presentation/providers/cards_provider.dart';
import 'package:networking/presentation/providers/engine_provider.dart';
import 'package:networking/presentation/providers/logs_provider.dart';
import 'package:networking/presentation/providers/settings_provider.dart';
import 'package:networking/presentation/widgets/engine_status_badge.dart';
import 'package:networking/presentation/widgets/stat_card.dart';
import 'package:networking/presentation/widgets/custom_log_viewer.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<EngineProvider>();
    final cardsProv = context.watch<CardsProvider>();
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
              // شريط حالة الاشتراك وحصة الكروت المسموح بها
              Builder(
                builder: (context) {
                  final sub = SubscriptionService.instance.currentSubscription;
                  if (sub == null) return const SizedBox.shrink();
                  final isDaily = sub.isDaily;
                  final allowed = sub.allowedCards;
                  final left = sub.remainingCards;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'حصة الكروت: $left متبقية من $allowed (${isDaily ? "تتجدد يومياً" : "رصيد دائم"})',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sub.isAvailable
                                ? AppColors.success.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sub.isAvailable ? 'متاح 🟢' : sub.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: sub.isAvailable ? AppColors.success : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

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
                                    final hasSaved = settingsProv.hasSavedNumber;
                                    final willResume = settings.resumeSaved && hasSaved;
                                    if (!willResume && settings.startNumber.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '⚠️ رقم كارت البداية إلزامي! يرجى إدخال رقم كارت البداية في شاشة الإعدادات أولاً لبدء الفحص والاصطياد.',
                                            style: TextStyle(fontFamily: 'Cairo'),
                                          ),
                                          backgroundColor: AppColors.danger,
                                          duration: Duration(seconds: 4),
                                        ),
                                      );
                                      return;
                                    }
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

                          // زر تسجيل الخروج الفوري من الكرت المتصل ومسح الكاش والكوكيز
                          OutlinedButton.icon(
                            onPressed: cardsProv.isLoggingOut
                                ? null
                                : () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '🚪 جاري تسجيل الخروج من الشبكة وتطهير الكاش والكوكيز...',
                                          style: TextStyle(fontFamily: 'Cairo'),
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    final ok =
                                        await engine.manualLogoutAndPurge();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? '✅ تم تسجيل الخروج من الكرت المتصل ومسح الكاش والكوكيز بالكامل!'
                                              : '⚠️ تعذر إتمام بعض خطوات تسجيل الخروج',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        backgroundColor: ok
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    );
                                  },
                            icon: cardsProv.isLoggingOut
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.danger,
                                    ),
                                  )
                                : const Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.danger,
                                  ),
                            label: const Text(
                              'تسجيل الخروج ومسح الكوكيز والكاش',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // خيار الاستئناف التلقائي (يظهر فقط إذا كان هناك رقم محفوظ مسبقاً في قاعدة البيانات)
                      if (settingsProv.hasSavedNumber) ...[
                        const Divider(height: 20),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'الاستئناف التلقائي من آخر رقم تم حفظه (${settingsProv.savedLastNumber})',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

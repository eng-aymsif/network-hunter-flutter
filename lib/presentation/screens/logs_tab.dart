import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/core/constants/app_strings.dart';
import 'package:networking/presentation/providers/logs_provider.dart';
import 'package:networking/presentation/widgets/custom_log_viewer.dart';

class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final logsProv = context.watch<LogsProvider>();

    return Column(
      children: [
        // شريط الأزرار العلوي
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Theme.of(context).cardColor,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'العدد: ${logsProv.logs.length} سجل',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text(AppStrings.btnCopyLogs, style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                onPressed: () {
                  logsProv.copyAllLogs();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ السجل بالكامل إلى الحافظة 📋', style: TextStyle(fontFamily: 'Cairo')),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.share, size: 16),
                label: const Text(AppStrings.btnExportLogs, style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                onPressed: () {
                  logsProv.shareLogs();
                },
              ),
              IconButton(
                tooltip: AppStrings.btnClearLogs,
                icon: const Icon(Icons.delete_sweep, color: AppColors.danger),
                onPressed: () {
                  logsProv.clearLogs();
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // نافذة السجلات التفاعلية
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CustomLogViewer(logs: logsProv.logs),
          ),
        ),
      ],
    );
  }
}

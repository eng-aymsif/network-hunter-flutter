import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/engine/hunter_engine.dart';

class EngineStatusBadge extends StatelessWidget {
  final EngineStatus status;
  final String statusText;

  const EngineStatusBadge({
    super.key,
    required this.status,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;

    switch (status) {
      case EngineStatus.running:
        bg = AppColors.successLight;
        fg = AppColors.success;
      case EngineStatus.paused:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
      case EngineStatus.stopping:
      case EngineStatus.error:
        bg = AppColors.dangerLight;
        fg = AppColors.danger;
      case EngineStatus.unbanning:
        bg = AppColors.purpleLight;
        fg = AppColors.purple;
      case EngineStatus.ready:
        bg = AppColors.successLight;
        fg = AppColors.success;
    }

    if (isDark) {
      bg = fg.withValues(alpha: 0.18);
      fg = switch (status) {
        EngineStatus.running || EngineStatus.ready => Colors.green.shade300,
        EngineStatus.paused => Colors.orange.shade300,
        EngineStatus.stopping || EngineStatus.error => Colors.red.shade300,
        EngineStatus.unbanning => Colors.purple.shade200,
      };
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.5)),
      ),
      child: Tooltip(
        message: statusText,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            statusText,
            key: ValueKey(status),
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.5)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

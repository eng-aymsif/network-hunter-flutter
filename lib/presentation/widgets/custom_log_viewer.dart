import 'package:flutter/material.dart';
import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/presentation/providers/logs_provider.dart';

class CustomLogViewer extends StatefulWidget {
  final List<LogEntry> logs;
  final bool autoScroll;

  const CustomLogViewer({
    super.key,
    required this.logs,
    this.autoScroll = true,
  });

  @override
  State<CustomLogViewer> createState() => _CustomLogViewerState();
}

class _CustomLogViewerState extends State<CustomLogViewer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant CustomLogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll && widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getLineColor(String message) {
    if (message.contains('🎉') || message.contains('✓')) {
      return AppColors.terminalGreen;
    }
    if (message.contains('❌') || message.contains('🛑')) {
      return AppColors.terminalRed;
    }
    if (message.contains('⚠️') || message.contains('⏸')) {
      return AppColors.terminalOrange;
    }
    if (message.contains('🚀') || message.contains('🔓') || message.contains('---')) {
      return AppColors.terminalBlue;
    }
    return AppColors.terminalText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.terminalBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(8),
      child: widget.logs.isEmpty
          ? const Center(
              child: Text(
                'سجل العمليات فارغ حالياً...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: widget.logs.length,
              itemBuilder: (context, index) {
                final entry = widget.logs[index];
                final color = _getLineColor(entry.message);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '[${entry.time}] ',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontFamily: 'Consolas',
                          ),
                        ),
                        TextSpan(
                          text: entry.message,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_timer_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Widget hiển thị đồng hồ đếm ngược
///
/// Features:
/// - Circular progress indicator
/// - Text "MM:SS"
/// - Đổi màu khi còn ít thời gian
/// - Animation pulse khi critical time
class TimerWidget extends StatefulWidget {
  final double size;
  final bool showLabel;

  const TimerWidget({super.key, this.size = 80, this.showLabel = true});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Xác định màu dựa trên thời gian còn lại
  Color _getColor(ExamTimerProvider timer) {
    if (timer.isCriticalTime) {
      // Dưới 1 phút - đỏ
      return AppTheme.errorRed;
    } else if (timer.isLowTime) {
      // Dưới 5 phút - vàng
      return AppTheme.warningYellow;
    }
    // Bình thường - xanh
    return AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamTimerProvider>(
      builder: (context, timer, child) {
        final color = _getColor(timer);

        // Pulse animation khi critical time
        if (timer.isCriticalTime && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!timer.isCriticalTime && _pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.reset();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: timer.isCriticalTime
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),

                    // Progress indicator
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: timer.progress,
                        strokeWidth: 6,
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),

                    // Time text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: color,
                          size: widget.size * 0.22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timer.formattedTime,
                          style: TextStyle(
                            fontSize: widget.size * 0.22,
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Label
            if (widget.showLabel) ...[
              const SizedBox(height: 8),
              Text(
                _getStatusText(timer),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getStatusText(ExamTimerProvider timer) {
    if (timer.isPaused) {
      return 'Đã tạm dừng';
    } else if (timer.isCriticalTime) {
      return 'Sắp hết giờ!';
    } else if (timer.isLowTime) {
      return 'Còn ít thời gian';
    } else if (timer.isRunning) {
      return 'Đang làm bài';
    }
    return 'Chờ bắt đầu';
  }
}

/// Compact timer widget for app bar
class CompactTimerWidget extends StatelessWidget {
  const CompactTimerWidget({super.key});

  Color _getColor(ExamTimerProvider timer) {
    if (timer.isCriticalTime) {
      return AppTheme.errorRed;
    } else if (timer.isLowTime) {
      return AppTheme.warningYellow;
    }
    return AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamTimerProvider>(
      builder: (context, timer, child) {
        final color = _getColor(timer);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                timer.isCriticalTime ? Icons.timer_off : Icons.timer_outlined,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                timer.formattedTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// lib/features/quiz/widgets/timer_countdown_widget.dart
import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';

class TimerCountdownWidget extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeUp;
  final TextStyle? textStyle;
  final Color? textColor;

  const TimerCountdownWidget({
    Key? key,
    required this.seconds,
    required this.onTimeUp,
    this.textStyle,
    this.textColor,
  }) : super(key: key);

  @override
  State<TimerCountdownWidget> createState() => _TimerCountdownWidgetState();
}

class _TimerCountdownWidgetState extends State<TimerCountdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _countdownAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    );

    _countdownAnimation = IntTween(
      begin: widget.seconds,
      end: 0,
    ).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTimeUp();
      }
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant TimerCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      // Nếu số giây thay đổi (hiếm xảy ra), reset lại
      _controller.reset();
      _controller.duration = Duration(seconds: widget.seconds);
      _countdownAnimation = IntTween(begin: widget.seconds, end: 0).animate(_controller);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // QUAN TRỌNG: Tránh memory leak
    super.dispose();
  }

  // Thêm phương thức để stop sớm (nếu cần)
  void stop() {
    _controller.stop();
  }

  // Thêm phương thức để expose remaining seconds (nếu cần dùng ở ngoài)
  int get remainingSeconds => _countdownAnimation.value;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: widget.textColor ?? AppTheme.textDark,
    );

    return AnimatedBuilder(
      animation: _countdownAnimation,
      builder: (context, child) {
        final seconds = _countdownAnimation.value;
        final displayText = seconds > 0 ? '${seconds}s' : '0s';

        // Đổi màu khi gần hết giờ (tùy chọn đẹp)
        final color = seconds <= 10
            ? AppTheme.errorRed
            : (widget.textColor ?? AppTheme.textDark);

        return Text(
          displayText,
          style: (widget.textStyle ?? defaultStyle).copyWith(color: color),
        );
      },
    );
  }
}
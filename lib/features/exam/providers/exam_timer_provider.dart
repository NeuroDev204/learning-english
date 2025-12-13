import 'dart:async';
import 'package:flutter/foundation.dart';

/// Provider quản lý đếm ngược thời gian làm bài
///
/// Sử dụng:
/// ```dart
/// final timer = context.read<ExamTimerProvider>();
/// timer.startTimer(15); // 15 phút
/// timer.onTimeUp = () => submitExam();
/// ```
class ExamTimerProvider extends ChangeNotifier {
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;

  /// Callback được gọi khi hết giờ
  VoidCallback? onTimeUp;

  /// Số giây còn lại
  int get remainingSeconds => _remainingSeconds;

  /// Tổng số giây ban đầu
  int get totalSeconds => _totalSeconds;

  /// Số giây đã trôi qua
  int get elapsedSeconds => _totalSeconds - _remainingSeconds;

  /// Timer đang chạy không
  bool get isRunning => _isRunning;

  /// Timer đang pause không
  bool get isPaused => _isPaused;

  /// Đã hết giờ chưa
  bool get isTimeUp => _remainingSeconds <= 0 && _totalSeconds > 0;

  /// Thời gian còn lại formatted (MM:SS)
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Phần trăm thời gian còn lại (0.0 - 1.0)
  double get progress {
    if (_totalSeconds == 0) return 1.0;
    return _remainingSeconds / _totalSeconds;
  }

  /// Kiểm tra còn ít thời gian không (dưới 5 phút)
  bool get isLowTime => _remainingSeconds > 0 && _remainingSeconds <= 300;

  /// Kiểm tra rất ít thời gian (dưới 1 phút)
  bool get isCriticalTime => _remainingSeconds > 0 && _remainingSeconds <= 60;

  /// Bắt đầu đếm ngược
  /// [minutes] - Số phút
  void startTimer(int minutes) {
    // Hủy timer cũ nếu có
    stopTimer();

    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _isRunning = true;
    _isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  /// Tick mỗi giây
  void _tick(Timer timer) {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();

      // Gọi callback khi hết giờ
      if (_remainingSeconds == 0) {
        stopTimer();
        onTimeUp?.call();
      }
    }
  }

  /// Tạm dừng timer
  void pauseTimer() {
    if (_isRunning && !_isPaused) {
      _timer?.cancel();
      _isPaused = true;
      notifyListeners();
    }
  }

  /// Tiếp tục timer
  void resumeTimer() {
    if (_isRunning && _isPaused) {
      _isPaused = false;
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      notifyListeners();
    }
  }

  /// Dừng timer hoàn toàn
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isPaused = false;
    notifyListeners();
  }

  /// Reset timer về trạng thái ban đầu
  void resetTimer() {
    stopTimer();
    _remainingSeconds = 0;
    _totalSeconds = 0;
    notifyListeners();
  }

  /// Thêm thời gian bonus
  void addBonusTime(int seconds) {
    _remainingSeconds += seconds;
    _totalSeconds += seconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

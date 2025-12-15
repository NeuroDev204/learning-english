import 'package:hive/hive.dart';
import '../models/dashboard_stats.dart';
import '../models/chart_data_point.dart';
import '../../quiz/models/quiz_session.dart';

class DashboardCache {
  static const String _statsBoxName = 'dashboard_stats';
  static const String _chartDataBoxName = 'dashboard_chart_data';
  static const String _sessionsBoxName = 'dashboard_sessions';
  static const String _statsKey = 'stats';
  static const String _chartDataKey = 'chart_data';
  static const String _sessionsKey = 'sessions';

  Future<void> init() async {
    await Hive.openBox(_statsBoxName);
    await Hive.openBox(_chartDataBoxName);
    await Hive.openBox(_sessionsBoxName);
  }

  /// Lưu stats vào cache
  Future<void> saveStats(DashboardStats stats) async {
    final box = Hive.box(_statsBoxName);
    await box.put(_statsKey, stats.toMap());
  }

  /// Lấy stats từ cache
  DashboardStats? getStats() {
    final box = Hive.box(_statsBoxName);
    final data = box.get(_statsKey);
    if (data == null) return null;
    return DashboardStats.fromMap(Map<String, dynamic>.from(data));
  }

  /// Lưu chart data points vào cache
  Future<void> saveChartData(List<ChartDataPoint> dataPoints) async {
    final box = Hive.box(_chartDataBoxName);
    await box.put(
      _chartDataKey,
      dataPoints.map((dp) => dp.toMap()).toList(),
    );
  }

  /// Lấy chart data points từ cache
  List<ChartDataPoint>? getChartData() {
    final box = Hive.box(_chartDataBoxName);
    final data = box.get(_chartDataKey);
    if (data == null) return null;
    return (data as List)
        .map((item) => ChartDataPoint.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Lưu sessions vào cache
  Future<void> saveSessions(List<QuizSession> sessions) async {
    final box = Hive.box(_sessionsBoxName);
    await box.put(
      _sessionsKey,
      sessions.map((s) => s.toMap()).toList(),
    );
  }

  /// Lấy sessions từ cache
  List<QuizSession>? getSessions() {
    final box = Hive.box(_sessionsBoxName);
    final data = box.get(_sessionsKey);
    if (data == null) return null;
    return (data as List)
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          DateTime playedAt = DateTime.now();
          final playedAtField = map['playedAt'];
          if (playedAtField is String) {
            try {
              playedAt = DateTime.parse(playedAtField);
            } catch (e) {
              playedAt = DateTime.now();
            }
          }
          
          return QuizSession(
            topicId: map['topicId'] ?? '',
            topicName: map['topicName'] ?? 'Chủ đề không xác định',
            mode: map['mode'] ?? 'quiz',
            questionCount: map['questionCount'] ?? 0,
            correctCount: map['correctCount'] ?? 0,
            scorePercentage: map['scorePercentage'] ?? 0,
            xpEarned: map['xpEarned'] ?? 0,
            durationSeconds: map['durationSeconds'] ?? 0,
            playedAt: playedAt,
            answers: (map['answers'] as List<dynamic>?)
                    ?.map((a) => QuizAnswer(
                          vocabularyId: a['vocabularyId'] ?? '',
                          word: a['word'] ?? '',
                          userAnswer: a['userAnswer'] ?? '',
                          isCorrect: a['isCorrect'] ?? false,
                          timeSpent: (a['timeSpent'] as num?)?.toDouble() ?? 0.0,
                        ))
                    .toList() ??
                [],
          );
        })
        .toList();
  }

  /// Xóa cache
  Future<void> clearCache() async {
    final statsBox = Hive.box(_statsBoxName);
    final chartBox = Hive.box(_chartDataBoxName);
    final sessionsBox = Hive.box(_sessionsBoxName);
    await statsBox.clear();
    await chartBox.clear();
    await sessionsBox.clear();
  }
}
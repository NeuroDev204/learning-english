import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';
import '../models/chart_data_point.dart';
import '../../quiz/models/quiz_session.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lấy thống kê dashboard từ Firestore
  Future<DashboardStats> getDashboardStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    try {
      final sessionsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quiz_sessions');

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Sửa: Tính weekStart từ thứ 2 đầu tuần
      // weekday: 1 = Monday, 7 = Sunday
      final daysFromMonday = (now.weekday - 1) % 7;
      final weekStart = todayStart.subtract(Duration(days: daysFromMonday));

      final monthStart = DateTime(now.year, now.month, 1);

      // Lấy tất cả sessions
      final allSessionsSnapshot =
          await sessionsRef.orderBy('playedAt', descending: true).get();

      final allSessions = allSessionsSnapshot.docs.map((doc) {
        final data = doc.data();
        final playedAtField = data['playedAt'];
        DateTime playedAt = DateTime.now();
        if (playedAtField is Timestamp) {
          playedAt = playedAtField.toDate();
        } else if (playedAtField is String) {
          try {
            playedAt = DateTime.parse(playedAtField);
          } catch (e) {
            playedAt = DateTime.now();
          }
        }

        return QuizSession(
          topicId: data['topicId'] ?? '',
          topicName: data['topicName'] ?? 'Chủ đề không xác định',
          mode: data['mode'] ?? 'quiz',
          questionCount: data['questionCount'] ?? 0,
          correctCount: data['correctCount'] ?? 0,
          scorePercentage: data['scorePercentage'] ?? 0,
          xpEarned: data['xpEarned'] ?? 0,
          durationSeconds: data['durationSeconds'] ?? 0,
          playedAt: playedAt,
          answers: (data['answers'] as List<dynamic>?)
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
      }).toList();

      // Tính số từ học theo thời gian (tổng số từ đã làm quiz)
      int wordsToday = 0;
      int wordsThisWeek = 0;
      int wordsThisMonth = 0;
      int totalXP = 0;
      int totalCorrect = 0;
      int totalQuestions = 0;

      final Set<String> weekDays = {};
      final Set<String> monthDays = {};
      final Set<String> allDays = {};

      for (final session in allSessions) {
        // Đếm số từ đã làm quiz (số câu đã trả lời)
        final answeredCount =
            session.answers.where((a) => a.userAnswer.isNotEmpty).length;

        // Sửa: Dùng >= thay vì isAfter để bao gồm cả ngày hôm nay/thứ 2/tháng này
        final sessionDate = DateTime(
          session.playedAt.year,
          session.playedAt.month,
          session.playedAt.day,
        );

        final dayKey =
            '${session.playedAt.year}-${session.playedAt.month}-${session.playedAt.day}';
        allDays.add(dayKey);

        if (sessionDate.isAtSameMomentAs(todayStart) ||
            sessionDate.isAfter(todayStart)) {
          wordsToday += answeredCount;
        }
        if (sessionDate.isAtSameMomentAs(weekStart) ||
            sessionDate.isAfter(weekStart)) {
          wordsThisWeek += answeredCount;
          weekDays.add(dayKey);
        }
        if (sessionDate.isAtSameMomentAs(monthStart) ||
            sessionDate.isAfter(monthStart)) {
          wordsThisMonth += answeredCount;
          monthDays.add(dayKey);
        }

        totalXP += session.xpEarned;
        totalCorrect += session.correctCount;
        totalQuestions += session.questionCount;
      }

      // Tính % chính xác trung bình
      final averageAccuracy =
          totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0;

      // Tính toán Streak (Chuỗi liên tiếp) thực tế từ lịch sử sessions
      int currentStreak = 0;
      DateTime cursor = DateTime(now.year, now.month, now.day);
      String cursorKey = '${cursor.year}-${cursor.month}-${cursor.day}';

      if (!allDays.contains(cursorKey)) {
        cursor = cursor.subtract(const Duration(days: 1));
        cursorKey = '${cursor.year}-${cursor.month}-${cursor.day}';
      }

      while (allDays.contains(cursorKey)) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
        cursorKey = '${cursor.year}-${cursor.month}-${cursor.day}';
      }

      return DashboardStats(
        wordsLearnedToday: wordsToday,
        wordsLearnedThisWeek: wordsThisWeek,
        wordsLearnedThisMonth: wordsThisMonth,
        currentStreak: currentStreak,
        totalXP: totalXP,
        averageAccuracy: averageAccuracy,
        totalSessions: allSessions.length,
        lastUpdated: DateTime.now(),
        weeklyStreakDays: weekDays.length,
        monthlyStreakDays: monthDays.length,
      );
    } catch (e) {
      debugPrint('Lỗi khi lấy dashboard stats: $e');
      rethrow;
    }
  }

  /// Lấy dữ liệu biểu đồ (7 ngày gần nhất) - XP, số từ học, % chính xác
  Future<List<ChartDataPoint>> getChartDataPoints({int days = 7}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final sessionsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quiz_sessions');

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));

      final sessionsSnapshot = await sessionsRef
          .where('playedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('playedAt')
          .get();

      // Nhóm dữ liệu theo ngày
      final Map<String, Map<String, dynamic>> dataByDate = {};

      for (final doc in sessionsSnapshot.docs) {
        final data = doc.data();
        final playedAtField = data['playedAt'];
        DateTime playedAt = DateTime.now();
        if (playedAtField is Timestamp) {
          playedAt = playedAtField.toDate();
        } else if (playedAtField is String) {
          try {
            playedAt = DateTime.parse(playedAtField);
          } catch (e) {
            playedAt = DateTime.now();
          }
        }

        final dateKey = '${playedAt.year}-${playedAt.month}-${playedAt.day}';

        // Parse answers để đếm số từ học (số câu đã trả lời)
        final answers = (data['answers'] as List<dynamic>?) ?? [];
        final wordsLearned = answers
            .where((a) => (a['userAnswer'] as String?)?.isNotEmpty ?? false)
            .length;

        final xp = (data['xpEarned'] as int?) ?? 0;
        final correctCount = (data['correctCount'] as int?) ?? 0;
        final questionCount = (data['questionCount'] as int?) ?? 0;
        final accuracy =
            questionCount > 0 ? (correctCount / questionCount * 100) : 0.0;

        if (dataByDate.containsKey(dateKey)) {
          dataByDate[dateKey]!['xp'] = (dataByDate[dateKey]!['xp'] ?? 0) + xp;
          dataByDate[dateKey]!['wordsLearned'] =
              (dataByDate[dateKey]!['wordsLearned'] ?? 0) + wordsLearned;

          // Tính accuracy trung bình (tổng correct / tổng questions)
          final totalCorrect =
              (dataByDate[dateKey]!['totalCorrect'] ?? 0) + correctCount;
          final totalQuestions =
              (dataByDate[dateKey]!['totalQuestions'] ?? 0) + questionCount;
          dataByDate[dateKey]!['totalCorrect'] = totalCorrect;
          dataByDate[dateKey]!['totalQuestions'] = totalQuestions;
          dataByDate[dateKey]!['accuracy'] =
              totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0;
        } else {
          dataByDate[dateKey] = {
            'xp': xp,
            'wordsLearned': wordsLearned,
            'totalCorrect': correctCount,
            'totalQuestions': questionCount,
            'accuracy': accuracy,
          };
        }
      }

      // Tạo danh sách data points cho 7 ngày
      final List<ChartDataPoint> dataPoints = [];
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final dayData = dataByDate[dateKey];

        dataPoints.add(ChartDataPoint(
          date: date,
          xp: dayData?['xp'] ?? 0,
          wordsLearned: dayData?['wordsLearned'] ?? 0,
          accuracy: (dayData?['accuracy'] ?? 0.0).toDouble(),
        ));
      }

      return dataPoints;
    } catch (e) {
      debugPrint('Lỗi khi lấy chart data points: $e');
      return [];
    }
  }

  /// Stream dashboard stats (real-time updates)
  Stream<DashboardStats> watchDashboardStats() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(DashboardStats(
        wordsLearnedToday: 0,
        wordsLearnedThisWeek: 0,
        wordsLearnedThisMonth: 0,
        currentStreak: 0,
        totalXP: 0,
        averageAccuracy: 0.0,
        totalSessions: 0,
        lastUpdated: DateTime.now(),
        weeklyStreakDays: 0,
        monthlyStreakDays: 0,
      ));
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_sessions')
        .orderBy('playedAt', descending: true)
        .snapshots()
        .asyncMap((_) => getDashboardStats());
  }

  /// Stream quiz sessions gần đây
  Stream<List<QuizSession>> watchRecentSessions({int limit = 10}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_sessions')
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        DateTime playedAt = DateTime.now();
        final playedAtField = data['playedAt'];
        if (playedAtField is Timestamp) {
          playedAt = playedAtField.toDate();
        } else if (playedAtField is String) {
          try {
            playedAt = DateTime.parse(playedAtField);
          } catch (e) {
            playedAt = DateTime.now();
          }
        }

        return QuizSession(
          topicId: data['topicId'] ?? '',
          topicName: data['topicName'] ?? 'Chủ đề không xác định',
          mode: data['mode'] ?? 'quiz',
          questionCount: data['questionCount'] ?? 0,
          correctCount: data['correctCount'] ?? 0,
          scorePercentage: data['scorePercentage'] ?? 0,
          xpEarned: data['xpEarned'] ?? 0,
          durationSeconds: data['durationSeconds'] ?? 0,
          playedAt: playedAt,
          answers: (data['answers'] as List<dynamic>?)
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
      }).toList();
    });
  }
}

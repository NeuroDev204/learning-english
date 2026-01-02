import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lấy leaderboard theo criteria và period
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardCriteria criteria,
    required LeaderboardPeriod period,
    int limit = 100,
  }) async {
    try {
      final usersSnapshot =
          await _firestore.collection('users').limit(limit).get();

      final now = DateTime.now();

      // Sửa: Tính weekStart từ thứ 2 đầu tuần
      final todayStart = DateTime(now.year, now.month, now.day);
      final daysFromMonday = (now.weekday - 1) % 7;
      final weekStart = todayStart.subtract(Duration(days: daysFromMonday));

      final monthStart = DateTime(now.year, now.month, 1);

      final List<LeaderboardEntry> entries = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        // Lấy thông tin cơ bản
        final displayName = userData['displayName'] ?? 'Unknown';
        final photoUrl = userData['photoUrl'];
        final profile = userData['profile'] as Map<String, dynamic>?;
        final longestStreak = (profile?['longestStreak'] as int?) ?? 0;

        // Tính số quiz hoàn thành và điểm trung bình
        final sessionsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('quiz_sessions')
            .get();

        // Biến tính toán cộng dồn từ sessions
        int tXP = 0, tCorrect = 0, tQuestions = 0, tQuizzes = 0;
        int wXP = 0, wCorrect = 0, wQuestions = 0, wQuizzes = 0;
        int mXP = 0, mCorrect = 0, mQuestions = 0, mQuizzes = 0;

        final Set<String> tDays = {};
        final Set<String> wDays = {};
        final Set<String> mDays = {};

        for (final sessionDoc in sessionsSnapshot.docs) {
          final sessionData = sessionDoc.data();
          final playedAtField = sessionData['playedAt'];
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

          final xpEarned = (sessionData['xpEarned'] as int?) ?? 0;
          final correct = (sessionData['correctCount'] as int?) ?? 0;
          final total = (sessionData['questionCount'] as int?) ?? 0;

          final sessionDate = DateTime(
            playedAt.year,
            playedAt.month,
            playedAt.day,
          );
          final dayKey = '${playedAt.year}-${playedAt.month}-${playedAt.day}';

          // 1. TÍNH CHO TẤT CẢ (All Time) - Sửa lỗi sai lệch dữ liệu
          tXP += xpEarned;
          tQuizzes++;
          tCorrect += correct;
          tQuestions += total;
          tDays.add(dayKey);

          // 2. TÍNH CHO TUẦN
          if (sessionDate.isAtSameMomentAs(weekStart) ||
              sessionDate.isAfter(weekStart)) {
            wXP += xpEarned;
            wQuizzes++;
            wCorrect += correct;
            wQuestions += total;
            wDays.add(dayKey);
          }

          // 3. TÍNH CHO THÁNG
          if (sessionDate.isAtSameMomentAs(monthStart) ||
              sessionDate.isAfter(monthStart)) {
            mXP += xpEarned;
            mQuizzes++;
            mCorrect += correct;
            mQuestions += total;
            mDays.add(dayKey);
          }
        }

        // Tính toán Streak (Chuỗi liên tiếp) thực tế từ lịch sử sessions
        // Đảm bảo tính chính xác: phải là các ngày liên tiếp
        int dynamicStreak = 0;
        DateTime cursor = DateTime(now.year, now.month, now.day);
        String cursorKey = '${cursor.year}-${cursor.month}-${cursor.day}';

        // Kiểm tra hôm nay hoặc hôm qua có học không
        if (!tDays.contains(cursorKey)) {
          cursor = cursor.subtract(const Duration(days: 1));
          cursorKey = '${cursor.year}-${cursor.month}-${cursor.day}';
        }

        // Đếm ngược các ngày liên tiếp
        while (tDays.contains(cursorKey)) {
          dynamicStreak++;
          cursor = cursor.subtract(const Duration(days: 1));
          cursorKey = '${cursor.year}-${cursor.month}-${cursor.day}';
        }

        // Xác định giá trị hiển thị dựa trên Period người dùng chọn
        double currentAvgScore = 0;
        int currentQuizzes = 0;

        if (period == LeaderboardPeriod.weekly) {
          currentAvgScore =
              wQuestions > 0 ? (wCorrect / wQuestions * 100) : 0.0;
          currentQuizzes = wQuizzes;
        } else if (period == LeaderboardPeriod.monthly) {
          currentAvgScore =
              mQuestions > 0 ? (mCorrect / mQuestions * 100) : 0.0;
          currentQuizzes = mQuizzes;
        } else {
          // All Time
          currentAvgScore =
              tQuestions > 0 ? (tCorrect / tQuestions * 100) : 0.0;
          currentQuizzes = tQuizzes;
        }

        entries.add(LeaderboardEntry(
          userId: userId,
          displayName: displayName,
          photoUrl: photoUrl,
          totalXP: tXP, // Lấy từ calculation thay vì profile
          currentStreak: dynamicStreak, // Sử dụng streak tính toán từ sessions
          longestStreak: longestStreak,
          completedQuizzes: currentQuizzes,
          averageScore: currentAvgScore,
          rank: 0, // Sẽ được set sau khi sort
          weeklyXP: wXP,
          monthlyXP: mXP,
          weeklyStreakDays: wDays.length,
          monthlyStreakDays: mDays.length,
        ));
      }

      // Sắp xếp theo criteria và period
      entries.sort((a, b) {
        double scoreA = _getRankingScore(a, criteria, period);
        double scoreB = _getRankingScore(b, criteria, period);
        return scoreB.compareTo(scoreA); // Giảm dần
      });

      // Set rank
      for (int i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          userId: entries[i].userId,
          displayName: entries[i].displayName,
          photoUrl: entries[i].photoUrl,
          totalXP: entries[i].totalXP,
          currentStreak: entries[i].currentStreak,
          longestStreak: entries[i].longestStreak,
          completedQuizzes: entries[i].completedQuizzes,
          averageScore: entries[i].averageScore,
          rank: i + 1,
          weeklyXP: entries[i].weeklyXP,
          monthlyXP: entries[i].monthlyXP,
          weeklyStreakDays: entries[i].weeklyStreakDays,
          monthlyStreakDays: entries[i].monthlyStreakDays,
        );
      }

      return entries;
    } catch (e) {
      debugPrint('Lỗi khi lấy leaderboard: $e');
      rethrow;
    }
  }

  /// Lấy điểm số để xếp hạng dựa trên criteria và period
  double _getRankingScore(
    LeaderboardEntry entry,
    LeaderboardCriteria criteria,
    LeaderboardPeriod period,
  ) {
    switch (criteria) {
      case LeaderboardCriteria.totalXP:
        if (period == LeaderboardPeriod.weekly)
          return entry.weeklyXP.toDouble();
        if (period == LeaderboardPeriod.monthly)
          return entry.monthlyXP.toDouble();
        return entry.totalXP.toDouble();

      case LeaderboardCriteria.weeklyXP:
        return entry.weeklyXP.toDouble();

      case LeaderboardCriteria.monthlyXP:
        return entry.monthlyXP.toDouble();

      case LeaderboardCriteria.streak:
        if (period == LeaderboardPeriod.weekly)
          return entry.weeklyStreakDays.toDouble();
        if (period == LeaderboardPeriod.monthly)
          return entry.monthlyStreakDays.toDouble();
        return entry.currentStreak.toDouble();

      case LeaderboardCriteria.weeklyStreak:
        return entry.weeklyStreakDays.toDouble();

      case LeaderboardCriteria.monthlyStreak:
        return entry.monthlyStreakDays.toDouble();

      case LeaderboardCriteria.completedQuizzes:
        return entry.completedQuizzes.toDouble();

      case LeaderboardCriteria.averageScore:
        return entry.averageScore;
    }
  }

  /// Lấy giá trị hiển thị dựa trên criteria và period
  String getDisplayValue(
    LeaderboardEntry entry,
    LeaderboardCriteria criteria,
    LeaderboardPeriod period,
  ) {
    switch (criteria) {
      case LeaderboardCriteria.totalXP:
        if (period == LeaderboardPeriod.weekly) return '${entry.weeklyXP} XP';
        if (period == LeaderboardPeriod.monthly) return '${entry.monthlyXP} XP';
        return '${entry.totalXP} XP';
      case LeaderboardCriteria.weeklyXP:
        return '${entry.weeklyXP} XP';
      case LeaderboardCriteria.monthlyXP:
        return '${entry.monthlyXP} XP';
      case LeaderboardCriteria.streak:
        if (period == LeaderboardPeriod.weekly)
          return '${entry.weeklyStreakDays} ngày học';
        if (period == LeaderboardPeriod.monthly)
          return '${entry.monthlyStreakDays} ngày học';
        return '${entry.currentStreak} ngày liên tiếp';
      case LeaderboardCriteria.weeklyStreak:
        return '${entry.weeklyStreakDays} ngày';
      case LeaderboardCriteria.monthlyStreak:
        return '${entry.monthlyStreakDays} ngày';
      case LeaderboardCriteria.completedQuizzes:
        return '${entry.completedQuizzes} bài';
      case LeaderboardCriteria.averageScore:
        return '${entry.averageScore.toStringAsFixed(1)}%';
    }
  }

  /// Lấy label cho criteria
  String getCriteriaLabel(LeaderboardCriteria criteria) {
    switch (criteria) {
      case LeaderboardCriteria.totalXP:
        return 'Tổng XP';
      case LeaderboardCriteria.weeklyXP:
        return 'XP Tuần';
      case LeaderboardCriteria.monthlyXP:
        return 'XP Tháng';
      case LeaderboardCriteria.streak:
        return 'Chuỗi ngày';
      case LeaderboardCriteria.weeklyStreak:
        return 'Ngày học (Tuần)';
      case LeaderboardCriteria.monthlyStreak:
        return 'Ngày học (Tháng)';
      case LeaderboardCriteria.completedQuizzes:
        return 'Số bài làm';
      case LeaderboardCriteria.averageScore:
        return 'Điểm TB';
    }
  }

  /// Lấy vị trí của user hiện tại
  Future<LeaderboardEntry?> getCurrentUserRank({
    required LeaderboardCriteria criteria,
    required LeaderboardPeriod period,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return null;

    final leaderboard = await getLeaderboard(
      criteria: criteria,
      period: period,
    );

    try {
      return leaderboard.firstWhere(
        (entry) => entry.userId == currentUserId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Stream leaderboard (real-time updates)
  Stream<List<LeaderboardEntry>> watchLeaderboard({
    required LeaderboardCriteria criteria,
    required LeaderboardPeriod period,
    int limit = 100,
  }) {
    return _firestore
        .collection('users')
        .snapshots()
        .asyncMap((_) => getLeaderboard(
              criteria: criteria,
              period: period,
              limit: limit,
            ));
  }
}

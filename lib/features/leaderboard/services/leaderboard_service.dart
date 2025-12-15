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
      final usersSnapshot = await _firestore
          .collection('users')
          .limit(limit)
          .get();

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
        final totalXP = (userData['totalXP'] as int?) ?? 0;
        final currentStreak = (userData['currentStreak'] as int?) ?? 0;
        final longestStreak = (userData['longestStreak'] as int?) ?? 0;

        // Tính số quiz hoàn thành và điểm trung bình
        final sessionsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('quiz_sessions')
            .get();

        int completedQuizzes = sessionsSnapshot.docs.length;
        int totalScore = 0;
        int weeklyXP = 0;
        int monthlyXP = 0;
        final Set<String> weeklyDays = {};
        final Set<String> monthlyDays = {};

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

          final scorePercentage = (sessionData['scorePercentage'] as int?) ?? 0;
          final xpEarned = (sessionData['xpEarned'] as int?) ?? 0;

          totalScore += scorePercentage;

          // Sửa: Tính XP và streak days theo tuần/tháng với logic đúng
          final sessionDate = DateTime(
            playedAt.year,
            playedAt.month,
            playedAt.day,
          );

          if (sessionDate.isAtSameMomentAs(weekStart) || sessionDate.isAfter(weekStart)) {
            weeklyXP += xpEarned;
            final dayKey = '${playedAt.year}-${playedAt.month}-${playedAt.day}';
            weeklyDays.add(dayKey);
          }
          if (sessionDate.isAtSameMomentAs(monthStart) || sessionDate.isAfter(monthStart)) {
            monthlyXP += xpEarned;
            final dayKey = '${playedAt.year}-${playedAt.month}-${playedAt.day}';
            monthlyDays.add(dayKey);
          }
        }

        final averageScore = completedQuizzes > 0
            ? (totalScore / completedQuizzes)
            : 0.0;

        entries.add(LeaderboardEntry(
          userId: userId,
          displayName: displayName,
          photoUrl: photoUrl,
          totalXP: totalXP,
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          completedQuizzes: completedQuizzes,
          averageScore: averageScore,
          rank: 0, // Sẽ được set sau khi sort
          weeklyXP: weeklyXP,
          monthlyXP: monthlyXP,
          weeklyStreakDays: weeklyDays.length,
          monthlyStreakDays: monthlyDays.length,
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
        return entry.totalXP.toDouble();
      
      case LeaderboardCriteria.weeklyXP:
        return entry.weeklyXP.toDouble();
      
      case LeaderboardCriteria.monthlyXP:
        return entry.monthlyXP.toDouble();
      
      case LeaderboardCriteria.streak:
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
        return '${entry.totalXP} XP';
      case LeaderboardCriteria.weeklyXP:
        return '${entry.weeklyXP} XP';
      case LeaderboardCriteria.monthlyXP:
        return '${entry.monthlyXP} XP';
      case LeaderboardCriteria.streak:
        return '${entry.currentStreak} ngày';
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
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final int completedQuizzes;
  final double averageScore;
  final int rank;
  
  // XP theo period
  final int weeklyXP;
  final int monthlyXP;
  
  // Streak theo period (số ngày học trong tuần/tháng)
  final int weeklyStreakDays;
  final int monthlyStreakDays;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.totalXP,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedQuizzes,
    required this.averageScore,
    required this.rank,
    required this.weeklyXP,
    required this.monthlyXP,
    required this.weeklyStreakDays,
    required this.monthlyStreakDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'completedQuizzes': completedQuizzes,
      'averageScore': averageScore,
      'rank': rank,
      'weeklyXP': weeklyXP,
      'monthlyXP': monthlyXP,
      'weeklyStreakDays': weeklyStreakDays,
      'monthlyStreakDays': monthlyStreakDays,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Unknown',
      photoUrl: map['photoUrl'],
      totalXP: map['totalXP'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      completedQuizzes: map['completedQuizzes'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      rank: map['rank'] ?? 0,
      weeklyXP: map['weeklyXP'] ?? 0,
      monthlyXP: map['monthlyXP'] ?? 0,
      weeklyStreakDays: map['weeklyStreakDays'] ?? 0,
      monthlyStreakDays: map['monthlyStreakDays'] ?? 0,
    );
  }
}

enum LeaderboardPeriod {
  allTime,
  weekly,
  monthly,
}

enum LeaderboardCriteria {
  totalXP,        // Tổng XP
  weeklyXP,       // XP tuần này
  monthlyXP,      // XP tháng này
  streak,          // Chuỗi ngày học hiện tại
  weeklyStreak,    // Số ngày học trong tuần
  monthlyStreak,   // Số ngày học trong tháng
  completedQuizzes, // Số quiz hoàn thành
  averageScore,    // Điểm trung bình
}
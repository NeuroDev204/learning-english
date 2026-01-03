class DashboardStats {
  final int wordsLearnedToday;
  final int wordsLearnedThisWeek;
  final int wordsLearnedThisMonth;
  final int currentStreak;
  final int totalXP;
  final double averageAccuracy;
  final int totalSessions;
  final DateTime lastUpdated;
  final int weeklyStreakDays;
  final int monthlyStreakDays;

  DashboardStats({
    required this.wordsLearnedToday,
    required this.wordsLearnedThisWeek,
    required this.wordsLearnedThisMonth,
    required this.currentStreak,
    required this.totalXP,
    required this.averageAccuracy,
    required this.totalSessions,
    required this.lastUpdated,
    this.weeklyStreakDays = 0,
    this.monthlyStreakDays = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'wordsLearnedToday': wordsLearnedToday,
      'wordsLearnedThisWeek': wordsLearnedThisWeek,
      'wordsLearnedThisMonth': wordsLearnedThisMonth,
      'currentStreak': currentStreak,
      'totalXP': totalXP,
      'averageAccuracy': averageAccuracy,
      'totalSessions': totalSessions,
      'lastUpdated': lastUpdated.toIso8601String(),
      'weeklyStreakDays': weeklyStreakDays,
      'monthlyStreakDays': monthlyStreakDays,
    };
  }

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      wordsLearnedToday: map['wordsLearnedToday'] ?? 0,
      wordsLearnedThisWeek: map['wordsLearnedThisWeek'] ?? 0,
      wordsLearnedThisMonth: map['wordsLearnedThisMonth'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      totalXP: map['totalXP'] ?? 0,
      averageAccuracy: (map['averageAccuracy'] ?? 0.0).toDouble(),
      totalSessions: map['totalSessions'] ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
      weeklyStreakDays: map['weeklyStreakDays'] ?? 0,
      monthlyStreakDays: map['monthlyStreakDays'] ?? 0,
    );
  }
}

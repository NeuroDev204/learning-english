class ChartDataPoint {
  final DateTime date;
  final int xp;
  final int wordsLearned;
  final double accuracy;

  ChartDataPoint({
    required this.date,
    required this.xp,
    required this.wordsLearned,
    required this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'xp': xp,
      'wordsLearned': wordsLearned,
      'accuracy': accuracy,
    };
  }

  factory ChartDataPoint.fromMap(Map<String, dynamic> map) {
    return ChartDataPoint(
      date: DateTime.parse(map['date']),
      xp: map['xp'] ?? 0,
      wordsLearned: map['wordsLearned'] ?? 0,
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
    );
  }
}
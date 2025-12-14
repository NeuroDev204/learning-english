/// Model tóm tắt kết quả quiz – dùng để hiển thị và lưu trữ
class QuizResult {
  final String topicId;
  final String topicName;
  final int totalQuestions;
  final int correctAnswers;
  final int scorePercentage;
  final int xpEarned;
  final int durationSeconds;
  final DateTime completedAt;
  final String mode; // "quiz" hoặc "flashcard"

  QuizResult({
    required this.topicId,
    required this.topicName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.xpEarned,
    required this.durationSeconds,
    required this.completedAt,
    this.mode = 'quiz',
  });

  /// Chuyển thành Map để lưu Firestore (nếu cần lưu riêng)
  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'scorePercentage': scorePercentage,
      'xpEarned': xpEarned,
      'durationSeconds': durationSeconds,
      'completedAt': completedAt.toIso8601String(),
      'mode': mode,
    };
  }

  /// Tạo từ Map
  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      topicId: map['topicId'] ?? '',
      topicName: map['topicName'] ?? 'Unknown Topic',
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      scorePercentage: map['scorePercentage'] ?? 0,
      xpEarned: map['xpEarned'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 0,
      completedAt: DateTime.parse(
        map['completedAt'] ?? DateTime.now().toIso8601String(),
      ),
      mode: map['mode'] ?? 'quiz',
    );
  }

  /// Tính level up (ví dụ cho Dashboard sau này)
  String get performanceMessage {
    if (scorePercentage >= 90) return 'Xuất sắc!';
    if (scorePercentage >= 70) return 'Rất tốt!';
    if (scorePercentage >= 50) return 'Khá tốt';
    return 'Cần cố gắng hơn nhé!';
  }

  /// Gợi ý ôn tập
  bool get shouldReview => scorePercentage < 70;
}

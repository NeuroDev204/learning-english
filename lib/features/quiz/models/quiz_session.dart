class QuizSession {
  final String topicId;
  final String topicName;
  final String mode; // "quiz" hoặc "flashcard"
  final int questionCount;
  final int correctCount;
  final int scorePercentage;
  final int xpEarned;
  final int durationSeconds;
  final DateTime playedAt;
  final List<QuizAnswer> answers;

  QuizSession({
    required this.topicId,
    required this.topicName,
    required this.mode,
    required this.questionCount,
    required this.correctCount,
    required this.scorePercentage,
    required this.xpEarned,
    required this.durationSeconds,
    required this.playedAt,
    required this.answers,
  });

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'mode': mode,
      'questionCount': questionCount,
      'correctCount': correctCount,
      'scorePercentage': scorePercentage,
      'xpEarned': xpEarned,
      'durationSeconds': durationSeconds,
      'playedAt': playedAt.toIso8601String(),
      'answers': answers.map((a) => a.toMap()).toList(),
    };
  }
}

class QuizAnswer {
  final String vocabularyId;
  final String word;
  final String userAnswer;
  final bool isCorrect;
  final double timeSpent;

  QuizAnswer({
    required this.vocabularyId,
    required this.word,
    required this.userAnswer,
    required this.isCorrect,
    required this.timeSpent,
  });

  Map<String, dynamic> toMap() => {
    'vocabularyId': vocabularyId,
    'word': word,
    'userAnswer': userAnswer,
    'isCorrect': isCorrect,
    'timeSpent': timeSpent,
  };
}

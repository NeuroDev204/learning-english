import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';

/// Model cho một đề thi
class Exam {
  final String id;
  final String title;                    // Tiêu đề đề thi
  final String sourceContent;            // Nội dung file gốc đã trích xuất
  final String sourceFileName;           // Tên file gốc
  final List<Question> questions;        // Danh sách câu hỏi
  final int durationMinutes;             // Thời gian làm bài (phút)
  final DateTime createdAt;              // Thời gian tạo

  Exam({
    required this.id,
    required this.title,
    required this.sourceContent,
    required this.sourceFileName,
    required this.questions,
    required this.durationMinutes,
    required this.createdAt,
  });

  /// Số lượng câu hỏi
  int get questionCount => questions.length;

  /// Số câu hỏi theo từng loại
  Map<QuestionType, int> get questionCountByType {
    final counts = <QuestionType, int>{};
    for (final q in questions) {
      counts[q.type] = (counts[q.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Chuyển đổi sang Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'sourceContent': sourceContent,
      'sourceFileName': sourceFileName,
      'questions': questions.map((q) => q.toMap()).toList(),
      'durationMinutes': durationMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Tạo Exam từ Map (Firestore data)
  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Exam',
      sourceContent: map['sourceContent'] ?? '',
      sourceFileName: map['sourceFileName'] ?? '',
      questions: (map['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      durationMinutes: map['durationMinutes'] ?? 15,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Tạo Exam từ Firestore DocumentSnapshot
  factory Exam.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exam.fromMap({...data, 'id': doc.id});
  }

  /// Copy with để tạo bản sao với thay đổi
  Exam copyWith({
    String? id,
    String? title,
    String? sourceContent,
    String? sourceFileName,
    List<Question>? questions,
    int? durationMinutes,
    DateTime? createdAt,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceContent: sourceContent ?? this.sourceContent,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      questions: questions ?? this.questions,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Exam(id: $id, title: $title, questions: ${questions.length}, duration: ${durationMinutes}min)';
  }
}

/// Model cho kết quả làm bài
class ExamResult {
  final String id;
  final String examId;
  final String examTitle;
  final String userId;
  final List<int> userAnswers;           // Đáp án người dùng chọn (-1 nếu chưa trả lời)
  final List<int> correctAnswers;        // Đáp án đúng
  final int score;                       // Số câu đúng
  final int totalQuestions;              // Tổng số câu hỏi
  final int durationSeconds;             // Thời gian làm bài thực tế (giây)
  final int allowedDurationMinutes;      // Thời gian cho phép (phút)
  final DateTime submittedAt;            // Thời gian nộp bài

  ExamResult({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.userId,
    required this.userAnswers,
    required this.correctAnswers,
    required this.score,
    required this.totalQuestions,
    required this.durationSeconds,
    required this.allowedDurationMinutes,
    required this.submittedAt,
  });

  /// Tỷ lệ đúng (0.0 - 1.0)
  double get scorePercentage {
    if (totalQuestions == 0) return 0.0;
    return score / totalQuestions;
  }

  /// Điểm số hiển thị (dạng 8.5/10)
  String get displayScore {
    final point = (scorePercentage * 10).toStringAsFixed(1);
    return '$point/10';
  }

  /// Số câu sai
  int get wrongCount => totalQuestions - score - unansweredCount;

  /// Số câu chưa trả lời
  int get unansweredCount {
    return userAnswers.where((a) => a == -1).length;
  }

  /// Thời gian làm bài formatted (mm:ss)
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Kiểm tra câu hỏi có đúng không
  bool isQuestionCorrect(int questionIndex) {
    if (questionIndex < 0 || questionIndex >= userAnswers.length) return false;
    return userAnswers[questionIndex] == correctAnswers[questionIndex];
  }

  /// Kiểm tra câu hỏi chưa trả lời
  bool isQuestionUnanswered(int questionIndex) {
    if (questionIndex < 0 || questionIndex >= userAnswers.length) return true;
    return userAnswers[questionIndex] == -1;
  }

  /// Chuyển đổi sang Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'examTitle': examTitle,
      'userId': userId,
      'userAnswers': userAnswers,
      'correctAnswers': correctAnswers,
      'score': score,
      'totalQuestions': totalQuestions,
      'durationSeconds': durationSeconds,
      'allowedDurationMinutes': allowedDurationMinutes,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  /// Tạo ExamResult từ Map (Firestore data)
  factory ExamResult.fromMap(Map<String, dynamic> map) {
    return ExamResult(
      id: map['id'] ?? '',
      examId: map['examId'] ?? '',
      examTitle: map['examTitle'] ?? 'Untitled Exam',
      userId: map['userId'] ?? '',
      userAnswers: List<int>.from(map['userAnswers'] ?? []),
      correctAnswers: List<int>.from(map['correctAnswers'] ?? []),
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 0,
      allowedDurationMinutes: map['allowedDurationMinutes'] ?? 15,
      submittedAt: map['submittedAt'] != null
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Tạo ExamResult từ Firestore DocumentSnapshot
  factory ExamResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamResult.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'ExamResult(id: $id, score: $score/$totalQuestions, duration: $formattedDuration)';
  }
}

/// Helper class cho exam duration options
class ExamDurationOption {
  final int minutes;
  final String label;
  final String description;

  const ExamDurationOption({
    required this.minutes,
    required this.label,
    required this.description,
  });

  /// Các option thời gian có sẵn
  static const List<ExamDurationOption> options = [
    ExamDurationOption(
      minutes: 10,
      label: '10 phút',
      description: 'Nhanh - Phù hợp ôn tập nhanh',
    ),
    ExamDurationOption(
      minutes: 15,
      label: '15 phút',
      description: 'Tiêu chuẩn - Phù hợp cho đề ngắn',
    ),
    ExamDurationOption(
      minutes: 30,
      label: '30 phút',
      description: 'Trung bình - Đủ thời gian suy nghĩ',
    ),
    ExamDurationOption(
      minutes: 45,
      label: '45 phút',
      description: 'Dài - Cho đề thi đầy đủ',
    ),
  ];
}

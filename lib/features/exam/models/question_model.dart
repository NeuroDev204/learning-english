import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum định nghĩa các loại câu hỏi trong đề thi
enum QuestionType {
  vocabulary,           // Câu hỏi từ vựng - chọn nghĩa đúng
  readingComprehension, // Đọc hiểu đoạn văn
  fillInBlanks,        // Điền từ vào chỗ trống
  trueFalse,           // Đúng / Sai
}

/// Extension để lấy thông tin display cho QuestionType
extension QuestionTypeExtension on QuestionType {
  /// Lấy tên hiển thị tiếng Việt
  String get displayName {
    switch (this) {
      case QuestionType.vocabulary:
        return 'Từ vựng';
      case QuestionType.readingComprehension:
        return 'Đọc hiểu';
      case QuestionType.fillInBlanks:
        return 'Điền từ';
      case QuestionType.trueFalse:
        return 'Đúng/Sai';
    }
  }

  /// Lấy tên hiển thị tiếng Anh
  String get displayNameEn {
    switch (this) {
      case QuestionType.vocabulary:
        return 'Vocabulary';
      case QuestionType.readingComprehension:
        return 'Reading Comprehension';
      case QuestionType.fillInBlanks:
        return 'Fill in the Blanks';
      case QuestionType.trueFalse:
        return 'True/False';
    }
  }

  /// Lấy icon cho loại câu hỏi
  String get icon {
    switch (this) {
      case QuestionType.vocabulary:
        return '📝';
      case QuestionType.readingComprehension:
        return '📖';
      case QuestionType.fillInBlanks:
        return '✏️';
      case QuestionType.trueFalse:
        return '✓✗';
    }
  }

  /// Lấy màu cho loại câu hỏi (hex value)
  int get colorValue {
    switch (this) {
      case QuestionType.vocabulary:
        return 0xFF5EB1FF; // Blue
      case QuestionType.readingComprehension:
        return 0xFFA78BFA; // Purple
      case QuestionType.fillInBlanks:
        return 0xFFFFD93D; // Yellow
      case QuestionType.trueFalse:
        return 0xFF4ADE80; // Green
    }
  }
}

/// Model cho một câu hỏi trong đề thi
class Question {
  final String id;
  final QuestionType type;
  final String question;           // Nội dung câu hỏi
  final List<String> options;      // Các đáp án (A, B, C, D)
  final int correctAnswerIndex;    // Index của đáp án đúng (0-3)
  final String? passage;           // Đoạn văn (cho Reading Comprehension)
  final String? explanation;       // Giải thích đáp án
  final String? blankSentence;     // Câu có chỗ trống (cho Fill in Blanks)

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.passage,
    this.explanation,
    this.blankSentence,
  });

  /// Lấy ký tự đáp án đúng (A, B, C, D)
  String get correctAnswerLetter {
    const letters = ['A', 'B', 'C', 'D'];
    if (correctAnswerIndex >= 0 && correctAnswerIndex < letters.length) {
      return letters[correctAnswerIndex];
    }
    return 'A';
  }

  /// Lấy nội dung đáp án đúng
  String get correctAnswer {
    if (correctAnswerIndex >= 0 && correctAnswerIndex < options.length) {
      return options[correctAnswerIndex];
    }
    return '';
  }

  /// Kiểm tra đáp án người dùng có đúng không
  bool isCorrect(int userAnswerIndex) {
    return userAnswerIndex == correctAnswerIndex;
  }

  /// Chuyển đổi sang Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'passage': passage,
      'explanation': explanation,
      'blankSentence': blankSentence,
    };
  }

  /// Tạo Question từ Map (Firestore data)
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      type: QuestionType.values[map['type'] ?? 0],
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      passage: map['passage'],
      explanation: map['explanation'],
      blankSentence: map['blankSentence'],
    );
  }

  /// Tạo Question từ Firestore DocumentSnapshot
  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question.fromMap({...data, 'id': doc.id});
  }

  /// Copy with để tạo bản sao với thay đổi
  Question copyWith({
    String? id,
    QuestionType? type,
    String? question,
    List<String>? options,
    int? correctAnswerIndex,
    String? passage,
    String? explanation,
    String? blankSentence,
  }) {
    return Question(
      id: id ?? this.id,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      passage: passage ?? this.passage,
      explanation: explanation ?? this.explanation,
      blankSentence: blankSentence ?? this.blankSentence,
    );
  }

  @override
  String toString() {
    return 'Question(id: $id, type: ${type.displayNameEn}, question: $question)';
  }
}

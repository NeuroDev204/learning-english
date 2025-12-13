import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';

/// Service để lưu trữ và truy xuất dữ liệu exam từ Firebase Firestore
///
/// Cấu trúc Firestore:
/// users/{uid}/exams/{examId}
///   ├── title: String
///   ├── sourceContent: String
///   ├── sourceFileName: String
///   ├── questions: List<Map>
///   ├── durationMinutes: int
///   ├── createdAt: Timestamp
///   └── results/{resultId}
///         ├── userAnswers: List<int>
///         ├── correctAnswers: List<int>
///         ├── score: int
///         ├── totalQuestions: int
///         ├── durationSeconds: int
///         └── submittedAt: Timestamp
class FirebaseExamService {
  /// Singleton pattern
  static final FirebaseExamService _instance = FirebaseExamService._internal();
  factory FirebaseExamService() => _instance;
  FirebaseExamService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lấy current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Kiểm tra user đã đăng nhập chưa
  void _checkAuth() {
    if (_currentUserId == null) {
      throw FirebaseExamException(
        'Vui lòng đăng nhập để sử dụng tính năng này',
      );
    }
  }

  /// Reference đến collection exams của user hiện tại
  CollectionReference<Map<String, dynamic>> get _examsCollection {
    _checkAuth();
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('exams');
  }

  // =============== EXAM OPERATIONS ===============

  /// Lưu đề thi mới vào Firestore
  /// Trả về exam ID đã lưu
  Future<String> saveExam(Exam exam) async {
    try {
      _checkAuth();

      final docRef = _examsCollection.doc(exam.id);
      await docRef.set(exam.toMap());

      return exam.id;
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể lưu đề thi: $e');
    }
  }

  /// Lấy đề thi theo ID
  Future<Exam?> getExam(String examId) async {
    try {
      _checkAuth();

      final doc = await _examsCollection.doc(examId).get();

      if (!doc.exists) return null;

      return Exam.fromFirestore(doc);
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể tải đề thi: $e');
    }
  }

  /// Lấy tất cả đề thi của user
  Future<List<Exam>> getAllExams() async {
    try {
      _checkAuth();

      final querySnapshot = await _examsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Exam.fromFirestore(doc)).toList();
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể tải danh sách đề thi: $e');
    }
  }

  /// Xóa đề thi
  Future<void> deleteExam(String examId) async {
    try {
      _checkAuth();

      // Xóa tất cả results của exam trước
      final resultsSnapshot = await _examsCollection
          .doc(examId)
          .collection('results')
          .get();

      final batch = _firestore.batch();
      for (final doc in resultsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Xóa exam
      batch.delete(_examsCollection.doc(examId));

      await batch.commit();
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể xóa đề thi: $e');
    }
  }

  // =============== RESULT OPERATIONS ===============

  /// Lưu kết quả làm bài
  Future<String> saveExamResult(ExamResult result) async {
    try {
      _checkAuth();

      final docRef = _examsCollection
          .doc(result.examId)
          .collection('results')
          .doc(result.id);

      await docRef.set(result.toMap());

      return result.id;
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể lưu kết quả: $e');
    }
  }

  /// Lấy tất cả kết quả của một đề thi
  Future<List<ExamResult>> getExamResults(String examId) async {
    try {
      _checkAuth();

      final querySnapshot = await _examsCollection
          .doc(examId)
          .collection('results')
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể tải kết quả: $e');
    }
  }

  /// Lấy kết quả mới nhất của một đề thi
  Future<ExamResult?> getLatestExamResult(String examId) async {
    try {
      _checkAuth();

      final querySnapshot = await _examsCollection
          .doc(examId)
          .collection('results')
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return ExamResult.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể tải kết quả: $e');
    }
  }

  /// Lấy tất cả kết quả của user (từ tất cả các exam)
  Future<List<ExamResult>> getAllResults() async {
    try {
      _checkAuth();

      final exams = await getAllExams();
      final allResults = <ExamResult>[];

      for (final exam in exams) {
        final results = await getExamResults(exam.id);
        allResults.addAll(results);
      }

      // Sort by submittedAt descending
      allResults.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      return allResults;
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể tải lịch sử: $e');
    }
  }

  /// Xóa kết quả
  Future<void> deleteResult(String examId, String resultId) async {
    try {
      _checkAuth();

      await _examsCollection
          .doc(examId)
          .collection('results')
          .doc(resultId)
          .delete();
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể xóa kết quả: $e');
    }
  }

  // =============== STATISTICS ===============

  /// Lấy thống kê tổng quan của user
  Future<ExamStatistics> getStatistics() async {
    try {
      _checkAuth();

      final exams = await getAllExams();
      final results = await getAllResults();

      if (results.isEmpty) {
        return ExamStatistics(
          totalExams: exams.length,
          totalAttempts: 0,
          averageScore: 0,
          bestScore: 0,
          totalTimeSpent: 0,
          questionsByType: {},
        );
      }

      // Tính toán thống kê
      final scores = results.map((r) => r.scorePercentage).toList();
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      final bestScore = scores.reduce((a, b) => a > b ? a : b);
      final totalTime = results.fold<int>(
        0,
        (sum, r) => sum + r.durationSeconds,
      );

      // Đếm câu hỏi theo loại
      final questionsByType = <QuestionType, int>{};
      for (final exam in exams) {
        for (final q in exam.questions) {
          questionsByType[q.type] = (questionsByType[q.type] ?? 0) + 1;
        }
      }

      return ExamStatistics(
        totalExams: exams.length,
        totalAttempts: results.length,
        averageScore: avgScore,
        bestScore: bestScore,
        totalTimeSpent: totalTime,
        questionsByType: questionsByType,
      );
    } catch (e) {
      if (e is FirebaseExamException) rethrow;
      throw FirebaseExamException('Không thể tải thống kê: $e');
    }
  }

  // =============== STREAM OPERATIONS ===============

  /// Stream để lắng nghe thay đổi danh sách exam
  Stream<List<Exam>> watchExams() {
    _checkAuth();

    return _examsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Exam.fromFirestore(doc)).toList(),
        );
  }

  /// Stream để lắng nghe thay đổi kết quả của một exam
  Stream<List<ExamResult>> watchExamResults(String examId) {
    _checkAuth();

    return _examsCollection
        .doc(examId)
        .collection('results')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExamResult.fromFirestore(doc))
              .toList(),
        );
  }
}

/// Model cho thống kê exam
class ExamStatistics {
  final int totalExams;
  final int totalAttempts;
  final double averageScore; // 0.0 - 1.0
  final double bestScore; // 0.0 - 1.0
  final int totalTimeSpent; // seconds
  final Map<QuestionType, int> questionsByType;

  ExamStatistics({
    required this.totalExams,
    required this.totalAttempts,
    required this.averageScore,
    required this.bestScore,
    required this.totalTimeSpent,
    required this.questionsByType,
  });

  /// Thời gian làm bài formatted
  String get formattedTotalTime {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} phút';
  }

  /// Điểm trung bình formatted
  String get formattedAverageScore {
    return '${(averageScore * 10).toStringAsFixed(1)}/10';
  }

  /// Điểm cao nhất formatted
  String get formattedBestScore {
    return '${(bestScore * 10).toStringAsFixed(1)}/10';
  }
}

/// Exception class cho Firebase Exam errors
class FirebaseExamException implements Exception {
  final String message;

  FirebaseExamException(this.message);

  @override
  String toString() => 'FirebaseExamException: $message';
}

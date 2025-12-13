import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../services/file_import_service.dart';
import '../services/exam_generator_service.dart';
import '../services/firebase_exam_service.dart';

/// Provider quản lý state chính cho exam flow
///
/// Flow sử dụng:
/// 1. importFile() - Chọn và import file
/// 2. generateExam() - Tạo đề thi từ nội dung
/// 3. startExam() - Bắt đầu làm bài
/// 4. selectAnswer() - Chọn đáp án
/// 5. submitExam() - Nộp bài và tính điểm
/// 6. saveResult() - Lưu kết quả vào Firebase
class ExamProvider extends ChangeNotifier {
  final FileImportService _fileImportService = FileImportService();
  final ExamGeneratorService _examGeneratorService = ExamGeneratorService();
  final FirebaseExamService _firebaseService = FirebaseExamService();
  final _uuid = const Uuid();

  // =============== FILE IMPORT STATE ===============

  PlatformFile? _selectedFile;
  String? _extractedContent;
  Map<String, int>? _contentStats;
  bool _isExtracting = false;
  String? _extractError;

  PlatformFile? get selectedFile => _selectedFile;
  String? get extractedContent => _extractedContent;
  Map<String, int>? get contentStats => _contentStats;
  bool get isExtracting => _isExtracting;
  String? get extractError => _extractError;
  bool get hasContent =>
      _extractedContent != null && _extractedContent!.isNotEmpty;

  // =============== EXAM GENERATION STATE ===============

  Exam? _currentExam;
  bool _isGenerating = false;
  String? _generateError;
  int _selectedDuration = 15; // phút
  int _questionCount = 15;

  Exam? get currentExam => _currentExam;
  bool get isGenerating => _isGenerating;
  String? get generateError => _generateError;
  int get selectedDuration => _selectedDuration;
  int get questionCount => _questionCount;

  // =============== EXAM TAKING STATE ===============

  List<int> _userAnswers = [];
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  ExamResult? _currentResult;

  List<int> get userAnswers => _userAnswers;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isSubmitting => _isSubmitting;
  ExamResult? get currentResult => _currentResult;

  /// Câu hỏi hiện tại
  Question? get currentQuestion {
    if (_currentExam == null) return null;
    if (_currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _currentExam!.questions.length)
      return null;
    return _currentExam!.questions[_currentQuestionIndex];
  }

  /// Tổng số câu hỏi
  int get totalQuestions => _currentExam?.questions.length ?? 0;

  /// Số câu đã trả lời
  int get answeredCount => _userAnswers.where((a) => a != -1).length;

  /// Kiểm tra đã trả lời câu hiện tại chưa
  bool get isCurrentQuestionAnswered {
    if (_currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _userAnswers.length) {
      return false;
    }
    return _userAnswers[_currentQuestionIndex] != -1;
  }

  // =============== FILE IMPORT METHODS ===============

  /// Mở file picker và import file
  Future<bool> importFile() async {
    try {
      _isExtracting = true;
      _extractError = null;
      notifyListeners();

      // Chọn file
      final file = await _fileImportService.pickFile();
      if (file == null) {
        _isExtracting = false;
        notifyListeners();
        return false;
      }

      _selectedFile = file;
      notifyListeners();

      // Trích xuất text
      final content = await _fileImportService.extractText(file);
      _extractedContent = content;
      _contentStats = _fileImportService.getContentStats(content);

      _isExtracting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _extractError = e.toString();
      _isExtracting = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear file đã import
  void clearImportedFile() {
    _selectedFile = null;
    _extractedContent = null;
    _contentStats = null;
    _extractError = null;
    notifyListeners();
  }

  // =============== EXAM GENERATION METHODS ===============

  /// Cập nhật thời gian làm bài
  void setDuration(int minutes) {
    _selectedDuration = minutes;
    notifyListeners();
  }

  /// Cập nhật số câu hỏi
  void setQuestionCount(int count) {
    _questionCount = count;
    notifyListeners();
  }

  /// Tạo đề thi từ nội dung đã import
  Future<bool> generateExam() async {
    if (_extractedContent == null || _selectedFile == null) {
      _generateError = 'Vui lòng import file trước';
      notifyListeners();
      return false;
    }

    try {
      _isGenerating = true;
      _generateError = null;
      notifyListeners();

      final exam = await _examGeneratorService.generateExam(
        content: _extractedContent!,
        questionCount: _questionCount,
        fileName: _selectedFile!.name,
        durationMinutes: _selectedDuration,
      );

      _currentExam = exam;
      _isGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _generateError = e.toString();
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  // =============== EXAM TAKING METHODS ===============

  /// Bắt đầu làm bài
  void startExam() {
    if (_currentExam == null) return;

    // Reset state
    _userAnswers = List.filled(_currentExam!.questions.length, -1);
    _currentQuestionIndex = 0;
    _currentResult = null;
    notifyListeners();
  }

  /// Chọn đáp án cho câu hỏi
  void selectAnswer(int questionIndex, int answerIndex) {
    if (questionIndex < 0 || questionIndex >= _userAnswers.length) return;
    if (answerIndex < 0 || answerIndex >= 4) return;

    _userAnswers[questionIndex] = answerIndex;
    notifyListeners();
  }

  /// Chọn đáp án cho câu hiện tại
  void selectCurrentAnswer(int answerIndex) {
    selectAnswer(_currentQuestionIndex, answerIndex);
  }

  /// Đi đến câu hỏi tiếp theo
  void nextQuestion() {
    if (_currentExam == null) return;
    if (_currentQuestionIndex < _currentExam!.questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Đi đến câu hỏi trước đó
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Đi đến câu hỏi cụ thể
  void goToQuestion(int index) {
    if (_currentExam == null) return;
    if (index >= 0 && index < _currentExam!.questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Nộp bài và tính điểm
  /// [elapsedSeconds] - Thời gian đã làm bài (giây)
  Future<ExamResult> submitExam(int elapsedSeconds) async {
    if (_currentExam == null) {
      throw Exception('Không có đề thi để nộp');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      // Tính điểm
      int score = 0;
      final correctAnswers = <int>[];

      for (int i = 0; i < _currentExam!.questions.length; i++) {
        final question = _currentExam!.questions[i];
        correctAnswers.add(question.correctAnswerIndex);

        if (i < _userAnswers.length &&
            _userAnswers[i] == question.correctAnswerIndex) {
          score++;
        }
      }

      // Tạo result
      final result = ExamResult(
        id: _uuid.v4(),
        examId: _currentExam!.id,
        examTitle: _currentExam!.title,
        userId: '', // Sẽ được set bởi FirebaseExamService
        userAnswers: List.from(_userAnswers),
        correctAnswers: correctAnswers,
        score: score,
        totalQuestions: _currentExam!.questions.length,
        durationSeconds: elapsedSeconds,
        allowedDurationMinutes: _currentExam!.durationMinutes,
        submittedAt: DateTime.now(),
      );

      _currentResult = result;
      _isSubmitting = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  // =============== FIREBASE METHODS ===============

  /// Lưu kết quả vào Firebase
  Future<void> saveResultToFirebase() async {
    if (_currentExam == null || _currentResult == null) {
      throw Exception('Không có dữ liệu để lưu');
    }

    // Lưu exam nếu chưa có
    await _firebaseService.saveExam(_currentExam!);

    // Lưu result
    await _firebaseService.saveExamResult(_currentResult!);
  }

  /// Lấy lịch sử exam
  Future<List<Exam>> getExamHistory() async {
    return await _firebaseService.getAllExams();
  }

  /// Lấy lịch sử kết quả
  Future<List<ExamResult>> getResultHistory() async {
    return await _firebaseService.getAllResults();
  }

  /// Lấy thống kê
  Future<ExamStatistics> getStatistics() async {
    return await _firebaseService.getStatistics();
  }

  // =============== RESET METHODS ===============

  /// Reset toàn bộ state
  void reset() {
    // File import
    _selectedFile = null;
    _extractedContent = null;
    _contentStats = null;
    _isExtracting = false;
    _extractError = null;

    // Exam generation
    _currentExam = null;
    _isGenerating = false;
    _generateError = null;
    _selectedDuration = 15;
    _questionCount = 15;

    // Exam taking
    _userAnswers = [];
    _currentQuestionIndex = 0;
    _isSubmitting = false;
    _currentResult = null;

    notifyListeners();
  }

  /// Reset chỉ exam state (giữ lại file đã import)
  void resetExam() {
    _currentExam = null;
    _isGenerating = false;
    _generateError = null;
    _userAnswers = [];
    _currentQuestionIndex = 0;
    _isSubmitting = false;
    _currentResult = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../providers/exam_timer_provider.dart';
import '../widgets/question_card.dart';
import '../widgets/timer_widget.dart';
import '../../../core/theme/app_theme.dart';
import 'exam_result_page.dart';

/// Trang làm bài thi chính
///
/// Bao gồm:
/// - Timer đếm ngược
/// - Câu hỏi hiện tại với options
/// - Navigation giữa các câu
/// - Nút nộp bài
class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Start timer after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _startTimer() {
    final examProvider = context.read<ExamProvider>();
    final timerProvider = context.read<ExamTimerProvider>();

    if (examProvider.currentExam == null) return;

    // Set callback khi hết giờ
    timerProvider.onTimeUp = () => _autoSubmit();

    // Bắt đầu timer
    timerProvider.startTimer(examProvider.currentExam!.durationMinutes);
  }

  void _autoSubmit() {
    // Tự động nộp bài khi hết giờ
    _showTimeUpDialog();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: AppTheme.errorRed),
            SizedBox(width: 10),
            Text('Hết giờ!', style: TextStyle(color: AppTheme.errorRed)),
          ],
        ),
        content: const Text(
          'Thời gian làm bài đã hết. Bài thi sẽ được nộp tự động.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text(
              'Xem kết quả',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Stop timer khi dispose
    context.read<ExamTimerProvider>().stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.paleBlue,
        appBar: _buildAppBar(),
        body: Consumer<ExamProvider>(
          builder: (context, examProvider, child) {
            if (examProvider.currentExam == null) {
              return const Center(child: Text('Không có đề thi'));
            }

            return Column(
              children: [
                // Progress bar
                _buildProgressBar(examProvider),

                // Question cards
                Expanded(child: _buildQuestionPages(examProvider)),

                // Bottom navigation
                _buildBottomNav(examProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _showExitConfirmDialog,
      ),
      title: Consumer<ExamProvider>(
        builder: (context, provider, _) {
          return Text(
            provider.currentExam?.title ?? 'Làm bài',
            style: const TextStyle(fontSize: 16),
          );
        },
      ),
      actions: const [
        // Timer widget
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: CompactTimerWidget(),
        ),
      ],
    );
  }

  /// Progress bar hiển thị tiến độ
  Widget _buildProgressBar(ExamProvider examProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          // Progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu ${examProvider.currentQuestionIndex + 1}/${examProvider.totalQuestions}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                'Đã trả lời: ${examProvider.answeredCount}/${examProvider.totalQuestions}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Linear progress
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:
                  (examProvider.currentQuestionIndex + 1) /
                  examProvider.totalQuestions,
              backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue,
              ),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 10),

          // Question dots
          _buildQuestionDots(examProvider),
        ],
      ),
    );
  }

  Widget _buildQuestionDots(ExamProvider examProvider) {
    return SizedBox(
      height: 24,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: examProvider.totalQuestions,
        itemBuilder: (context, index) {
          final isAnswered =
              index < examProvider.userAnswers.length &&
              examProvider.userAnswers[index] != -1;
          final isCurrent = index == examProvider.currentQuestionIndex;

          return GestureDetector(
            onTap: () => _goToQuestion(index),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.primaryBlue
                    : isAnswered
                    ? AppTheme.successGreen.withValues(alpha: 0.3)
                    : AppTheme.lightBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.primaryBlue
                      : isAnswered
                      ? AppTheme.successGreen
                      : AppTheme.lightBlue,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCurrent
                        ? Colors.white
                        : isAnswered
                        ? AppTheme.successGreen
                        : AppTheme.textGrey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Question pages (swipeable)
  Widget _buildQuestionPages(ExamProvider examProvider) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => examProvider.goToQuestion(index),
      itemCount: examProvider.totalQuestions,
      itemBuilder: (context, index) {
        final question = examProvider.currentExam!.questions[index];
        final selectedAnswer = index < examProvider.userAnswers.length
            ? examProvider.userAnswers[index]
            : -1;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: QuestionCard(
            question: question,
            questionNumber: index + 1,
            totalQuestions: examProvider.totalQuestions,
            selectedAnswer: selectedAnswer,
            showResult: false,
            onAnswerSelected: (answerIndex) {
              examProvider.selectAnswer(index, answerIndex);
            },
          ),
        );
      },
    );
  }

  /// Bottom navigation bar
  Widget _buildBottomNav(ExamProvider examProvider) {
    final isFirstQuestion = examProvider.currentQuestionIndex == 0;
    final isLastQuestion =
        examProvider.currentQuestionIndex == examProvider.totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isFirstQuestion ? null : _previousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Trước'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Submit button (nếu là câu cuối hoặc đã trả lời hết)
            if (isLastQuestion ||
                examProvider.answeredCount == examProvider.totalQuestions)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showSubmitConfirmDialog,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Nộp bài',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLastQuestion ? null : _nextQuestion,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    'Tiếp',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =============== NAVIGATION ===============

  void _previousQuestion() {
    final examProvider = context.read<ExamProvider>();
    examProvider.previousQuestion();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextQuestion() {
    final examProvider = context.read<ExamProvider>();
    examProvider.nextQuestion();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToQuestion(int index) {
    final examProvider = context.read<ExamProvider>();
    examProvider.goToQuestion(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // =============== DIALOGS ===============

  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warningYellow),
            SizedBox(width: 10),
            Text('Thoát bài thi?'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn thoát? Tiến độ làm bài sẽ bị mất.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tiếp tục làm'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.read<ExamTimerProvider>().stopTimer();
              context.read<ExamProvider>().resetExam();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Thoát', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSubmitConfirmDialog() {
    final examProvider = context.read<ExamProvider>();
    final unanswered = examProvider.totalQuestions - examProvider.answeredCount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.send, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('Nộp bài?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đã trả lời ${examProvider.answeredCount}/${examProvider.totalQuestions} câu.',
            ),
            if (unanswered > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Còn $unanswered câu chưa trả lời!',
                style: const TextStyle(
                  color: AppTheme.warningYellow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Bạn có chắc muốn nộp bài?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Làm tiếp'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
            ),
            child: const Text('Nộp bài', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =============== SUBMIT ===============

  Future<void> _submitExam() async {
    final examProvider = context.read<ExamProvider>();
    final timerProvider = context.read<ExamTimerProvider>();

    // Dừng timer
    timerProvider.stopTimer();

    // Tính thời gian đã làm
    final elapsedSeconds = timerProvider.elapsedSeconds;

    try {
      // Submit và lấy kết quả
      await examProvider.submitExam(elapsedSeconds);

      if (!mounted) return;

      // Navigate đến trang kết quả
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ExamResultPage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.errorRed),
      );
    }
  }
}

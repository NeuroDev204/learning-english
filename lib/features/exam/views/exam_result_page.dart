import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../models/exam_model.dart';
import '../widgets/question_card.dart';
import '../../../core/theme/app_theme.dart';

/// Trang hiển thị kết quả sau khi nộp bài
class ExamResultPage extends StatelessWidget {
  const ExamResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Kết quả'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _exitExam(context),
          ),
        ],
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          final result = examProvider.currentResult;

          if (result == null) {
            return const Center(child: Text('Không có kết quả'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Score card
                _buildScoreCard(result),

                // Stats grid
                _buildStatsGrid(result),

                // Action buttons
                _buildActionButtons(context, examProvider),

                // Review section
                _buildReviewSection(context, examProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Score card với animation
  Widget _buildScoreCard(ExamResult result) {
    final percentage = result.scorePercentage;
    final grade = _getGrade(percentage);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            grade.color.withValues(alpha: 0.9),
            grade.color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: grade.color.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Grade emoji
          Text(grade.emoji, style: const TextStyle(fontSize: 60)),

          const SizedBox(height: 12),

          // Score
          Text(
            result.displayScore,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // Percentage
          Text(
            '${(percentage * 100).toStringAsFixed(0)}% chính xác',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          // Grade message
          Text(
            grade.message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Stats grid
  Widget _buildStatsGrid(ExamResult result) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                iconColor: AppTheme.successGreen,
                value: '${result.score}',
                label: 'Đúng',
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.cancel,
                iconColor: AppTheme.errorRed,
                value: '${result.wrongCount}',
                label: 'Sai',
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.remove_circle,
                iconColor: AppTheme.textGrey,
                value: '${result.unansweredCount}',
                label: 'Bỏ qua',
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                iconColor: AppTheme.primaryBlue,
                value: result.formattedDuration,
                label: 'Thời gian',
                context: context,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.whiteCardDecoration(context: context),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  /// Action buttons
  Widget _buildActionButtons(BuildContext context, ExamProvider examProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Save to Firebase button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _saveResult(context, examProvider),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Lưu kết quả',
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

          const SizedBox(width: 12),

          // Try again button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _tryAgain(context, examProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Làm lại'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Review section
  Widget _buildReviewSection(BuildContext context, ExamProvider examProvider) {
    final exam = examProvider.currentExam;
    final result = examProvider.currentResult;

    if (exam == null || result == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Builder(
            builder: (context) => Row(
              children: [
                const Icon(Icons.rate_review,
                    color: AppTheme.accentPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Xem lại bài làm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Question review cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exam.questions.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final question = exam.questions[index];
            final userAnswer = index < result.userAnswers.length
                ? result.userAnswers[index]
                : -1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: QuestionCard(
                question: question,
                questionNumber: index + 1,
                totalQuestions: exam.questions.length,
                selectedAnswer: userAnswer,
                showResult: true,
              ),
            );
          },
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // =============== HELPERS ===============

  _GradeInfo _getGrade(double percentage) {
    if (percentage >= 0.9) {
      return _GradeInfo(
        emoji: '🏆',
        message: 'Xuất sắc!',
        color: const Color(0xFFFFD700), // Gold
      );
    } else if (percentage >= 0.8) {
      return _GradeInfo(
        emoji: '🌟',
        message: 'Giỏi lắm!',
        color: AppTheme.successGreen,
      );
    } else if (percentage >= 0.7) {
      return _GradeInfo(
        emoji: '👍',
        message: 'Khá tốt!',
        color: AppTheme.primaryBlue,
      );
    } else if (percentage >= 0.5) {
      return _GradeInfo(
        emoji: '💪',
        message: 'Cần cố gắng thêm!',
        color: AppTheme.warningYellow,
      );
    } else {
      return _GradeInfo(
        emoji: '📚',
        message: 'Hãy ôn tập nhiều hơn!',
        color: AppTheme.errorRed,
      );
    }
  }

  // =============== ACTIONS ===============

  Future<void> _saveResult(
    BuildContext context,
    ExamProvider examProvider,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Save to Firebase
      await examProvider.saveResultToFirebase();

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Đã lưu kết quả thành công!'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  void _tryAgain(BuildContext context, ExamProvider examProvider) {
    // Reset và bắt đầu lại
    examProvider.startExam();

    // Navigate lại exam page (thay thế result page)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          // Import ExamPage
          return const _ExamPageRedirect();
        },
      ),
    );
  }

  void _exitExam(BuildContext context) {
    // Reset state và về home
    context.read<ExamProvider>().reset();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}

/// Helper redirect widget
class _ExamPageRedirect extends StatelessWidget {
  const _ExamPageRedirect();

  @override
  Widget build(BuildContext context) {
    // Lazy import để tránh circular dependency
    return FutureBuilder(
      future: Future.delayed(Duration.zero),
      builder: (context, _) {
        // Navigate to ExamPage after this frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) {
                // Direct import here
                return Scaffold(
                  body: Builder(
                    builder: (context) {
                      // Use dynamic import pattern
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                );
              },
            ),
          );
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

/// Grade info helper class
class _GradeInfo {
  final String emoji;
  final String message;
  final Color color;

  _GradeInfo({required this.emoji, required this.message, required this.color});
}

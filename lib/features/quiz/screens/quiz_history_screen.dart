// lib/features/quiz/screens/quiz_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/quiz/models/quiz_session.dart';
import 'package:learn_english/features/quiz/services/quiz_session_service.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizSessionService = QuizSessionService();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lịch sử học tập',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<QuizSession>>(
        stream: quizSessionService.getQuizHistory(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải dữ liệu: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.errorRed),
              ),
            );
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử học tập',
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy hoàn thành một bài quiz để xem lịch sử!',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];

              // Tính thống kê
              final answeredCount =
                  session.answers.where((a) => a.userAnswer.isNotEmpty).length;
              final correctCount =
                  session.answers.where((a) => a.isCorrect).length;
              final wrongCount = answeredCount - correctCount;
              final unansweredCount = session.questionCount - answeredCount;

              final percentage = session.questionCount > 0
                  ? (correctCount / session.questionCount * 100).round()
                  : 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            QuizHistoryDetailScreen(session: session),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(session.playedAt),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                session.mode == 'flashcard'
                                    ? 'Flashcard'
                                    : 'Quiz',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session.topicName,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 12),

                        // 3 thống kê Đúng/Sai/Chưa làm – nhỏ gọn
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompactStat(Icons.check_circle,
                                AppTheme.successGreen, '$correctCount', 'Đúng'),
                            _buildCompactStat(Icons.cancel, AppTheme.errorRed,
                                '$wrongCount', 'Sai'),
                            _buildCompactStat(
                                Icons.radio_button_unchecked,
                                Colors.grey.shade600,
                                '$unansweredCount',
                                'Chưa làm'),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // XP, Thời gian, Chính xác
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompactStat(
                                Icons.star,
                                AppTheme.warningYellow,
                                '+${session.xpEarned}',
                                'XP'),
                            _buildCompactStat(Icons.timer, AppTheme.primaryBlue,
                                '${session.durationSeconds}s', 'Thời gian'),
                            _buildCompactStat(
                                Icons.bar_chart,
                                AppTheme.accentPurple,
                                '$percentage%',
                                'Chính xác'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCompactStat(
      IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

// Màn hình chi tiết session – giữ nguyên như trước (đã sửa lỗi)
class QuizHistoryDetailScreen extends StatelessWidget {
  final QuizSession session;

  const QuizHistoryDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Chi tiết bài làm',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: session.answers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final answer = session.answers[index];
          final isAnswered = answer.userAnswer.isNotEmpty;
          final isCorrect = answer.isCorrect;

          Color borderColor = Theme.of(context).colorScheme.outline;
          Color bgColor = Theme.of(context).colorScheme.surface;
          IconData statusIcon = Icons.radio_button_unchecked;
          Color iconColor = Colors.grey.shade600;
          String statusText = 'Chưa làm';

          if (isCorrect) {
            borderColor = AppTheme.successGreen;
            bgColor = AppTheme.successGreen.withValues(alpha: 0.05);
            statusIcon = Icons.check_circle;
            iconColor = AppTheme.successGreen;
            statusText = 'Đúng';
          } else if (isAnswered) {
            borderColor = AppTheme.errorRed;
            bgColor = AppTheme.errorRed.withValues(alpha: 0.05);
            statusIcon = Icons.cancel;
            iconColor = AppTheme.errorRed;
            statusText = 'Sai';
          }

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Câu ${index + 1}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text(statusText,
                            style: TextStyle(
                                color: iconColor, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Icon(statusIcon, color: iconColor, size: 28),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  answer.word,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (isAnswered) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppTheme.successGreen.withValues(alpha: 0.15)
                          : AppTheme.errorRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(isCorrect ? Icons.check : Icons.close,
                            color: isCorrect
                                ? AppTheme.successGreen
                                : AppTheme.errorRed),
                        const SizedBox(width: 12),
                        Text(
                          'Bạn đã chọn: ${answer.userAnswer}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!isAnswered)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('Bạn chưa trả lời câu này',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

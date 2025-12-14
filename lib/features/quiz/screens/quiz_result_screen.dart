// lib/features/quiz/screens/quiz_result_screen.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/quiz/models/quiz_question.dart';
import 'package:learn_english/features/topic/models/topic.dart';
import 'quiz_result_pdf_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final Topic topic;
  final int correctCount;
  final int totalQuestions;
  final int xpEarned;
  final int durationSeconds;
  final List<QuizQuestion> questions;
  final List<String> userAnswers;

  const QuizResultScreen({
    Key? key,
    required this.topic,
    required this.correctCount,
    required this.totalQuestions,
    required this.xpEarned,
    required this.durationSeconds,
    required this.questions,
    required this.userAnswers,
  }) : super(key: key);

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late ConfettiController _confettiController;
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.totalQuestions == 0
        ? 0
        : (widget.correctCount / widget.totalQuestions * 100).round();

    // Tính đúng số câu sai và chưa làm
    final answeredCount = widget.userAnswers.where((ans) => ans.isNotEmpty).length;
    final wrongCount = answeredCount - widget.correctCount;
    final unansweredCount = widget.totalQuestions - answeredCount;

    return Scaffold(
      backgroundColor: AppTheme.paleBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textDark, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Kết quả',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 24),

                // Card tổng kết điểm
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentPink.withOpacity(0.9), AppTheme.accentPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppTheme.accentPink.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${widget.correctCount}/${widget.totalQuestions}',
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percentage% chính xác',
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          percentage >= 90
                              ? 'Xuất sắc!'
                              : percentage >= 70
                                  ? 'Rất tốt!'
                                  : 'Cố lên nhé!',
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Thống kê: Đúng / Sai / Chưa làm
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.whiteCardDecoration(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(Icons.check_circle, AppTheme.successGreen, 'Đúng', '${widget.correctCount}'),
                          _buildStatItem(Icons.cancel, AppTheme.errorRed, 'Sai', '$wrongCount'),
                          _buildStatItem(Icons.radio_button_unchecked, Colors.grey.shade600, 'Chưa làm', '$unansweredCount'),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(Icons.star, AppTheme.warningYellow, 'XP', '+${widget.xpEarned}'),
                          _buildStatItem(Icons.timer, AppTheme.primaryBlue, 'Thời gian', _formatTime(widget.durationSeconds)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Nút hành động
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Làm lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizResultPdfScreen(
                                topic: widget.topic,
                                correctCount: widget.correctCount,
                                totalQuestions: widget.totalQuestions,
                                xpEarned: widget.xpEarned,
                                durationSeconds: widget.durationSeconds,
                                questions: widget.questions,
                                userAnswers: widget.userAnswers,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Xuất PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Nút xem lại đáp án (giữ nguyên giao diện cũ)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => setState(() => _showReview = !_showReview),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt, color: AppTheme.accentPurple),
                          const SizedBox(width: 12),
                          Text(
                            'Xem lại đáp án',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const Spacer(),
                          Icon(_showReview ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.textGrey),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_showReview) ...[
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.questions.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final q = widget.questions[index];
                      final userAns = index < widget.userAnswers.length ? widget.userAnswers[index] : '';
                      final isCorrect = userAns == q.correctAnswer;

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCorrect ? AppTheme.successGreen.withOpacity(0.3) : AppTheme.errorRed.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Câu ${index + 1}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              q.type == QuestionType.wordToMeaning ? q.vocabulary.word : q.vocabulary.meaning,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                              textAlign: TextAlign.center,
                            ),
                            if (q.type == QuestionType.wordToMeaning)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('/${q.vocabulary.pronunciation}/', style: const TextStyle(fontSize: 16, color: AppTheme.textGrey, fontStyle: FontStyle.italic)),
                              ),
                            const SizedBox(height: 20),
                            ...q.options.asMap().entries.map((opt) {
                              final optIndex = opt.key;
                              final optText = opt.value;
                              final label = ['A', 'B', 'C', 'D'][optIndex];
                              final isUserSelected = userAns == optText;
                              final isCorrectAnswer = optText == q.correctAnswer;

                              Color bgColor = Colors.grey.shade50;
                              Color borderColor = Colors.grey.shade300;

                              if (isUserSelected && isCorrectAnswer) {
                                bgColor = AppTheme.successGreen.withOpacity(0.15);
                                borderColor = AppTheme.successGreen;
                              } else if (isUserSelected) {
                                bgColor = AppTheme.errorRed.withOpacity(0.15);
                                borderColor = AppTheme.errorRed;
                              } else if (isCorrectAnswer) {
                                bgColor = AppTheme.successGreen.withOpacity(0.1);
                                borderColor = AppTheme.successGreen;
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor, width: 2),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                                        child: Center(
                                          child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          optText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isCorrectAnswer || isUserSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isCorrectAnswer) const Icon(Icons.check, color: AppTheme.successGreen, size: 24),
                                      if (isUserSelected && !isCorrectAnswer) const Icon(Icons.close, color: AppTheme.errorRed, size: 24),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            if (!isCorrect && userAns.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  'Bạn đã chọn sai. Đáp án đúng là: ${q.correctAnswer}',
                                  style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
      ],
    );
  }
}
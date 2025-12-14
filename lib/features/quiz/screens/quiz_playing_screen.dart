// lib/features/quiz/screens/quiz_playing_screen.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/quiz/models/quiz_question.dart';
import 'package:learn_english/features/quiz/models/quiz_session.dart';
import 'package:learn_english/features/quiz/services/quiz_service.dart';
import 'package:learn_english/features/quiz/services/quiz_session_service.dart';
import 'package:learn_english/features/quiz/widgets/answer_option_button.dart';
import 'package:learn_english/features/quiz/widgets/confetti_overlay.dart';
import 'package:learn_english/features/quiz/widgets/loading_quiz_animation.dart';
import 'package:learn_english/features/quiz/widgets/question_card.dart';
//import 'package:learn_english/features/quiz/widgets/timer_countdown_widget.dart';
import 'package:learn_english/features/topic/models/topic.dart';
import 'quiz_result_screen.dart';
import 'dart:async';

class QuizPlayingScreen extends StatefulWidget {
  final Topic topic;
  final int questionCount;
  final int timerPerQuestion;

  const QuizPlayingScreen({
    super.key,
    required this.topic,
    required this.questionCount,
    required this.timerPerQuestion,
  });

  @override
  State<QuizPlayingScreen> createState() => _QuizPlayingScreenState();
}

class _QuizPlayingScreenState extends State<QuizPlayingScreen> {
  final QuizService _quizService = QuizService();
  final QuizSessionService _sessionService = QuizSessionService();
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));

  late List<QuizQuestion> questions;
  int currentIndex = 0;

  bool isLoading = true;
  bool showResult = false;
  bool isSubmitting = false;
  bool isTimeUp = false;

  String? selectedAnswer;
  final Stopwatch stopwatch = Stopwatch();
  List<String> userAnswers = [];
  
  // Thêm Timer để cập nhật UI mỗi giây
  Timer? _uiUpdateTimer;
  int _remainingSeconds = 0;

  int get totalSeconds => widget.timerPerQuestion * widget.questionCount;

  @override
  void initState() {
    super.initState();
    userAnswers = List.filled(widget.questionCount, '');
    _remainingSeconds = totalSeconds;
    _loadQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _uiUpdateTimer?.cancel();
    stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    questions = await _quizService.generateQuestions(
      topicId: widget.topic.id,
      count: widget.questionCount,
    );
    if (mounted) {
      setState(() => isLoading = false);
      stopwatch.start();
      _startTimer();
    }
  }

  void _startTimer() {
    // Cập nhật UI mỗi giây
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || isSubmitting || isTimeUp) {
        timer.cancel();
        return;
      }
      
      final elapsed = stopwatch.elapsed.inSeconds;
      final remaining = (totalSeconds - elapsed).clamp(0, totalSeconds);
      
      if (remaining <= 0 && !isTimeUp) {
        setState(() => isTimeUp = true);
        timer.cancel();
        _goToResult();
      } else {
        setState(() => _remainingSeconds = remaining);
      }
    });
  }

  void _selectAnswer(String answer) {
    if (showResult || isLoading || isSubmitting || isTimeUp) return;

    setState(() {
      selectedAnswer = answer;
      userAnswers[currentIndex] = answer;
      showResult = true;

      if (answer == questions[currentIndex].correctAnswer) {
        _confettiController.play();
      }
    });
  }

  void _goToQuestion(int index) {
    if (isSubmitting || isTimeUp) return;
    setState(() {
      currentIndex = index;
      selectedAnswer = userAnswers[index];
      showResult = userAnswers[index].isNotEmpty;
    });
  }

  Future<void> _goToResult() async {
    if (isSubmitting || !mounted) return;

    // Hủy timer UI update
    _uiUpdateTimer?.cancel();
    
    setState(() => isSubmitting = true);

    stopwatch.stop();
    final duration = stopwatch.elapsed.inSeconds;

    final actualCorrect = userAnswers.asMap().entries.where((e) {
      return e.value.isNotEmpty && e.value == questions[e.key].correctAnswer;
    }).length;

    final xp = _quizService.calculateXp(
      correctCount: actualCorrect,
      totalQuestions: questions.length,
      durationSeconds: duration,
    );

    final answers = questions.asMap().entries.map((e) {
      final q = e.value;
      final userAns = userAnswers[e.key];
      return QuizAnswer(
        vocabularyId: q.vocabulary.id,
        word: q.vocabulary.word,
        userAnswer: userAns,
        isCorrect: userAns.isNotEmpty && userAns == q.correctAnswer,
        timeSpent: 0.0,
      );
    }).toList();

    final session = QuizSession(
      topicId: widget.topic.id,
      topicName: widget.topic.name,
      mode: 'quiz',
      questionCount: questions.length,
      correctCount: actualCorrect,
      scorePercentage: questions.isEmpty ? 0 : ((actualCorrect / questions.length) * 100).round(),
      xpEarned: xp,
      durationSeconds: duration,
      playedAt: DateTime.now(),
      answers: answers,
    );

    // QUAN TRỌNG: Navigate trước, lưu sau (trong background)
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          topic: widget.topic,
          correctCount: actualCorrect,
          totalQuestions: questions.length,
          xpEarned: xp,
          durationSeconds: duration,
          questions: questions,
          userAnswers: userAnswers,
        ),
      ),
    );

    // Lưu trong background (không block UI)
    try {
      await _sessionService.saveSession(session);
      debugPrint('Lưu kết quả thành công!');
    } catch (e) {
      debugPrint('Lỗi lưu (không ảnh hưởng UI): $e');
      // Không hiển thị lỗi vì đã navigate rồi
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.paleBlue,
        body: LoadingQuizAnimation(),
      );
    }

    final question = questions[currentIndex];
    final labels = ['A', 'B', 'C', 'D'];
    final progress = (currentIndex + 1) / questions.length;
    final timeProgress = _remainingSeconds / totalSeconds;

    return Scaffold(
      backgroundColor: AppTheme.paleBlue,
      appBar: AppBar(
        backgroundColor: AppTheme.paleBlue,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              if (!isSubmitting && !isTimeUp) {
                _uiUpdateTimer?.cancel();
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '×',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            // Timer với progress bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: _remainingSeconds <= 10 
                        ? AppTheme.errorRed 
                        : AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_remainingSeconds}s',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds <= 10 
                          ? AppTheme.errorRed 
                          : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Progress bar cho thời gian
            SizedBox(
              width: 200,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: timeProgress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remainingSeconds <= 10 
                        ? AppTheme.errorRed 
                        : AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentIndex + 1}/${questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiến độ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${((progress * 100).round())}%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppTheme.paleBlue,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  QuestionCard(
                    question: question,
                    currentQuestion: currentIndex + 1,
                    totalQuestions: questions.length,
                  ),
                  
                  const SizedBox(height: 32),

                  // Đáp án dạng 2x2 grid - cải thiện spacing
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 3.0, // Giảm từ 3.2 để đáp án cao hơn, dễ nhìn hơn
                    ),
                    itemCount: question.options.length,
                    itemBuilder: (context, i) {
                      return _buildOption(i, question.options, labels, question);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Thanh dưới cố định với cải thiện
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh số câu với cải thiện
                SizedBox(
                  height: 70,
                  child: Column(
                    children: [
                      Text(
                        'Chọn câu hỏi',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final answered = userAnswers[index].isNotEmpty;
                            final correct = answered && 
                                userAnswers[index] == questions[index].correctAnswer;

                            return GestureDetector(
                              onTap: () => _goToQuestion(index),
                              child: Container(
                                width: 48,
                                height: 48,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: currentIndex == index
                                      ? AppTheme.primaryBlue
                                      : correct
                                          ? AppTheme.successGreen
                                          : answered
                                              ? AppTheme.errorRed
                                              : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: currentIndex == index
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: currentIndex == index
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryBlue.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: currentIndex == index
                                          ? Colors.white
                                          : AppTheme.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Nút Trước và Hoàn thành với cải thiện
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (currentIndex > 0 && !isSubmitting && !isTimeUp)
                            ? () => _goToQuestion(currentIndex - 1)
                            : null,
                        icon: const Icon(Icons.arrow_back, size: 20),
                        label: const Text('Trước'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryBlue,
                          disabledBackgroundColor: Colors.grey.shade100,
                          disabledForegroundColor: Colors.grey.shade400,
                          side: BorderSide(
                            color: (currentIndex > 0 && !isSubmitting && !isTimeUp)
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: (isSubmitting || isTimeUp)
                            ? null
                            : _goToResult,
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_circle, size: 22),
                        label: Text(
                          isSubmitting
                              ? 'Đang lưu...'
                              : isTimeUp
                                  ? 'Hết giờ!'
                                  : 'Hoàn thành',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTimeUp
                              ? AppTheme.errorRed
                              : AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ConfettiOverlay(controller: _confettiController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOption(
      int index, List<String> options, List<String> labels, QuizQuestion question) {
    final opt = options[index];
    return AnswerOptionButton(
      label: labels[index],
      text: opt,
      isCorrect: showResult ? opt == question.correctAnswer : null,
      isSelected: selectedAnswer == opt,
      onTap: (isSubmitting || isTimeUp) ? null : () => _selectAnswer(opt),
    );
  }
}
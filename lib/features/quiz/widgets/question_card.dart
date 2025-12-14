import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/quiz_question.dart';

class QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int currentQuestion;
  final int totalQuestions;

  const QuestionCard({
    super.key,
    required this.question,
    required this.currentQuestion,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.whiteCardDecoration(),
      child: Column(
        children: [
          Text(
            'Câu $currentQuestion/$totalQuestions',
            style: const TextStyle(fontSize: 16, color: AppTheme.textGrey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Text(
            question.type == QuestionType.wordToMeaning
                ? 'Nghĩa của từ này là gì?'
                : 'Từ tiếng Anh của nghĩa này là gì?',
            style: const TextStyle(fontSize: 20, color: AppTheme.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            question.type == QuestionType.wordToMeaning ? question.vocabulary.word : question.vocabulary.meaning,
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            textAlign: TextAlign.center,
          ),
          if (question.type == QuestionType.wordToMeaning)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '/${question.vocabulary.pronunciation}/',
                style: const TextStyle(fontSize: 22, color: AppTheme.textGrey, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
import 'package:learn_english/features/topic/models/vocabulary.dart';

enum QuestionType { wordToMeaning, meaningToWord }

class QuizQuestion {
  final String id;
  final Vocabulary vocabulary;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.id,
    required this.vocabulary,
    required this.type,
    required this.options,
    required this.correctAnswer,
  });
}

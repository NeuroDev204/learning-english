import 'dart:math';
import 'package:learn_english/features/topic/services/vocabulary_service.dart';
import '../models/quiz_question.dart';

class QuizService {
  final VocabularyService _vocabService = VocabularyService();
  final Random _random = Random();

  Future<List<QuizQuestion>> generateQuestions({
    required String topicId,
    required int count,
  }) async {
    final vocabList = await _vocabService.getVocabulariesByTopic(topicId).first;
    if (vocabList.isEmpty) return [];

    final selected = vocabList.length <= count
        ? vocabList
        : (vocabList..shuffle(_random)).take(count).toList();

    final List<QuizQuestion> questions = [];

    for (final vocab in selected) {
      final type = _random.nextBool()
          ? QuestionType.wordToMeaning
          : QuestionType.meaningToWord;

      final wrongOptions = vocabList.where((v) => v.id != vocab.id).toList()
        ..shuffle(_random);

      final wrongAnswers = wrongOptions
          .take(3)
          .map((v) => type == QuestionType.wordToMeaning ? v.meaning : v.word)
          .toList();

      final correctAnswer = type == QuestionType.wordToMeaning
          ? vocab.meaning
          : vocab.word;
      final options = (wrongAnswers + [correctAnswer])..shuffle(_random);

      questions.add(
        QuizQuestion(
          id: vocab.id,
          vocabulary: vocab,
          type: type,
          options: options,
          correctAnswer: correctAnswer,
        ),
      );
    }
    return questions;
  }

  int calculateXp({
    required int correctCount,
    required int totalQuestions,
    required int durationSeconds,
  }) {
    if (totalQuestions == 0) return 0;
    final percentage = (correctCount / totalQuestions * 100).round();
    final base = correctCount * 10;
    final perfect = percentage == 100 ? 50 : 0;
    final fast = durationSeconds < totalQuestions * 10 ? 30 : 0;
    return base + perfect + fast;
  }
}

import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/question_model.dart';
import '../models/exam_model.dart';

/// Service để tự động sinh đề thi từ nội dung text
/// Sử dụng logic rule-based (NLP cơ bản)
class ExamGeneratorService {
  /// Singleton pattern
  static final ExamGeneratorService _instance =
      ExamGeneratorService._internal();
  factory ExamGeneratorService() => _instance;
  ExamGeneratorService._internal();

  final _uuid = const Uuid();
  final _random = Random();

  // Danh sách từ phổ biến để tránh chọn làm câu hỏi vocabulary
  static const _commonWords = {
    'the',
    'a',
    'an',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'have',
    'has',
    'had',
    'do',
    'does',
    'did',
    'will',
    'would',
    'could',
    'should',
    'may',
    'might',
    'must',
    'can',
    'and',
    'or',
    'but',
    'if',
    'then',
    'else',
    'when',
    'where',
    'why',
    'how',
    'what',
    'which',
    'who',
    'this',
    'that',
    'these',
    'those',
    'it',
    'its',
    'they',
    'them',
    'their',
    'we',
    'us',
    'our',
    'you',
    'your',
    'he',
    'him',
    'his',
    'she',
    'her',
    'to',
    'of',
    'in',
    'for',
    'on',
    'with',
    'at',
    'by',
    'from',
    'as',
    'into',
    'through',
    'during',
    'before',
    'after',
    'above',
    'below',
    'between',
    'under',
    'again',
    'further',
    'once',
    'here',
    'there',
    'all',
    'each',
    'few',
    'more',
    'most',
    'other',
    'some',
    'such',
    'no',
    'nor',
    'not',
    'only',
    'own',
    'same',
    'so',
    'than',
    'too',
    'very',
    'just',
    'also',
    'now',
    'new',
    'first',
    'last',
    'long',
    'great',
    'little',
    'old',
    'right',
    'big',
    'high',
    'different',
    'small',
    'large',
    'next',
    'early',
    'young',
    'important',
  };

  // Các prefix/suffix phổ biến để tạo wrong answers
  static const _prefixes = ['un', 'dis', 'mis', 're', 'pre', 'non', 'anti'];
  static const _suffixes = [
    'ly',
    'ness',
    'ment',
    'tion',
    'able',
    'ible',
    'ful',
    'less',
  ];

  /// Tạo đề thi từ nội dung text
  /// [content] - Nội dung text đã trích xuất
  /// [questionCount] - Số lượng câu hỏi mong muốn
  /// [fileName] - Tên file gốc
  /// [durationMinutes] - Thời gian làm bài (phút)
  Future<Exam> generateExam({
    required String content,
    required int questionCount,
    required String fileName,
    required int durationMinutes,
  }) async {
    List<Question> questions = [];

    // BƯỚC 1: Kiểm tra xem content có chứa câu hỏi đã format sẵn không
    // (Q... A) B) C) D) Answer: ...)
    final preFormattedQuestions = _parsePreFormattedQuestions(content);

    if (preFormattedQuestions.isNotEmpty) {
      // Nếu có câu hỏi format sẵn, sử dụng chúng
      questions = preFormattedQuestions.take(questionCount).toList();
    }

    // BƯỚC 2: Nếu chưa đủ câu hỏi, sinh thêm từ nội dung
    if (questions.length < questionCount) {
      final remaining = questionCount - questions.length;

      // Phân bố câu hỏi theo tỷ lệ:
      // - Vocabulary: 30%
      // - Reading Comprehension: 25%
      // - Fill in Blanks: 25%
      // - True/False: 20%

      final vocabCount = (remaining * 0.30).round();
      final readingCount = (remaining * 0.25).round();
      final fillBlanksCount = (remaining * 0.25).round();
      final trueFalseCount =
          remaining - vocabCount - readingCount - fillBlanksCount;

      // Tạo câu hỏi từng loại
      questions.addAll(await _generateVocabularyQuestions(content, vocabCount));
      questions.addAll(await _generateReadingQuestions(content, readingCount));
      questions.addAll(
        await _generateFillInBlanksQuestions(content, fillBlanksCount),
      );
      questions.addAll(
        await _generateTrueFalseQuestions(content, trueFalseCount),
      );
    }

    // Shuffle câu hỏi (chỉ cho phần tự sinh, giữ nguyên thứ tự pre-formatted)
    if (preFormattedQuestions.isEmpty) {
      questions.shuffle(_random);
    }

    // Tạo title từ tên file
    final title = _generateTitle(fileName);

    return Exam(
      id: _uuid.v4(),
      title: title,
      sourceContent: content,
      sourceFileName: fileName,
      questions: questions,
      durationMinutes: durationMinutes,
      createdAt: DateTime.now(),
    );
  }

  /// Parse câu hỏi đã format sẵn từ content
  /// Nhận diện format: Q1: / Q1. + A) B) C) D) + Answer: X
  List<Question> _parsePreFormattedQuestions(String content) {
    final questions = <Question>[];

    // Pattern để tìm đáp án đúng
    final answerPattern = RegExp(
      r'(?:Answer|Ans|Đáp án|Key)[:\s]*([A-Da-d])',
      caseSensitive: false,
    );

    // Tìm Reading passage (đoạn văn dài trước các câu hỏi Q21-Q30)
    String? sharedPassage = _extractSharedPassage(content);

    // Chia content thành các block câu hỏi
    final questionBlocks = _splitIntoQuestionBlocks(content);

    for (final block in questionBlocks) {
      final question = _parseQuestionBlock(block, answerPattern, sharedPassage);
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  /// Trích xuất đoạn văn chung cho Reading Comprehension
  String? _extractSharedPassage(String content) {
    // Tìm phần "Read the following passage" hoặc đoạn văn dài trước Q21
    final readingMatch = RegExp(
      r'(?:Read the following passage.*?:|READING COMPREHENSION)\s*(.+?)(?=Q\s*\d+[:.]\s*)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(content);

    if (readingMatch != null) {
      final passage = readingMatch.group(1)?.trim();
      if (passage != null && passage.length > 100) {
        return passage;
      }
    }

    // Tìm đoạn văn dài giữa PART 3 và Q21
    final part3Match = RegExp(
      r'PART\s*3[:\s]*.*?(?:READING|COMPREHENSION).*?\n(.+?)(?=Q\s*2[0-9][:.]\s*)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(content);

    if (part3Match != null) {
      final passage = part3Match.group(1)?.trim();
      if (passage != null && passage.length > 100) {
        return passage;
      }
    }

    return null;
  }

  /// Chia content thành các block câu hỏi riêng biệt
  List<String> _splitIntoQuestionBlocks(String content) {
    final blocks = <String>[];

    // Pattern để tách câu hỏi: Q1: hoặc Q1. hoặc Q 1:
    final splitPattern = RegExp(
      r'(?=(?:^|\n)\s*Q\s*\d+\s*[:.])',
      multiLine: true,
    );

    final parts = content.split(splitPattern);

    for (final part in parts) {
      final trimmed = part.trim();
      // Only include if it starts with Q and has Answer
      if (trimmed.isNotEmpty &&
          RegExp(r'^Q\s*\d+', caseSensitive: false).hasMatch(trimmed) &&
          RegExp(
            r'Answer[:\s]*[A-Da-d]',
            caseSensitive: false,
          ).hasMatch(trimmed)) {
        blocks.add(trimmed);
      }
    }

    return blocks;
  }

  /// Parse một block câu hỏi thành Question object
  Question? _parseQuestionBlock(
    String block,
    RegExp answerPattern,
    String? sharedPassage,
  ) {
    try {
      // Tìm đáp án đúng trước
      final answerMatch = answerPattern.firstMatch(block);
      if (answerMatch == null) return null;

      final correctLetter = answerMatch.group(1)!.toUpperCase();
      final correctIndex = correctLetter.codeUnitAt(0) - 'A'.codeUnitAt(0);
      if (correctIndex < 0 || correctIndex > 3) return null;

      // Loại bỏ phần Answer khỏi block
      String cleanBlock = block
          .replaceAll(
            RegExp(
              r'\s*(?:Answer|Ans|Đáp án|Key)[:\s]*[A-Da-d].*',
              caseSensitive: false,
              dotAll: true,
            ),
            '',
          )
          .trim();

      // Tìm tất cả các option markers với word boundary
      // Pattern: bắt đầu dòng hoặc sau whitespace, theo sau là A/B/C/D và . hoặc )
      final allOptionMatches = RegExp(
        r'(?:^|\n|\s)([A-Da-d])[.)]\s*',
        multiLine: true,
      ).allMatches(cleanBlock).toList();

      // Lọc và sắp xếp các options theo thứ tự A -> B -> C -> D
      final optionPositions = <String, int>{};
      int lastPos = -1;

      for (final optionLetter in ['A', 'B', 'C', 'D']) {
        // Tìm match cho option này ở vị trí sau lastPos
        for (final match in allOptionMatches) {
          final letter = match.group(1)?.toUpperCase();
          if (letter == optionLetter && match.start > lastPos) {
            optionPositions[optionLetter] = match.start;
            lastPos = match.start;
            break;
          }
        }
      }

      if (!optionPositions.containsKey('A') ||
          !optionPositions.containsKey('B')) {
        return null;
      }

      // Lấy question text (phần trước A))
      final posA = optionPositions['A']!;
      String questionText = cleanBlock.substring(0, posA).trim();

      // Loại bỏ số thứ tự câu hỏi ở đầu (Q1: hoặc Q1.)
      questionText = questionText
          .replaceFirst(
            RegExp(r'^Q\s*\d+\s*[:.]?\s*', caseSensitive: false),
            '',
          )
          .trim();

      if (questionText.isEmpty) return null;

      // Sắp xếp options theo thứ tự A, B, C, D
      final sortedOptions = optionPositions.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // Trích xuất nội dung từng option
      final options = <String>[];
      for (int i = 0; i < sortedOptions.length; i++) {
        final currentOption = sortedOptions[i];
        final startPos = currentOption.value;

        // Tìm vị trí kết thúc option này
        int endPos;
        if (i + 1 < sortedOptions.length) {
          endPos = sortedOptions[i + 1].value;
        } else {
          endPos = cleanBlock.length;
        }

        // Lấy text của option
        String optionText = cleanBlock.substring(startPos, endPos).trim();

        // Loại bỏ ký tự đánh dấu option (A. hoặc A))
        optionText = optionText
            .replaceFirst(RegExp(r'^[A-Da-d][.)]\s*'), '')
            .trim();

        // Loại bỏ newlines và extra whitespace
        optionText = optionText.replaceAll(RegExp(r'\s+'), ' ').trim();

        if (optionText.isNotEmpty) {
          options.add(optionText);
        }
      }

      if (options.length < 2) return null;

      // Xác định loại câu hỏi dựa trên nội dung
      QuestionType type = QuestionType.vocabulary;
      String? passage;
      String displayQuestion = questionText;

      // Lấy số câu hỏi để xác định phần (Part)
      final questionNumMatch = RegExp(
        r'^Q\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(block);
      final questionNum = int.tryParse(questionNumMatch?.group(1) ?? '0') ?? 0;

      // Q21-Q30: Reading Comprehension - sử dụng sharedPassage
      if (questionNum >= 21 && questionNum <= 30 && sharedPassage != null) {
        type = QuestionType.readingComprehension;
        passage = sharedPassage;
      }
      // Q31-Q40: Error Identification
      else if (questionNum >= 31 && questionNum <= 40) {
        type = QuestionType
            .vocabulary; // Hiển thị như vocabulary nhưng là error ID
        // Không cần xử lý đặc biệt vì format đã đúng
      }
      // Kiểm tra các từ khóa khác cho reading
      else if (questionText.toLowerCase().contains('passage') ||
          questionText.toLowerCase().contains('according to') ||
          questionText.toLowerCase().contains('the text')) {
        type = QuestionType.readingComprehension;
        passage = sharedPassage;
      }
      // Fill in blanks
      else if (questionText.contains('_____') ||
          questionText.contains('____') ||
          questionText.contains('___')) {
        type = QuestionType.fillInBlanks;
      }
      // True/False
      else if (options.length == 2 &&
          (options[0].toLowerCase() == 'true' ||
              options[0].toLowerCase() == 'false')) {
        type = QuestionType.trueFalse;
      }

      // Đảm bảo correctIndex không vượt quá số options
      final safeCorrectIndex = correctIndex < options.length ? correctIndex : 0;

      return Question(
        id: _uuid.v4(),
        type: type,
        question: displayQuestion,
        options: options,
        correctAnswerIndex: safeCorrectIndex,
        passage: passage,
        blankSentence: type == QuestionType.fillInBlanks
            ? displayQuestion
            : null,
        explanation:
            'Đáp án đúng là: $correctLetter) ${options[safeCorrectIndex]}',
      );
    } catch (e) {
      return null;
    }
  }

  /// Tạo câu hỏi Vocabulary
  /// Chọn từ khó và tạo 4 đáp án
  Future<List<Question>> _generateVocabularyQuestions(
    String content,
    int count,
  ) async {
    final questions = <Question>[];

    // Tách từ và lọc từ có độ dài >= 6 ký tự, không phải common words
    final words = _extractSignificantWords(content);

    if (words.isEmpty) {
      return questions;
    }

    // Shuffle và chọn từ
    words.shuffle(_random);
    final selectedWords = words.take(count).toList();

    for (final word in selectedWords) {
      final question = _createVocabularyQuestion(word, words);
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  /// Tạo một câu hỏi vocabulary
  Question? _createVocabularyQuestion(String word, List<String> wordPool) {
    // Tạo các đáp án sai
    final wrongAnswers = _generateWrongAnswers(word, wordPool, 3);
    if (wrongAnswers.length < 3) return null;

    // Random vị trí đáp án đúng
    final correctIndex = _random.nextInt(4);
    final options = List<String>.filled(4, '');

    options[correctIndex] = word.toLowerCase();
    int wrongIdx = 0;
    for (int i = 0; i < 4; i++) {
      if (i != correctIndex) {
        options[i] = wrongAnswers[wrongIdx++].toLowerCase();
      }
    }

    // Các dạng câu hỏi vocabulary
    final questionTemplates = [
      'Which word means the same as "${_getMeaning(word)}"?',
      'Choose the correct word that fits the context:',
      'Select the appropriate vocabulary word:',
      'Which word is most suitable for this context?',
    ];

    return Question(
      id: _uuid.v4(),
      type: QuestionType.vocabulary,
      question: questionTemplates[_random.nextInt(questionTemplates.length)],
      options: options,
      correctAnswerIndex: correctIndex,
      explanation: 'The correct answer is "$word".',
    );
  }

  /// Tạo câu hỏi Reading Comprehension
  Future<List<Question>> _generateReadingQuestions(
    String content,
    int count,
  ) async {
    final questions = <Question>[];

    // Chia content thành các đoạn văn
    final paragraphs = content
        .split(RegExp(r'\n\n+'))
        .where((p) => p.trim().length >= 100)
        .toList();

    if (paragraphs.isEmpty) return questions;

    for (int i = 0; i < count && i < paragraphs.length; i++) {
      final passage = paragraphs[i % paragraphs.length].trim();
      final question = _createReadingQuestion(passage, i);
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  /// Tạo một câu hỏi reading comprehension
  Question? _createReadingQuestion(String passage, int index) {
    // Cắt passage nếu quá dài
    final shortPassage = passage.length > 500
        ? '${passage.substring(0, 500)}...'
        : passage;

    // Các dạng câu hỏi reading
    final questionTypes = [
      {
        'question': 'What is the main idea of this passage?',
        'correctAnswer':
            'The passage discusses ${_getTopicFromPassage(passage)}',
        'wrongAnswers': [
          'The passage is about unrelated topics',
          'The passage focuses on historical events only',
          'The passage describes personal experiences',
        ],
      },
      {
        'question': 'According to the passage, which statement is true?',
        'correctAnswer': 'The information in the passage supports this view',
        'wrongAnswers': [
          'This contradicts the main point',
          'The passage does not mention this',
          'This is opposite to what is stated',
        ],
      },
      {
        'question': 'What can be inferred from this passage?',
        'correctAnswer': 'The author implies important insights',
        'wrongAnswers': [
          'No conclusions can be drawn',
          'The opposite meaning is intended',
          'The text is purely factual without implications',
        ],
      },
    ];

    final selectedType = questionTypes[index % questionTypes.length];
    final correctIndex = _random.nextInt(4);

    final options = List<String>.filled(4, '');
    options[correctIndex] = selectedType['correctAnswer'] as String;

    final wrongAnswers = selectedType['wrongAnswers'] as List<String>;
    int wrongIdx = 0;
    for (int i = 0; i < 4; i++) {
      if (i != correctIndex) {
        options[i] = wrongAnswers[wrongIdx++ % wrongAnswers.length];
      }
    }

    return Question(
      id: _uuid.v4(),
      type: QuestionType.readingComprehension,
      question: selectedType['question'] as String,
      options: options,
      correctAnswerIndex: correctIndex,
      passage: shortPassage,
      explanation: 'Based on the passage content.',
    );
  }

  /// Tạo câu hỏi Fill in the Blanks
  Future<List<Question>> _generateFillInBlanksQuestions(
    String content,
    int count,
  ) async {
    final questions = <Question>[];

    // Tách câu từ content
    final sentences = content
        .split(RegExp(r'[.!?]+\s*'))
        .where((s) => s.trim().length >= 30 && s.trim().length <= 150)
        .toList();

    if (sentences.isEmpty) return questions;

    sentences.shuffle(_random);

    for (int i = 0; i < count && i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      final question = _createFillInBlanksQuestion(sentence);
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  /// Tạo một câu hỏi fill in blanks
  Question? _createFillInBlanksQuestion(String sentence) {
    // Tách từ và chọn một từ để "xóa"
    final words = sentence
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .toList();

    if (words.length < 3) return null;

    // Chọn từ ở giữa câu (không phải đầu hoặc cuối)
    final middleWords = words.sublist(1, words.length - 1);
    if (middleWords.isEmpty) return null;

    final targetWord = middleWords[_random.nextInt(middleWords.length)];

    // Tạo câu với blank
    final blankSentence = sentence.replaceFirst(
      RegExp(r'\b' + RegExp.escape(targetWord) + r'\b'),
      '_____',
    );

    if (blankSentence == sentence) return null; // Không thay thế được

    // Tạo wrong answers
    final wrongAnswers = _generateWrongAnswers(targetWord, words, 3);
    if (wrongAnswers.length < 3) return null;

    final correctIndex = _random.nextInt(4);
    final options = List<String>.filled(4, '');
    options[correctIndex] = targetWord.toLowerCase();

    int wrongIdx = 0;
    for (int i = 0; i < 4; i++) {
      if (i != correctIndex) {
        options[i] = wrongAnswers[wrongIdx++].toLowerCase();
      }
    }

    return Question(
      id: _uuid.v4(),
      type: QuestionType.fillInBlanks,
      question: 'Fill in the blank with the correct word:',
      options: options,
      correctAnswerIndex: correctIndex,
      blankSentence: blankSentence,
      explanation: 'The correct word is "$targetWord".',
    );
  }

  /// Tạo câu hỏi True/False
  Future<List<Question>> _generateTrueFalseQuestions(
    String content,
    int count,
  ) async {
    final questions = <Question>[];

    // Tách câu từ content
    final sentences = content
        .split(RegExp(r'[.!?]+\s*'))
        .where((s) => s.trim().length >= 20 && s.trim().length <= 100)
        .toList();

    if (sentences.isEmpty) return questions;

    sentences.shuffle(_random);

    for (int i = 0; i < count && i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      final isTrue = _random.nextBool();
      final question = _createTrueFalseQuestion(sentence, isTrue);
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  /// Tạo một câu hỏi true/false
  Question? _createTrueFalseQuestion(String sentence, bool shouldBeTrue) {
    String statement;

    if (shouldBeTrue) {
      statement = sentence;
    } else {
      // Biến đổi câu thành sai bằng cách thêm "not" hoặc đổi nghĩa
      statement = _makeStatementFalse(sentence);
    }

    final correctIndex = shouldBeTrue ? 0 : 1;

    return Question(
      id: _uuid.v4(),
      type: QuestionType.trueFalse,
      question: 'Is the following statement true or false?\n\n"$statement"',
      options: ['True', 'False', 'Not mentioned', 'Cannot determine'],
      correctAnswerIndex: correctIndex,
      explanation: shouldBeTrue
          ? 'This statement is correct based on the passage.'
          : 'This statement has been modified to be incorrect.',
    );
  }

  // =============== HELPER METHODS ===============

  /// Trích xuất từ có ý nghĩa từ content
  List<String> _extractSignificantWords(String content) {
    final words = content
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Z]+'))
        .where((w) => w.length >= 6)
        .where((w) => !_commonWords.contains(w))
        .toSet()
        .toList();
    return words;
  }

  /// Tạo đáp án sai từ một từ
  List<String> _generateWrongAnswers(
    String word,
    List<String> wordPool,
    int count,
  ) {
    final wrongAnswers = <String>[];

    // Phương pháp 1: Lấy từ khác từ word pool
    final otherWords = wordPool
        .where((w) => w != word && w.length >= 4)
        .toList();
    otherWords.shuffle(_random);
    wrongAnswers.addAll(otherWords.take(count));

    // Phương pháp 2: Biến đổi từ gốc nếu chưa đủ
    if (wrongAnswers.length < count) {
      for (final prefix in _prefixes) {
        if (wrongAnswers.length >= count) break;
        final modified = '$prefix$word';
        if (!wrongAnswers.contains(modified) && modified != word) {
          wrongAnswers.add(modified);
        }
      }
    }

    // Phương pháp 3: Thêm suffix
    if (wrongAnswers.length < count) {
      for (final suffix in _suffixes) {
        if (wrongAnswers.length >= count) break;
        final modified = '$word$suffix';
        if (!wrongAnswers.contains(modified)) {
          wrongAnswers.add(modified);
        }
      }
    }

    return wrongAnswers.take(count).toList();
  }

  /// Lấy topic từ passage (đơn giản: lấy vài từ đầu)
  String _getTopicFromPassage(String passage) {
    final words = passage.split(RegExp(r'\s+')).take(5).join(' ');
    return words.isEmpty ? 'the main topic' : words.toLowerCase();
  }

  /// Tạo nghĩa giả từ từ (placeholder)
  String _getMeaning(String word) {
    // Trong thực tế nên dùng dictionary API
    return 'a specific concept related to the context';
  }

  /// Biến câu thành sai
  String _makeStatementFalse(String sentence) {
    // Thêm "not" sau động từ to be hoặc modal verbs
    final patterns = [
      (RegExp(r'\bis\b'), 'is not'),
      (RegExp(r'\bare\b'), 'are not'),
      (RegExp(r'\bwas\b'), 'was not'),
      (RegExp(r'\bwere\b'), 'were not'),
      (RegExp(r'\bcan\b'), 'cannot'),
      (RegExp(r'\bwill\b'), 'will not'),
      (RegExp(r'\bshould\b'), 'should not'),
    ];

    for (final (pattern, replacement) in patterns) {
      if (pattern.hasMatch(sentence)) {
        return sentence.replaceFirst(pattern, replacement);
      }
    }

    // Nếu không tìm thấy pattern, thêm "It is not true that" ở đầu
    return 'It is false that ${sentence.toLowerCase()}';
  }

  /// Tạo title từ tên file
  String _generateTitle(String fileName) {
    // Loại bỏ extension và format
    final name = fileName
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();

    if (name.isEmpty) {
      return 'English Exam ${DateTime.now().millisecondsSinceEpoch}';
    }

    // Capitalize first letter of each word
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

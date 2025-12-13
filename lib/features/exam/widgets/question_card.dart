import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../../../core/theme/app_theme.dart';
import 'answer_option_widget.dart';

/// Widget hiển thị một câu hỏi đầy đủ
///
/// Bao gồm:
/// - Badge loại câu hỏi
/// - Passage (cho Reading Comprehension)
/// - Câu hỏi / câu có blank
/// - 4 options
class QuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber; // Số thứ tự câu hỏi (1-based)
  final int totalQuestions; // Tổng số câu hỏi
  final int? selectedAnswer; // Index đáp án đã chọn (-1 hoặc null = chưa chọn)
  final bool showResult; // Có hiển thị kết quả không
  final ValueChanged<int>? onAnswerSelected; // Callback khi chọn đáp án

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    this.selectedAnswer,
    this.showResult = false,
    this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.whiteCardDecoration(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Question number và type badge
            _buildHeader(),

            const SizedBox(height: 16),

            // Passage (nếu có - cho Reading Comprehension)
            if (question.passage != null && question.passage!.isNotEmpty) ...[
              _buildPassage(),
              const SizedBox(height: 20),
            ],

            // Blank sentence (nếu có - cho Fill in Blanks)
            if (question.blankSentence != null &&
                question.blankSentence!.isNotEmpty) ...[
              _buildBlankSentence(),
              const SizedBox(height: 20),
            ],

            // Question text
            _buildQuestionText(),

            const SizedBox(height: 24),

            // Answer options
            _buildOptions(),

            // Explanation (nếu có và đang show result)
            if (showResult && question.explanation != null) ...[
              const SizedBox(height: 20),
              _buildExplanation(),
            ],
          ],
        ),
      ),
    );
  }

  /// Header với số thứ tự và badge loại câu hỏi
  Widget _buildHeader() {
    return Row(
      children: [
        // Question number
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Câu $questionNumber/$totalQuestions',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Question type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(question.type.colorValue).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(question.type.colorValue).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(question.type.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                question.type.displayName,
                style: TextStyle(
                  color: Color(question.type.colorValue),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Status indicator (khi show result)
        if (showResult) _buildStatusIndicator(),
      ],
    );
  }

  /// Status indicator (đúng/sai)
  Widget _buildStatusIndicator() {
    final isCorrect =
        selectedAnswer != null &&
        selectedAnswer != -1 &&
        selectedAnswer == question.correctAnswerIndex;
    final isUnanswered = selectedAnswer == null || selectedAnswer == -1;

    if (isUnanswered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.textGrey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_circle_outline,
              size: 16,
              color: AppTheme.textGrey,
            ),
            SizedBox(width: 4),
            Text(
              'Bỏ qua',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.successGreen.withValues(alpha: 0.15)
            : AppTheme.errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
          ),
          const SizedBox(width: 4),
          Text(
            isCorrect ? 'Đúng' : 'Sai',
            style: TextStyle(
              color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Passage box cho Reading Comprehension
  Widget _buildPassage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.paleBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightBlue.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, size: 18, color: AppTheme.accentPurple),
              SizedBox(width: 8),
              Text(
                'Đoạn văn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentPurple,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.passage!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Blank sentence box cho Fill in Blanks
  Widget _buildBlankSentence() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentYellow.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note, size: 18, color: AppTheme.textDark),
              SizedBox(width: 8),
              Text(
                'Điền từ vào chỗ trống',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppTheme.textDark,
              ),
              children: _buildBlankSentenceSpans(),
            ),
          ),
        ],
      ),
    );
  }

  /// Tạo spans cho blank sentence với highlight phần blank
  List<TextSpan> _buildBlankSentenceSpans() {
    final sentence = question.blankSentence!;
    final parts = sentence.split('_____');
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));

      if (i < parts.length - 1) {
        // Thêm blank placeholder
        spans.add(
          const TextSpan(
            text: ' _____ ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
              backgroundColor: Color(0x205EB1FF),
            ),
          ),
        );
      }
    }

    return spans;
  }

  /// Question text
  Widget _buildQuestionText() {
    return Text(
      question.question,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
        height: 1.5,
      ),
    );
  }

  /// Answer options
  Widget _buildOptions() {
    return Column(
      children: List.generate(question.options.length, (index) {
        final isSelected = selectedAnswer == index;
        final isCorrect = showResult
            ? index == question.correctAnswerIndex
            : null;

        return AnswerOptionWidget(
          index: index,
          text: question.options[index],
          isSelected: isSelected,
          isCorrect: isCorrect,
          showResult: showResult,
          onTap: showResult ? null : () => onAnswerSelected?.call(index),
        );
      }),
    );
  }

  /// Explanation box
  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppTheme.successGreen,
              ),
              SizedBox(width: 8),
              Text(
                'Giải thích',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successGreen,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.explanation!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

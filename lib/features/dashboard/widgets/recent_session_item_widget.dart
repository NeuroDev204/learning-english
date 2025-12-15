import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../../quiz/models/quiz_session.dart';

class RecentSessionItemWidget extends StatelessWidget {
  final QuizSession session;

  const RecentSessionItemWidget({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final answeredCount = session.answers
        .where((a) => a.userAnswer.isNotEmpty)
        .length;
    final correctCount = session.correctCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  session.topicName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.mode == 'flashcard' ? 'Flashcard' : 'Quiz',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(session.playedAt),
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('📚', '$answeredCount', 'Từ học'),
              _buildStat('✅', '$correctCount', 'Đúng'),
              _buildStat('📊', '${session.scorePercentage}%', 'Chính xác'),
              _buildStat('⭐', '+${session.xpEarned}', 'XP'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }
}

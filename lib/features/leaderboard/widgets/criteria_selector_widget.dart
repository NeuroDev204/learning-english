import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/leaderboard_entry.dart';

class CriteriaSelectorWidget extends StatelessWidget {
  final LeaderboardCriteria selectedCriteria;
  final LeaderboardPeriod period;
  final Function(LeaderboardCriteria) onCriteriaChanged;

  const CriteriaSelectorWidget({
    super.key,
    required this.selectedCriteria,
    required this.period,
    required this.onCriteriaChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Danh sách criteria theo period
    List<LeaderboardCriteria> availableCriteria;

    if (period == LeaderboardPeriod.allTime) {
      availableCriteria = [
        LeaderboardCriteria.totalXP,
        LeaderboardCriteria.streak,
        LeaderboardCriteria.completedQuizzes,
        LeaderboardCriteria.averageScore,
      ];
    } else if (period == LeaderboardPeriod.weekly) {
      availableCriteria = [
        LeaderboardCriteria.weeklyXP,
        LeaderboardCriteria.weeklyStreak,
        LeaderboardCriteria.completedQuizzes,
        LeaderboardCriteria.averageScore,
      ];
    } else {
      availableCriteria = [
        LeaderboardCriteria.monthlyXP,
        LeaderboardCriteria.monthlyStreak,
        LeaderboardCriteria.completedQuizzes,
        LeaderboardCriteria.averageScore,
      ];
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: availableCriteria.map((criteria) {
          return Expanded(
            child: _buildCriteriaButton(context, criteria),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCriteriaButton(
      BuildContext context, LeaderboardCriteria criteria) {
    final isSelected = selectedCriteria == criteria;
    final label = _getCriteriaLabel(criteria);
    final emoji = _getCriteriaEmoji(criteria);

    return GestureDetector(
      onTap: () => onCriteriaChanged(criteria),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getCriteriaLabel(LeaderboardCriteria criteria) {
    switch (criteria) {
      case LeaderboardCriteria.totalXP:
        return 'Tổng XP';
      case LeaderboardCriteria.weeklyXP:
        return 'XP Tuần';
      case LeaderboardCriteria.monthlyXP:
        return 'XP Tháng';
      case LeaderboardCriteria.streak:
        return 'Chuỗi';
      case LeaderboardCriteria.weeklyStreak:
        return 'Ngày (Tuần)';
      case LeaderboardCriteria.monthlyStreak:
        return 'Ngày (Tháng)';
      case LeaderboardCriteria.completedQuizzes:
        return 'Số bài';
      case LeaderboardCriteria.averageScore:
        return 'Điểm TB';
    }
  }

  String _getCriteriaEmoji(LeaderboardCriteria criteria) {
    switch (criteria) {
      case LeaderboardCriteria.totalXP:
      case LeaderboardCriteria.weeklyXP:
      case LeaderboardCriteria.monthlyXP:
        return '⭐';
      case LeaderboardCriteria.streak:
      case LeaderboardCriteria.weeklyStreak:
      case LeaderboardCriteria.monthlyStreak:
        return '🔥';
      case LeaderboardCriteria.completedQuizzes:
        return '📝';
      case LeaderboardCriteria.averageScore:
        return '📊';
    }
  }
}

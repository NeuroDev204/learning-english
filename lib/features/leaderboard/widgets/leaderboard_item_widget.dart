import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class LeaderboardItemWidget extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final LeaderboardCriteria criteria;
  final LeaderboardPeriod period;

  const LeaderboardItemWidget({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
    required this.criteria,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final service = LeaderboardService();
    final displayValue = service.getDisplayValue(entry, criteria, period);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryBlue.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppTheme.primaryBlue, width: 2)
            : Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getRankColor(entry.rank),
              borderRadius: BorderRadius.circular(22),
              boxShadow: entry.rank <= 3
                  ? [
                      BoxShadow(
                        color: _getRankColor(entry.rank).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: entry.rank <= 3 ? Colors.white : AppTheme.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser
                    ? AppTheme.primaryBlue
                    : AppTheme.lightBlue.withOpacity(0.5),
                width: 2.5,
              ),
              image: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(entry.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: entry.photoUrl == null || entry.photoUrl!.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.paleBlue,
                    ),
                    child: Center(
                      child: Text(
                        entry.displayName.isNotEmpty
                            ? entry.displayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser
                              ? AppTheme.primaryBlue
                              : AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge('⭐', '${entry.totalXP}'),
                    const SizedBox(width: 6),
                    _buildStatBadge('🔥', '${entry.currentStreak}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return AppTheme.accentYellow;
    if (rank == 2) return AppTheme.textGrey;
    if (rank == 3) return AppTheme.accentPink;
    return AppTheme.paleBlue;
  }
}
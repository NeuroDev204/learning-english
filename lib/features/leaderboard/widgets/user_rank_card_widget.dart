import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class UserRankCardWidget extends StatelessWidget {
  final LeaderboardEntry? userEntry;
  final LeaderboardCriteria criteria;
  final LeaderboardPeriod period;

  const UserRankCardWidget({
    super.key,
    required this.userEntry,
    required this.criteria,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (userEntry == null) {
      return const SizedBox.shrink();
    }

    final service = LeaderboardService();
    final displayValue = service.getDisplayValue(userEntry!, criteria, period);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.8),
            AppTheme.primaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                '${userEntry!.rank}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vị trí của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEntry!.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      displayValue,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '⭐',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${userEntry!.totalXP}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
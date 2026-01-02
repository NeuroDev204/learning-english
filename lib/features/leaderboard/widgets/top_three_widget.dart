import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class TopThreeWidget extends StatelessWidget {
  final List<LeaderboardEntry> topThree;
  final LeaderboardCriteria criteria;
  final LeaderboardPeriod period;

  const TopThreeWidget({
    super.key,
    required this.topThree,
    required this.criteria,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }

    final service = LeaderboardService();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🏆 Top 3',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              if (topThree.length > 1)
                Expanded(
                  child: _buildPodium(
                    entry: topThree[1],
                    rank: 2,
                    height: 100,
                    color: AppTheme.textGrey,
                    displayValue: service.getDisplayValue(
                      topThree[1],
                      criteria,
                      period,
                    ),
                  ),
                ),
              // 1st place
              if (topThree.isNotEmpty)
                Expanded(
                  child: _buildPodium(
                    entry: topThree[0],
                    rank: 1,
                    height: 140,
                    color: AppTheme.accentYellow,
                    displayValue: service.getDisplayValue(
                      topThree[0],
                      criteria,
                      period,
                    ),
                  ),
                ),
              // 3rd place
              if (topThree.length > 2)
                Expanded(
                  child: _buildPodium(
                    entry: topThree[2],
                    rank: 3,
                    height: 80,
                    color: AppTheme.accentPink,
                    displayValue: service.getDisplayValue(
                      topThree[2],
                      criteria,
                      period,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium({
    required LeaderboardEntry entry,
    required int rank,
    required double height,
    required Color color,
    required String displayValue,
  }) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            image: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(entry.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: entry.photoUrl == null || entry.photoUrl!.isEmpty
              ? Center(
                  child: Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          entry.displayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Value
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

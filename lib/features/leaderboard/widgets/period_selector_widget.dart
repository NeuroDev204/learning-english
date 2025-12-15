import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/leaderboard_entry.dart';

class PeriodSelectorWidget extends StatelessWidget {
  final LeaderboardPeriod selectedPeriod;
  final Function(LeaderboardPeriod) onPeriodChanged;

  const PeriodSelectorWidget({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.paleBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Tất cả', LeaderboardPeriod.allTime),
          ),
          Expanded(
            child: _buildPeriodButton('Tuần', LeaderboardPeriod.weekly),
          ),
          Expanded(
            child: _buildPeriodButton('Tháng', LeaderboardPeriod.monthly),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, LeaderboardPeriod period) {
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppTheme.primaryBlue
                  : AppTheme.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';

class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int weeklyStreakDays;
  final int monthlyStreakDays;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.weeklyStreakDays,
    required this.monthlyStreakDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentYellow.withOpacity(0.8),
            AppTheme.accentYellow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentYellow.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Chuỗi hiện tại (All-time)
                _buildStreakRow(
                  icon: '🔥',
                  label: 'Chuỗi hiện tại',
                  value: '$currentStreak ngày',
                  isMain: true,
                ),

                const SizedBox(height: 12),
                Divider(color: Colors.white.withOpacity(0.3), height: 1),
                const SizedBox(height: 12),

                // 2. Tuần này
                _buildStreakRow(
                  icon: '📅',
                  label: 'Tuần này',
                  value: '$weeklyStreakDays ngày',
                ),

                const SizedBox(height: 8),

                // 3. Tháng này
                _buildStreakRow(
                  icon: '🗓️',
                  label: 'Tháng này',
                  value: '$monthlyStreakDays ngày',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakRow({
    required String icon,
    required String label,
    required String value,
    bool isMain = false,
  }) {
    return Row(
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: isMain ? 32 : 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 16 : 14,
              color: Colors.white.withOpacity(isMain ? 1.0 : 0.9),
              fontWeight: isMain ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isMain ? 24 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

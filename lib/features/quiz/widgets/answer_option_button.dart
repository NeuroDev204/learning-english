import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';

class AnswerOptionButton extends StatelessWidget {
  final String label;
  final String text;
  final bool? isCorrect;
  final bool isSelected;
  final VoidCallback? onTap;

  const AnswerOptionButton({
    super.key,
    required this.label,
    required this.text,
    this.isCorrect,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Color borderColor = AppTheme.primaryBlue.withValues(alpha: 0.3);
    Color textColor = AppTheme.textDark;
    IconData? icon;
    Color? iconColor;

    // Xác định màu và icon dựa trên trạng thái
    if (isCorrect == true) {
      // Đáp án đúng
      backgroundColor = AppTheme.successGreen.withValues(alpha: 0.25);
      borderColor = AppTheme.successGreen;
      textColor = AppTheme.successGreen;
      icon = Icons.check_circle;
      iconColor = AppTheme.successGreen;
    } else if (isCorrect == false) {
      // Đáp án sai (khi đã chọn sai)
      backgroundColor = AppTheme.errorRed.withValues(alpha: 0.25);
      borderColor = AppTheme.errorRed;
      textColor = AppTheme.errorRed;
      icon = Icons.cancel;
      iconColor = AppTheme.errorRed;
    } else if (isSelected) {
      // Đã chọn nhưng chưa hiển thị kết quả
      borderColor = AppTheme.accentYellow;
      backgroundColor = AppTheme.accentYellow.withValues(alpha: 0.2);
      textColor = AppTheme.textDark;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: isSelected || isCorrect != null ? 3.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isCorrect != null || isSelected)
                  ? borderColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isCorrect != null ? 16 : 12,
              offset: Offset(0, isCorrect != null ? 8 : 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Label với background rõ ràng hơn
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCorrect == true
                    ? AppTheme.successGreen.withValues(alpha: 0.2)
                    : isCorrect == false
                        ? AppTheme.errorRed.withValues(alpha: 0.2)
                        : isSelected
                            ? AppTheme.accentYellow.withValues(alpha: 0.2)
                            : AppTheme.primaryBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCorrect == true
                        ? AppTheme.successGreen
                        : isCorrect == false
                            ? AppTheme.errorRed
                            : isSelected
                                ? AppTheme.accentYellow
                                : AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCorrect != null || isSelected
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            // Icon hiển thị kết quả
            if (icon != null) ...[
              const SizedBox(width: 12),
              Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

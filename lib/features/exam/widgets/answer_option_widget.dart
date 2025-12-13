import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Widget hiển thị nút chọn đáp án
///
/// Hỗ trợ các trạng thái:
/// - Normal: chưa chọn
/// - Selected: đang chọn
/// - Correct: đáp án đúng (khi review)
/// - Incorrect: đáp án sai (khi review)
class AnswerOptionWidget extends StatelessWidget {
  final int index; // 0-3 (A, B, C, D)
  final String text; // Nội dung đáp án
  final bool isSelected; // Đang được chọn không
  final bool? isCorrect; // null = chưa submit, true/false = đáp án đúng/sai
  final bool showResult; // Có hiển thị kết quả không
  final VoidCallback? onTap; // Callback khi tap

  const AnswerOptionWidget({
    super.key,
    required this.index,
    required this.text,
    this.isSelected = false,
    this.isCorrect,
    this.showResult = false,
    this.onTap,
  });

  /// Lấy ký tự đáp án (A, B, C, D)
  String get optionLetter {
    const letters = ['A', 'B', 'C', 'D'];
    return index < letters.length ? letters[index] : '?';
  }

  /// Xác định màu nền dựa trên trạng thái
  Color _getBackgroundColor() {
    if (showResult) {
      if (isCorrect == true) {
        return AppTheme.successGreen.withValues(alpha: 0.15);
      } else if (isSelected && isCorrect == false) {
        return AppTheme.errorRed.withValues(alpha: 0.15);
      }
    }

    if (isSelected) {
      return AppTheme.primaryBlue.withValues(alpha: 0.15);
    }

    return Colors.white;
  }

  /// Xác định màu border dựa trên trạng thái
  Color _getBorderColor() {
    if (showResult) {
      if (isCorrect == true) {
        return AppTheme.successGreen;
      } else if (isSelected && isCorrect == false) {
        return AppTheme.errorRed;
      }
    }

    if (isSelected) {
      return AppTheme.primaryBlue;
    }

    return AppTheme.lightBlue.withValues(alpha: 0.3);
  }

  /// Xác định màu chữ cho option letter
  Color _getLetterColor() {
    if (showResult) {
      if (isCorrect == true) {
        return AppTheme.successGreen;
      } else if (isSelected && isCorrect == false) {
        return AppTheme.errorRed;
      }
    }

    if (isSelected) {
      return AppTheme.primaryBlue;
    }

    return AppTheme.textGrey;
  }

  /// Xác định icon dựa trên trạng thái
  IconData? _getIcon() {
    if (showResult) {
      if (isCorrect == true) {
        return Icons.check_circle;
      } else if (isSelected && isCorrect == false) {
        return Icons.cancel;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final isDisabled = showResult || onTap == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getBorderColor(),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected && !showResult
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Option letter circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected && !showResult
                        ? AppTheme.primaryBlue
                        : _getBorderColor().withValues(alpha: 0.3),
                    border: Border.all(color: _getLetterColor(), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      optionLetter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected && !showResult
                            ? Colors.white
                            : _getLetterColor(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Option text
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                ),

                // Result icon
                if (icon != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    icon,
                    color: isCorrect == true
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    size: 24,
                  ),
                ],

                // Radio indicator (khi chưa submit)
                if (!showResult) ...[
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.textGrey.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:learn_english/core/theme/app_theme.dart';

class LoadingQuizAnimation extends StatelessWidget {
  const LoadingQuizAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bạn tải file Lottie miễn phí này: https://lottiefiles.com/108275-loading-books
          // Đặt vào assets/animations/loading_quiz.json
          Lottie.asset(
            'assets/animations/loading_quiz.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          Text(
            'Đang chuẩn bị câu hỏi...',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          CircularProgressIndicator(color: AppTheme.primaryBlue),
        ],
      ),
    );
  }
}

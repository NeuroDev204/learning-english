import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/topic/models/vocabulary.dart';

class FlashcardWidget extends StatelessWidget {
  final Vocabulary vocabulary;
  const FlashcardWidget({Key? key, required this.vocabulary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      direction: FlipDirection.HORIZONTAL,
      // Mặt trước (Tiếng Anh)
      front: Container(
        decoration: AppTheme.whiteCardDecoration(context: context),
        child: Center(
          child: SingleChildScrollView(
            // Cho phép cuộn nếu chữ quá to
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  vocabulary.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '/${vocabulary.pronunciation}/',
                  style: TextStyle(
                    fontSize: 22,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "(Chạm để xem nghĩa)",
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5)),
                )
              ],
            ),
          ),
        ),
      ),
      // Mặt sau (Tiếng Việt)
      back: Container(
        decoration: AppTheme.whiteCardDecoration(context: context),
        child: Center(
          child: SingleChildScrollView(
            // Quan trọng: Chống lỗi tràn màn hình
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  vocabulary.meaning,
                  style: TextStyle(
                      fontSize: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

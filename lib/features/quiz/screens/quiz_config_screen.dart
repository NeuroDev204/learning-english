// lib/features/quiz/screens/quiz_config_screen.dart
import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/topic/models/topic.dart';
import 'package:learn_english/features/topic/models/vocabulary.dart';
import 'package:learn_english/features/topic/services/vocabulary_service.dart';
import 'package:learn_english/features/quiz/screens/quiz_playing_screen.dart';
import 'package:learn_english/features/quiz/screens/flashcard_screen.dart';

class QuizConfigScreen extends StatefulWidget {
  final Topic topic;
  const QuizConfigScreen({super.key, required this.topic});

  @override
  State<QuizConfigScreen> createState() => _QuizConfigScreenState();
}

class _QuizConfigScreenState extends State<QuizConfigScreen> {
  final VocabularyService _vocabService = VocabularyService();

  int questionCount = 10;
  int totalMinutes = 5;
  String mode = 'quiz';

  List<Vocabulary> _vocabList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVocabularies();
  }

  Future<void> _loadVocabularies() async {
    try {
      final stream = _vocabService.getVocabulariesByTopic(widget.topic.id);
      final list = await stream.first;
      if (mounted) {
        setState(() {
          _vocabList = list;
          _isLoading = false;
          if (_vocabList.length < questionCount) {
            questionCount = _vocabList.length;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải từ vựng: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startQuiz() {
    if (_vocabList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chủ đề này chưa có từ vựng nào!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPlayingScreen(
          topic: widget.topic,
          questionCount: questionCount,
          timerPerQuestion: totalMinutes * 60 ~/ questionCount,
        ),
      ),
    );
  }

  void _startFlashcard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FlashcardScreen(topic: widget.topic)),
    );
  }

  Widget _buildConfigSection(String title, String subtitle, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: AppTheme.textGrey)),
        const SizedBox(height: 16),
        content,
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.textGrey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 24, color: AppTheme.textDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    return Scaffold(
      backgroundColor: AppTheme.paleBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Text(widget.topic.name, style: const TextStyle(color: AppTheme.textDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chọn chế độ
            _buildConfigSection(
              'Chọn chế độ',
              'Quiz trắc nghiệm hoặc Flashcard ôn từ',
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => mode = 'quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mode == 'quiz' ? AppTheme.primaryBlue : Colors.white,
                        foregroundColor: mode == 'quiz' ? Colors.white : AppTheme.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Trắc nghiệm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => mode = 'flashcard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mode == 'flashcard' ? AppTheme.primaryBlue : Colors.white,
                        foregroundColor: mode == 'flashcard' ? Colors.white : AppTheme.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Flashcard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            if (mode == 'quiz') ...[
              // Số lượng câu hỏi – DÙNG SLIDER NHƯ BAN ĐẦU
              _buildConfigSection(
                'Số lượng câu hỏi',
                'Tối đa ${_vocabList.length} từ trong chủ đề',
                Column(
                  children: [
                    Slider(
                      value: questionCount.toDouble(),
                      min: 1,
                      max: _vocabList.length.toDouble(),
                      divisions: _vocabList.length - 1,
                      label: questionCount.toString(),
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (value) {
                        setState(() {
                          questionCount = value.round();
                        });
                      },
                    ),
                    Text(
                      '$questionCount câu hỏi',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              ),

              // Thời gian làm bài – GIỮ Ô NHẬP + NÚT +/-
              _buildConfigSection(
                'Thời gian làm bài',
                'Tổng thời gian cho toàn bộ câu hỏi',
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _circleButton(
                      icon: Icons.remove,
                      onTap: () {
                        setState(() {
                          if (totalMinutes > 1) totalMinutes--;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '$totalMinutes',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          final newValue = int.tryParse(value);
                          if (newValue != null && newValue >= 1 && newValue <= 60) {
                            setState(() {
                              totalMinutes = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('phút', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 20),
                    _circleButton(
                      icon: Icons.add,
                      onTap: () {
                        setState(() {
                          if (totalMinutes < 60) totalMinutes++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Nút bắt đầu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: mode == 'quiz' ? _startQuiz : _startFlashcard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  mode == 'quiz' ? 'Bắt đầu trắc nghiệm' : 'Bắt đầu Flashcard',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
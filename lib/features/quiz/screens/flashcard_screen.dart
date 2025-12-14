import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/quiz/widgets/flashcard_widget.dart';
import 'package:learn_english/features/topic/models/topic.dart';
import 'package:learn_english/features/topic/models/vocabulary.dart';
import 'package:learn_english/features/topic/services/vocabulary_service.dart';

class FlashcardScreen extends StatefulWidget {
  final Topic topic;
  const FlashcardScreen({Key? key, required this.topic}) : super(key: key);

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final VocabularyService _service = VocabularyService();
  List<Vocabulary> _vocabList = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stream = _service.getVocabulariesByTopic(widget.topic.id);
    final list = await stream.first;
    if (mounted) {
      setState(() {
        _vocabList = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paleBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.topic.name, style: const TextStyle(color: AppTheme.textDark)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vocabList.isEmpty
              ? const Center(child: Text('Chưa có từ vựng nào'))
              : Column(
                  children: [
                    // Thanh tiến trình
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _vocabList.length,
                      color: AppTheme.primaryBlue,
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 6,
                    ),
                    
                    const SizedBox(height: 20),

                    // Nội dung Flashcard (Expanded để chiếm chỗ trống còn lại)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Center(
                              child: SizedBox(
                                height: constraints.maxHeight * 0.85, // Giới hạn chiều cao thẻ
                                width: double.infinity,
                                child: FlashcardWidget(
                                  vocabulary: _vocabList[_currentIndex],
                                  // Key giúp reset trạng thái lật thẻ khi đổi từ
                                  key: ValueKey(_vocabList[_currentIndex].id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Khu vực nút điều hướng
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Nút Trước
                          ElevatedButton.icon(
                            onPressed: _currentIndex > 0
                                ? () => setState(() => _currentIndex--)
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Trước"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryBlue,
                              elevation: 0,
                              side: const BorderSide(color: AppTheme.primaryBlue),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),

                          // Số trang
                          Text(
                            '${_currentIndex + 1} / ${_vocabList.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),

                          // Nút Tiếp
                          ElevatedButton.icon(
                            onPressed: _currentIndex < _vocabList.length - 1
                                ? () => setState(() => _currentIndex++)
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text("Tiếp"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
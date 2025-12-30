import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/topic/models/topic.dart';
import 'package:learn_english/features/topic/models/vocabulary.dart';
import 'package:learn_english/features/vocabulary/services/groq_vocab_service.dart';
import 'package:learn_english/features/topic/services/vocabulary_service.dart';

class VocabularyGenerateScreen extends StatefulWidget {
  final Topic topic;

  const VocabularyGenerateScreen({super.key, required this.topic});

  @override
  State<VocabularyGenerateScreen> createState() =>
      _VocabularyGenerateScreenState();
}

class _VocabularyGenerateScreenState extends State<VocabularyGenerateScreen> {
  final VocabularyService _vocabService = VocabularyService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _wordCount = 15;
  String _selectedLevel = 'intermediate';
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _generatedVocab = [];

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedVocab = [];
    });

    try {
      final list = await GroqVocabService.generateVocabList(
        topic: widget.topic.name,
        wordCount: _wordCount,
        level: _selectedLevel,
      );

      setState(() => _generatedVocab = list);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      final vocabs = _generatedVocab.map((item) {
        return Vocabulary(
          id: '',
          topicId: widget.topic.id,
          word: item['en'] ?? '',
          pronunciation: item['ipa'] ?? '',
          meaning: item['vn'] ?? '',
          example: item['example'] ?? '',
          synonyms: [],
          level: _selectedLevel,
          partOfSpeech: item['type'],
          tags: [],
          createdAt: DateTime.now(),
        );
      }).toList();

      await _vocabService.createMultipleVocabularies(vocabs);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã lưu thành công $_wordCount từ mới!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lưu thất bại: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AI Generate Vocabulary',
            style: TextStyle(color: AppTheme.textDark)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                      color: AppTheme.paleBlue,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.auto_awesome,
                      size: 50, color: AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 24),

              // Topic info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.paleBlue,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chủ đề:',
                        style: TextStyle(color: AppTheme.textGrey)),
                    const SizedBox(height: 4),
                    Text(widget.topic.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Số lượng từ
              const Text('Số lượng từ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Slider(
                value: _wordCount.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                label: _wordCount.toString(),
                onChanged: (v) => setState(() => _wordCount = v.toInt()),
              ),
              Center(
                  child: Text('$_wordCount từ',
                      style: const TextStyle(color: AppTheme.textGrey))),
              const SizedBox(height: 24),

              // Độ khó
              const Text('Độ khó',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildLevelButton('beginner', 'Beginner')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildLevelButton('intermediate', 'Intermediate')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLevelButton('advanced', 'Advanced')),
                ],
              ),
              const SizedBox(height: 32),

              // Nút generate
              ElevatedButton(
                onPressed: _isGenerating ? null : _generate,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56)),
                child: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Generate với AI',
                        style: TextStyle(fontSize: 16)),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    style: const TextStyle(color: AppTheme.errorRed)),
              ],

              // Preview kết quả
              if (_generatedVocab.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text('Preview kết quả (${_generatedVocab.length} từ)',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _generatedVocab.length,
                  itemBuilder: (_, i) {
                    final item = _generatedVocab[i];
                    return Card(
                      child: ListTile(
                        title: Text(item['en'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${item['vn']} • ${item['type']}\n${item['example']}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveAll,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppTheme.successGreen,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Lưu tất cả vào bộ từ',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(String value, String label) {
    final selected = _selectedLevel == value;
    Color color = switch (value) {
      'beginner' => AppTheme.successGreen,
      'intermediate' => AppTheme.warningYellow,
      'advanced' => AppTheme.errorRed,
      _ => AppTheme.primaryBlue,
    };

    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300, width: 2),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textGrey,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

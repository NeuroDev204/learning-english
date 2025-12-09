import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';

class VocabularyCreateScreen extends StatefulWidget {
  final String topicId;

  const VocabularyCreateScreen({Key? key, required this.topicId})
    : super(key: key);

  @override
  State<VocabularyCreateScreen> createState() => _VocabularyCreateScreenState();
}

class _VocabularyCreateScreenState extends State<VocabularyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = VocabularyService();

  final _wordController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();
  final _synonymsController = TextEditingController();

  String _selectedLevel = 'beginner';
  bool _isLoading = false;

  @override
  void dispose() {
    _wordController.dispose();
    _pronunciationController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _synonymsController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse synonyms từ string thành list
      final synonymsList = _synonymsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final vocab = Vocabulary(
        id: '',
        topicId: widget.topicId,
        word: _wordController.text.trim(),
        pronunciation: _pronunciationController.text.trim(),
        meaning: _meaningController.text.trim(),
        example: _exampleController.text.trim(),
        synonyms: synonymsList,
        level: _selectedLevel,
        createdAt: DateTime.now(),
      );

      await _service.createVocabulary(vocab);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vocabulary added successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text(
          'Add New Word',
          style: TextStyle(color: AppTheme.textDark),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.paleBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    size: 40,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Word (English)
              TextFormField(
                controller: _wordController,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Word (English) *',
                  hintText: 'e.g., hello',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a word';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pronunciation (IPA)
              TextFormField(
                controller: _pronunciationController,
                decoration: const InputDecoration(
                  labelText: 'Pronunciation (IPA) *',
                  hintText: 'e.g., həˈloʊ',
                  prefixIcon: Icon(Icons.record_voice_over),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pronunciation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Meaning (Vietnamese)
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(
                  labelText: 'Meaning (Vietnamese) *',
                  hintText: 'e.g., xin chào',
                  prefixIcon: Icon(Icons.translate),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter meaning';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Example
              TextFormField(
                controller: _exampleController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Example Sentence *',
                  hintText: 'e.g., Hello, how are you?',
                  prefixIcon: Icon(Icons.chat_bubble_outline),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an example';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Synonyms (optional)
              TextFormField(
                controller: _synonymsController,
                decoration: const InputDecoration(
                  labelText: 'Synonyms (optional)',
                  hintText: 'e.g., hi, greetings (comma separated)',
                  prefixIcon: Icon(Icons.list_alt),
                ),
              ),
              const SizedBox(height: 24),

              // Level selector
              const Text(
                'Difficulty Level *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildLevelOption('beginner', 'Beginner')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLevelOption('intermediate', 'Intermediate'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLevelOption('advanced', 'Advanced')),
                ],
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.paleBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fields marked with * are required',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Add Vocabulary'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelOption(String value, String label) {
    final isSelected = _selectedLevel == value;
    Color color;

    switch (value) {
      case 'beginner':
        color = AppTheme.successGreen;
        break;
      case 'intermediate':
        color = AppTheme.warningYellow;
        break;
      case 'advanced':
        color = AppTheme.errorRed;
        break;
      default:
        color = AppTheme.primaryBlue;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textGrey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

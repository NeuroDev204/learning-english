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
  String? _selectedPartOfSpeech;
  final Set<String> _selectedTags = {};
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
        partOfSpeech: _selectedPartOfSpeech,
        tags: _selectedTags.toList(),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Word',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
                child: Builder(
                  builder: (context) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      size: 40,
                      color: AppTheme.primaryBlue,
                    ),
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

              // ✅ NEW: Part of Speech
              Builder(
                builder: (context) => Text(
                  'Part of Speech',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PartOfSpeech.all.map((pos) {
                  final isSelected = _selectedPartOfSpeech == pos;
                  return Builder(
                    builder: (context) => ChoiceChip(
                      label: Text(
                        '${PartOfSpeech.getIcon(pos)} ${pos}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPartOfSpeech = selected ? pos : null;
                        });
                      },
                      selectedColor: AppTheme.primaryBlue,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ✅ NEW: Tags
              Builder(
                builder: (context) => Text(
                  'Tags (Multiple selection)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: VocabularyTags.all.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return Builder(
                    builder: (context) => FilterChip(
                      label: Text(
                        '${VocabularyTags.getIcon(tag)} ${tag}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                      selectedColor: AppTheme.accentPink,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Level selector
              Builder(
                builder: (context) => Text(
                  'Difficulty Level *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
              Builder(
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
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
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
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

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          setState(() {
            _selectedLevel = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

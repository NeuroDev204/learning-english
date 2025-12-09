import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/auth/services/auth_service.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';
import 'vocabulary_create_screen.dart';
import 'vocabulary_edit_screen.dart';

class VocabularyListScreen extends StatefulWidget {
  final Topic topic;

  const VocabularyListScreen({Key? key, required this.topic}) : super(key: key);

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  final VocabularyService _service = VocabularyService();
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final role = authService.currentUserData?.role ?? 'user';
        final isAdmin = role == 'admin';

        return Scaffold(
          backgroundColor: AppTheme.paleBlue,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.name,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Vocabulary List',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: AppTheme.primaryBlue,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),

          // FAB chỉ hiện với admin
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            VocabularyCreateScreen(topicId: widget.topic.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Word'),
                  backgroundColor: AppTheme.primaryBlue,
                )
              : null,

          body: Column(
            children: [
              // Search bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search vocabulary...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppTheme.primaryBlue),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Vocabulary list
              Expanded(
                child: StreamBuilder<List<Vocabulary>>(
                  stream: _searchQuery.isEmpty
                      ? _service.getVocabulariesByTopic(widget.topic.id)
                      : _service.searchVocabularies(
                          widget.topic.id,
                          _searchQuery,
                        ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final vocabularies = snapshot.data ?? [];

                    if (vocabularies.isEmpty) {
                      return _buildEmptyState(isAdmin);
                    }

                    return _isGridView
                        ? _buildGridView(vocabularies, isAdmin)
                        : _buildListView(vocabularies, isAdmin);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState(bool isAdmin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.paleBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No vocabulary yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Tap the + button to add your first word'
                  : 'No words available in this topic yet',
              style: const TextStyle(fontSize: 14, color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LIST VIEW ====================
  Widget _buildListView(List<Vocabulary> vocabularies, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: vocabularies.length,
      itemBuilder: (context, index) {
        final vocab = vocabularies[index];
        return _buildVocabCard(vocab, isAdmin);
      },
    );
  }

  // ==================== GRID VIEW ====================
  Widget _buildGridView(List<Vocabulary> vocabularies, bool isAdmin) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: vocabularies.length,
      itemBuilder: (context, index) {
        final vocab = vocabularies[index];
        return _buildVocabGridCard(vocab, isAdmin);
      },
    );
  }

  // ==================== VOCAB CARD (LIST) ====================
  Widget _buildVocabCard(Vocabulary vocab, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showVocabDetail(vocab),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getLevelColor(vocab.level),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    vocab.level[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vocab.word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/${vocab.pronunciation}/',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vocab.meaning,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Admin menu
              if (isAdmin)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: AppTheme.textGrey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppTheme.errorRed,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VocabularyEditScreen(vocabulary: vocab),
                        ),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(vocab);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== VOCAB CARD (GRID) ====================
  Widget _buildVocabGridCard(Vocabulary vocab, bool isAdmin) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showVocabDetail(vocab),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getLevelColor(vocab.level),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vocab.level.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Word
                  Text(
                    vocab.word,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Pronunciation
                  Text(
                    '/${vocab.pronunciation}/',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGrey,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Meaning
                  Text(
                    vocab.meaning,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Admin menu
            if (isAdmin)
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.textGrey,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VocabularyEditScreen(vocabulary: vocab),
                        ),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(vocab);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================
  Color _getLevelColor(String level) {
    switch (level) {
      case 'beginner':
        return AppTheme.successGreen;
      case 'intermediate':
        return AppTheme.warningYellow;
      case 'advanced':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryBlue;
    }
  }

  void _showVocabDetail(Vocabulary vocab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Word
                    Text(
                      vocab.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Pronunciation
                    Text(
                      '/${vocab.pronunciation}/',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppTheme.textGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getLevelColor(vocab.level),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        vocab.level.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meaning
                    _buildDetailSection('Meaning', vocab.meaning),

                    // Example
                    _buildDetailSection('Example', vocab.example),

                    // Synonyms
                    if (vocab.synonyms.isNotEmpty)
                      _buildDetailSection(
                        'Synonyms',
                        vocab.synonyms.join(', '),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Vocabulary vocab) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Vocabulary?'),
        content: Text('Are you sure you want to delete "${vocab.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.deleteVocabulary(vocab.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vocabulary deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

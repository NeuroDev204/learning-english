import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learn_english/features/topic/models/vocabulary.dart';

/// Service quản lý CRUD cho Vocabulary - UPDATED with Filters
class VocabularyService {
  final CollectionReference _vocabRef = FirebaseFirestore.instance.collection(
    'vocabularies',
  );

  // ==================== CREATE ====================

  Future<String> createVocabulary(Vocabulary vocab) async {
    try {
      final docRef = await _vocabRef.add(vocab.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create vocabulary: $e');
    }
  }

  // ==================== READ ====================

  Stream<List<Vocabulary>> getVocabulariesByTopic(String topicId) {
    return _vocabRef
        .where('topicId', isEqualTo: topicId)
        .orderBy('word')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Vocabulary.fromFirestore(doc))
              .toList();
        });
  }

  Future<Vocabulary?> getVocabularyById(String vocabId) async {
    try {
      final doc = await _vocabRef.doc(vocabId).get();
      if (!doc.exists) return null;
      return Vocabulary.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get vocabulary: $e');
    }
  }

  // ✅ NEW: Filter by multiple criteria
  Stream<List<Vocabulary>> getFilteredVocabularies({
    required String topicId,
    String? level,
    String? partOfSpeech,
    List<String>? tags,
    String? searchQuery,
  }) {
    return _vocabRef.where('topicId', isEqualTo: topicId).snapshots().map((
      snapshot,
    ) {
      var vocabs = snapshot.docs
          .map((doc) => Vocabulary.fromFirestore(doc))
          .toList();

      // Filter by level
      if (level != null && level.isNotEmpty) {
        vocabs = vocabs.where((v) => v.level == level).toList();
      }

      // Filter by part of speech
      if (partOfSpeech != null && partOfSpeech.isNotEmpty) {
        vocabs = vocabs.where((v) => v.partOfSpeech == partOfSpeech).toList();
      }

      // Filter by tags (contains any of the tags)
      if (tags != null && tags.isNotEmpty) {
        vocabs = vocabs.where((v) {
          return v.tags.any((tag) => tags.contains(tag));
        }).toList();
      }

      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        vocabs = vocabs.where((v) {
          return v.word.toLowerCase().contains(query) ||
              v.meaning.toLowerCase().contains(query) ||
              v.example.toLowerCase().contains(query);
        }).toList();
      }

      // Sort by word
      vocabs.sort((a, b) => a.word.compareTo(b.word));

      return vocabs;
    });
  }

  Stream<List<Vocabulary>> searchVocabularies(String topicId, String keyword) {
    return _vocabRef.where('topicId', isEqualTo: topicId).snapshots().map((
      snapshot,
    ) {
      final allVocabs = snapshot.docs
          .map((doc) => Vocabulary.fromFirestore(doc))
          .toList();

      final query = keyword.toLowerCase();
      return allVocabs.where((vocab) {
        return vocab.word.toLowerCase().contains(query) ||
            vocab.meaning.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<int> countVocabulariesInTopic(String topicId) async {
    try {
      final snapshot = await _vocabRef
          .where('topicId', isEqualTo: topicId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ==================== UPDATE ====================

  Future<void> updateVocabulary(String vocabId, Vocabulary vocab) async {
    try {
      final updatedVocab = vocab.copyWith(updatedAt: DateTime.now());
      await _vocabRef.doc(vocabId).update(updatedVocab.toMap());
    } catch (e) {
      throw Exception('Failed to update vocabulary: $e');
    }
  }

  // ==================== DELETE ====================
  Future<void> deleteVocabulary(String vocabId) async {
    try {
      await _vocabRef.doc(vocabId).delete();
    } catch (e) {
      throw Exception('Failed to delete vocabulary: $e');
    }
  }

  Future<void> deleteAllVocabulariesInTopic(String topicId) async {
    try {
      final snapshot = await _vocabRef
          .where('topicId', isEqualTo: topicId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete vocabularies: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  Future<void> createMultipleVocabularies(List<Vocabulary> vocabs) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var vocab in vocabs) {
        final docRef = _vocabRef.doc();
        batch.set(docRef, vocab.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create multiple vocabularies: $e');
    }
  }

  // ==================== STATISTICS ====================

  Future<Map<String, int>> getVocabularyStatsByLevel(String topicId) async {
    try {
      final snapshot = await _vocabRef
          .where('topicId', isEqualTo: topicId)
          .get();

      final stats = <String, int>{
        'beginner': 0,
        'intermediate': 0,
        'advanced': 0,
      };

      for (var doc in snapshot.docs) {
        final vocab = Vocabulary.fromFirestore(doc);
        stats[vocab.level] = (stats[vocab.level] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      return {};
    }
  }

  // ✅ NEW: Stats by part of speech
  Future<Map<String, int>> getStatsByPartOfSpeech(String topicId) async {
    try {
      final snapshot = await _vocabRef
          .where('topicId', isEqualTo: topicId)
          .get();

      final stats = <String, int>{};

      for (var doc in snapshot.docs) {
        final vocab = Vocabulary.fromFirestore(doc);
        if (vocab.partOfSpeech != null) {
          stats[vocab.partOfSpeech!] = (stats[vocab.partOfSpeech!] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      return {};
    }
  }

  // ✅ NEW: Stats by tags
  Future<Map<String, int>> getStatsByTags(String topicId) async {
    try {
      final snapshot = await _vocabRef
          .where('topicId', isEqualTo: topicId)
          .get();

      final stats = <String, int>{};

      for (var doc in snapshot.docs) {
        final vocab = Vocabulary.fromFirestore(doc);
        for (var tag in vocab.tags) {
          stats[tag] = (stats[tag] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      return {};
    }
  }

  Stream<List<Vocabulary>> getAllVocabularies() {
    return _vocabRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Vocabulary.fromFirestore(doc)).toList();
    });
  }
}

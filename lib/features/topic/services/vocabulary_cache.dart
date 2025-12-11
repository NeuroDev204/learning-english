import 'package:hive/hive.dart';
import 'package:learn_english/features/topic/models/vocabulary.dart';

/// Cache service cho Vocabulary - Offline support
class VocabularyCache {
  final Box box = Hive.box('vocabularyCache');

  // ==================== SAVE ====================

  /// Lưu danh sách vocabulary của 1 topic
  void saveVocabulariesByTopic(String topicId, List<Vocabulary> vocabs) {
    try {
      final data = vocabs.map((v) => v.toMap()).toList();
      box.put('topic_$topicId', data);
      
      // Lưu timestamp để check expire
      box.put('topic_${topicId}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving vocabularies to cache: $e');
    }
  }

  /// Lưu 1 vocabulary
  void saveVocabulary(Vocabulary vocab) {
    try {
      box.put('vocab_${vocab.id}', vocab.toMap());
    } catch (e) {
      print('Error saving vocabulary to cache: $e');
    }
  }

  // ==================== GET ====================

  /// Lấy danh sách vocabulary của 1 topic
  List<Vocabulary> getVocabulariesByTopic(String topicId) {
    try {
      final raw = box.get('topic_$topicId');
      if (raw == null) return [];

      // Check if cache is expired (older than 7 days)
      if (_isCacheExpired('topic_${topicId}_timestamp', days: 7)) {
        return [];
      }

      return (raw as List)
          .map((e) => Vocabulary.fromMap(e as Map<String, dynamic>, e['id'] ?? ''))
          .toList();
    } catch (e) {
      print('Error getting vocabularies from cache: $e');
      return [];
    }
  }

  /// Lấy 1 vocabulary
  Vocabulary? getVocabulary(String vocabId) {
    try {
      final raw = box.get('vocab_$vocabId');
      if (raw == null) return null;

      return Vocabulary.fromMap(raw as Map<String, dynamic>, vocabId);
    } catch (e) {
      print('Error getting vocabulary from cache: $e');
      return null;
    }
  }

  // ==================== DELETE ====================

  /// Xóa cache của 1 topic
  void deleteTopicCache(String topicId) {
    try {
      box.delete('topic_$topicId');
      box.delete('topic_${topicId}_timestamp');
    } catch (e) {
      print('Error deleting topic cache: $e');
    }
  }

  /// Xóa cache của 1 vocabulary
  void deleteVocabularyCache(String vocabId) {
    try {
      box.delete('vocab_$vocabId');
    } catch (e) {
      print('Error deleting vocabulary cache: $e');
    }
  }

  /// Xóa toàn bộ cache
  void clearAllCache() {
    try {
      box.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // ==================== UTILITY ====================

  /// Check if cache is expired
  bool _isCacheExpired(String timestampKey, {int days = 7}) {
    try {
      final timestampStr = box.get(timestampKey);
      if (timestampStr == null) return true;

      final timestamp = DateTime.parse(timestampStr as String);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      return difference.inDays > days;
    } catch (e) {
      return true;
    }
  }

  /// Check if topic has cache
  bool hasTopicCache(String topicId) {
    return box.containsKey('topic_$topicId');
  }

  /// Get cache size (number of cached topics)
  int getCacheSize() {
    return box.keys.where((key) => key.toString().startsWith('topic_')).length;
  }

  /// Get all cached topic IDs
  List<String> getCachedTopicIds() {
    return box.keys
        .where((key) => key.toString().startsWith('topic_') && 
               !key.toString().endsWith('_timestamp'))
        .map((key) => key.toString().replaceFirst('topic_', ''))
        .toList();
  }
}

/// Hybrid service: Firebase + Cache
class VocabularyHybridService {
  final VocabularyCache _cache = VocabularyCache();

  /// Get vocabularies with cache fallback
  /// 1. Load from cache first (instant)
  /// 2. Then fetch from Firebase (update cache)
  Stream<List<Vocabulary>> getVocabulariesWithCache(
    String topicId,
    Stream<List<Vocabulary>> firebaseStream,
  ) async* {
    // Step 1: Emit cached data first (if exists)
    final cachedVocabs = _cache.getVocabulariesByTopic(topicId);
    if (cachedVocabs.isNotEmpty) {
      yield cachedVocabs;
    }

    // Step 2: Listen to Firebase and update cache
    await for (final vocabs in firebaseStream) {
      _cache.saveVocabulariesByTopic(topicId, vocabs);
      yield vocabs;
    }
  }

  /// Clear cache for a topic
  void clearTopicCache(String topicId) {
    _cache.deleteTopicCache(topicId);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clearAllCache();
  }
}
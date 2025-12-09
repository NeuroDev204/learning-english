import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learn_english/features/topic/models/vocabulary.dart';

/// Service quản lý CRUD cho Vocabulary
class VocabularyService {
  final CollectionReference _vocabRef = FirebaseFirestore.instance.collection(
    'vocabularies',
  );

  // ==================== CREATE ====================

  /// Thêm từ vựng mới vào topic
  Future<String> createVocabulary(Vocabulary vocab) async {
    try {
      final docRef = await _vocabRef.add(vocab.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create vocabulary: $e');
    }
  }

  // ==================== READ ====================

  /// Lấy tất cả từ vựng của 1 topic (Stream real-time)
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

  /// Lấy 1 từ vựng theo ID
  Future<Vocabulary?> getVocabularyById(String vocabId) async {
    try {
      final doc = await _vocabRef.doc(vocabId).get();
      if (!doc.exists) return null;
      return Vocabulary.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get vocabulary: $e');
    }
  }

  /// Tìm kiếm từ vựng theo keyword trong topic
  Stream<List<Vocabulary>> searchVocabularies(String topicId, String keyword) {
    return _vocabRef.where('topicId', isEqualTo: topicId).snapshots().map((
      snapshot,
    ) {
      final allVocabs = snapshot.docs
          .map((doc) => Vocabulary.fromFirestore(doc))
          .toList();

      // Filter locally (Firestore không hỗ trợ search text tốt)
      return allVocabs.where((vocab) {
        final query = keyword.toLowerCase();
        return vocab.word.toLowerCase().contains(query) ||
            vocab.meaning.toLowerCase().contains(query);
      }).toList();
    });
  }

  /// Đếm số từ vựng trong topic
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

  /// Cập nhật từ vựng
  Future<void> updateVocabulary(String vocabId, Vocabulary vocab) async {
    try {
      final updatedVocab = vocab.copyWith(updatedAt: DateTime.now());
      await _vocabRef.doc(vocabId).update(updatedVocab.toMap());
    } catch (e) {
      throw Exception('Failed to update vocabulary: $e');
    }
  }

  // ==================== DELETE ====================

  /// Xóa 1 từ vựng
  Future<void> deleteVocabulary(String vocabId) async {
    try {
      await _vocabRef.doc(vocabId).delete();
    } catch (e) {
      throw Exception('Failed to delete vocabulary: $e');
    }
  }

  /// Xóa tất cả từ vựng trong topic (khi xóa topic)
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

  /// Thêm nhiều từ vựng cùng lúc
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

  /// Lấy thống kê từ vựng theo level
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

  /// Lấy tất cả từ vựng (để hiển thị ở home, sắp xếp theo ngày tạo)
  Stream<List<Vocabulary>> getAllVocabularies() {
    // NOTE: Có thể thêm .limit(20) để giới hạn số lượng từ vựng ở home
    return _vocabRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Vocabulary.fromFirestore(doc)).toList();
    });
  }
}

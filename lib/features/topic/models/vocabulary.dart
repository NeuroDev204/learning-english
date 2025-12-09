import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho từ vựng
/// Mỗi từ vựng thuộc về 1 topic
class Vocabulary {
  final String id;
  final String topicId; // ID của topic mà từ này thuộc về
  final String word; // Từ tiếng Anh
  final String pronunciation; // Phiên âm IPA
  final String meaning; // Nghĩa tiếng Việt
  final String example; // Câu ví dụ
  final String? imageUrl; // URL hình ảnh minh họa (optional)
  final List<String> synonyms; // Từ đồng nghĩa
  final String level; // Cấp độ: beginner, intermediate, advanced
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags; // noun, verb, adjective, idiom...
  final String? partOfSpeech;

  Vocabulary({
    required this.id,
    required this.topicId,
    required this.word,
    required this.pronunciation,
    required this.meaning,
    required this.example,
    this.imageUrl,
    this.synonyms = const [],
    this.level = 'beginner',
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.partOfSpeech,
  });

  /// Chuyển sang Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'word': word,
      'pronunciation': pronunciation,
      'meaning': meaning,
      'example': example,
      'imageUrl': imageUrl,
      'synonyms': synonyms,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Tạo từ Map
  factory Vocabulary.fromMap(Map<String, dynamic> map, String docId) {
    return Vocabulary(
      id: docId,
      topicId: map['topicId'] ?? '',
      word: map['word'] ?? '',
      pronunciation: map['pronunciation'] ?? '',
      meaning: map['meaning'] ?? '',
      example: map['example'] ?? '',
      imageUrl: map['imageUrl'],
      synonyms: List<String>.from(map['synonyms'] ?? []),
      level: map['level'] ?? 'beginner',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  /// Tạo từ Firestore Document
  factory Vocabulary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vocabulary.fromMap(data, doc.id);
  }

  /// Copy with để cập nhật
  Vocabulary copyWith({
    String? id,
    String? topicId,
    String? word,
    String? pronunciation,
    String? meaning,
    String? example,
    String? imageUrl,
    List<String>? synonyms,
    String? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      word: word ?? this.word,
      pronunciation: pronunciation ?? this.pronunciation,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      imageUrl: imageUrl ?? this.imageUrl,
      synonyms: synonyms ?? this.synonyms,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

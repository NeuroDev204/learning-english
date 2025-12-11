import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho từ vựng - UPDATED with tags & part of speech
class Vocabulary {
  final String id;
  final String topicId;
  final String word;
  final String pronunciation;
  final String meaning;
  final String example;
  final String? imageUrl;
  final List<String> synonyms;
  final String level; // beginner, intermediate, advanced

  // ✅ NEW FIELDS
  final String? partOfSpeech; // noun, verb, adjective, adverb, etc.
  final List<String> tags; // idiom, phrasal-verb, slang, business, etc.

  final DateTime createdAt;
  final DateTime? updatedAt;

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
    this.partOfSpeech,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
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
      'partOfSpeech': partOfSpeech,
      'tags': tags,
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
      partOfSpeech: map['partOfSpeech'],
      tags: List<String>.from(map['tags'] ?? []),
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
    String? partOfSpeech,
    List<String>? tags,
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
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Constants cho Part of Speech
class PartOfSpeech {
  static const String noun = 'noun';
  static const String verb = 'verb';
  static const String adjective = 'adjective';
  static const String adverb = 'adverb';
  static const String pronoun = 'pronoun';
  static const String preposition = 'preposition';
  static const String conjunction = 'conjunction';
  static const String interjection = 'interjection';

  static const List<String> all = [
    noun,
    verb,
    adjective,
    adverb,
    pronoun,
    preposition,
    conjunction,
    interjection,
  ];

  static String getLabel(String value) {
    switch (value) {
      case noun:
        return 'Noun (Danh từ)';
      case verb:
        return 'Verb (Động từ)';
      case adjective:
        return 'Adjective (Tính từ)';
      case adverb:
        return 'Adverb (Trạng từ)';
      case pronoun:
        return 'Pronoun (Đại từ)';
      case preposition:
        return 'Preposition (Giới từ)';
      case conjunction:
        return 'Conjunction (Liên từ)';
      case interjection:
        return 'Interjection (Thán từ)';
      default:
        return value;
    }
  }

  static String getIcon(String value) {
    switch (value) {
      case noun:
        return '📦';
      case verb:
        return '⚡';
      case adjective:
        return '🎨';
      case adverb:
        return '🔄';
      case pronoun:
        return '👤';
      case preposition:
        return '📍';
      case conjunction:
        return '🔗';
      case interjection:
        return '❗';
      default:
        return '📝';
    }
  }
}

/// Constants cho Tags
class VocabularyTags {
  static const String idiom = 'idiom';
  static const String phrasalVerb = 'phrasal-verb';
  static const String slang = 'slang';
  static const String business = 'business';
  static const String academic = 'academic';
  static const String informal = 'informal';
  static const String formal = 'formal';
  static const String common = 'common';
  static const String rare = 'rare';

  static const List<String> all = [
    idiom,
    phrasalVerb,
    slang,
    business,
    academic,
    informal,
    formal,
    common,
    rare,
  ];

  static String getLabel(String value) {
    switch (value) {
      case idiom:
        return 'Idiom (Thành ngữ)';
      case phrasalVerb:
        return 'Phrasal Verb';
      case slang:
        return 'Slang (Tiếng lóng)';
      case business:
        return 'Business (Kinh doanh)';
      case academic:
        return 'Academic (Học thuật)';
      case informal:
        return 'Informal (Thân mật)';
      case formal:
        return 'Formal (Trang trọng)';
      case common:
        return 'Common (Phổ biến)';
      case rare:
        return 'Rare (Ít dùng)';
      default:
        return value;
    }
  }

  static String getIcon(String value) {
    switch (value) {
      case idiom:
        return '🎭';
      case phrasalVerb:
        return '🔀';
      case slang:
        return '😎';
      case business:
        return '💼';
      case academic:
        return '🎓';
      case informal:
        return '💬';
      case formal:
        return '👔';
      case common:
        return '⭐';
      case rare:
        return '💎';
      default:
        return '🏷️';
    }
  }
}

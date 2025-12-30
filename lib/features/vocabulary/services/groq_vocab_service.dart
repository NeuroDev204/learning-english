import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqVocabService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  /// Generate danh sách từ vựng theo topic bằng Groq AI
  static Future<List<Map<String, dynamic>>> generateVocabList({
    required String topic,
    int wordCount = 20,
    String level = 'intermediate', // beginner, intermediate, advanced
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not found in .env file');
    }

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "llama-3.1-8b-instant",
        "temperature": 0.7,
        "max_tokens": 4096,
        "messages": [
          {
            "role": "system",
            "content": "You are an expert English teacher. Respond ONLY with valid JSON array, no explanations, no markdown."
          },
          {
            "role": "user",
            "content": """
Generate exactly $wordCount $level-level English vocabulary words related to "$topic".

For each word:
- en: English word or phrase
- vn: Natural and accurate Vietnamese translation
- ipa: UK pronunciation in IPA format
- example: One natural example sentence
- type: Part of speech (noun, verb, adjective, adverb, phrase, idiom, phrasal-verb, etc.)

Return ONLY the JSON array in this exact format:
[
  {"en": "journey", "vn": "hành trình", "ipa": "/ˈdʒɜː.ni/", "example": "Life is a long journey full of adventures.", "type": "noun"}
]
"""
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String content = data['choices'][0]['message']['content'].trim();

      // Clean code block nếu có
      if (content.startsWith('```json')) content = content.substring(7);
      if (content.endsWith('```')) content = content.substring(0, content.length - 3);
      content = content.trim();

      try {
        final List<dynamic> list = jsonDecode(content);
        return list.cast<Map<String, dynamic>>();
      } catch (e) {
        throw Exception('Parse JSON failed: $e\nResponse: $content');
      }
    } else {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }
  }
}
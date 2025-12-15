import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/quiz_session.dart';

class QuizSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveSession(QuizSession session) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
          'QuizSessionService: Không thể lưu - Người dùng chưa đăng nhập.');
      throw Exception('Người dùng chưa đăng nhập. Không thể lưu kết quả quiz.');
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final sessionsRef = userRef.collection('quiz_sessions');

      // Sửa: Dùng Timestamp.now() thay vì FieldValue.serverTimestamp() để tránh lỗi trên web
      final sessionData = session.toMap();
      sessionData['playedAt'] = Timestamp.fromDate(session.playedAt);

      // Lưu session trước
      final sessionRef = sessionsRef.doc();
      await sessionRef.set(sessionData);

      // Sau đó cập nhật user XP (dùng batch thay vì transaction để đơn giản hơn)
      final userSnapshot = await userRef.get();

      int currentXP = 0;
      int currentStreak = 0;
      int longestStreak = 0;
      DateTime? lastActive;

      if (userSnapshot.exists) {
        final data = userSnapshot.data()!;
        currentXP = (data['totalXP'] as int?) ?? 0;
        currentStreak = (data['currentStreak'] as int?) ?? 0;
        longestStreak = (data['longestStreak'] as int?) ?? 0;
        final lastTs = data['lastActiveDate'] as Timestamp?;
        lastActive = lastTs?.toDate();
      }

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      // Kiểm tra xem có phải ngày mới không
      bool isNewDay = false;
      if (lastActive == null) {
        // Lần đầu làm quiz
        isNewDay = true;
      } else {
        final lastActiveStart = DateTime(
          lastActive.year,
          lastActive.month,
          lastActive.day,
        );
        
        // Nếu là ngày mới
        if (todayStart.isAfter(lastActiveStart)) {
          final daysDiff = todayStart.difference(lastActiveStart).inDays;
          
          if (daysDiff == 1) {
            // Ngày liên tiếp - tăng streak
            isNewDay = true;
          } else if (daysDiff > 1) {
            // Bỏ lỡ ngày - reset streak về 1 (ngày hôm nay)
            currentStreak = 0;
            isNewDay = true;
          }
          // Nếu daysDiff == 0 thì đã làm quiz trong ngày hôm nay rồi
        }
      }

      // Cập nhật streak
      final newStreak = isNewDay ? currentStreak + 1 : currentStreak;
      
      // Cập nhật longestStreak nếu cần
      final newLongestStreak = newStreak > longestStreak 
          ? newStreak 
          : longestStreak;

      await userRef.set({
        'totalXP': currentXP + session.xpEarned,
        'currentStreak': newStreak,
        'longestStreak': newLongestStreak,
        'lastActiveDate': Timestamp.fromDate(today),
      }, SetOptions(merge: true));

      debugPrint('Đã lưu kết quả quiz thành công cho user: ${user.uid}');
      debugPrint('XP: ${currentXP} + ${session.xpEarned} = ${currentXP + session.xpEarned}');
      debugPrint('Streak: $currentStreak -> $newStreak');
    } catch (e) {
      debugPrint('Lỗi khi lưu kết quả quiz: $e');
      rethrow;
    }
  }

  Stream<List<QuizSession>> getQuizHistory({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_sessions')
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        DateTime playedAt = DateTime.now();
        final playedAtField = data['playedAt'];
        if (playedAtField is Timestamp) {
          playedAt = playedAtField.toDate();
        } else if (playedAtField is String) {
          try {
            playedAt = DateTime.parse(playedAtField);
          } catch (e) {
            playedAt = DateTime.now();
          }
        }

        return QuizSession(
          topicId: data['topicId'] ?? '',
          topicName: data['topicName'] ?? 'Chủ đề không xác định',
          mode: data['mode'] ?? 'quiz',
          questionCount: data['questionCount'] ?? 0,
          correctCount: data['correctCount'] ?? 0,
          scorePercentage: data['scorePercentage'] ?? 0,
          xpEarned: data['xpEarned'] ?? 0,
          durationSeconds: data['durationSeconds'] ?? 0,
          playedAt: playedAt,
          answers: (data['answers'] as List<dynamic>?)
                  ?.map((a) => QuizAnswer(
                        vocabularyId: a['vocabularyId'] ?? '',
                        word: a['word'] ?? '',
                        userAnswer: a['userAnswer'] ?? '',
                        isCorrect: a['isCorrect'] ?? false,
                        timeSpent: (a['timeSpent'] as num?)?.toDouble() ?? 0.0,
                      ))
                  .toList() ??
              [],
        );
      }).toList();
    });
  }
}

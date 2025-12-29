import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/quiz_session.dart';
import '../../auth/services/xp_tracking_service.dart';
import '../../auth/services/auth_service.dart';

class QuizSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final XPTrackingService _xpTrackingService = XPTrackingService();

  Future<void> saveSession(QuizSession session, AuthService authService) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
          'QuizSessionService: Không thể lưu - Người dùng chưa đăng nhập.');
      throw Exception('Người dùng chưa đăng nhập. Không thể lưu kết quả quiz.');
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final sessionsRef = userRef.collection('quiz_sessions');

      // Lưu quiz session
      final sessionData = session.toMap();
      sessionData['playedAt'] = Timestamp.fromDate(session.playedAt);

      final sessionRef = sessionsRef.doc();
      await sessionRef.set(sessionData);

      // Lấy current user profile
      final userData = authService.currentUserData;
      if (userData?.profile != null) {
        // Sử dụng XPTrackingService để cập nhật XP và streak
        await _xpTrackingService.addXP(
          user.uid,
          userData!.profile!,
          session.xpEarned,
        );

        // Cập nhật streak
        await _xpTrackingService.updateStreak(
          user.uid,
          userData.profile!,
        );

        // Reload user data để cập nhật UI
        await authService.reloadUser();
      }

      debugPrint('Đã lưu kết quả quiz thành công cho user: ${user.uid}');
      debugPrint('XP earned: ${session.xpEarned}');
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

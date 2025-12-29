import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/user_entity.dart';

/// Service để track và update XP theo ngày
class XPTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kiểm tra và reset XP nếu sang ngày mới
  Future<UserProfile?> checkAndResetDailyXP(
      String userId, UserProfile? currentProfile) async {
    if (currentProfile == null) return null;

    final now = DateTime.now();
    final lastUpdate = currentProfile.lastXPUpdateDate;

    // Nếu chưa có lastUpdate, khởi tạo
    if (lastUpdate == null) {
      return currentProfile.copyWith(
        lastXPUpdateDate: now,
        todayXP: 0,
      );
    }

    // Kiểm tra nếu đã sang ngày mới
    final isSameDay = _isSameDay(lastUpdate, now);

    if (!isSameDay) {
      // Sang ngày mới -> reset todayXP
      final updatedProfile = currentProfile.copyWith(
        todayXP: 0,
        lastXPUpdateDate: now,
      );

      // Cập nhật vào Firestore
      await _updateProfileInFirestore(userId, updatedProfile);

      return updatedProfile;
    }

    return currentProfile;
  }

  /// Thêm XP cho user
  Future<UserProfile?> addXP(
      String userId, UserProfile currentProfile, int xpAmount) async {
    final now = DateTime.now();
    final lastUpdate = currentProfile.lastXPUpdateDate;

    // Kiểm tra nếu sang ngày mới
    int newTodayXP = currentProfile.todayXP;
    if (lastUpdate == null || !_isSameDay(lastUpdate, now)) {
      // Sang ngày mới -> reset todayXP
      newTodayXP = 0;
    }

    // Cập nhật XP
    final updatedProfile = currentProfile.copyWith(
      totalXP: currentProfile.totalXP + xpAmount,
      todayXP: newTodayXP + xpAmount,
      lastXPUpdateDate: now,
    );

    // Lưu vào Firestore
    await _updateProfileInFirestore(userId, updatedProfile);

    return updatedProfile;
  }

  /// Lấy XP hôm nay của user
  Future<int> getTodayXP(String userId, UserProfile? currentProfile) async {
    if (currentProfile == null) return 0;

    final now = DateTime.now();
    final lastUpdate = currentProfile.lastXPUpdateDate;

    // Nếu chưa có lastUpdate hoặc đã sang ngày mới -> return 0
    if (lastUpdate == null || !_isSameDay(lastUpdate, now)) {
      return 0;
    }

    return currentProfile.todayXP;
  }

  /// Update streak khi user hoàn thành bài học
  Future<UserProfile?> updateStreak(
      String userId, UserProfile currentProfile) async {
    final now = DateTime.now();
    final lastUpdate = currentProfile.lastXPUpdateDate;

    // Nếu chưa có lastUpdate, khởi tạo streak = 1
    if (lastUpdate == null) {
      final updatedProfile = currentProfile.copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastXPUpdateDate: now,
      );
      await _updateProfileInFirestore(userId, updatedProfile);
      return updatedProfile;
    }

    final daysDiff = _daysBetween(lastUpdate, now);

    int newStreak = currentProfile.currentStreak;

    if (daysDiff == 0) {
      // Cùng ngày -> không thay đổi streak
      return currentProfile;
    } else if (daysDiff == 1) {
      // Liên tiếp -> tăng streak
      newStreak = currentProfile.currentStreak + 1;
    } else {
      // Bỏ lỡ ngày -> reset streak = 1
      newStreak = 1;
    }

    final newLongestStreak = newStreak > currentProfile.longestStreak
        ? newStreak
        : currentProfile.longestStreak;

    final updatedProfile = currentProfile.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastXPUpdateDate: now,
    );

    await _updateProfileInFirestore(userId, updatedProfile);
    return updatedProfile;
  }

  // ==================== HELPERS ====================

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  int _daysBetween(DateTime date1, DateTime date2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d2.difference(d1).inDays;
  }

  Future<void> _updateProfileInFirestore(
      String userId, UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profile.totalXP': profile.totalXP,
        'profile.todayXP': profile.todayXP,
        'profile.lastXPUpdateDate': profile.lastXPUpdateDate?.toIso8601String(),
        'profile.currentStreak': profile.currentStreak,
        'profile.longestStreak': profile.longestStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating profile in Firestore: $e');
      rethrow;
    }
  }
}

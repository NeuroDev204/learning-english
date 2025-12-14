import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_datasource.dart';

/// Implementation of UserRepository
/// Kết nối giữa Domain Layer và Data Layer
class UserRepositoryImpl implements UserRepository {
  final UserDatasource _userDatasource;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Thêm instance Firestore

  UserRepositoryImpl({
    required UserDatasource userDatasource,
  }) : _userDatasource = userDatasource;

  @override
  Future<UserEntity?> getUserData(String userId) async {
    return await _userDatasource.getUserData(userId);
  }

  @override
  Future<void> saveUserData(UserEntity user) async {
    await _userDatasource.saveUserData(user);
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? photoUrl,
    String? learningAim,
  }) async {
    await _userDatasource.updateUserProfile(
      userId: userId,
      displayName: displayName,
      phoneNumber: phoneNumber,
      bio: bio,
      photoUrl: photoUrl,
      learningAim: learningAim,
    );
  }

  @override
  Future<void> updateUserSettings({
    required String userId,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? darkModeEnabled,
    String? languagePreference,
    int? dailyGoal,
    bool? reminderEnabled,
    DateTime? reminderTime,
  }) async {
    await _userDatasource.updateUserSettings(
      userId: userId,
      notificationsEnabled: notificationsEnabled,
      soundEnabled: soundEnabled,
      darkModeEnabled: darkModeEnabled,
      languagePreference: languagePreference,
      dailyGoal: dailyGoal,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
    );
  }

  @override
  Future<void> deleteUserData(String userId) async {
    await _userDatasource.deleteUserData(userId);
  }

  @override
  Stream<UserEntity?> watchUserData(String userId) {
    return _userDatasource.watchUserData(userId);
  }

  /// Đảm bảo document user tồn tại trong Firestore
  /// Dùng khi user đăng nhập lần đầu để khởi tạo các field mặc định như XP, streak...
  @override
  Future<void> ensureUserDocumentExists(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'totalXP': 0,
        'currentStreak': 0,
        'lastActiveDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
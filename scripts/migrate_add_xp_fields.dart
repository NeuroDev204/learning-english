// Script để migrate thêm các field XP tracking vào user documents hiện có
// Chạy: dart scripts/migrate_add_xp_fields.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🚀 Bắt đầu migration: Thêm XP tracking fields...');

  // Initialize Firebase (cần config phù hợp với project)
  // Lưu ý: Bạn cần copy firebase_options.dart vào đây hoặc config thủ công

  try {
    final firestore = FirebaseFirestore.instance;
    final usersCollection = firestore.collection('users');

    // Lấy tất cả user documents
    final querySnapshot = await usersCollection.get();
    print('📊 Tìm thấy ${querySnapshot.docs.length} users');

    int updated = 0;
    int skipped = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final profile = data['profile'] as Map<String, dynamic>?;

      if (profile == null) {
        print('⚠️  User ${doc.id} không có profile, bỏ qua');
        skipped++;
        continue;
      }

      // Kiểm tra xem đã có field chưa
      final hasTodayXP = profile.containsKey('todayXP');
      final hasLastXPUpdateDate = profile.containsKey('lastXPUpdateDate');

      if (hasTodayXP && hasLastXPUpdateDate) {
        print('✅ User ${doc.id} đã có XP fields, bỏ qua');
        skipped++;
        continue;
      }

      // Update document với default values
      await doc.reference.update({
        'profile.todayXP': 0,
        'profile.lastXPUpdateDate': DateTime.now().toIso8601String(),
        // Đảm bảo các field cũ cũng có giá trị mặc định nếu chưa có
        'profile.totalXP': profile['totalXP'] ?? 0,
        'profile.currentStreak': profile['currentStreak'] ?? 0,
        'profile.longestStreak': profile['longestStreak'] ?? 0,
      });

      print('✅ Updated user ${doc.id}');
      updated++;
    }

    print('\n🎉 Migration hoàn tất!');
    print('   - Đã cập nhật: $updated users');
    print('   - Bỏ qua: $skipped users');
  } catch (e) {
    print('❌ Lỗi migration: $e');
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_settings.dart';

class NotificationSettingsStorage {
  static const String _keySettings = 'notification_settings';

  Future<void> saveSettings(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toJson());
      await prefs.setString(_keySettings, json);
    } catch (e) {
      print('Lỗi khi lưu notification settings: $e');
      rethrow;
    }
  }

  Future<NotificationSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keySettings);

      if (jsonString == null) {
        return NotificationSettings();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return NotificationSettings.fromJson(json);
    } catch (e) {
      print('Lỗi khi đọc notification settings: $e');
      return NotificationSettings();
    }
  }

  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySettings);
    } catch (e) {
      print('Lỗi khi xóa notification settings: $e');
      rethrow;
    }
  }
}

import 'dart:async';
import 'dart:html' as html;
import '../models/notification_settings.dart';
import 'notification_settings_storage.dart';
import 'notification_service_interface.dart';

class WebNotificationService implements INotificationService {
  static final WebNotificationService _instance =
      WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  final NotificationSettingsStorage _storage = NotificationSettingsStorage();
  bool _initialized = false;
  bool _permissionGranted = false;
  final Map<int, Timer> _scheduledTimers = {};

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final permission = await _requestPermission();
      _permissionGranted = permission;

      if (!_permissionGranted) {
        print('⚠️ Web notification permission denied');
        return;
      }

      _initialized = true;

      final settings = await loadSettings();
      if (settings.enabled) {
        await scheduleNotifications(settings);
      }

      print('✅ Web notification service initialized');
    } catch (e) {
      print('❌ Lỗi khi khởi tạo web notification service: $e');
      rethrow;
    }
  }

  Future<bool> _requestPermission() async {
    try {
      final permission = html.Notification.permission;

      if (permission == 'granted') {
        return true;
      } else if (permission == 'default') {
        final result = await html.Notification.requestPermission();
        return result == 'granted';
      }

      return false;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  @override
  Future<void> scheduleNotifications(NotificationSettings settings) async {
    if (!_initialized) {
      await initialize();
    }

    await cancelAllNotifications();

    if (!settings.enabled || !_permissionGranted) {
      return;
    }

    for (int i = 0; i < settings.timeSlots.length; i++) {
      final slot = settings.timeSlots[i];
      if (!slot.enabled) continue;

      _scheduleDailyNotification(
        id: i,
        hour: slot.hour,
        minute: slot.minute,
        title: 'Nhắc nhở học tập 📚',
        body: settings.customMessage,
      );
    }

    print(
        '✅ Đã schedule ${settings.timeSlots.where((s) => s.enabled).length} web notifications');
  }

  void _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) {
    _scheduledTimers[id]?.cancel();

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delay = scheduledTime.difference(now);

    _scheduledTimers[id] = Timer(delay, () {
      _showNotification(title, body);

      _scheduleDailyNotification(
        id: id,
        hour: hour,
        minute: minute,
        title: title,
        body: body,
      );
    });

    print(
        '✅ Scheduled web notification #$id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  }

  void _showNotification(String title, String body) {
    try {
      if (!_permissionGranted) return;

      html.Notification(title, body: body, icon: '/favicon.png');
      print('🔔 Web notification shown: $title');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    for (final timer in _scheduledTimers.values) {
      timer.cancel();
    }
    _scheduledTimers.clear();
    print('🗑️ Đã hủy tất cả web notifications');
  }

  @override
  Future<void> showTestNotification() async {
    if (!_permissionGranted) {
      final granted = await _requestPermission();
      if (!granted) {
        throw Exception('Notification permission denied');
      }
      _permissionGranted = true;
    }

    _showNotification(
      'Test Notification 🔔',
      'Đây là notification test! Nếu bạn thấy điều này, notification đang hoạt động.',
    );
  }

  @override
  Future<NotificationSettings> loadSettings() async {
    return await _storage.loadSettings();
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    await _storage.saveSettings(settings);
    await scheduleNotifications(settings);
  }

  @override
  Future<int> getPendingNotificationsCount() async {
    return _scheduledTimers.length;
  }
}

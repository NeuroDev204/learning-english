import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/notification_settings.dart';
import 'notification_settings_storage.dart';
import 'notification_service_interface.dart';

class MobileNotificationService implements INotificationService {
  static final MobileNotificationService _instance =
      MobileNotificationService._internal();
  factory MobileNotificationService() => _instance;
  MobileNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationSettingsStorage _storage = NotificationSettingsStorage();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestPermissions();

      _initialized = true;

      final settings = await _storage.loadSettings();
      if (settings.enabled) {
        await scheduleNotifications(settings);
      }

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Lỗi khi khởi tạo notification service: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleNotifications(NotificationSettings settings) async {
    if (!_initialized) {
      await initialize();
    }

    await cancelAllNotifications();

    if (!settings.enabled) {
      print('Notifications disabled, không schedule');
      return;
    }

    for (int i = 0; i < settings.timeSlots.length; i++) {
      final slot = settings.timeSlots[i];
      if (!slot.enabled) continue;

      await _scheduleDailyNotification(
        id: i,
        hour: slot.hour,
        minute: slot.minute,
        title: 'Nhắc nhở học tập 📚',
        body: settings.customMessage,
        soundEnabled: settings.soundEnabled,
        vibrationEnabled: settings.vibrationEnabled,
      );
    }

    print(
        '✅ Đã schedule ${settings.timeSlots.where((s) => s.enabled).length} notifications');
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        'daily_reminder',
        'Nhắc nhở học hằng ngày',
        channelDescription: 'Thông báo nhắc nhở học tiếng Anh mỗi ngày',
        importance: Importance.high,
        priority: Priority.high,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundEnabled,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Lặp lại hằng ngày
      );

      print(
          '✅ Scheduled notification #$id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ Lỗi khi schedule notification #$id: $e');
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Đã hủy tất cả notifications');
  }

  Future<void> showTestNotification() async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'test_notification',
      'Test Notification',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Test Notification 🔔',
      'Đây là notification test! Nếu bạn thấy điều này, notification đang hoạt động.',
      details,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  @override
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    await _storage.saveSettings(settings);
    await scheduleNotifications(settings);
  }

  @override
  Future<NotificationSettings> loadSettings() async {
    return await _storage.loadSettings();
  }
}

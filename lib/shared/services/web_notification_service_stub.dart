import 'dart:async';
import '../models/notification_settings.dart';
import 'notification_service_interface.dart';

class PendingNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String? payload;

  PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.payload,
  });
}

// Stub implementation for non-web platforms
class WebNotificationService implements INotificationService {
  static final WebNotificationService _instance =
      WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  @override
  Future<void> initialize() async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<bool> requestPermission() async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<void> showNotification({
    required String title,
    String? body,
    String? payload,
  }) async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<void> cancelNotification(int id) async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<void> cancelAllNotifications() async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<List<PendingNotification>> getPendingNotifications() async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<NotificationSettings> getSettings() async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<void> scheduleTopicNotifications(NotificationSettings settings) async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<int> getPendingNotificationsCount() async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<NotificationSettings> loadSettings() async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<void> scheduleNotifications(NotificationSettings settings) async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Future<void> showTestNotification() async {
    throw UnsupportedError('WebNotificationService is only available on web');
  }

  @override
  Stream<String?> get onNotificationClick => const Stream.empty();

  @override
  bool get hasPermission => false;
}

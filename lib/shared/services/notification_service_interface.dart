import '../models/notification_settings.dart';

abstract class INotificationService {
  Future<void> initialize();

  Future<void> scheduleNotifications(NotificationSettings settings);

  Future<void> cancelAllNotifications();

  Future<void> showTestNotification();

  Future<NotificationSettings> loadSettings();

  Future<void> updateSettings(NotificationSettings settings);

  Future<int> getPendingNotificationsCount();
}

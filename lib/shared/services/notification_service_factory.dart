import 'package:flutter/foundation.dart' show kIsWeb;
import 'notification_service_interface.dart';
import 'web_notification_service_stub.dart'
    if (dart.library.html) 'web_notification_service.dart';
import 'notification_service.dart';

class NotificationServiceFactory {
  static INotificationService? _instance;

  static INotificationService getInstance() {
    if (_instance != null) return _instance!;

    if (kIsWeb) {
      _instance = WebNotificationService();
    } else {
      _instance = MobileNotificationService();
    }

    return _instance!;
  }
}

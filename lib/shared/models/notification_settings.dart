/// Model để lưu trữ cài đặt notification
class NotificationSettings {
  final bool enabled;
  final List<NotificationTimeSlot> timeSlots;
  final String customMessage;
  final bool soundEnabled;
  final bool vibrationEnabled;

  NotificationSettings({
    this.enabled = true,
    List<NotificationTimeSlot>? timeSlots,
    this.customMessage = 'Đã đến giờ học tiếng Anh! 📚',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  }) : timeSlots = timeSlots ??
            [
              NotificationTimeSlot(hour: 9, minute: 0, enabled: true),
              NotificationTimeSlot(hour: 20, minute: 0, enabled: true),
            ];

  NotificationSettings copyWith({
    bool? enabled,
    List<NotificationTimeSlot>? timeSlots,
    String? customMessage,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      timeSlots: timeSlots ?? this.timeSlots,
      customMessage: customMessage ?? this.customMessage,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
      'customMessage': customMessage,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      timeSlots: (json['timeSlots'] as List<dynamic>?)
              ?.map((slot) => NotificationTimeSlot.fromJson(slot))
              .toList() ??
          [
            NotificationTimeSlot(hour: 9, minute: 0, enabled: true),
            NotificationTimeSlot(hour: 20, minute: 0, enabled: true),
          ],
      customMessage: json['customMessage'] ?? 'Đã đến giờ học tiếng Anh! 📚',
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }
}

class NotificationTimeSlot {
  final int hour; // 0-23
  final int minute; // 0-59
  final bool enabled;

  NotificationTimeSlot({
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  String get displayTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  NotificationTimeSlot copyWith({
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return NotificationTimeSlot(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
    };
  }

  factory NotificationTimeSlot.fromJson(Map<String, dynamic> json) {
    return NotificationTimeSlot(
      hour: json['hour'] ?? 9,
      minute: json['minute'] ?? 0,
      enabled: json['enabled'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationTimeSlot &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

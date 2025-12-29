import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:learn_english/core/theme/app_theme.dart';
import '../../shared/models/notification_settings.dart';
import '../../shared/services/notification_service_factory.dart';
import '../../shared/services/notification_service_interface.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final INotificationService _notificationService;
  final TextEditingController _messageController = TextEditingController();

  NotificationSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationServiceFactory.getInstance();
    _loadSettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _notificationService.loadSettings();
      setState(() {
        _settings = settings;
        _messageController.text = settings.customMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    try {
      await _notificationService.updateSettings(_settings!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu cài đặt thành công'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi lưu settings: $e')),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔔 Đã gửi test notification'),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _addTimeSlot() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && _settings != null) {
      final newSlot = NotificationTimeSlot(
        hour: picked.hour,
        minute: picked.minute,
        enabled: true,
      );

      if (_settings!.timeSlots.contains(newSlot)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Khung giờ này đã tồn tại')),
          );
        }
        return;
      }

      setState(() {
        _settings = _settings!.copyWith(
          timeSlots: [..._settings!.timeSlots, newSlot],
        );
      });
      await _saveSettings();
    }
  }

  void _removeTimeSlot(int index) {
    if (_settings == null) return;

    setState(() {
      final slots = List<NotificationTimeSlot>.from(_settings!.timeSlots);
      slots.removeAt(index);
      _settings = _settings!.copyWith(timeSlots: slots);
    });
    _saveSettings();
  }

  void _toggleTimeSlot(int index) {
    if (_settings == null) return;

    setState(() {
      final slots = List<NotificationTimeSlot>.from(_settings!.timeSlots);
      slots[index] = slots[index].copyWith(enabled: !slots[index].enabled);
      _settings = _settings!.copyWith(timeSlots: slots);
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Cài đặt nhắc nhở'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _testNotification,
            tooltip: 'Test notification',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Không thể tải settings'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainToggle(),
                      const SizedBox(height: 24),
                      _buildTimeSlotsSection(),
                      const SizedBox(height: 24),
                      _buildCustomMessageSection(),
                      const SizedBox(height: 24),
                      _buildSoundVibrationSection(),
                      const SizedBox(height: 24),
                      _buildPendingNotificationsInfo(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMainToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.whiteCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _settings!.enabled
                  ? AppTheme.successGreen.withOpacity(0.1)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _settings!.enabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: _settings!.enabled
                  ? AppTheme.successGreen
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bật nhắc nhở học tập',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _settings!.enabled
                      ? 'Nhận thông báo hằng ngày'
                      : 'Tắt tất cả thông báo',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings!.enabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings!.copyWith(enabled: value);
              });
              _saveSettings();
            },
            activeColor: AppTheme.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Text(
                'Khung giờ nhắc nhở',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _settings!.timeSlots.length,
            itemBuilder: (context, index) {
              final slot = _settings!.timeSlots[index];
              return _buildTimeSlotItem(slot, index);
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addTimeSlot,
            icon: const Icon(Icons.add),
            label: const Text('Thêm khung giờ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotItem(NotificationTimeSlot slot, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: slot.enabled
            ? AppTheme.primaryBlue.withOpacity(0.05)
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: slot.enabled
              ? AppTheme.primaryBlue.withOpacity(0.2)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: slot.enabled
                  ? AppTheme.primaryBlue
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              slot.displayTime,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              slot.enabled ? 'Đang bật' : 'Tắt',
              style: TextStyle(
                color: slot.enabled
                    ? AppTheme.textDark
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Switch(
            value: slot.enabled,
            onChanged: (_) => _toggleTimeSlot(index),
            activeColor: AppTheme.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.errorRed,
            onPressed: () => _removeTimeSlot(index),
            tooltip: 'Xóa',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMessageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.message, color: AppTheme.accentPurple),
              const SizedBox(width: 12),
              Text(
                'Nội dung thông báo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: 'Nhập nội dung thông báo...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryBlue),
              ),
            ),
            onChanged: (value) {
              _settings = _settings!.copyWith(customMessage: value);
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _saveSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã cập nhật nội dung thông báo'),
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Lưu nội dung'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundVibrationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: AppTheme.warningYellow),
              const SizedBox(width: 12),
              Text(
                'Tùy chọn nâng cao',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _settings!.soundEnabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings!.copyWith(soundEnabled: value);
              });
              _saveSettings();
            },
            title: const Text('Âm thanh'),
            subtitle: const Text('Phát âm thanh khi có thông báo'),
            secondary: const Icon(Icons.volume_up, color: AppTheme.primaryBlue),
            activeColor: AppTheme.primaryBlue,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            value: _settings!.vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings!.copyWith(vibrationEnabled: value);
              });
              _saveSettings();
            },
            title: const Text('Rung'),
            subtitle: const Text('Rung máy khi có thông báo'),
            secondary: const Icon(Icons.vibration, color: AppTheme.accentPink),
            activeColor: AppTheme.primaryBlue,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotificationsInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.successGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Thông báo đã được lên lịch',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<int>(
            future: _notificationService.getPendingNotificationsCount(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              return Text(
                'Có ${snapshot.data!} thông báo đang chờ ${kIsWeb ? '(Web timers)' : ''}',
                style: TextStyle(color: Colors.grey[700]),
              );
            },
          ),
        ],
      ),
    );
  }
}

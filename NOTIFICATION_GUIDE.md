# 📱 HƯỚNG DẪN SỬ DỤNG NOTIFICATION SYSTEM

## 🎯 Tổng quan

Hệ thống notification cho phép app nhắc nhở người dùng học tiếng Anh hằng ngày vào các khung giờ đã đặt trước.

## ⚠️ QUAN TRỌNG: PLATFORM SUPPORT

**Notification hoạt động trên:**

- ✅ **Android** (API 21+) - Flutter local notifications
- ✅ **iOS** (10.0+) - Flutter local notifications
- ✅ **Web** - HTML5 Web Notifications API
- ⚠️ **Desktop** - Chưa hỗ trợ (có thể thêm sau)

### 🌐 Web Notifications

**Trên trình duyệt web:**

- Yêu cầu HTTPS (hoặc localhost để dev)
- Browser sẽ yêu cầu cấp quyền notification
- Notifications hoạt động khi tab mở hoặc đóng (tùy browser)
- Sử dụng browser's native notification system

**Browsers hỗ trợ:**

- ✅ Chrome/Edge (desktop & mobile)
- ✅ Firefox (desktop & mobile)
- ✅ Safari (macOS & iOS 16.4+)

**Lưu ý Web:**

- Notifications dùng JavaScript timers
- Chỉ hoạt động khi browser không bị force close
- Có thể thêm Service Worker để cải thiện (tùy chọn)

**Để test notification:**

```bash
# Web
flutter run -d chrome

# Android/iOS
flutter run
```

---

## 🚀 CÁCH SỬ DỤNG

### 1️⃣ Truy cập màn hình cài đặt

Có 2 cách:

**Cách 1: Từ Home Screen**

- Mở app → Nhìn lên AppBar (thanh trên cùng)
- Nhấn vào icon 🔔 (Notifications) bên cạnh icon giỏ hàng
- Màn hình **"Cài đặt nhắc nhở"** sẽ hiển thị

**Cách 2: Code navigation**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationSettingsScreen(),
  ),
);
```

---

### 2️⃣ Bật/Tắt nhắc nhở

**Trong màn hình Cài đặt nhắc nhở:**

1. Phần đầu tiên hiển thị toggle **"Bật nhắc nhở học tập"**
2. Bật switch ở bên phải:
   - ✅ **BẬT** = App sẽ gửi thông báo hằng ngày
   - ❌ **TẮT** = Hủy tất cả thông báo đã lên lịch

---

### 3️⃣ Quản lý khung giờ nhắc nhở

**Mặc định có 2 khung giờ:**

- 🌅 **09:00** - Buổi sáng
- 🌙 **20:00** - Buổi tối

#### **Thêm khung giờ mới:**

1. Nhấn nút **"+ Thêm khung giờ"**
2. Time Picker hiện ra
3. Chọn giờ và phút mong muốn
4. Nhấn **OK** → Khung giờ mới được thêm vào danh sách

#### **Bật/Tắt từng khung giờ:**

- Mỗi khung giờ có 1 switch riêng
- Tắt switch = không nhận thông báo vào giờ đó
- Bật switch = nhận thông báo vào giờ đó

#### **Xóa khung giờ:**

- Nhấn icon 🗑️ (Xóa) bên phải mỗi khung giờ
- Khung giờ sẽ bị xóa khỏi danh sách

---

### 4️⃣ Tùy chỉnh nội dung thông báo

**Phần "Nội dung thông báo":**

1. Mặc định: `"Đã đến giờ học tiếng Anh! 📚"`
2. Nhập nội dung tùy chỉnh (tối đa 100 ký tự)
3. Nhấn nút **"💾 Lưu nội dung"**
4. Thông báo sẽ hiển thị nội dung mới từ lần tiếp theo

**Gợi ý nội dung:**

- ⏰ "Đã đến giờ học! Hãy dành 15 phút ôn từ vựng nào! 📖"
- 🔥 "Streak của bạn đang chờ! Học ngay để giữ lửa! 🔥"
- 🎯 "Mục tiêu hôm nay: 10 từ mới! Bắt đầu thôi! 💪"
- 🌟 "Học 1 chút mỗi ngày = Tiến bộ dài lâu! Let's go! 🚀"

---

### 5️⃣ Cài đặt nâng cao

**Âm thanh:**

- Bật = Phát âm thanh khi có thông báo
- Tắt = Chỉ hiển thị thông báo không tiếng

**Rung:**

- Bật = Máy rung khi có thông báo
- Tắt = Không rung

---

### 6️⃣ Test ngay lập tức

**Để kiểm tra notification có hoạt động không:**

1. Nhấn icon 🔔 **"Test notification"** ở góc trên bên phải màn hình
2. App sẽ gửi ngay 1 thông báo test
3. Nếu thấy thông báo hiện ra → ✅ **Đã hoạt động!**
4. Nếu không thấy → Kiểm tra quyền (xem phần dưới)

---

## ⚙️ CÀI ĐẶT HỆ THỐNG (CHO ANDROID)

### Cấp quyền thông báo

**Android 13+ (API 33+):**
App sẽ tự động yêu cầu quyền khi khởi động lần đầu.

Nếu bị từ chối, bật thủ công:

```
Settings → Apps → Learn English → Notifications → Allow
```

**Cho phép Exact Alarm (Lịch chính xác):**

```
Settings → Apps → Learn English → Alarms & reminders → Allow
```

### Chế độ Battery Saver

Nếu bật Battery Saver, notifications có thể bị delay. Để tối ưu:

```
Settings → Battery → Battery optimization → Learn English → Don't optimize
```

---

## 🧪 CÁCH TEST NOTIFICATION

### Test 1: Thông báo ngay lập tức

```
1. Mở màn hình Notification Settings
2. Nhấn icon 🔔 ở góc trên phải
3. Đợi 1-2 giây
4. Thông báo test sẽ hiện ra
```

### Test 2: Lên lịch thông báo thật

```
1. Thêm khung giờ = giờ hiện tại + 1 phút
   (Ví dụ: nếu giờ là 14:30, thêm 14:31)
2. Bật notification
3. Đợi 1 phút
4. Thông báo sẽ hiện ra đúng giờ
```

### Test 3: Kiểm tra pending notifications

```
1. Cuộn xuống cuối màn hình Settings
2. Phần "Thông báo đã được lên lịch"
3. Xem số lượng notifications đang chờ
   (Số này = số khung giờ đang BẬT)
```

---

## 📱 FLOW HOẠT ĐỘNG

### Khi app khởi động:

```
1. main.dart → Initialize NotificationService
2. Load settings từ SharedPreferences
3. Nếu enabled = true → Schedule tất cả notifications
4. Notifications được lên lịch lặp lại HẰNG NGÀY
```

### Khi người dùng thay đổi settings:

```
1. User bật/tắt toggle hoặc thêm/xóa time slot
2. Settings được lưu vào SharedPreferences
3. Cancel tất cả notifications cũ
4. Re-schedule lại notifications mới
```

### Khi đến giờ nhắc nhở:

```
1. Android/iOS system trigger notification
2. Notification hiển thị với title + custom message
3. User tap vào notification → Mở app
4. Notification tự động schedule lại cho ngày mai (repeat daily)
```

---

## 🔧 TROUBLESHOOTING

### ❌ Không nhận được thông báo

**Kiểm tra:**

1. ✅ Toggle "Bật nhắc nhở" đã BẬT?
2. ✅ Có ít nhất 1 khung giờ được BẬT?
3. ✅ Quyền notification đã được cấp?
4. ✅ Khung giờ đúng không? (Đã qua giờ sẽ schedule cho ngày mai)
5. ✅ Battery Saver đã TẮT?

**Debug:**

```dart
// Trong NotificationSettingsScreen
Future<void> _checkPendingNotifications() async {
  final pending = await _notificationService.getPendingNotifications();
  print('Pending notifications: ${pending.length}');
  for (var notif in pending) {
    print('ID: ${notif.id}, Title: ${notif.title}');
  }
}
```

### ⚠️ App bị crash khi test notification

**Nguyên nhân:** Chưa install packages

**Giải pháp:**

```bash
flutter pub get
flutter clean
flutter run
```

### 🔄 Notification không lặp lại

**Kiểm tra code trong notification_service.dart:**

```dart
matchDateTimeComponents: DateTimeComponents.time // ← Quan trọng!
```

---

## 📂 CẤU TRÚC CODE

```
lib/
├── shared/
│   ├── models/
│   │   └── notification_settings.dart      # Model lưu settings
│   └── services/
│       ├── notification_service.dart        # Service chính
│       └── notification_settings_storage.dart # Lưu/đọc storage
└── screens/
    └── notification_settings_screen.dart    # UI settings
```

---

## 🎨 CUSTOMIZATION

### Thay đổi notification icon

```kotlin
// android/app/src/main/res/drawable/notification_icon.xml
// Tạo icon tùy chỉnh
```

### Thay đổi notification channel

```dart
// notification_service.dart
const androidDetails = AndroidNotificationDetails(
  'daily_reminder',           // ← Đổi ID
  'Nhắc nhở học hằng ngày',  // ← Đổi tên
  channelDescription: '...',
  importance: Importance.max, // ← Đổi độ ưu tiên
);
```

### Thêm action buttons

```dart
final androidDetails = AndroidNotificationDetails(
  // ...
  actions: [
    const AndroidNotificationAction(
      'start_quiz',
      'Bắt đầu học',
      showsUserInterface: true,
    ),
    const AndroidNotificationAction(
      'snooze',
      'Nhắc lại sau',
    ),
  ],
);
```

---

## 📝 LƯU Ý QUAN TRỌNG

1. **Timezone:** App sử dụng `Asia/Ho_Chi_Minh` (GMT+7)
2. **Storage:** Settings lưu trong SharedPreferences (key: `notification_settings`)
3. **Permissions:** Android 13+ cần request runtime permission
4. **Battery:** Doze mode có thể delay notifications
5. **Repeat:** Notifications lặp lại hằng ngày vào cùng giờ

---

## 🎯 CHECKLIST HOÀN THÀNH

Đảm bảo đã làm đủ các bước:

- [x] ✅ Install packages: `flutter pub get`
- [x] ✅ Cấp quyền notification trên thiết bị
- [x] ✅ Test thông báo ngay lập tức
- [x] ✅ Thêm khung giờ nhắc nhở
- [x] ✅ Tùy chỉnh nội dung thông báo
- [x] ✅ Kiểm tra pending notifications
- [ ] ⏳ Chờ đến giờ để test notification thật

---

## 🆘 HỖ TRỢ

Nếu gặp vấn đề, kiểm tra logs:

```bash
# Android
adb logcat | grep -i notification

# Flutter
flutter run --verbose
```

**Common logs:**

- `✅ Notification service initialized` → Thành công
- `✅ Scheduled notification #X at HH:MM` → Đã lên lịch
- `🗑️ Đã hủy tất cả notifications` → Cleared

---

## 🎉 HOÀN TẤT!

Bây giờ app của bạn đã có hệ thống nhắc nhở học tập hoàn chỉnh! 🚀

**Features:**

- ✅ Lịch nhắc học cố định hằng ngày
- ✅ Bật/tắt notification
- ✅ Tùy chọn nhiều khung giờ
- ✅ Tùy chỉnh nội dung thông báo
- ✅ Lưu trữ dữ liệu persistent
- ✅ Test notification ngay lập tức
- ✅ Sound & vibration settings

**Chúc bạn code vui vẻ! 💻✨**

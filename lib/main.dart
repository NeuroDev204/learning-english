import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'features/auth/auth_setup.dart';
import 'features/auth/services/admin_initialization_service.dart';
import 'features/exam/providers/exam_provider.dart';
import 'features/exam/providers/exam_timer_provider.dart';
import 'screens/auth_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/services/dashboard_cache.dart';
import 'shared/services/notification_service_factory.dart';

void main() async {
  // Đảm bảo Flutter binding được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Khởi tạo Hive
  await Hive.initFlutter();
  await Hive.openBox('topicCache');

  // Khởi tạo Dashboard cache
  final dashboardCache = DashboardCache();
  await dashboardCache.init();

  // Initialize notification service (hỗ trợ cả web và mobile)
  try {
    final notificationService = NotificationServiceFactory.getInstance();
    await notificationService.initialize();
    print('✅ Notification service initialized (${kIsWeb ? 'Web' : 'Mobile'})');
  } catch (e) {
    print('⚠️ Notification service initialization failed: $e');
  }

  // Initialize default admin user if not exists
  final adminService = AdminInitializationService();
  final adminExists = await adminService.adminExists();
  if (!adminExists) {
    print('Initializing default admin user...');
    await adminService.initializeDefaultAdmin();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme Provider for dark/light mode
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Auth Service with Firestore integration
        ChangeNotifierProvider(create: (_) => AuthSetup.createAuthService()),
        // User Profile Service for editing profile
        ChangeNotifierProvider(
          create: (_) => AuthSetup.createUserProfileService(),
        ),
        // Exam feature providers
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => ExamTimerProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Learn English',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

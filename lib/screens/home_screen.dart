import 'package:flutter/material.dart';
import 'package:learn_english/features/auth/domain/entities/user_entity.dart';
import 'package:learn_english/features/topic/screens/topic_list_screen.dart';
import 'package:learn_english/features/exam/views/import_file_page.dart';
import 'package:provider/provider.dart';
import '../features/auth/services/auth_service.dart';
import '../features/auth/services/xp_tracking_service.dart';
import '../core/theme/app_theme.dart';
import '../features/topic/models/vocabulary.dart';
import '../features/topic/services/vocabulary_service.dart';
import 'edit_profile_screen.dart';
import '../features/quiz/screens/quiz_history_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import 'notification_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Service to fetch vocabulary data
  final VocabularyService _vocabService = VocabularyService();
  final XPTrackingService _xpTrackingService = XPTrackingService();

  int _currentLesson = 1;
  bool _hasCheckedDailyReset = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _checkDailyReset();
  }

  Future<void> _checkEmailVerification() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    debugPrint('🔍 _checkEmailVerification - Before reload');
    await authService.reloadUser();
    debugPrint(
        '🔍 _checkEmailVerification - After reload: XP=${authService.currentUserData?.profile?.totalXP}');
  }

  Future<void> _checkDailyReset() async {
    if (_hasCheckedDailyReset) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    debugPrint('🔍 _checkDailyReset - Starting...');
    // Đợi 1 chút để AuthService load xong user data
    await Future.delayed(const Duration(milliseconds: 500));

    final userData = authService.currentUserData;
    debugPrint(
        '🔍 _checkDailyReset - userData: ${userData?.id}, hasProfile: ${userData?.profile != null}');
    debugPrint(
        '🔍 _checkDailyReset - Current XP: ${userData?.profile?.totalXP}, TodayXP: ${userData?.profile?.todayXP}, Streak: ${userData?.profile?.currentStreak}');

    if (userData?.profile != null && userData?.id != null) {
      // Kiểm tra và reset XP nếu sang ngày mới
      await _xpTrackingService.checkAndResetDailyXP(
        userData!.id,
        userData.profile,
      );

      // Reload user data để cập nhật UI
      debugPrint('🔍 _checkDailyReset - Before final reload');
      await authService.reloadUser();
      debugPrint(
          '🔍 _checkDailyReset - After final reload: XP=${authService.currentUserData?.profile?.totalXP}');

      if (mounted) {
        setState(() {
          _hasCheckedDailyReset = true;
        });
      }
    } else {
      debugPrint('⚠️ _checkDailyReset - No user data or profile!');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.errorRed),
            const SizedBox(width: 12),
            const Text('Sign Out?'),
          ],
        ),
        content: Text(
          'You will lose your current progress if you haven\'t saved it.',
          style: TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final UserEntity? userData = authService.currentUserData;

        // NOTE: Lấy role đúng từ UserEntity (đã định nghĩa trong feature/auth)
        // role: 'user' hoặc 'admin'
        final String role = userData?.role ?? 'user';
        final bool isAdmin = role == 'admin';

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: _buildAppBar(),
          drawer: _buildDrawer(isAdmin), // NOTE: truyền isAdmin vào drawer
          body: _buildBody(isAdmin), // NOTE: truyền isAdmin vào body
        );
      },
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: Builder(
        builder: (context) => Consumer<AuthService>(
          builder: (context, authService, child) {
            final user = authService.currentUser;
            final userData = authService.currentUserData;
            final photoUrl = userData?.photoUrl ?? user?.photoURL;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryBlue, width: 2),
                    image: photoUrl != null && photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Center(
                          child: Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ??
                                'U',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
      title: Consumer<AuthService>(
        builder: (context, authService, child) {
          final userData = authService.currentUserData;
          final currentStreak = userData?.profile?.currentStreak ?? 0;
          final totalXP = userData?.profile?.totalXP ?? 0;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppTheme.accentYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentStreak',
                      style: TextStyle(
                        color: AppTheme.accentYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warningYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: AppTheme.warningYellow, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$totalXP',
                      style: TextStyle(
                        color: AppTheme.warningYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Notification button (hỗ trợ cả web và mobile)
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppTheme.primaryBlue),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            );
          },
          tooltip: 'Nhắc nhở học tập',
        ),
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined,
              color: AppTheme.primaryBlue),
          onPressed: () {
            // Shop action
          },
        ),
      ],
    );
  }

  // ==================== DRAWER ====================
  Widget _buildDrawer(bool isAdmin) {
    return Drawer(
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          final userData = authService.currentUserData;
          // Use photoUrl from Firestore if available, fallback to Firebase Auth
          final photoUrl = userData?.photoUrl ?? user?.photoURL;

          debugPrint('🖼️ Drawer rendering - photoUrl: $photoUrl');
          debugPrint('   - userData?.photoUrl: ${userData?.photoUrl}');
          debugPrint('   - user?.photoURL: ${user?.photoURL}');

          return Column(
            children: [
              // Header with user info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                decoration: BoxDecoration(color: AppTheme.primaryBlue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        image: photoUrl != null && photoUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Center(
                              child: Text(
                                user?.displayName
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      userData?.displayName ?? user?.displayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // NOTE: CHIP ROLE hiển thị role 'admin' / 'user'
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdmin
                                ? Icons.school_rounded
                                : Icons.person_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAdmin ? 'Admin / Teacher' : 'User / Student',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.history_rounded,
                      title: 'Quiz History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to settings
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.emoji_events_outlined,
                      title: 'Achievements',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to achievements
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.leaderboard_outlined,
                      title: 'Leaderboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LeaderboardScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Shop',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to shop
                      },
                    ),

                    const Divider(height: 1),

                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to help
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to about
                      },
                    ),

                    // NOTE: Nhóm menu Management chỉ dành cho admin
                    if (isAdmin) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                        child: Text(
                          'Management',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.category_rounded,
                        title: 'Manage Topics',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TopicListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.translate_rounded,
                        title: 'Manage Vocabulary',
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: điều hướng đến màn quản lý từ vựng
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => WordManagementScreen()));
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Logout button at bottom
              Container(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: BorderSide(color: AppTheme.errorRed, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  // ==================== BODY ====================
  // NOTE: thêm tham số isAdmin để phân biệt UI admin vs user
  Widget _buildBody(bool isAdmin) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Daily Goal Card
          _buildDailyGoalCard(),

          const SizedBox(height: 24),

          // ===== ADMIN VIEW =====
          if (isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Teacher tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildAdminQuickActionsSection(),
            const SizedBox(height: 24),
          ]
          // ===== USER VIEW =====
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Study tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildStudentQuickActionsSection(),
            const SizedBox(height: 24),
          ],

          // My Vocabulary title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'My Vocabulary',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Display the list of words from Firestore
          _buildWordList(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // NOTE: section quick actions dành cho admin (quản lý topic/word)
  Widget _buildAdminQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TopicListScreen()),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.category_rounded, size: 26),
                      SizedBox(height: 8),
                      Text(
                        'Manage topics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create & edit topics\nfor students',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: sang màn manage vocab
                // Navigator.push(context, MaterialPageRoute(builder: (_) => WordManagementScreen()));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.translate_rounded, size: 26),
                      SizedBox(height: 8),
                      Text(
                        'Manage words',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Update vocabulary\ninside topics',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NOTE: section quick actions dành cho student (user)
  Widget _buildStudentQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Row 1: Browse topics & Review words
          Row(
            children: [
              // Card 1: Browse topics
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // User sẽ vào TopicListScreen ở chế độ read-only
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TopicListScreen(),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.category_outlined, size: 26),
                          SizedBox(height: 8),
                          Text(
                            'Browse topics',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View all vocabulary\nby topics',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Card 2: Review words
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Tạm thời cuộn xuống My Vocabulary
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.menu_book_outlined, size: 26),
                          SizedBox(height: 8),
                          Text(
                            'Review words',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Check your saved\nvocabulary',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Premium Exam Creation Card
          GestureDetector(
            onTap: () {
              // Navigate đến trang import file để tạo đề thi
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportFilePage()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon container with glow effect
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'AI Exam Generator',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black.withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Import PDF/Word → Auto-generate quiz',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildFeatureChip(
                                    Icons.picture_as_pdf,
                                    'PDF',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFeatureChip(Icons.description, 'Word'),
                                  const SizedBox(width: 8),
                                  _buildFeatureChip(Icons.quiz, 'Quiz'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Arrow
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for feature chips in exam card
  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WORD LIST ====================
  Widget _buildWordList() {
    return StreamBuilder<List<Vocabulary>>(
      stream: _vocabService.getAllVocabularies(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Handle error state
        if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          return const Center(child: Text('Something went wrong!'));
        }
        // Handle empty state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No words found yet. Try adding one!'),
            ),
          );
        }

        // Display the list of words
        final words = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true, // Important for nested scrolling
          physics:
              const NeverScrollableScrollPhysics(), // Let the parent scroll
          itemCount: words.length,
          itemBuilder: (context, index) {
            final word = words[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                title: Text(
                  word.word,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(word.meaning),
                trailing: Text(
                  '/${word.pronunciation}/',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== DAILY GOAL CARD ====================
  Widget _buildDailyGoalCard() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final userData = authService.currentUserData;
        final dailyGoal = userData?.settings.dailyGoal ?? 20;
        final todayProgress = userData?.profile?.todayXP ?? 0;
        final progressPercent = (todayProgress / dailyGoal).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative emoji in corner
              const Positioned(
                top: -6,
                right: -6,
                child: Text('🎯', style: TextStyle(fontSize: 34)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Daily Goal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('🌟', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.successGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$todayProgress/$dailyGoal XP',
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 12,
                      backgroundColor: AppTheme.paleBlue,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.successGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    progressPercent >= 1.0
                        ? '🎉 Goal achieved! Keep going!'
                        : 'Complete lessons to reach your daily goal!',
                    style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLessonNode({
    required int lessonNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    String? emoji,
    required bool isCompleted,
    required bool isActive,
    bool isLocked = false,
    double progress = 0.0,
  }) {
    Color getColor() {
      if (isCompleted) return AppTheme.successGreen;
      if (isActive) return AppTheme.primaryBlue;
      return Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              _startLesson(lessonNumber);
            },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Lesson Circle
            Stack(
              alignment: Alignment.center,
              children: [
                // Progress circle
                if (isActive && progress > 0)
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(getColor()),
                    ),
                  ),

                // Main circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey.shade200 : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: getColor(), width: 4),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: getColor().withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: isLocked
                      ? const Icon(Icons.lock, color: Colors.grey, size: 32)
                      : isCompleted
                          ? Icon(
                              Icons.check,
                              color: AppTheme.successGreen,
                              size: 40,
                            )
                          : Icon(icon, color: getColor(), size: 36),
                ),
              ],
            ),

            const SizedBox(width: 20),

            // Lesson Info
            Expanded(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Lesson $lessonNumber',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isActive)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Current',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? Colors.grey : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Emoji decoration
                  if (emoji != null && !isLocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 59),
      width: 4,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ==================== ACTIONS ====================
  void _startLesson(int lessonNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.play_circle_outline, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Text('Start Lesson $lessonNumber?'),
          ],
        ),
        content: const Text(
          'You\'re about to start a new lesson. Are you ready?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start lesson logic here
            },
            child: const Text('Let\'s Go!'),
          ),
        ],
      ),
    );
  }

  void _showUserProfile() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final userData = authService.currentUserData;
    // Use photoUrl from Firestore if available, fallback to Firebase Auth
    final photoUrl = userData?.photoUrl ?? user?.photoURL;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.paleBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 4,
                        ),
                        image: photoUrl != null && photoUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Center(
                              child: Text(
                                user?.displayName
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Name
                    Text(
                      user?.displayName ?? 'User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.paleBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        final currentStreak = authService
                                .currentUserData?.profile?.currentStreak ??
                            0;
                        final totalXP =
                            authService.currentUserData?.profile?.totalXP ?? 0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              icon: Icons.local_fire_department,
                              value: '$currentStreak',
                              label: 'Day Streak',
                              color: AppTheme.accentYellow,
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: Colors.grey.shade200,
                            ),
                            _buildStatItem(
                              icon: Icons.star,
                              value: '$totalXP',
                              label: 'Total XP',
                              color: AppTheme.warningYellow,
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: Colors.grey.shade200,
                            ),
                            _buildStatItem(
                              icon: Icons.emoji_events,
                              value: '0',
                              label: 'Achievements',
                              color: AppTheme.successGreen,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Account info
                    _buildProfileInfoCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Verification Status',
                      value: user?.emailVerified == true
                          ? 'Verified ✓'
                          : 'Not Verified',
                      valueColor: user?.emailVerified == true
                          ? AppTheme.successGreen
                          : AppTheme.warningYellow,
                    ),
                    _buildProfileInfoCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Member Since',
                      value: _formatDate(user?.metadata.creationTime),
                    ),
                    _buildProfileInfoCard(
                      icon: Icons.access_time_outlined,
                      title: 'Last Sign In',
                      value: _formatDate(user?.metadata.lastSignInTime),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
      ],
    );
  }

  Widget _buildProfileInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.paleBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

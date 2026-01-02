import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/dashboard_stats.dart';
import '../models/chart_data_point.dart';
import '../services/dashboard_service.dart';
import '../services/dashboard_cache.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/streak_widget.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/recent_session_item_widget.dart';
import '../../quiz/models/quiz_session.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final DashboardCache _cache = DashboardCache();

  DashboardStats? _stats;
  List<ChartDataPoint> _chartDataPoints = [];
  List<QuizSession> _recentSessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCache();
    _loadData();
  }

  Future<void> _initCache() async {
    await _cache.init();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Thử lấy từ cache trước
      final cachedStats = _cache.getStats();
      final cachedChartData = _cache.getChartData();
      final cachedSessions = _cache.getSessions();

      if (cachedStats != null && cachedChartData != null) {
        setState(() {
          _stats = cachedStats;
          _chartDataPoints = cachedChartData;
        });
      }

      if (cachedSessions != null) {
        setState(() {
          _recentSessions = cachedSessions;
        });
      }

      // Load từ Firestore
      final stats = await _dashboardService.getDashboardStats();
      final chartData = await _dashboardService.getChartDataPoints(days: 7);

      // Lưu vào cache
      await _cache.saveStats(stats);
      await _cache.saveChartData(chartData);

      setState(() {
        _stats = stats;
        _chartDataPoints = chartData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
      });
    }

    // Load recent sessions
    _dashboardService.watchRecentSessions(limit: 5).listen((sessions) {
      if (mounted) {
        setState(() {
          _recentSessions = sessions;
        });
        // Lưu sessions vào cache
        _cache.saveSessions(sessions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _loadData,
            child: const Text(
              'Làm mới',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.errorRed),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Streak Widget
                        if (_stats != null)
                          StreakWidget(streak: _stats!.currentStreak),
                        const SizedBox(height: 20),

                        // Stats Cards - Số từ học
                        Text(
                          'Số từ học',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_stats != null)
                          Row(
                            children: [
                              Expanded(
                                child: StatCardWidget(
                                  emoji: '📅',
                                  label: 'Hôm nay',
                                  value: '${_stats!.wordsLearnedToday}',
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCardWidget(
                                  emoji: '📆',
                                  label: 'Tuần này',
                                  value: '${_stats!.wordsLearnedThisWeek}',
                                  color: AppTheme.accentPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCardWidget(
                                  emoji: '🗓️',
                                  label: 'Tháng này',
                                  value: '${_stats!.wordsLearnedThisMonth}',
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),

                        // Biểu đồ XP
                        if (_chartDataPoints.isNotEmpty)
                          BarChartWidget(
                            values: _chartDataPoints
                                .map((dp) => dp.xp.toDouble())
                                .toList(),
                            title: 'XP theo thời gian (7 ngày)',
                            emoji: '⭐',
                            color: AppTheme.warningYellow,
                            valueLabel: 'XP',
                          ),
                        const SizedBox(height: 16),

                        // Biểu đồ Số từ học
                        if (_chartDataPoints.isNotEmpty)
                          BarChartWidget(
                            values: _chartDataPoints
                                .map((dp) => dp.wordsLearned.toDouble())
                                .toList(),
                            title: 'Số từ học (7 ngày)',
                            emoji: '📚',
                            color: AppTheme.primaryBlue,
                            valueLabel: 'Từ',
                          ),
                        const SizedBox(height: 16),

                        // Biểu đồ % chính xác
                        if (_chartDataPoints.isNotEmpty)
                          BarChartWidget(
                            values: _chartDataPoints
                                .map((dp) => dp.accuracy)
                                .toList(),
                            title: '% Chính xác (7 ngày)',
                            emoji: '📊',
                            color: AppTheme.successGreen,
                            valueLabel: '%',
                          ),
                        const SizedBox(height: 24),

                        // Thống kê tổng quan
                        Text(
                          'Thống kê tổng quan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_stats != null)
                          Row(
                            children: [
                              Expanded(
                                child: StatCardWidget(
                                  emoji: '⭐',
                                  label: 'Tổng XP',
                                  value: '${_stats!.totalXP}',
                                  color: AppTheme.warningYellow,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCardWidget(
                                  emoji: '📊',
                                  label: 'Chính xác',
                                  value:
                                      '${_stats!.averageAccuracy.toStringAsFixed(1)}%',
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCardWidget(
                                  emoji: '📝',
                                  label: 'Tổng bài',
                                  value: '${_stats!.totalSessions}',
                                  color: AppTheme.accentPink,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),

                        // Danh sách session gần đây
                        Text(
                          'Bài làm gần đây',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _recentSessions.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    'Chưa có bài làm nào',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6)),
                                  ),
                                ),
                              )
                            : Column(
                                children: _recentSessions
                                    .map((session) => RecentSessionItemWidget(
                                          session: session,
                                        ))
                                    .toList(),
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}

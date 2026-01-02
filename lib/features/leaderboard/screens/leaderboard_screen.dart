import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../widgets/period_selector_widget.dart';
import '../widgets/criteria_selector_widget.dart';
import '../widgets/top_three_widget.dart';
import '../widgets/user_rank_card_widget.dart';
import '../widgets/leaderboard_item_widget.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _service = LeaderboardService();

  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.allTime;
  LeaderboardCriteria _selectedCriteria = LeaderboardCriteria.totalXP;
  List<LeaderboardEntry> _leaderboard = [];
  LeaderboardEntry? _currentUserEntry;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final leaderboard = await _service.getLeaderboard(
        criteria: _selectedCriteria,
        period: _selectedPeriod,
      );
      final currentUser = await _service.getCurrentUserRank(
        criteria: _selectedCriteria,
        period: _selectedPeriod,
      );

      setState(() {
        _leaderboard = leaderboard;
        _currentUserEntry = currentUser;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(LeaderboardPeriod period) {
    setState(() {
      _selectedPeriod = period;
      // Reset criteria về mặc định theo period
      if (period == LeaderboardPeriod.allTime) {
        _selectedCriteria = LeaderboardCriteria.totalXP;
      } else if (period == LeaderboardPeriod.weekly) {
        _selectedCriteria = LeaderboardCriteria.weeklyXP;
      } else {
        _selectedCriteria = LeaderboardCriteria.monthlyXP;
      }
    });
    _loadLeaderboard();
  }

  void _onCriteriaChanged(LeaderboardCriteria criteria) {
    setState(() {
      _selectedCriteria = criteria;
    });
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Bảng xếp hạng',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _loadLeaderboard,
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
                        onPressed: _loadLeaderboard,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period selector
                        PeriodSelectorWidget(
                          selectedPeriod: _selectedPeriod,
                          onPeriodChanged: _onPeriodChanged,
                        ),
                        const SizedBox(height: 16),

                        // Criteria selector
                        CriteriaSelectorWidget(
                          selectedCriteria: _selectedCriteria,
                          period: _selectedPeriod,
                          onCriteriaChanged: _onCriteriaChanged,
                        ),
                        const SizedBox(height: 20),

                        // User rank card
                        if (_currentUserEntry != null)
                          UserRankCardWidget(
                            userEntry: _currentUserEntry,
                            criteria: _selectedCriteria,
                            period: _selectedPeriod,
                          ),
                        const SizedBox(height: 20),

                        // Top 3
                        if (_leaderboard.length >= 3)
                          TopThreeWidget(
                            topThree: _leaderboard.take(3).toList(),
                            criteria: _selectedCriteria,
                            period: _selectedPeriod,
                          ),
                        const SizedBox(height: 20),

                        // Leaderboard list (từ vị trí thứ 4 trở đi)
                        if (_leaderboard.length > 3) ...[
                          Text(
                            'Bảng xếp hạng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: _leaderboard.skip(3).map((entry) {
                              return LeaderboardItemWidget(
                                entry: entry,
                                isCurrentUser:
                                    entry.userId == _currentUserEntry?.userId,
                                criteria: _selectedCriteria,
                                period: _selectedPeriod,
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}

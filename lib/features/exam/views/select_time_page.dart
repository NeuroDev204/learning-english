import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../models/exam_model.dart';
import '../../../core/theme/app_theme.dart';
import 'exam_page.dart';

/// Trang chọn thời gian và số câu hỏi
class SelectTimePage extends StatefulWidget {
  const SelectTimePage({super.key});

  @override
  State<SelectTimePage> createState() => _SelectTimePageState();
}

class _SelectTimePageState extends State<SelectTimePage> {
  int _selectedDurationIndex = 1; // Default: 15 phút
  double _questionCount = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paleBlue,
      appBar: AppBar(
        title: const Text('Cài đặt đề thi'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration selection
                      _buildDurationSection(),

                      const SizedBox(height: 32),

                      // Question count slider
                      _buildQuestionCountSection(),

                      const SizedBox(height: 32),

                      // Summary card
                      _buildSummaryCard(),
                    ],
                  ),
                ),
              ),

              // Bottom action bar
              _buildBottomBar(context, examProvider),
            ],
          );
        },
      ),
    );
  }

  /// Duration selection section
  Widget _buildDurationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: AppTheme.primaryBlue, size: 24),
              SizedBox(width: 12),
              Text(
                'Thời gian làm bài',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Chọn thời gian phù hợp với số câu hỏi',
            style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),

          const SizedBox(height: 20),

          // Duration options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              ExamDurationOption.options.length,
              (index) => _buildDurationOption(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(int index) {
    final option = ExamDurationOption.options[index];
    final isSelected = _selectedDurationIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedDurationIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.lightBlue.withValues(alpha: 0.5),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              '${option.minutes}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'phút',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Question count slider section
  Widget _buildQuestionCountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    color: AppTheme.accentPurple,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Số câu hỏi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_questionCount.toInt()} câu',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentPurple,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentPurple,
              inactiveTrackColor: AppTheme.accentPurple.withValues(alpha: 0.2),
              thumbColor: AppTheme.accentPurple,
              overlayColor: AppTheme.accentPurple.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _questionCount,
              min: 5,
              max: 30,
              divisions: 25,
              onChanged: (value) => setState(() => _questionCount = value),
            ),
          ),

          // Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 câu',
                style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
              Text(
                '30 câu',
                style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Question breakdown
          _buildQuestionBreakdown(),
        ],
      ),
    );
  }

  Widget _buildQuestionBreakdown() {
    final total = _questionCount.toInt();
    final vocabCount = (total * 0.30).round();
    final readingCount = (total * 0.25).round();
    final fillCount = (total * 0.25).round();
    final tfCount = total - vocabCount - readingCount - fillCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.paleBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Phân bố câu hỏi:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildBreakdownChip('📝 Từ vựng', vocabCount, 0xFF5EB1FF),
              _buildBreakdownChip('📖 Đọc hiểu', readingCount, 0xFFA78BFA),
              _buildBreakdownChip('✏️ Điền từ', fillCount, 0xFFFFD93D),
              _buildBreakdownChip('✓✗ Đúng/Sai', tfCount, 0xFF4ADE80),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownChip(String label, int count, int colorValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(colorValue).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(colorValue).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(colorValue),
        ),
      ),
    );
  }

  /// Summary card
  Widget _buildSummaryCard() {
    final duration = ExamDurationOption.options[_selectedDurationIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.8),
            AppTheme.accentPurple.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Đề thi của bạn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem(
                Icons.quiz,
                '${_questionCount.toInt()}',
                'Câu hỏi',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildSummaryItem(Icons.timer, '${duration.minutes}', 'Phút'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Bottom action bar
  Widget _buildBottomBar(BuildContext context, ExamProvider examProvider) {
    final isGenerating = examProvider.isGenerating;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isGenerating ? null : () => _startExam(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: AppTheme.successGreen,
            disabledBackgroundColor: AppTheme.successGreen.withValues(
              alpha: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isGenerating
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Đang tạo đề thi...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Bắt đầu làm bài',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Start exam handler
  Future<void> _startExam(BuildContext context) async {
    final provider = context.read<ExamProvider>();
    final duration = ExamDurationOption.options[_selectedDurationIndex];

    // Set settings
    provider.setDuration(duration.minutes);
    provider.setQuestionCount(_questionCount.toInt());

    // Generate exam
    final success = await provider.generateExam();

    if (!context.mounted) return;

    if (success) {
      // Start exam state
      provider.startExam();

      // Navigate to exam page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ExamPage()),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.generateError ?? 'Không thể tạo đề thi'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}

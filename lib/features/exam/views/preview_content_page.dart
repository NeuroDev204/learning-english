import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'select_time_page.dart';

/// Trang preview nội dung đã trích xuất từ file
class PreviewContentPage extends StatelessWidget {
  const PreviewContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paleBlue,
      appBar: AppBar(
        title: const Text('Xem nội dung'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              // Clear và quay lại import
              context.read<ExamProvider>().clearImportedFile();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Chọn file khác'),
          ),
        ],
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          return Column(
            children: [
              // Stats bar
              _buildStatsBar(examProvider),

              // Content preview
              Expanded(child: _buildContentPreview(examProvider)),

              // Bottom action bar
              _buildBottomBar(context),
            ],
          );
        },
      ),
    );
  }

  /// Stats bar hiển thị thống kê nội dung
  Widget _buildStatsBar(ExamProvider examProvider) {
    final stats = examProvider.contentStats;
    final fileName = examProvider.selectedFile?.name ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Stats row
          if (stats != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(Icons.text_fields, '${stats['words']} từ'),
                const SizedBox(width: 12),
                _buildStatChip(Icons.short_text, '${stats['sentences']} câu'),
                const SizedBox(width: 12),
                _buildStatChip(Icons.subject, '${stats['paragraphs']} đoạn'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.paleBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Content preview
  Widget _buildContentPreview(ExamProvider examProvider) {
    final content = examProvider.extractedContent ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.paleBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.preview, color: AppTheme.primaryBlue, size: 20),
                SizedBox(width: 10),
                Text(
                  'Nội dung đã trích xuất',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          // Content text
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom action bar
  Widget _buildBottomBar(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentYellow.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppTheme.warningYellow,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hệ thống sẽ tự động phân tích và tạo câu hỏi',
                      style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),

            // Generate exam button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SelectTimePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_document, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Tạo đề thi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

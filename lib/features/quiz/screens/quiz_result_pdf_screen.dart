import 'package:flutter/material.dart';
import 'package:learn_english/core/theme/app_theme.dart';
import 'package:learn_english/features/quiz/models/quiz_question.dart';
import 'package:learn_english/features/topic/models/topic.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart'; 

class QuizResultPdfScreen extends StatelessWidget {
  final Topic topic;
  final int correctCount;
  final int totalQuestions;
  final int xpEarned;
  final int durationSeconds;
  final List<QuizQuestion> questions;
  final List<String> userAnswers;

  const QuizResultPdfScreen({
    super.key,
    required this.topic,
    required this.correctCount,
    required this.totalQuestions,
    required this.xpEarned,
    required this.durationSeconds,
    required this.questions,
    required this.userAnswers,
  });

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn kiểu xuất PDF',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in, color: AppTheme.successGreen, size: 32),
              title: const Text('Xuất kết quả bài làm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: const Text('Hiển thị đáp án đúng, đáp án bạn chọn, điểm số'),
              onTap: () {
                Navigator.pop(ctx);
                _generatePdf(context, showAnswers: true);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.quiz, color: AppTheme.primaryBlue, size: 32),
              title: const Text('Xuất đề thi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: const Text('Chỉ hiển thị câu hỏi và 4 đáp án (không lộ đáp án đúng)'),
              onTap: () {
                Navigator.pop(ctx);
                _generatePdf(context, showAnswers: false);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, {required bool showAnswers}) async {
    final pdf = pw.Document();

    // Tải font hỗ trợ tiếng Việt
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          margin: const pw.EdgeInsets.all(40),
        ),
        header: (_) => pw.Center(
          child: pw.Text(
            showAnswers ? 'KẾT QUẢ BÀI LÀM - ${topic.name}' : 'ĐỀ THI TRẮC NGHIỆM - ${topic.name}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 20),
          if (showAnswers) _buildResultStats(),
          pw.SizedBox(height: 20),
          pw.Text(
            showAnswers ? 'CHI TIẾT CÂU TRẢ LỜI' : 'NỘI DUNG ĐỀ THI',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),
          pw.SizedBox(height: 10),
          ...questions.asMap().entries.map((e) {
            final index = e.key + 1;
            final q = e.value;
            final userAns = e.key < userAnswers.length ? userAnswers[e.key] : '';

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Câu $index:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    q.type == QuestionType.wordToMeaning ? q.vocabulary.word : q.vocabulary.meaning,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  // Sửa lỗi ở đây: Bỏ const vì có interpolation động
                  if (q.type == QuestionType.wordToMeaning)
                    pw.Text(
                      '/${q.vocabulary.pronunciation}/',
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic), // Không dùng const
                    ),
                  pw.SizedBox(height: 12),
                  ...q.options.asMap().entries.map((opt) {
                    final label = ['A', 'B', 'C', 'D'][opt.key];
                    final optText = opt.value;
                    final isUserChoice = optText == userAns;
                    final isCorrectAns = optText == q.correctAnswer;

                    PdfColor? bgColor;
                    PdfColor borderColor = PdfColors.grey400;

                    if (showAnswers) {
                      if (isCorrectAns) {
                        bgColor = PdfColors.green100;
                        borderColor = PdfColors.green;
                      } else if (isUserChoice) {
                        bgColor = PdfColors.red100;
                        borderColor = PdfColors.red;
                      }
                    }

                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: bgColor,
                        border: pw.Border.all(color: borderColor),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Text('$label. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(child: pw.Text(optText)),
                          if (showAnswers && isCorrectAns)
                            pw.Text(' ✓', style: const pw.TextStyle(color: PdfColors.green)),
                          if (showAnswers && isUserChoice && !isCorrectAns)
                            pw.Text(' ✗', style: const pw.TextStyle(color: PdfColors.red)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text(
              'Generated by Learn English App',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: showAnswers
          ? 'Ket_qua_${topic.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}'
          : 'De_thi_${topic.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  pw.Widget _buildResultStats() {
    final percentage = totalQuestions > 0 ? (correctCount / totalQuestions * 100).round() : 0;
    return pw.Column(
      children: [
        pw.Text('Điểm số: $correctCount/$totalQuestions ($percentage%)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.Text('XP nhận được: +$xpEarned', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Thời gian: ${durationSeconds ~/ 60} phút ${durationSeconds % 60} giây'),
        pw.SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paleBlue,
      appBar: AppBar(
        title: const Text('Xuất kết quả PDF'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 80, color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              const Text(
                'Chọn kiểu xuất PDF',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bạn có thể xuất kết quả bài làm hoặc chỉ đề thi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _showExportOptions(context),
                  icon: const Icon(Icons.print),
                  label: const Text('Chọn kiểu xuất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
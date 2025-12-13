import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

/// Service để import và trích xuất text từ file PDF/Word
class FileImportService {
  /// Singleton pattern
  static final FileImportService _instance = FileImportService._internal();
  factory FileImportService() => _instance;
  FileImportService._internal();

  /// Mở file picker và cho phép chọn file PDF hoặc Word
  /// Trả về [PlatformFile] hoặc null nếu user cancel
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      throw FileImportException('Không thể mở file picker: $e');
    }
  }

  /// Trích xuất text từ file (tự động detect loại file)
  /// [file] - PlatformFile từ file picker
  /// Trả về nội dung text đã trích xuất
  Future<String> extractText(PlatformFile file) async {
    final extension = file.extension?.toLowerCase();

    if (extension == 'pdf') {
      return await extractTextFromPdf(file);
    } else if (extension == 'docx') {
      return await extractTextFromDocx(file);
    } else if (extension == 'doc') {
      // .doc format cũ không hỗ trợ trực tiếp
      throw FileImportException(
        'Định dạng .doc cũ không được hỗ trợ. Vui lòng convert sang .docx hoặc .pdf',
      );
    } else {
      throw FileImportException('Định dạng file không được hỗ trợ: $extension');
    }
  }

  /// Trích xuất text từ file PDF
  /// Sử dụng Syncfusion Flutter PDF
  Future<String> extractTextFromPdf(PlatformFile file) async {
    try {
      // Đọc bytes từ file
      final bytes = await _getFileBytes(file);
      if (bytes == null || bytes.isEmpty) {
        throw FileImportException('Không thể đọc file PDF');
      }

      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text từ tất cả các trang
      final StringBuffer textBuffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        final String pageText = extractor.extractText(startPageIndex: i);
        textBuffer.writeln(pageText);
        textBuffer.writeln(); // Thêm dòng trống giữa các trang
      }

      // Đóng document
      document.dispose();

      final extractedText = textBuffer.toString().trim();

      if (extractedText.isEmpty) {
        throw FileImportException(
          'Không thể trích xuất text từ PDF. File có thể là ảnh scan hoặc bị bảo vệ.',
        );
      }

      return _cleanText(extractedText);
    } catch (e) {
      if (e is FileImportException) rethrow;
      throw FileImportException('Lỗi đọc PDF: $e');
    }
  }

  /// Trích xuất text từ file DOCX (Word 2007+)
  /// DOCX là file ZIP chứa XML
  Future<String> extractTextFromDocx(PlatformFile file) async {
    try {
      // Đọc bytes từ file
      final bytes = await _getFileBytes(file);
      if (bytes == null || bytes.isEmpty) {
        throw FileImportException('Không thể đọc file DOCX');
      }

      // Giải nén ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      // Tìm file document.xml (chứa nội dung chính)
      final documentXml = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => throw FileImportException('File DOCX không hợp lệ'),
      );

      // Parse XML
      final xmlContent = utf8.decode(documentXml.content as List<int>);
      final document = xml.XmlDocument.parse(xmlContent);

      // Extract text từ các thẻ <w:t>
      final StringBuffer textBuffer = StringBuffer();

      // Tìm tất cả paragraph elements
      final paragraphs = document.findAllElements('w:p');

      for (final paragraph in paragraphs) {
        final texts = paragraph.findAllElements('w:t');
        for (final textElement in texts) {
          textBuffer.write(textElement.innerText);
        }
        textBuffer.writeln(); // Xuống dòng sau mỗi paragraph
      }

      final extractedText = textBuffer.toString().trim();

      if (extractedText.isEmpty) {
        throw FileImportException('Không thể trích xuất text từ DOCX');
      }

      return _cleanText(extractedText);
    } catch (e) {
      if (e is FileImportException) rethrow;
      throw FileImportException('Lỗi đọc DOCX: $e');
    }
  }

  /// Lấy bytes từ PlatformFile
  Future<List<int>?> _getFileBytes(PlatformFile file) async {
    // Nếu có bytes trực tiếp (web)
    if (file.bytes != null) {
      return file.bytes;
    }

    // Nếu có path (mobile/desktop)
    if (file.path != null) {
      final fileObj = File(file.path!);
      if (await fileObj.exists()) {
        return await fileObj.readAsBytes();
      }
    }

    return null;
  }

  /// Làm sạch text đã trích xuất
  String _cleanText(String text) {
    return text
        // Loại bỏ multiple spaces
        .replaceAll(RegExp(r' +'), ' ')
        // Loại bỏ multiple newlines
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // Loại bỏ tabs
        .replaceAll('\t', ' ')
        // Trim
        .trim();
  }

  /// Thống kê nội dung đã trích xuất
  Map<String, int> getContentStats(String content) {
    final words = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final sentences = content
        .split(RegExp(r'[.!?]+\s*'))
        .where((s) => s.isNotEmpty)
        .toList();
    final paragraphs = content
        .split(RegExp(r'\n\n+'))
        .where((p) => p.isNotEmpty)
        .toList();

    return {
      'words': words.length,
      'sentences': sentences.length,
      'paragraphs': paragraphs.length,
      'characters': content.length,
    };
  }
}

/// Exception class cho File Import errors
class FileImportException implements Exception {
  final String message;

  FileImportException(this.message);

  @override
  String toString() => 'FileImportException: $message';
}

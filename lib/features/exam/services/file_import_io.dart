// File import helper for IO platforms (mobile/desktop)
import 'dart:io';

/// Read file bytes from path (IO platforms only)
Future<List<int>?> readFileBytesFromPath(String path) async {
  final file = File(path);
  if (await file.exists()) {
    return await file.readAsBytes();
  }
  return null;
}

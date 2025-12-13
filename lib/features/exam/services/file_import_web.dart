// File import helper for Web platform

/// Read file bytes from path (stub for web - not used since web uses bytes directly)
Future<List<int>?> readFileBytesFromPath(String path) async {
  // Web platform doesn't support file paths, use bytes from PlatformFile directly
  return null;
}

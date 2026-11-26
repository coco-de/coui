/// Stub implementation for web platforms where dart:io is unavailable.
///
/// All disk operations are no-ops.
library;

/// Reads a cached icon set — always returns null on web.
Future<String?> readCacheFile(String cacheDir, String prefix) => .value();

/// Writes an icon set — no-op on web.
Future<void> writeCacheFile(
  String cacheDir,
  String prefix,
  String content,
) => .value();

/// Deletes cache directory — no-op on web.
Future<void> deleteCacheDir(String cacheDir) => .value();

/// Loads all cached icon sets — always returns empty on web.
Future<Map<String, String>> loadAllCacheFiles(String cacheDir) => .value({});

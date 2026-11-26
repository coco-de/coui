/// Dart:io implementation for disk caching.
library;

import 'dart:io';

/// Reads a cached icon set from disk.
Future<String?> readCacheFile(String cacheDir, String prefix) async {
  final file = File('$cacheDir/$prefix.json');
  if (!await file.exists()) return null;
  try {
    return await file.readAsString();
  } on FileSystemException {
    return null;
  }
}

/// Writes an icon set to disk cache.
Future<void> writeCacheFile(
  String cacheDir,
  String prefix,
  String content,
) async {
  try {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) {
      final _ = await dir.create(recursive: true);
    }
    final _ = await File('$cacheDir/$prefix.json').writeAsString(content);
  } on FileSystemException {
    // Ignore write failures.
  }
}

/// Deletes the entire cache directory.
Future<void> deleteCacheDir(String cacheDir) async {
  try {
    final dir = Directory(cacheDir);
    if (await dir.exists()) {
      final _ = await dir.delete(recursive: true);
    }
  } on FileSystemException {
    // Ignore.
  }
}

/// Loads all cached icon sets from disk.
Future<Map<String, String>> loadAllCacheFiles(String cacheDir) async {
  final results = <String, String>{};
  try {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) return results;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final prefix = entity.uri.pathSegments.last.replaceAll('.json', '');
          results[prefix] = content;
        } on FileSystemException {
          // Skip corrupted files.
        }
      }
    }
  } on FileSystemException {
    // Ignore.
  }
  return results;
}

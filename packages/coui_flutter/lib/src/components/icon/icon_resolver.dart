/// Icon resolver with two-level caching and local persistence.
library;

import 'dart:convert';

import 'package:coui_core/coui_core.dart'
    show CoreBundledIcons, IconSvgData, IconifyJson;
import 'package:coui_flutter/src/components/icon/disk_cache.dart' as disk;
import 'package:http/http.dart' as http;

/// Resolves icons from the Iconify API with memory + disk caching.
///
/// Every icon CoUI's own components draw ships in [CoreBundledIcons] and
/// resolves synchronously from it — no preload, no network — so component
/// chrome renders on its first frame offline, behind a strict CSP and in
/// widget tests (#5149). Icons outside the bundle still come from the
/// caches or the Iconify API, and [register] still wins over the bundle.
///
/// Usage:
/// ```dart
/// // Preload at startup:
/// await IconResolver.instance.preload([
///   'lucide:home',
///   'radix-icons:chevron-left',
/// ]);
///
/// // Then use anywhere (sync):
/// final data = IconResolver.instance.get('lucide:home');
/// ```
class IconResolver {
  IconResolver._();

  /// Singleton instance.
  static final instance = IconResolver._();

  /// Disk cache directory path.
  String cacheDir = '.coui_icons_cache';

  var _prefixCache = <String, IconifyJson>{};
  var _resolvedCache = <String, IconSvgData>{};

  /// Parses an icon ID string into (prefix, name).
  ///
  /// Throws [ArgumentError] if the format is invalid.
  static (String, String) parseIconId(String icon) {
    final parts = icon.split(':');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      throw ArgumentError(
        'Invalid icon ID "$icon". '
        'Expected format: "prefix:name" (e.g., "lucide:home")',
      );
    }
    return (parts[0], parts[1]);
  }

  /// Gets a registered, bundled or cached icon. Returns null if it is none
  /// of those yet — call [preload] for icons outside the bundle.
  IconSvgData? get(String icon) {
    final cached = _resolvedCache[icon] ?? CoreBundledIcons.icons[icon];
    if (cached != null) return cached;

    final (prefix, name) = parseIconId(icon);
    final prefixData = _prefixCache[prefix];
    if (prefixData == null) return null;

    final resolved = prefixData.resolve(name);
    if (resolved != null) {
      _resolvedCache = {..._resolvedCache, icon: resolved};
    }
    return resolved;
  }

  /// Whether the icon is cached and available.
  bool has(String icon) => get(icon) != null;

  /// Preloads icons from disk cache or Iconify API.
  Future<void> preload(
    List<String> icons, {
    bool useLocalCache = true,
  }) async {
    final parsed = icons.map(parseIconId);
    final grouped = <String, List<String>>{
      for (final prefix in {for (final (p, _) in parsed) p})
        prefix: [
          for (final (p, n) in parsed)
            if (p == prefix) n,
        ],
    };

    for (final entry in grouped.entries) {
      final prefix = entry.key;
      final names = entry.value;
      final allResolved = names.every((name) => has('$prefix:$name'));
      if (allResolved) continue;

      if (useLocalCache) {
        final loaded = await _loadFromDisk(prefix, names);
        if (loaded) continue;
      }
      await _fetchFromApi(prefix, names);
    }
  }

  /// Manually registers an icon.
  void register(String icon, IconSvgData data) {
    _resolvedCache = {..._resolvedCache, icon: data};
  }

  /// Clears all caches (memory + disk). The bundled icons stay — they are
  /// part of the package, not a cache.
  Future<void> clearCache() async {
    _prefixCache = <String, IconifyJson>{};
    _resolvedCache = <String, IconSvgData>{};
    await disk.deleteCacheDir(cacheDir);
  }

  /// Clears memory cache only.
  void clearMemoryCache() {
    _prefixCache = <String, IconifyJson>{};
    _resolvedCache = <String, IconSvgData>{};
  }

  /// Loads all cached icon sets from disk.
  Future<void> loadFromDisk() async {
    final files = await disk.loadAllCacheFiles(cacheDir);
    final loaded = <String, IconifyJson>{};
    for (final entry in files.entries) {
      try {
        final json = jsonDecode(entry.value) as Map<String, dynamic>;
        loaded[entry.key] = IconifyJson.fromJson(json);
      } on Exception catch (_) {
        // Skip corrupted cache files.
      }
    }
    _prefixCache = {..._prefixCache, ...loaded};
  }

  Future<bool> _loadFromDisk(String prefix, List<String> names) async {
    final content = await disk.readCacheFile(cacheDir, prefix);
    if (content == null) return false;
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      final iconifyJson = IconifyJson.fromJson(json);
      _prefixCache = {..._prefixCache, prefix: iconifyJson};
      final resolvedEntries = <String, IconSvgData>{};
      var allFound = true;
      for (final name in names) {
        final resolved = iconifyJson.resolve(name);
        if (resolved != null) {
          resolvedEntries['$prefix:$name'] = resolved;
        } else {
          allFound = false;
        }
      }
      _resolvedCache = {..._resolvedCache, ...resolvedEntries};
      return allFound;
    } on Exception catch (_) {
      return false;
    }
  }

  Future<void> _fetchFromApi(String prefix, List<String> names) async {
    final namesParam = names.join(',');
    final url = Uri.parse(
      'https://api.iconify.design/$prefix.json?icons=$namesParam',
    );
    const httpStatusOk = 200;
    try {
      final response = await http.get(url);
      if (response.statusCode != httpStatusOk) return;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final iconifyJson = IconifyJson.fromJson(json);
      _prefixCache = {..._prefixCache, prefix: iconifyJson};

      final resolvedEntries = <String, IconSvgData>{};
      for (final name in names) {
        final resolved = iconifyJson.resolve(name);
        if (resolved != null) {
          resolvedEntries['$prefix:$name'] = resolved;
        }
      }
      _resolvedCache = {..._resolvedCache, ...resolvedEntries};
      await disk.writeCacheFile(cacheDir, prefix, jsonEncode(json));
    } on Exception catch (_) {
      // Silently fail — icon will show placeholder.
    }
  }
}

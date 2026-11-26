/// Accept-list matching shared by the Flutter and Web `FileInput`.
library;

/// Answers "does this file satisfy the `accept` list?" for both platforms.
///
/// Flutter and Web learn a file's type differently — Flutter hands over an
/// `XFile` (name + optional MIME), Web a `File` (name + `type`) — but the
/// question itself must be answered identically: the same dropped file
/// passing on one platform and disappearing on the other is exactly the
/// divergence the component's cross-platform contract forbids.
///
/// The list syntax follows the HTML `accept` attribute, which is also what
/// the picker filters are derived from:
///
/// ```dart
/// CoreFileInputAccept.matches(
///   fileName: 'report.PDF',
///   mimeType: 'application/pdf',
///   accept: ['.pdf', 'image/*'],
/// ); // true
/// ```
abstract final class CoreFileInputAccept {
  /// Whether a file named [fileName] (with optional [mimeType]) satisfies
  /// [accept].
  ///
  /// An empty [accept] accepts everything. Entries are matched
  /// case-insensitively and may be:
  ///
  /// - an extension with a leading dot — `.pdf`
  /// - an extension without one — `pdf` (HTML allows this form)
  /// - a MIME type — `application/pdf`, or a wildcard — `image/*`
  ///
  /// A MIME entry also matches through the file's extension when the file
  /// carries no MIME type (`image/png` accepts `photo.png`) — a drop often
  /// arrives without one, and rejecting on that alone would silently
  /// discard a file the same list accepts when picked.
  static bool matches({
    required String fileName,
    required List<String> accept,
    String? mimeType,
  }) {
    if (accept.isEmpty) return true;

    final extension = _extensionOf(fileName);
    final normalizedMime = _normalize(mimeType);

    for (final entry in accept) {
      final value = _normalize(entry);
      if (value == null) continue;

      if (value.startsWith('.')) {
        if (extension != null && extension == value.substring(1)) return true;
        continue;
      }

      if (value.contains('/')) {
        if (normalizedMime != null && _mimeMatches(value, normalizedMime)) {
          return true;
        }
        final subtype = value.split('/').last;
        if (subtype != '*' && extension != null && extension == subtype) {
          return true;
        }
        continue;
      }

      if (extension != null && extension == value) return true;
    }

    return false;
  }

  /// The bare extension entries of [accept] — `['.PDF', 'image/png']`
  /// becomes `['pdf', 'png']`.
  ///
  /// Platform pickers that filter by extension (Flutter's `file_picker`)
  /// take this form. MIME wildcards (`image/*`) have no extension
  /// equivalent and are skipped, so a list of nothing but wildcards
  /// yields no filter and the picker falls back to any file type.
  static List<String> extensions(List<String>? accept) {
    if (accept == null || accept.isEmpty) return const [];

    final extensions = <String>[];
    for (final entry in accept) {
      final value = _normalize(entry);
      if (value == null) continue;

      if (value.startsWith('.')) {
        extensions.add(value.substring(1));
        continue;
      }
      if (value.contains('/')) {
        final subtype = value.split('/').last;
        if (subtype != '*') extensions.add(subtype);
        continue;
      }
      extensions.add(value);
    }

    return extensions;
  }

  /// Whether the MIME [pattern] (possibly `type/*`) covers [actual].
  static bool _mimeMatches(String pattern, String actual) {
    if (pattern == '*/*') return true;
    if (pattern.endsWith('/*')) {
      return actual.startsWith(pattern.substring(0, pattern.length - 1));
    }

    return pattern == actual;
  }

  /// The lowercase extension of [fileName] — the text after the last dot —
  /// or null when the name carries none.
  ///
  /// A leading dot is a hidden name, not an extension (`.gitignore`), so
  /// the dot must not be the first character.
  static String? _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return null;

    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Trims and lowercases [value], returning null when nothing is left.
  static String? _normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;

    return normalized;
  }
}

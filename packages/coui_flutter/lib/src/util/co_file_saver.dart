import 'dart:typed_data';

import 'package:file_saver_ffi/file_saver_ffi.dart';

/// Cross-platform file saving, so a caller never has to know which plugin
/// writes to disk on which platform.
///
/// The Web twin (`coui_web`'s `CoFileSaver`) takes the same named
/// parameters — a browser download instead of a native save dialog — so
/// app code that saves a file reads identically on both platforms.
///
/// ```dart
/// await CoFileSaver.saveBytes(
///   bytes: reportBytes,
///   fileName: 'report.pdf',
///   mimeType: 'application/pdf',
/// );
/// ```
abstract final class CoFileSaver {
  /// Writes [bytes] to a location the user picks.
  ///
  /// [fileName] is the full name — its extension names the saved file's
  /// type. [mimeType] is only a hint for platforms that read one; when
  /// omitted the file is saved as a generic binary.
  ///
  /// Returns the saved location, or null when the user cancelled the save
  /// dialog.
  static Future<Uri?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    final (baseName, extension) = _splitFileName(fileName);

    return FileSaver.saveAsAsync(
      input: SaveBytesInput(bytes),
      fileType: CustomFileType(
        ext: extension,
        mimeType: mimeType ?? 'application/octet-stream',
      ),
      fileName: baseName,
    );
  }

  /// Copies the file at [path] to a location the user picks.
  ///
  /// [fileName] overrides the saved name; the file's own name is used when
  /// omitted. Returns the saved location, or null when the user cancelled.
  static Future<Uri?> saveFile({required String path, String? fileName}) {
    final name = fileName ?? path.split(RegExp(r'[/\\]')).last;
    final (baseName, extension) = _splitFileName(name);

    return FileSaver.saveAsAsync(
      input: SaveFileInput(path),
      fileType: CustomFileType(
        ext: extension,
        mimeType: 'application/octet-stream',
      ),
      fileName: baseName,
    );
  }

  /// Splits [fileName] into the base name and extension `file_saver_ffi`
  /// wants separately (it appends the extension itself).
  ///
  /// A name with no extension is saved with a `.bin` suffix rather than a
  /// trailing dot — the plugin always joins the two, so "no extension"
  /// cannot be expressed.
  static (String, String) _splitFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return (fileName, 'bin');

    return (fileName.substring(0, dot), fileName.substring(dot + 1));
  }
}

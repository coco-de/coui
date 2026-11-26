import 'dart:typed_data';

import 'package:coui_web/src/util/co_file_saver_dom.dart';

/// Cross-platform file saving, so a caller never has to know which plugin
/// writes to disk on which platform.
///
/// The Flutter twin (`coui_flutter`'s `CoFileSaver`) takes the same named
/// parameters — a native save dialog instead of a browser download — so app
/// code that saves a file reads identically on both platforms.
///
/// ```dart
/// await CoFileSaver.saveBytes(
///   bytes: reportBytes,
///   fileName: 'report.pdf',
///   mimeType: 'application/pdf',
/// );
/// ```
abstract final class CoFileSaver {
  /// Hands [bytes] to the browser as a download named [fileName].
  ///
  /// Unlike the Flutter twin there is no destination to pick and no result
  /// to report: the browser owns where downloads land, so nothing is
  /// returned.
  static Future<void> saveBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    downloadBytes(bytes, fileName, mimeType);

    return .value();
  }
}

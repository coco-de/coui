/// Platform-independent line data for `CodeDiff`.
library;

import 'package:coui_core/src/component/contracts/code_diff/core_code_diff_line_type.dart';

/// `CodeDiff` 의 단일 라인 데이터.
///
/// Plain Dart class — same shape on Flutter and Web (no platform
/// widget reference), so callers compose `List<CoreCodeDiffLine>`
/// once and pass it to either implementation.
class CoreCodeDiffLine {
  /// Creates a [CoreCodeDiffLine].
  const CoreCodeDiffLine({
    required this.text,
    required this.type,
    this.lineNumber,
  });

  /// Line text content (rendered as-is, monospace).
  final String text;

  /// Whether the line was added, removed, or unchanged.
  final CoreCodeDiffLineType type;

  /// Optional line number rendered in the gutter when
  /// `showLineNumbers` is true.
  final int? lineNumber;
}

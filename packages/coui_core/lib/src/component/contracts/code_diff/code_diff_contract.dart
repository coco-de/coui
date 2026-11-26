/// Platform-independent contract for unified `CodeDiff` components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/code_diff/code_diff_style.dart';
import 'package:coui_core/src/component/contracts/code_diff/core_code_diff_line.dart';

/// Contract for a unified line-by-line code diff viewer.
///
/// Renders a `List<CoreCodeDiffLine>` with added / removed / unchanged
/// rows. Added and removed rows are solid bands painted with the design
/// system's `successContainer` / `errorContainer` tokens (opaque, no tint
/// alpha), on a `surfaceContainerLow` face with no border. The `+ ` / `- `
/// prefix and the line number on a band take the matching
/// `onSuccessContainer` / `onErrorContainer`, while the diff text keeps the
/// body `onSurface` ink on every row. Default is non-interactive. Pass
/// [onLineTap] to make rows activatable; scroll still belongs to a wrapping
/// `ScrollArea`.
///
/// Typography is monospace: the body is the `codeMd` role (13) and the
/// line-number gutter the `codeSm` role (12), both set in the mono family
/// on one fixed 21px line box. With no vertical padding on the row or the
/// gutter, every row is exactly 21px tall and rows abut, so the `+ ` / `- `
/// / `  ` prefix, the line number and the text sit on one 21px grid. Each
/// row starts 12px in, the gutter cell is 40px wide (a 28px digit column
/// plus a 12px gap, right-aligned to the end edge), and the prefix starts at
/// x = 52.
abstract interface class CoreCodeDiffContract {
  /// Lines rendered in order.
  List<CoreCodeDiffLine> get lines;

  /// Whether to render the line-number gutter when a row carries a
  /// `lineNumber`.
  bool get showLineNumbers;

  /// Called when a row is activated. `null` keeps the viewer
  /// non-interactive (default).
  CoreValueChanged<CoreCodeDiffLine>? get onLineTap;

  /// Per-instance composite chrome / text style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreCodeDiffStyle.defaultX)
  ///   → CoreCodeDiffTheme.style
  ///   → widget.codeDiffStyle
  /// ```
  CoreCodeDiffStyle? get codeDiffStyle;
}

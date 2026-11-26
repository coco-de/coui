/// Platform-independent theme for `Diff`.
library;

import 'package:coui_core/src/component/contracts/diff/diff_style.dart';
import 'package:meta/meta.dart';

/// `Diff` component theme overrides.
///
/// All numeric values are pre-scaling; the Flutter side applies
/// `theme.scaling` internally.
///
/// Per Epic #1302 chrome flows through the single [style] field —
/// see [CoreDiffStyle] for the merge chain. Layout chrome
/// (`aspectRatio`, `initialPosition`) lives on [CoreDiffStyle]
/// since Epic #1370 Phase 4 — the legacy flat fields were removed.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreDiffTheme.style                           // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance diffStyle
/// ```
@immutable
class CoreDiffTheme {
  /// Creates a [CoreDiffTheme].
  const CoreDiffTheme({this.style});

  /// Project-wide composite style applied to every `Diff`.
  ///
  /// Resolved before any per-instance `widget.diffStyle`.
  final CoreDiffStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreDiffTheme && other.style == style);

  @override
  int get hashCode => style.hashCode;
}

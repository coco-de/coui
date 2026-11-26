/// Platform-independent theme for `CodeDiff`.
library;

import 'package:coui_core/src/component/contracts/code_diff/code_diff_style.dart';
import 'package:meta/meta.dart';

/// `CodeDiff` component theme overrides.
///
/// All chrome / dimensional / nested text style overrides flow through
/// the composite [style] slot — there are no flat chrome fields
/// (Epic #1543 / 7-6 (i)). See [CoreCodeDiffStyle] for the merge chain.
@immutable
class CoreCodeDiffTheme {
  /// Creates a [CoreCodeDiffTheme].
  const CoreCodeDiffTheme({this.style});

  /// Project-wide composite style applied to every `CodeDiff`.
  ///
  /// Resolved before any per-instance `widget.codeDiffStyle`.
  final CoreCodeDiffStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreCodeDiffTheme && other.style == style);

  @override
  int get hashCode => style.hashCode;
}

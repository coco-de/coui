/// Theme data for `ChipInput` customisation.
library;

import 'package:coui_core/src/component/contracts/chip_input/chip_input_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ChipInput`.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [style] field — see [CoreChipInputStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreChipInputTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance chipInputStyle
/// ```
@immutable
class CoreChipInputTheme {
  /// Creates a [CoreChipInputTheme].
  const CoreChipInputTheme({this.style});

  /// Project-wide composite style applied to every `ChipInput`.
  final CoreChipInputStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChipInputTheme && other.style == style;

  @override
  int get hashCode => style.hashCode;
}

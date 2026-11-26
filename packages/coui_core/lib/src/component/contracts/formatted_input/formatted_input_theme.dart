/// Theme data for `FormattedInput` customisation.
library;

import 'package:coui_core/src/component/contracts/formatted_input/formatted_input_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `FormattedInput`.
///
/// Per Epic #1302 chrome / dimensional / colour overrides flow through
/// the single [style] field — see [CoreFormattedInputStyle] for the
/// merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreFormattedInputTheme.style               // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance formattedInputStyle
/// ```
@immutable
class CoreFormattedInputTheme {
  /// Creates a [CoreFormattedInputTheme].
  const CoreFormattedInputTheme({this.style});

  /// Project-wide composite style applied to every `FormattedInput`.
  final CoreFormattedInputStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFormattedInputTheme && other.style == style;

  @override
  int get hashCode => style.hashCode;
}

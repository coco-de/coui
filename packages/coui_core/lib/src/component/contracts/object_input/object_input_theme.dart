/// Theme data for `ObjectInput` customisation.
library;

import 'package:coui_core/src/component/contracts/object_input/object_input_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ObjectInput`.
///
/// Per Epic #1302 chrome / dimensional / colour overrides flow through
/// the single [style] field — see [CoreObjectInputStyle] for the merge
/// chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreObjectInputTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance objectInputStyle
/// ```
@immutable
class CoreObjectInputTheme {
  /// Creates a [CoreObjectInputTheme].
  const CoreObjectInputTheme({this.style});

  /// Project-wide composite style applied to every `ObjectInput`.
  final CoreObjectInputStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreObjectInputTheme && other.style == style;

  @override
  int get hashCode => style.hashCode;
}

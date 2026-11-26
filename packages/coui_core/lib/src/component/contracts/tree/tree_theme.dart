/// Theme data for `Tree` customization.
library;

import 'package:coui_core/src/component/contracts/tree/tree_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `Tree`.
///
/// Per Epic #1302 / #1370 all 시각 chrome flows through the single
/// [style] slot — see [CoreTreeStyle].
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreTreeTheme.style
///   → parent component slot override
///   → widget per-instance treeStyle
/// ```
@immutable
class CoreTreeTheme {
  /// Creates a [CoreTreeTheme].
  const CoreTreeTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreTreeStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTreeTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}

/// Platform-independent theme data for unified table components.
library;

import 'package:coui_core/src/component/contracts/table/table_style.dart';
import 'package:meta/meta.dart';

/// Theme override for unified table components.
///
/// All visual chrome flows through the single [style] slot — see
/// [CoreTableStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreTableTheme.style
///   → parent component slot override
///   → widget per-instance tableStyle
/// ```
@immutable
class CoreTableTheme {
  /// Creates a [CoreTableTheme].
  const CoreTableTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreTableStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTableTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}

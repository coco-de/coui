/// Theme overrides for the unified MediaQueryVisibility component.
library;

import 'package:coui_core/src/component/contracts/media_query_visibility/media_query_visibility_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `MediaQueryVisibility`.
///
/// Follows the standard CoUI `CoreXxxTheme { style: CoreXxxStyle? }`
/// shape — all defaults live on [CoreMediaQueryVisibilityStyle], the
/// theme just exposes a single slot.
@immutable
class CoreMediaQueryVisibilityTheme {
  /// Creates a [CoreMediaQueryVisibilityTheme].
  const CoreMediaQueryVisibilityTheme({this.style});

  /// Style overrides applied to every `MediaQueryVisibility` rendered
  /// under this theme.
  final CoreMediaQueryVisibilityStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMediaQueryVisibilityTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}

/// Theme overrides for navigation bar components.
library;

import 'package:coui_core/src/component/contracts/navigation_bar/navigation_bar_style.dart';
import 'package:coui_core/src/component/contracts/navigation_bar/navigation_bar_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `NavigationBar`.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreNavigationBarStyle.defaultX)
///   → CoreNavigationBarTheme.style
///   → CoreNavigationBarTheme.variantStyles[variant]
///   → widget per-instance navigationBarStyle
/// ```
@immutable
class CoreNavigationBarTheme {
  /// Creates a [CoreNavigationBarTheme].
  const CoreNavigationBarTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreNavigationBarStyle? style;

  /// Per-variant override styles.
  final Map<CoreNavigationBarVariant, CoreNavigationBarStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNavigationBarTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null ? null : Object.hashAll(variantStyles!.entries),
  );

  static bool _mapEquals(
    Map<CoreNavigationBarVariant, CoreNavigationBarStyle>? a,
    Map<CoreNavigationBarVariant, CoreNavigationBarStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

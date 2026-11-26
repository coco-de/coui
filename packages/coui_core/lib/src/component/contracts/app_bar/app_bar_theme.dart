/// Theme data for `AppBar` customization.
library;

import 'package:coui_core/src/component/contracts/app_bar/app_bar_style.dart';
import 'package:coui_core/src/component/contracts/app_bar/app_bar_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `AppBar`.
///
/// Holds the project [style] applied to every `AppBar` whose
/// widget-level `appBarStyle` is null, plus optional [variantStyles]
/// keyed by [CoreAppBarVariant] for variant-specific overrides.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (`CoreAppBarStyle.defaultX` static const +
///                        `CoreAppBarStyle.defaultsByVariant`)
///   → theme.appBar.style
///   → theme.appBar.variantStyles[variant]
///   → widget per-instance appBarStyle
/// ```
@immutable
class CoreAppBarTheme {
  /// Creates a [CoreAppBarTheme].
  const CoreAppBarTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreAppBarStyle? style;

  /// Per-variant override styles. Looked up via the bar's
  /// [CoreAppBarVariant], merged on top of [style].
  final Map<CoreAppBarVariant, CoreAppBarStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAppBarTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(style, variantStyles);

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

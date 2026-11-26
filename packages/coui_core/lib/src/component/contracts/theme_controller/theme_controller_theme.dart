/// Theme overrides for theme controller components.
library;

import 'package:coui_core/src/component/contracts/theme_controller/theme_controller_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ThemeController`.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreThemeControllerStyle.defaultX)
///   → CoreThemeControllerStyle.defaultsBySize[size]
///   → CoreThemeControllerTheme.style
///   → widget per-instance themeControllerStyle
/// ```
///
/// One slot, not two: `variantStyles` is what a Theme offers when a
/// component has a variant axis to key it by, and this control has
/// none. The size ladder is not that axis — a project overriding "the
/// large tier only" is asking for something the widget already gets
/// from [CoreThemeControllerStyle.defaultsBySize], and giving the Theme
/// a second table keyed by size would put two answers in the merge
/// chain for the same field.
@immutable
class CoreThemeControllerTheme {
  /// Creates a [CoreThemeControllerTheme].
  const CoreThemeControllerTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreThemeControllerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreThemeControllerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}

/// Theme data for `Button` customisation.
library;

import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/button/button_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Button`.
///
/// Holds the project [style] applied to every `Button` whose
/// widget-level `buttonStyle` is null, plus optional [variantStyles]
/// keyed by [CoreButtonVariant] for variant-specific overrides
/// (looked up by the widget's `variant` parameter).
///
/// Per Epic #1302 / #1370 all 시각 chrome — including
/// `animationDuration` for chrome state transitions and
/// `disableHoverEffect` for hover-effect suppression — flows through
/// the [style] / [variantStyles] slots, not the Theme itself.
///
/// ### Resolve chain.
///
/// ```text
/// design system default for variant
///   → CoreButtonTheme.style                       // 프로젝트 공통
///   → CoreButtonTheme.variantStyles[widget.variant]
///   → parent component slot override
///   → widget per-instance buttonStyle
/// ```
@immutable
class CoreButtonTheme {
  /// Creates a [CoreButtonTheme].
  const CoreButtonTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreButtonStyle? style;

  /// Per-variant override styles. Looked up by the widget's
  /// `variant` parameter, merged on top of [style].
  final Map<CoreButtonVariant, CoreButtonStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreButtonTheme &&
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

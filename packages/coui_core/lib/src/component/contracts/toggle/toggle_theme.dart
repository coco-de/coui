/// Theme data for `Toggle` (switch) customisation.
library;

import 'package:coui_core/src/component/contracts/toggle/toggle_style.dart';
import 'package:coui_core/src/component/contracts/toggle/toggle_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Toggle`.
///
/// Holds the project [style] applied to every `Toggle` whose
/// widget-level `toggleStyle` is null, plus optional
/// [variantStyles] keyed by [CoreToggleVariant] for variant-specific
/// chrome (looked up by the widget's `variant`).
///
/// ### Resolve chain.
///
/// ```text
/// design system default for variant
///   → CoreToggleTheme.style                       // 프로젝트 공통
///   → CoreToggleTheme.variantStyles[widget.variant]
///   → parent component slot override
///   → widget per-instance toggleStyle
/// ```
@immutable
class CoreToggleTheme {
  /// Creates a [CoreToggleTheme].
  const CoreToggleTheme({
    this.style,
    this.variantStyles,
  });

  /// Project-level base style. `null` → no project override.
  final CoreToggleStyle? style;

  /// Per-variant override styles. Looked up by the widget's
  /// `variant` parameter, merged on top of [style].
  final Map<CoreToggleVariant, CoreToggleStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreToggleTheme &&
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

/// Theme data for `RadioGroup` customisation.
library;

import 'package:coui_core/src/component/contracts/radio_group/radio_group_style.dart';
import 'package:coui_core/src/component/contracts/radio_group/radio_group_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `RadioGroup`.
///
/// Holds the project [style] applied to every `RadioGroup` whose
/// widget-level `radioGroupStyle` is null, plus optional
/// [variantStyles] keyed by [CoreRadioGroupVariant] for
/// variant-specific chrome (looked up by the widget's `variant`).
///
/// ### Resolve chain.
///
/// ```text
/// design system default for variant
///   → CoreRadioGroupTheme.style                       // 프로젝트 공통
///   → CoreRadioGroupTheme.variantStyles[widget.variant]
///   → parent component slot override
///   → widget per-instance radioGroupStyle
/// ```
@immutable
class CoreRadioGroupTheme {
  /// Creates a [CoreRadioGroupTheme].
  const CoreRadioGroupTheme({
    this.style,
    this.variantStyles,
  });

  /// Project-level base style. `null` → no project override.
  final CoreRadioGroupStyle? style;

  /// Per-variant override styles. Looked up by the widget's
  /// `variant` parameter, merged on top of [style].
  final Map<CoreRadioGroupVariant, CoreRadioGroupStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRadioGroupTheme &&
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

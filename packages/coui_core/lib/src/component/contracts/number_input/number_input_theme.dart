/// Theme data for `NumberInput` customisation.
library;

import 'package:coui_core/src/component/contracts/number_input/number_input_style.dart';
import 'package:coui_core/src/component/contracts/number_input/number_input_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `NumberInput`.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreNumberInputTheme.style
///   → CoreNumberInputTheme.variantStyles[variant]
///   → widget per-instance numberInputStyle
/// ```
@immutable
class CoreNumberInputTheme {
  /// Creates a [CoreNumberInputTheme].
  const CoreNumberInputTheme({this.style, this.variantStyles});

  /// Project-wide style applied to every `NumberInput`.
  final CoreNumberInputStyle? style;

  /// Per-variant project overrides, merged on top of [style].
  final Map<CoreNumberInputVariant, CoreNumberInputStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNumberInputTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(style, variantStyles?.length);

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

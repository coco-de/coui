/// Theme data for Steps customization.
library;

import 'package:coui_core/src/component/contracts/steps/steps_style.dart';
import 'package:coui_core/src/component/contracts/steps/steps_variant.dart';
import 'package:meta/meta.dart';

/// Theme overrides for Steps.
///
/// Per-instance chrome flows through the composite [style] field and the
/// per-variant [variantStyles] map — see [CoreStepsStyle]. The variant
/// itself is a widget parameter; the theme only answers "how does each
/// variant look in this project".
@immutable
class CoreStepsTheme {
  /// Creates a [CoreStepsTheme].
  const CoreStepsTheme({this.style, this.variantStyles});

  /// Project-wide composite style applied to every `Steps`.
  ///
  /// Resolved before [variantStyles] and any per-instance
  /// `widget.stepsStyle`.
  final CoreStepsStyle? style;

  /// Per-variant override styles. Looked up by the widget's `variant`
  /// parameter, merged on top of [style].
  final Map<CoreStepsVariant, CoreStepsStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStepsTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(style, _mapHash(variantStyles));

  /// Order-independent hash of the entries, so two maps [_mapEquals] calls
  /// equal hash alike — hashing the map object would use its identity.
  static int? _mapHash<K, V>(Map<K, V>? map) {
    if (map == null) return null;
    return Object.hashAllUnordered(
      map.entries.map((entry) => Object.hash(entry.key, entry.value)),
    );
  }

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

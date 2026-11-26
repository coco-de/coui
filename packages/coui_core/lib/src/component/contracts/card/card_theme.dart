/// Theme data for `Card` customization.
library;

import 'package:coui_core/src/component/contracts/card/card_style.dart';
import 'package:coui_core/src/component/contracts/card/card_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Card`.
///
/// Holds the project [style] applied to every `Card` whose
/// widget-level `style` is null, plus optional [variantStyles] keyed
/// by [CoreCardVariant] for variant-specific overrides.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (`CoreCardStyle.defaultX` static const +
///                        `CoreCardStyle.defaultsByVariant`)
///   → theme.card.style
///   → theme.card.variantStyles[variant]
///   → parent component slot override
///   → widget per-instance style
/// ```
///
/// `CoreCardStyle` is now platform-neutral (Epic #1415 option D) so this
/// theme no longer carries platform-specific generics.
@immutable
class CoreCardTheme {
  /// Creates a [CoreCardTheme].
  const CoreCardTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreCardStyle? style;

  /// Per-variant override styles. Looked up via the card's
  /// [CoreCardVariant], merged on top of [style].
  final Map<CoreCardVariant, CoreCardStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCardTheme &&
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

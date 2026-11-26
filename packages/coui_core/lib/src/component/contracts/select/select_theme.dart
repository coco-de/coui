/// Theme slots for `Select`.
library;

import 'package:coui_core/src/component/contracts/select/select_style.dart';
import 'package:coui_core/src/component/contracts/select/select_variant.dart';
import 'package:meta/meta.dart';

/// Project-wide `Select` chrome override — one shared [style] plus a
/// per-[CoreSelectVariant] override, so a project can restyle the error
/// trigger without touching the ordinary one.
@immutable
class CoreSelectTheme {
  /// Creates a theme.
  const CoreSelectTheme({this.style, this.variantStyles});

  /// Chrome applied to every select in the project.
  final CoreSelectStyle? style;

  /// Chrome applied to selects of one variant, over [style].
  final Map<CoreSelectVariant, CoreSelectStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSelectTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(style, _mapHash(variantStyles));

  /// `MapEntry` has identity equality, so hashing the entries would give
  /// two equal maps two different codes — and a value type whose `==`
  /// says equal while its `hashCode` disagrees breaks every set and map
  /// it lands in. Hash what `==` actually compares: the pairs.
  static int? _mapHash(Map<CoreSelectVariant, CoreSelectStyle>? map) {
    if (map == null) return null;
    var hash = 0;
    for (final entry in map.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
  }

  static bool _mapEquals(
    Map<CoreSelectVariant, CoreSelectStyle>? a,
    Map<CoreSelectVariant, CoreSelectStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

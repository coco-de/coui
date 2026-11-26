/// Project-level theme for `Sidebar`.
library;

import 'package:coui_core/src/component/contracts/sidebar/sidebar_style.dart';
import 'package:coui_core/src/component/contracts/sidebar/sidebar_type.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Sidebar`.
///
/// Holds the project [style] applied to every `Sidebar`, plus
/// [variantStyles] keyed by the widget's `type` axis.
/// Chrome flows only through these slots; semantic identifiers stay on
/// the widget, where the caller states them.
///
/// ```text
/// design-system default
///   → CoreSidebarTheme.style
///   → CoreSidebarTheme.variantStyles[type]
///   → widget per-instance style
/// ```
@immutable
class CoreSidebarTheme {
  /// Creates a [CoreSidebarTheme].
  const CoreSidebarTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreSidebarStyle? style;

  /// Per-type override styles, merged on top of [style].
  final Map<CoreSidebarType, CoreSidebarStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarTheme &&
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

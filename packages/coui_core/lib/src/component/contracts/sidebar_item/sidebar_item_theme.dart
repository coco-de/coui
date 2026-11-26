/// Project-level theme for `SidebarItem`.
library;

import 'package:coui_core/src/component/contracts/sidebar_item/sidebar_item_level.dart';
import 'package:coui_core/src/component/contracts/sidebar_item/sidebar_item_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `SidebarItem`.
///
/// Holds the project [style] applied to every `SidebarItem`, plus
/// [variantStyles] keyed by the widget's `level` axis.
/// Chrome flows only through these slots; semantic identifiers stay on
/// the widget, where the caller states them.
///
/// ```text
/// design-system default
///   → CoreSidebarItemTheme.style
///   → CoreSidebarItemTheme.variantStyles[level]
///   → widget per-instance style
/// ```
@immutable
class CoreSidebarItemTheme {
  /// Creates a [CoreSidebarItemTheme].
  const CoreSidebarItemTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreSidebarItemStyle? style;

  /// Per-level override styles, merged on top of [style].
  final Map<CoreSidebarItemLevel, CoreSidebarItemStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarItemTheme &&
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

/// Theme overrides for navigation-menu components.
library;

import 'package:coui_core/src/component/contracts/navigation_menu/navigation_menu_style.dart';
import 'package:coui_core/src/component/contracts/navigation_menu/navigation_menu_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for NavigationMenu.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters.
@immutable
class CoreNavigationMenuTheme {
  /// Creates a [CoreNavigationMenuTheme].
  const CoreNavigationMenuTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreNavigationMenuStyle? style;

  /// Per-variant override styles.
  final Map<CoreNavigationMenuVariant, CoreNavigationMenuStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNavigationMenuTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null
        ? null
        : Object.hashAll(
            variantStyles!.entries
                .map((e) => Object.hash(e.key, e.value))
                .toList(growable: false),
          ),
  );

  static bool _mapEquals(
    Map<CoreNavigationMenuVariant, CoreNavigationMenuStyle>? a,
    Map<CoreNavigationMenuVariant, CoreNavigationMenuStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

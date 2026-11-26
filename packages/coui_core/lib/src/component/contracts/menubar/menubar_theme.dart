/// Theme overrides for menubar components.
library;

import 'package:coui_core/src/component/contracts/menubar/menubar_style.dart';
import 'package:coui_core/src/component/contracts/menubar/menubar_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for Menubar.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters.
@immutable
class CoreMenubarTheme {
  /// Creates a [CoreMenubarTheme].
  const CoreMenubarTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreMenubarStyle? style;

  /// Per-variant override styles.
  final Map<CoreMenubarVariant, CoreMenubarStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenubarTheme &&
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
    Map<CoreMenubarVariant, CoreMenubarStyle>? a,
    Map<CoreMenubarVariant, CoreMenubarStyle>? b,
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

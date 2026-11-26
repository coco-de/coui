/// Theme overrides for scaffold components.
library;

import 'package:coui_core/src/component/contracts/scaffold/scaffold_style.dart';
import 'package:coui_core/src/component/contracts/scaffold/scaffold_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Scaffold`.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreScaffoldStyle.defaultX)
///   → CoreScaffoldTheme.style
///   → CoreScaffoldTheme.variantStyles[variant]
///   → widget per-instance scaffoldStyle
/// ```
@immutable
class CoreScaffoldTheme {
  /// Creates a [CoreScaffoldTheme].
  const CoreScaffoldTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreScaffoldStyle? style;

  /// Per-variant override styles.
  final Map<CoreScaffoldVariant, CoreScaffoldStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreScaffoldTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null ? null : Object.hashAll(variantStyles!.entries),
  );

  static bool _mapEquals(
    Map<CoreScaffoldVariant, CoreScaffoldStyle>? a,
    Map<CoreScaffoldVariant, CoreScaffoldStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

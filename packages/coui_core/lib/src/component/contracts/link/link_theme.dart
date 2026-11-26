/// Theme data for `Link` customisation.
library;

import 'package:coui_core/src/component/contracts/link/link_style.dart';
import 'package:coui_core/src/component/contracts/link/link_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Link`.
///
/// Holds the project [style] applied to every `Link` whose
/// widget-level `linkStyle` is null, and a per-variant [variantStyles]
/// layer on top of it.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreLinkStyle.defaultsByVariant[variant],
///                        CoreLinkStyle.defaultX)
///   → CoreLinkTheme.style                          // 프로젝트 공통
///   → CoreLinkTheme.variantStyles[variant]         // 프로젝트 변형별
///   → widget per-instance linkStyle
/// ```
@immutable
class CoreLinkTheme {
  /// Creates a [CoreLinkTheme].
  const CoreLinkTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreLinkStyle? style;

  /// Project-level per-variant style, merged on top of [style].
  /// `null` → no per-variant override.
  final Map<CoreLinkVariant, CoreLinkStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreLinkTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null
        ? null
        : Object.hashAllUnordered(
            variantStyles!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );

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

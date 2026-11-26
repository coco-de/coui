import 'package:coui_core/src/component/contracts/filter/filter_style.dart';
import 'package:coui_core/src/component/contracts/filter/filter_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for filter components.
///
/// Per Epic #1302 the visual chrome of every Filter flows through the
/// single [style] field — see [CoreFilterStyle] for the merge chain.
/// [variantStyles] supplies optional per-variant overrides.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreFilterTheme.style                       // 프로젝트 공통
///   → CoreFilterTheme.variantStyles[variant]
///   → parent component slot override
///   → widget per-instance filterStyle
/// ```
@immutable
class CoreFilterTheme {
  /// Creates a [CoreFilterTheme].
  const CoreFilterTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreFilterStyle? style;

  /// Per-variant override styles. `null` → no variant override.
  final Map<CoreFilterVariant, CoreFilterStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFilterTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null ? null : Object.hashAll(variantStyles!.entries),
  );

  static bool _mapEquals(
    Map<CoreFilterVariant, CoreFilterStyle>? a,
    Map<CoreFilterVariant, CoreFilterStyle>? b,
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

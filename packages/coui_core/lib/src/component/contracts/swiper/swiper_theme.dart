/// Theme data for `Swiper` customisation.
library;

import 'package:coui_core/src/component/contracts/swiper/swiper_style.dart';
import 'package:coui_core/src/component/contracts/swiper/swiper_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Swiper`.
///
/// Holds the project [style] applied to every `Swiper` whose
/// widget-level `swiperStyle` is null, plus optional per-variant
/// [variantStyles] overrides.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreSwiperStyle.defaultX)
///   → CoreSwiperTheme.style                       // 프로젝트 공통
///   → CoreSwiperTheme.variantStyles[variant]       // variant 공통
///   → widget per-instance swiperStyle
/// ```
@immutable
class CoreSwiperTheme {
  /// Creates a [CoreSwiperTheme].
  const CoreSwiperTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreSwiperStyle? style;

  /// Per-variant override styles. `null` → no variant override.
  final Map<CoreSwiperVariant, CoreSwiperStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwiperTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEq(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(style, _mapHash(variantStyles));

  static int _mapHash(Map<CoreSwiperVariant, CoreSwiperStyle>? map) {
    if (map == null) return 0;
    // MapEntry has no stable hashCode — hash sorted key/value pairs.
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    return Object.hashAll([
      for (final entry in entries) ...[entry.key, entry.value],
    ]);
  }

  static bool _mapEq(
    Map<CoreSwiperVariant, CoreSwiperStyle>? a,
    Map<CoreSwiperVariant, CoreSwiperStyle>? b,
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

/// Project-level theme overrides for category breakdown components.
///
/// ```text
/// CoreCategoryBreakdownStyle.default*
///   → CoreCategoryBreakdownTheme.style                     // 프로젝트 공통
///   → CoreCategoryBreakdownTheme.variantStyles[variant]    // variant 별
///   → widget.categoryBreakdownStyle                        // 인스턴스별
/// ```
library;

import 'package:coui_core/src/component/contracts/category_breakdown/category_breakdown_style.dart';
import 'package:coui_core/src/component/contracts/category_breakdown/category_breakdown_variant.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `CategoryBreakdown`.
@immutable
class CoreCategoryBreakdownTheme {
  /// Creates a [CoreCategoryBreakdownTheme].
  const CoreCategoryBreakdownTheme({this.style, this.variantStyles});

  /// Project-wide style applied to every `CategoryBreakdown`.
  final CoreCategoryBreakdownStyle? style;

  /// Per-variant project-wide style, merged after [style].
  final Map<CoreCategoryBreakdownVariant, CoreCategoryBreakdownStyle>?
  variantStyles;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreCategoryBreakdownTheme || style != other.style) {
      return false;
    }
    final a = variantStyles;
    final b = other.variantStyles;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null
        ? null
        : Object.hashAllUnordered(
            variantStyles!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );
}

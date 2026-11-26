/// Theme overrides for breadcrumb components.
library;

import 'package:coui_core/src/component/contracts/breadcrumb/breadcrumb_style.dart';
import 'package:coui_core/src/component/contracts/breadcrumb/breadcrumb_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for Breadcrumb.
///
/// Holds the project [style] applied to every `Breadcrumb` whose
/// widget-level `breadcrumbStyle` is null, plus optional [variantStyles]
/// keyed by [CoreBreadcrumbVariant] for variant-specific overrides
/// (looked up by the widget's `variant` parameter).
///
/// 시각 chrome 은 전부 [style] / [variantStyles] 슬롯으로만 흐른다
/// (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
/// Semantic identifier (`variant`) 는 **widget-only** — Theme 이
/// override 하면 caller 의 `variant:` 를 짓밟고 Flutter 가 Web (이미
/// 무시) 과 갈라지므로 Theme 에 두지 않는다.
///
/// ### Resolve chain.
///
/// ```text
/// design system default for variant
///   → CoreBreadcrumbTheme.style                       // 프로젝트 공통
///   → CoreBreadcrumbTheme.variantStyles[widget.variant]
///   → widget per-instance breadcrumbStyle
/// ```
@immutable
class CoreBreadcrumbTheme {
  /// Creates a [CoreBreadcrumbTheme].
  const CoreBreadcrumbTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreBreadcrumbStyle? style;

  /// Per-variant override styles. Looked up by the widget's
  /// `variant` parameter, merged on top of [style].
  final Map<CoreBreadcrumbVariant, CoreBreadcrumbStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBreadcrumbTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(style, variantStyles);

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

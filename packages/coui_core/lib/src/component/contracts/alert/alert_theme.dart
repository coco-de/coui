/// Theme overrides for alert components.
library;

import 'package:coui_core/coui_core.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for Alert.
///
/// Holds the project [style] applied to every `Alert` whose
/// widget-level `alertStyle` is null, plus optional [variantStyles]
/// keyed by [CoreAlertVariant] for variant-specific overrides
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
///   → CoreAlertTheme.style                       // 프로젝트 공통
///   → CoreAlertTheme.variantStyles[widget.variant]
///   → parent component slot override
///   → widget per-instance alertStyle
/// ```
@immutable
class CoreAlertTheme {
  /// Creates a [CoreAlertTheme].
  const CoreAlertTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreAlertStyle? style;

  /// Per-variant override styles. Looked up by the widget's
  /// `variant` parameter, merged on top of [style].
  final Map<CoreAlertVariant, CoreAlertStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAlertTheme &&
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

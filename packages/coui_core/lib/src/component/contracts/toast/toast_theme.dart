/// Theme data for `Toast` customisation.
library;

import 'package:coui_core/src/component/contracts/toast/toast_style.dart';
import 'package:coui_core/src/component/contracts/toast/toast_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Toast`.
///
/// Holds the project [style] applied to every `Toast` whose
/// widget-level `toastStyle` is null, plus optional [variantStyles]
/// keyed by [CoreToastVariant] for variant-specific chrome.
///
/// ### Resolve chain.
///
/// ```text
/// design system default for variant
///   → CoreToastTheme.style                       // 프로젝트 공통
///   → CoreToastTheme.variantStyles[widget.variant]
///   → parent component slot override
///   → widget per-instance toastStyle
/// ```
@immutable
class CoreToastTheme {
  /// Creates a [CoreToastTheme].
  const CoreToastTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreToastStyle? style;

  /// Per-variant override styles. Looked up by the widget's
  /// `variant` parameter, merged on top of [style].
  final Map<CoreToastVariant, CoreToastStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreToastTheme &&
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

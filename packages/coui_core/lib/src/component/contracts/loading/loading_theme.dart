import 'package:coui_core/src/component/contracts/loading/loading_style.dart';
import 'package:coui_core/src/component/contracts/loading/loading_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for loading spinner.
///
/// Per Epic #1302 all chrome flows through the [style] / [variantStyles]
/// slots (`CoreLoadingStyle.color` / `.size`). Theme exposes only the
/// `style` + `variantStyles` slots — chrome plain fields and semantic
/// identifiers (`variant` / `componentSize`) are forbidden here.
///
/// ### Resolve chain.
///
/// ```text
/// design system default for variant
///   → CoreLoadingTheme.style                            // 프로젝트 공통
///   → CoreLoadingTheme.variantStyles[widget.variant]
///   → parent component slot override
///   → widget per-instance loadingStyle
/// ```
@immutable
class CoreLoadingTheme {
  /// Creates a [CoreLoadingTheme].
  const CoreLoadingTheme({this.style, this.variantStyles});

  /// Project-wide composite style applied to every `Loading`.
  ///
  /// Resolved before any per-instance `widget.loadingStyle`.
  final CoreLoadingStyle? style;

  /// Per-variant override styles. Looked up by the widget's `variant`
  /// parameter, merged on top of [style].
  final Map<CoreLoadingVariant, CoreLoadingStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreLoadingTheme &&
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

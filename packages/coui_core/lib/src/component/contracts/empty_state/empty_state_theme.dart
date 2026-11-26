import 'package:coui_core/src/component/contracts/empty_state/empty_state_style.dart';
import 'package:coui_core/src/component/contracts/empty_state/empty_state_variant.dart';
import 'package:meta/meta.dart';

/// Empty-state component theme overrides.
///
/// Phase 6f shape: a project-wide [style] base plus per-variant
/// [variantStyles] overrides. All chrome (padding, colours, gaps,
/// typography overrides) is carried inside [CoreEmptyStateStyle].
///
/// ```text
/// CoreEmptyStateStyle.defaults / defaultsByVariant
///   → CoreEmptyStateTheme.style                     // project base
///   → CoreEmptyStateTheme.variantStyles[variant]    // variant override
///   → widget.emptyStateStyle                        // per-instance
/// ```
@immutable
class CoreEmptyStateTheme {
  /// Creates a [CoreEmptyStateTheme].
  const CoreEmptyStateTheme({this.style, this.variantStyles});

  /// Project-wide composite style applied to every `EmptyState`.
  final CoreEmptyStateStyle? style;

  /// Per-variant override styles. Resolved after [style] and before
  /// the per-instance `widget.emptyStateStyle`.
  final Map<CoreEmptyStateVariant, CoreEmptyStateStyle>? variantStyles;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreEmptyStateTheme &&
        runtimeType == other.runtimeType &&
        style == other.style &&
        _variantStylesEq(variantStyles, other.variantStyles);
  }

  @override
  int get hashCode => Object.hash(style, _variantStylesHash(variantStyles));

  static bool _variantStylesEq(
    Map<CoreEmptyStateVariant, CoreEmptyStateStyle>? a,
    Map<CoreEmptyStateVariant, CoreEmptyStateStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static int _variantStylesHash(
    Map<CoreEmptyStateVariant, CoreEmptyStateStyle>? m,
  ) {
    if (m == null) return 0;
    final sorted = m.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    return Object.hashAll(sorted.map((e) => Object.hash(e.key, e.value)));
  }
}

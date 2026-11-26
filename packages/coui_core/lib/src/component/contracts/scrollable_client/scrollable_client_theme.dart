import 'package:coui_core/src/component/contracts/scrollable_client/scrollable_client_style.dart';
import 'package:meta/meta.dart';

/// Platform-independent theme for `ScrollableClient`.
///
/// Carries only the chrome [style] slot ({style} — `ScrollableClient` has
/// no variant enum, so there is no `variantStyles` slot). Behaviour defaults
/// (`diagonalDragBehavior`, `overscroll`, `hitTestBehavior`,
/// `keyboardDismissBehavior`, `showScrollbar`) are not theme overrides —
/// they live as `static const` on `CoreScrollableClientContract` so the
/// Flutter and Web resolvers share a single source.
@immutable
class CoreScrollableClientTheme {
  /// Creates a [CoreScrollableClientTheme].
  const CoreScrollableClientTheme({this.style});

  /// Project-level scrollbar chrome style merged on top of the
  /// design-system default. `null` → no project override.
  final CoreScrollableClientStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreScrollableClientTheme copyWith({CoreScrollableClientStyle? style}) {
    return CoreScrollableClientTheme(style: style ?? this.style);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreScrollableClientTheme && other.style == style);

  @override
  int get hashCode => style.hashCode;
}

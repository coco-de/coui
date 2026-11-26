// CoreHoverCardTheme is effectively immutable (all fields are final).
// The `meta` package isn't a direct dependency of coui_core, so
// `@immutable` cannot be used without adding a new dep. Matching
// the established pattern used across sibling Core*Theme classes.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// Theme overrides for hover card components.
library;

import 'package:coui_core/coui_core.dart';

/// Project-level theme overrides for HoverCard.
///
/// Applied via `CoreComponentTheme.hoverCard`. Individual widget
/// parameters take priority over theme values.
///
/// Phase 6f migration (Epic #1579 §3, Issue #1594): chrome flat fields
/// (`backgroundColor`, `borderColor`, `borderRadius`, `padding`,
/// `openDelay`, `closeDelay`) were absorbed into [style]. `openDelay` /
/// `closeDelay` already live on [CoreHoverCardStyle] as chrome (per the
/// Style class' doc — "overlay timing tokens belong with the visual
/// surface they govern").
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreHoverCardTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance hoverCardStyle
///   → widget chrome props (openDelay, closeDelay)
/// ```
class CoreHoverCardTheme {
  /// Creates a [CoreHoverCardTheme].
  const CoreHoverCardTheme({
    this.style,
  });

  /// Project-wide composite style applied to every `HoverCard`.
  ///
  /// Resolved before any per-instance `widget.hoverCardStyle`.
  final CoreHoverCardStyle? style;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CoreHoverCardTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}

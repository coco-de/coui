import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [ScrollArea].
///
/// Output of [resolveScrollArea] — the merge chain has been applied
/// plus static-const default fallback:
///
/// ```text
/// CoreScrollAreaStyle.defaultX
///   → CoreScrollAreaTheme.style
///   → widget.scrollAreaStyle
/// ```
class ResolvedScrollArea {
  /// Creates a [ResolvedScrollArea].
  const ResolvedScrollArea({
    required this.height,
    required this.maxHeight,
    required this.scrollbarStyle,
  });

  /// Fixed viewport height (logical px, scaling applied), or null when
  /// the scroll area adopts the parent / child height.
  final double? height;

  /// Maximum viewport height (logical px, scaling applied), or null
  /// when unbounded.
  final double? maxHeight;

  /// Nested chrome for the composed `Scrollbar` — the ScrollArea
  /// defaults merged with the caller's partial overrides, raw-forwarded
  /// so `Scrollbar`'s own resolver applies scaling and token
  /// resolution.
  final CoreScrollbarStyle scrollbarStyle;
}

/// Resolves [ResolvedScrollArea] for [ScrollArea].
///
/// Single entry point for the merge chain:
///
/// ```text
/// CoreScrollAreaStyle.defaultX
///   → CoreScrollAreaTheme.style
///   → widget.scrollAreaStyle
/// ```
ResolvedScrollArea resolveScrollArea(
  BuildContext context, {
  CoreScrollAreaStyle? scrollAreaStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scrollAreaTheme = theme.coreComponentTheme?.scrollArea;

  // 2단 merge chain — variant 가 없는 컴포넌트.
  final merged = resolveStyleChain(const CoreScrollAreaStyle(), [
    scrollAreaTheme?.style,
    scrollAreaStyle,
  ]);

  // Composite nested slot — the ScrollArea-divergent defaults merged
  // with the caller's partial overrides, then raw-forwarded (the
  // composed scrollbar's own resolver applies scaling and resolves the
  // colour tokens).
  final scrollbarStyle = CoreScrollAreaStyle.defaultScrollbarStyle.merge(
    merged.scrollbarStyle,
  );

  // Size constraints — `sizeScaling` applied here (resolver), guarded so a
  // null override stays null. Synthesis stays in local vars so the return
  // literal is a bare mapping (resolver-pattern.md Anti-Pattern B).
  final height = merged.height != null ? merged.height! * scaling : null;
  final maxHeight = merged.maxHeight != null
      ? merged.maxHeight! * scaling
      : null;

  return ResolvedScrollArea(
    height: height,
    maxHeight: maxHeight,
    scrollbarStyle: scrollbarStyle,
  );
}

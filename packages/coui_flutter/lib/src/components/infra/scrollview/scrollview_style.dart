import 'package:coui_flutter/coui_flutter.dart';

/// Resolved auto-scroll tuning for [ScrollViewInterceptor].
///
/// Output of [resolveScrollViewInterceptor] — the merge chain has
/// been applied plus the `CoreScrollViewInterceptorStyle.defaultX`
/// fallbacks:
///
/// ```text
/// CoreScrollViewInterceptorStyle.defaultX
///   → CoreScrollViewInterceptorTheme.style
///   → widget.scrollViewInterceptorStyle
/// ```
class ResolvedScrollViewInterceptor {
  /// Creates a [ResolvedScrollViewInterceptor].
  const ResolvedScrollViewInterceptor({
    required this.dragSpeed,
    required this.maxScrollSpeed,
  });

  /// Multiplier applied to the pointer offset before the easing curve.
  final double dragSpeed;

  /// Maximum absolute scroll velocity per frame (logical px).
  final double maxScrollSpeed;
}

/// Resolves [ResolvedScrollViewInterceptor] for the given [context].
///
/// Single entry point for the scroll-view interceptor tuning slot —
/// applies the merge chain (`CoreScrollViewInterceptorTheme.style` →
/// `scrollViewInterceptorStyle`) and the static-const default
/// fallbacks.
ResolvedScrollViewInterceptor resolveScrollViewInterceptor(
  BuildContext context, {
  CoreScrollViewInterceptorStyle? scrollViewInterceptorStyle,
}) {
  final coreTheme = Theme.of(context).coreComponentTheme?.scrollViewInterceptor;

  // Merge chain: theme.style → scrollViewInterceptorStyle.
  final merged = resolveStyleChain(const CoreScrollViewInterceptorStyle(), [
    coreTheme?.style,
    scrollViewInterceptorStyle,
  ]);

  return ResolvedScrollViewInterceptor(
    dragSpeed:
        merged.dragSpeed ?? CoreScrollViewInterceptorStyle.defaultDragSpeed,
    maxScrollSpeed:
        merged.maxScrollSpeed ??
        CoreScrollViewInterceptorStyle.defaultMaxScrollSpeed,
  );
}

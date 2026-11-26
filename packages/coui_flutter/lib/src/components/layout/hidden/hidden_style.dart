import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Hidden].
class ResolvedHidden {
  /// Creates a [ResolvedHidden].
  const ResolvedHidden({
    required this.direction,
    required this.duration,
    required this.keepSpace,
    required this.reverse,
    required this.curve,
  });

  /// Effective collapse direction.
  final CoreHiddenDirection direction;

  /// Effective transition duration.
  final Duration duration;

  /// Whether to reserve space for the hidden content (only opacity animates).
  final bool keepSpace;

  /// Whether to collapse from the trailing edge.
  final bool reverse;

  /// Paint-ready animation curve, converted from the resolved
  /// `CoreCubicBezier` token (the Web twin emits the same four control
  /// points as its `cubic-bezier(...)` timing function).
  final Curve curve;
}

/// Resolves [ResolvedHidden] for [Hidden].
///
/// Priority (per-field): widget value > `CoreComponentTheme.hidden` >
/// design-system default.
ResolvedHidden resolveHidden(
  BuildContext context, {
  CoreHiddenDirection? direction,
  Duration? duration,
  bool? keepSpace,
  bool? reverse,
  CoreCubicBezier? curve,
}) {
  final coreTheme = Theme.of(context).coreComponentTheme?.hidden;

  // Folds the project theme's chrome style over the design-system
  // default so the per-instance transition duration / easing stay 1:1
  // with the Web resolver (`merged.transitionX ?? CoreHiddenStyle
  // .defaultTransitionX`). The defaults equal
  // `Duration(milliseconds: CoreDuration.normal)` (200 ms) and
  // `CoreEasing.move`, so behaviour is unchanged.
  final merged = resolveStyleChain(const CoreHiddenStyle(), [
    coreTheme?.style,
  ]);

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final effectiveDirection = direction ?? coreTheme?.direction ?? .vertical;
  final effectiveDuration =
      duration ??
      coreTheme?.duration ??
      merged.transitionDuration ??
      CoreHiddenStyle.defaultTransitionDuration;
  final effectiveKeepSpace = keepSpace ?? coreTheme?.keepSpace ?? false;
  final effectiveReverse = reverse ?? coreTheme?.reverse ?? false;
  final effectiveCurve =
      curve ??
      coreTheme?.curve ??
      merged.transitionCurve ??
      CoreHiddenStyle.defaultTransitionCurve;

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final curveValue = effectiveCurve.toValue();

  return ResolvedHidden(
    direction: effectiveDirection,
    duration: effectiveDuration,
    keepSpace: effectiveKeepSpace,
    reverse: effectiveReverse,
    curve: curveValue,
  );
}

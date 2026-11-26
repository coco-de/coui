import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedPageTransition
// ═══════════════════════════════════════════════════

/// Resolver output for the page transition [RoutePage] and
/// [RoutePageRoute] draw where the platform has no page motion of its own.
///
/// ```text
/// CorePageTransitionStyle.defaultEnterDuration / … / defaultSlideDistance
///   → theme.coreComponentTheme.pageTransition.style
///   → pageTransitionStyle
/// ```
class ResolvedPageTransition {
  /// Creates a [ResolvedPageTransition].
  const ResolvedPageTransition({
    required this.enterDuration,
    required this.exitDuration,
    required this.enterCurve,
    required this.exitCurve,
    required this.slideDistance,
  });

  /// How long a new screen takes to arrive — [Duration.zero] under a
  /// reduced-motion request.
  final Duration enterDuration;

  /// How long a closed screen takes to leave — [Duration.zero] under a
  /// reduced-motion request.
  final Duration exitDuration;

  /// Paint-ready arrival curve.
  final Curve enterCurve;

  /// Paint-ready departure curve, in real time: the screen starts leaving
  /// at rest and speeds up. A route plays its departure as its animation
  /// running backwards, so the transition reads this through
  /// [Curve.flipped].
  final Curve exitCurve;

  /// How far below its place a new screen starts, in logical pixels — the
  /// style's distance times the theme's scaling.
  final double slideDistance;
}

// ═══════════════════════════════════════════════════
// resolvePageTransition — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedPageTransition] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CorePageTransitionStyle.defaultX` static const fallbacks. Without a
/// [Theme] above [context] the design-system defaults apply.
///
/// A reduced-motion request makes both durations zero. A page transition
/// always moves a screen, whatever its length, so it is transition-tier
/// motion even when an app sets it longer than the tier's ceiling — the
/// same answer the route gives the platform's own transitions, whose
/// lengths are Flutter's rather than a CoUI duration.
ResolvedPageTransition resolvePageTransition(
  BuildContext context, {
  CorePageTransitionStyle? pageTransitionStyle,
}) {
  final theme = Theme.maybeOf(context);
  final scaling = theme?.scaling ?? 1;
  final pageTransitionTheme = theme?.coreComponentTheme?.pageTransition;

  final merged = resolveStyleChain(const CorePageTransitionStyle(), [
    pageTransitionTheme?.style,
    pageTransitionStyle,
  ]);

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final reduce = resolveReducedMotion(context);
  final enterDuration = reduce
      ? Duration.zero
      : merged.enterDuration ?? CorePageTransitionStyle.defaultEnterDuration;
  final exitDuration = reduce
      ? Duration.zero
      : merged.exitDuration ?? CorePageTransitionStyle.defaultExitDuration;
  final enterCurve =
      (merged.enterCurve ?? CorePageTransitionStyle.defaultEnterCurve)
          .toValue();
  final exitCurve =
      (merged.exitCurve ?? CorePageTransitionStyle.defaultExitCurve).toValue();
  final slideDistance =
      (merged.slideDistance ?? CorePageTransitionStyle.defaultSlideDistance) *
      scaling;

  return ResolvedPageTransition(
    enterDuration: enterDuration,
    exitDuration: exitDuration,
    enterCurve: enterCurve,
    exitCurve: exitCurve,
    slideDistance: slideDistance,
  );
}

library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Hover`.
///
/// Widget tree (`co_hover.dart` decides which optional branches render):
///
/// ```text
/// MouseRegion (onEnter / onExit drive the timing callbacks)
///   └─ effect wrapper (driven by the immediate `_pointerInside` flag):
///        • none      → child as-is
///        • scaleUp   → AnimatedScale (scaleUpFactor)
///        • scaleDown → AnimatedScale (scaleDownFactor)
///        • fade      → AnimatedOpacity (fadeOpacity)
///        • brighten  → AnimatedContainer > ColorFiltered (brightenFactor)
///        • shadow    → AnimatedContainer (hoverShadows)
///             └─ child                              // SizedBox when null
/// ```
///
/// Every field is paint-ready: the effect wrappers receive plain
/// Flutter values (`double`, `Duration`, `List<BoxShadow>`) so the
/// widget never re-runs the merge / fallback / colour-resolution chain.
/// The `shadow` effect's [hoverShadows] already has its `CoreColor`
/// base colour resolved through `scheme.resolve(...).toValue()`.
///
/// Field grouping:
///
/// 1. **Visual-effect chrome** — the per-effect hovered-state factors
///    plus the shared [effectDuration] read by the `Animated*` wrappers.
/// 2. **Behaviour timings** — [waitDuration] / [showDuration] /
///    [minDuration] consumed by the `MouseRegion` enter / exit handlers.
///    They are resolved here so the widget has a single resolve call.
///    The `effect` enum stays a widget prop (C13 — the semantic
///    identifier is widget-only and never stored here).
class ResolvedHover {
  /// Creates a [ResolvedHover].
  const ResolvedHover({
    required this.scaleUpFactor,
    required this.scaleDownFactor,
    required this.fadeOpacity,
    required this.brightenFactor,
    required this.hoverShadows,
    required this.effectDuration,
    required this.waitDuration,
    required this.showDuration,
    required this.minDuration,
    required this.curve,
  });

  // ── Visual-effect chrome ────────────────────────────────────

  /// Hovered-state scale factor for the `scaleUp` effect.
  final double scaleUpFactor;

  /// Hovered-state scale factor for the `scaleDown` effect.
  final double scaleDownFactor;

  /// Hovered-state opacity for the `fade` effect.
  final double fadeOpacity;

  /// Hovered-state brightness multiplier for the `brighten` effect.
  final double brightenFactor;

  /// Hovered-state box-shadow stack for the `shadow` effect — already
  /// resolved to paint-ready [BoxShadow]s (the `CoreColor` base colour
  /// ran through `scheme.resolve(...).toValue()`).
  final List<BoxShadow> hoverShadows;

  /// Transition duration shared by every `Animated*` effect wrapper.
  final Duration effectDuration;

  /// The shape the chrome change takes over time.
  ///
  /// Paired with the duration beside it rather than left to the framework.
  /// Flutter's implicit animations default to `Curves.linear` and the Web
  /// twin's CSS transition does not — same length, different shape, so
  /// side by side one pane slides at a constant rate while the other eases
  /// in and out. Both platforms name the same `CoreEasing` alias instead.
  final Curve curve;

  // ── Behaviour timings (MouseRegion enter / exit) ────────────

  /// Delay before the hover state is reported as active.
  final Duration waitDuration;

  /// Delay before the hover state is reported as inactive after the
  /// pointer leaves.
  final Duration showDuration;

  /// Minimum duration the hover state stays active once reported.
  final Duration minDuration;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedHover] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreHoverStyle.defaultX)
///   → CoreHoverTheme.style
///   → widget timing parameters (folded into a CoreHoverStyle layer)
///   → widget.hoverStyle
/// ```
///
/// The widget exposes the `wait` / `show` / `min` timings as loose
/// `Duration?` parameters, so they are folded into a `CoreHoverStyle`
/// layer; the resolution then runs through the same
/// `merged.X ?? CoreHoverStyle.defaultX` surface the chrome path uses,
/// keeping the contract / default / merged mapping 1:1:1.
///
/// [effect] is the widget's semantic prop and is **not** stored on
/// [ResolvedHover] (C13 — semantic identifiers stay widget-only); the
/// widget switches on it directly to choose which effect wrapper renders.
ResolvedHover resolveHover(
  BuildContext context, {
  required CoreHoverEffect effect,
  Duration? waitDuration,
  Duration? showDuration,
  Duration? minDuration,
  CoreHoverStyle? hoverStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final hoverTheme = theme.coreComponentTheme?.hover;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreHoverStyle(), [
    hoverTheme?.style,
    CoreHoverStyle(
      waitDuration: waitDuration,
      showDuration: showDuration,
      minDuration: minDuration,
    ),
    hoverStyle,
  ]);

  // ─── Resolved visual-effect chrome ────────────────────
  final scaleUpFactor =
      merged.scaleUpFactor ?? CoreHoverStyle.defaultScaleUpFactor;
  final scaleDownFactor =
      merged.scaleDownFactor ?? CoreHoverStyle.defaultScaleDownFactor;
  final fadeOpacity = merged.fadeOpacity ?? CoreHoverStyle.defaultFadeOpacity;
  final brightenFactor =
      merged.brightenFactor ?? CoreHoverStyle.defaultBrightenFactor;

  // `shadow` effect — resolve the base colour through the colour scheme
  // (C7 — never a standalone `.toValue()`), then tint the default /
  // override shadow stack with it so the widget reads paint-ready
  // [BoxShadow]s.
  final shadowBase = scheme
      .resolve(merged.shadowBaseColor ?? CoreHoverStyle.defaultShadowBaseColor)
      .toValue();
  final shadowBoxShadow =
      merged.shadowBoxShadow ?? CoreHoverStyle.defaultShadowBoxShadow;
  final hoverShadows = shadowBoxShadow.toValue(
    base: shadowBase,
    geometry: theme.geometry,
  );

  final effectDuration = resolveMotionDuration(
    context,
    merged.effectDuration ?? CoreHoverStyle.defaultEffectDuration,
  );

  // ─── Resolved behaviour timings ───────────────────────
  final resolvedWaitDuration = resolveMotionDuration(
    context,
    merged.waitDuration ?? CoreHoverStyle.defaultWaitDuration,
  );
  final resolvedShowDuration = resolveMotionDuration(
    context,
    merged.showDuration ?? CoreHoverStyle.defaultShowDuration,
  );
  final resolvedMinDuration = resolveMotionDuration(
    context,
    merged.minDuration ?? CoreHoverStyle.defaultMinDuration,
  );

  return ResolvedHover(
    // The same alias the Web twin names for this element's CSS
    // transition. Chrome moving between states is `move`; a curve
    // stated on one platform and defaulted on the other is the
    // divergence nothing renders differently enough to notice until
    // the two are put side by side.
    curve: CoreEasing.move.toValue(),
    scaleUpFactor: scaleUpFactor,
    scaleDownFactor: scaleDownFactor,
    fadeOpacity: fadeOpacity,
    brightenFactor: brightenFactor,
    hoverShadows: hoverShadows,
    effectDuration: effectDuration,
    waitDuration: resolvedWaitDuration,
    showDuration: resolvedShowDuration,
    minDuration: resolvedMinDuration,
  );
}

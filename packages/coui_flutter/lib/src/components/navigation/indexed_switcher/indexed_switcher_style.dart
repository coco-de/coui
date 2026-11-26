import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedIndexedSwitcher
// ═══════════════════════════════════════════════════

/// Resolver output for [IndexedSwitcher].
///
/// The fade-out and fade-in timing after the nested-merge chain, the
/// `CoreIndexedSwitcherStyle.defaultX` static const fallbacks and the
/// reduced-motion policy:
///
/// ```text
/// CoreIndexedSwitcherStyle.defaultExitDuration / … / defaultEnterCurve
///   → theme.coreComponentTheme.indexedSwitcher.style
///   → widget.indexedSwitcherStyle
/// ```
class ResolvedIndexedSwitcher {
  /// Creates a [ResolvedIndexedSwitcher].
  const ResolvedIndexedSwitcher({
    required this.exitDuration,
    required this.enterDuration,
    required this.exitCurve,
    required this.enterCurve,
  });

  /// How long the outgoing view fades out — [Duration.zero] under a
  /// reduced-motion request.
  final Duration exitDuration;

  /// How long the incoming view fades in after the outgoing view is gone —
  /// [Duration.zero] under a reduced-motion request.
  final Duration enterDuration;

  /// Paint-ready fade-out curve. The Web twin emits the same four control
  /// points as the fade-out's timing function.
  final Curve exitCurve;

  /// Paint-ready fade-in curve. The Web twin emits the same four control
  /// points as the fade-in's timing function.
  final Curve enterCurve;
}

// ═══════════════════════════════════════════════════
// resolveIndexedSwitcher — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedIndexedSwitcher] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreIndexedSwitcherStyle.defaultX` static const fallbacks, then routes
/// both durations through [resolveMotionDuration] so a reduced-motion
/// request makes the switch instant — the Web twin reads the same request
/// through the `--coui-duration-*` variables.
ResolvedIndexedSwitcher resolveIndexedSwitcher(
  BuildContext context, {
  CoreIndexedSwitcherStyle? indexedSwitcherStyle,
}) {
  final indexedSwitcherTheme = Theme.of(
    context,
  ).coreComponentTheme?.indexedSwitcher;

  final merged = resolveStyleChain(const CoreIndexedSwitcherStyle(), [
    indexedSwitcherTheme?.style,
    indexedSwitcherStyle,
  ]);

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final exitDuration = resolveMotionDuration(
    context,
    merged.exitDuration ?? CoreIndexedSwitcherStyle.defaultExitDuration,
  );
  final enterDuration = resolveMotionDuration(
    context,
    merged.enterDuration ?? CoreIndexedSwitcherStyle.defaultEnterDuration,
  );
  final exitCurve =
      (merged.exitCurve ?? CoreIndexedSwitcherStyle.defaultExitCurve).toValue();
  final enterCurve =
      (merged.enterCurve ?? CoreIndexedSwitcherStyle.defaultEnterCurve)
          .toValue();

  return ResolvedIndexedSwitcher(
    exitDuration: exitDuration,
    enterDuration: enterDuration,
    exitCurve: exitCurve,
    enterCurve: enterCurve,
  );
}

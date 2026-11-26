import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [OverflowMarquee].
class ResolvedOverflowMarquee {
  /// Creates a [ResolvedOverflowMarquee].
  const ResolvedOverflowMarquee({
    required this.direction,
    required this.duration,
    required this.delayDuration,
    required this.step,
    required this.fadePortion,
    required this.curve,
    required this.pauseOnHover,
  });

  /// Effective scroll direction.
  final CoreAxis direction;

  /// Effective cycle duration.
  final Duration duration;

  /// Effective delay between cycles.
  final Duration delayDuration;

  /// Effective speed step (px).
  final double step;

  /// Effective edge fade length (px).
  final double fadePortion;

  /// Effective easing curve.
  final Curve curve;

  /// Effective hover-to-pause behaviour.
  final bool pauseOnHover;
}

/// Resolves [ResolvedOverflowMarquee] for [OverflowMarquee].
///
/// Timing / dimensional chrome merge chain: design system default →
/// `CoreOverflowMarqueeTheme.style` → `widget.overflowMarqueeStyle`.
/// Semantic / behavioural inputs ([direction], [curve], [pauseOnHover])
/// are widget-only — Theme does not override them.
ResolvedOverflowMarquee resolveOverflowMarquee(
  BuildContext context, {
  CoreAxis? direction,
  CoreMarqueeCurve? curve,
  bool? pauseOnHover,
  CoreOverflowMarqueeStyle? overflowMarqueeStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.overflowMarquee;

  final merged = resolveStyleChain(const CoreOverflowMarqueeStyle(), [
    coreTheme?.style,
    overflowMarqueeStyle,
  ]);

  // Stage1 RESOLVE — settle semantic / timing inputs.
  final resolvedDirection = direction ?? .horizontal;
  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreOverflowMarqueeStyle.defaultDuration,
  );
  final delayDuration = resolveMotionDuration(
    context,
    merged.delayDuration ?? CoreOverflowMarqueeStyle.defaultDelayDuration,
  );
  final resolvedPauseOnHover = pauseOnHover ?? false;
  // Stage2 EMIT — scaled dimensions + curve materialisation live in locals.
  final step = (merged.step ?? CoreOverflowMarqueeStyle.defaultStep) * scaling;
  final fadePortion =
      (merged.fadePortion ?? CoreOverflowMarqueeStyle.defaultFadePortion) *
      scaling;
  final resolvedCurve = (curve ?? CoreMarqueeCurve.linear).toValue();

  return ResolvedOverflowMarquee(
    direction: resolvedDirection,
    duration: duration,
    delayDuration: delayDuration,
    step: step,
    fadePortion: fadePortion,
    curve: resolvedCurve,
    pauseOnHover: resolvedPauseOnHover,
  );
}

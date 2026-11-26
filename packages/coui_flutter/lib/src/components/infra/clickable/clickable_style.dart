import 'package:coui_flutter/coui_flutter.dart';

/// Resolver output for [Clickable].
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus the static-const default fallback
/// and type conversion done.
class ResolvedClickable {
  /// Creates a [ResolvedClickable].
  const ResolvedClickable({
    required this.borderRadius,
    required this.focusOutlineStyle,
    required this.pressedScale,
    required this.pressedTranslate,
    required this.pressedBoxShadow,
    required this.disabledOpacity,
    required this.duration,
    required this.pressDuration,
    required this.curve,
  });

  /// Focus-ring corner radius.
  final BorderRadius borderRadius;

  /// Paint-ready focus-outline style — passed straight to
  /// `FocusOutline.focusOutlineStyle`. Every nested field
  /// (`align` / `borderColor` / `borderWidth` / `offsetColor`) has
  /// resolved through the design defaults, theme.style and the
  /// per-instance slot.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Scale applied while pressed. `1.0` disables the feedback.
  final double pressedScale;

  /// How far the control moves while pressed, in logical pixels.
  ///
  /// `Offset.zero` leaves it where it is, which is the default. A style
  /// that raises its surfaces states a shift here and a smaller stack in
  /// [pressedBoxShadow] — together they read as the surface going down
  /// rather than as it changing size.
  final Offset pressedTranslate;

  /// The shadow cast while pressed, or null to keep the resting one.
  final List<BoxShadow>? pressedBoxShadow;

  /// Opacity applied while disabled.
  final double disabledOpacity;

  /// Container / hover transition duration.
  final Duration duration;

  /// The shape the chrome change takes over time.
  ///
  /// Paired with the duration beside it rather than left to the framework.
  /// Flutter's implicit animations default to `Curves.linear` and the Web
  /// twin's CSS transition does not — same length, different shape, so
  /// side by side one pane slides at a constant rate while the other eases
  /// in and out. Both platforms name the same `CoreEasing` alias instead.
  final Curve curve;

  /// Press-feedback transition duration.
  ///
  /// Already routed through [resolveMotionDuration] — collapses to
  /// [Duration.zero] under the ambient reduced-motion preference, same as
  /// every other resolver-emitted duration (`core/design-tokens.md`'s
  /// transition tier).
  final Duration pressDuration;
}

/// Resolves [ResolvedClickable] for [Clickable].
///
/// Priority (per-field):
/// `clickableStyle` (`CoreClickableStyle`) >
/// `CoreClickableTheme.style` > design-system default
/// (`CoreClickableStyle` static const).
ResolvedClickable resolveClickable(
  BuildContext context, {
  CoreClickableStyle? clickableStyle,
}) {
  final coreTheme = Theme.of(context).coreComponentTheme?.clickable;

  // Merge chain: theme.style → widget.clickableStyle.
  final merged = resolveStyleChain(const CoreClickableStyle(), [
    coreTheme?.style,
    clickableStyle,
  ]);

  final borderRadiusCore =
      merged.borderRadius ?? CoreClickableStyle.defaultBorderRadius;

  // Single slot — design default merged with the per-instance
  // override. `borderRadius` follows the clickable's own radius
  // override; `duration` falls back to the clickable transition
  // duration.
  final focusOutlineStyle = CoreClickableStyle.defaultFocusOutlineStyle
      .merge(merged.focusOutlineStyle)
      .copyWith(
        borderRadius:
            merged.focusOutlineStyle?.borderRadius ?? borderRadiusCore,
        duration: resolveMotionDuration(
          context,
          merged.focusOutlineStyle?.duration ??
              CoreClickableStyle.defaultDuration,
        ),
      );

  // Stage 2 EMIT — the press offset scales with the platform density the
  // same way every other dimensional value does, and the shadow resolves
  // its tint through the active scheme like any other.
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final translateCore =
      merged.pressedTranslate ?? CoreClickableStyle.defaultPressedTranslate;
  final pressedTranslate = Offset(
    translateCore.dx * scaling,
    translateCore.dy * scaling,
  );
  final pressedShadowCore = merged.pressedBoxShadow;
  final pressedBoxShadow = pressedShadowCore == null
      ? null
      : pressedShadowCore.toValue(
          base: theme.colorScheme
              .resolve(const CoreColor.token(CoreColors.shadow))
              .toValue(),
          // The active surface style bends this the same way it bends a
          // resting shadow — a press under a preset that flattens shadows
          // should not quietly keep a soft one.
          geometry: theme.geometry,
        );
  // Press-feedback transition duration — the shared feedback (the shrink,
  // translation and shadow in `Clickable`) is transition-tier motion, so it
  // collapses to zero under reduced motion like other resolver-emitted
  // duration does. Wrapping the *merged* value here, rather than trusting
  // each caller to pre-resolve its own override (`Button` does; most
  // `Clickable` consumers relying on `CoreClickableStyle.defaultPressDuration`
  // do not), is the one place both paths are guaranteed to pass through.
  final pressDuration = resolveMotionDuration(
    context,
    merged.pressDuration ?? CoreClickableStyle.defaultPressDuration,
  );

  return ResolvedClickable(
    // The same alias the Web twin names for this element's CSS
    // transition. Chrome moving between states is `move`; a curve
    // stated on one platform and defaulted on the other is the
    // divergence nothing renders differently enough to notice until
    // the two are put side by side.
    curve: CoreEasing.move.toValue(),
    borderRadius: borderRadiusCore.toValue(
      geometry: Theme.of(context).geometry,
    ),
    focusOutlineStyle: focusOutlineStyle,
    pressedScale: merged.pressedScale ?? CoreClickableStyle.defaultPressedScale,
    pressedTranslate: pressedTranslate,
    pressedBoxShadow: pressedBoxShadow,
    disabledOpacity:
        merged.disabledOpacity ?? CoreClickableStyle.defaultDisabledOpacity,
    duration: resolveMotionDuration(
      context,
      merged.duration ?? CoreClickableStyle.defaultDuration,
    ),
    pressDuration: pressDuration,
  );
}

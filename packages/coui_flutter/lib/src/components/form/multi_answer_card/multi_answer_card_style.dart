import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedMultiAnswerCard
// ═══════════════════════════════════════════════════

/// Resolver output for `MultiAnswerCard`.
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus token lookup and type conversion.
class ResolvedMultiAnswerCard {
  /// Creates a [ResolvedMultiAnswerCard].
  const ResolvedMultiAnswerCard({
    required this.idleContainerStyle,
    required this.hoverContainerStyle,
    required this.selectedContainerStyle,
    required this.disabledContainerStyle,
    required this.restingInset,
    required this.selectedInset,
    required this.bodyTextStyle,
    required this.selectedBodyTextStyle,
    required this.disabledBodyTextStyle,
    required this.checkboxGapStyle,
    required this.checkboxStyle,
    required this.checkboxSize,
    required this.transitionDuration,
    required this.transitionCurve,
    required this.clickableStyle,
  });

  /// Chrome for the resting (unselected, not hovered) card — fill =
  /// `backgroundColor` token, border = `borderColor` token. All three
  /// bundles leave `surfaceBlur` unset: every fill is a real, opaque
  /// design token (`surface` / `primary` derivatives, never the
  /// transparent sentinel), so there is no fill-less-box risk in
  /// letting a material preset reach any of them (unlike `Checkbox`'s
  /// checked-glyph contrast concern — this card has no glyph riding on
  /// the fill, only caller-supplied text/content that already carries
  /// its own colour).
  final CoreOutlinedContainerStyle idleContainerStyle;

  /// Chrome for the hovered (not selected) card — fill =
  /// `hoverColor` token, border = `hoverBorderColor` token.
  final CoreOutlinedContainerStyle hoverContainerStyle;

  /// Chrome for the disabled card, selected or not — fill =
  /// `disabledBackgroundColor`, border = `disabledBorderColor`, both the
  /// dedicated disabled tokens (the composed `Clickable` does not fade
  /// it a second time). Border width stays the resting one.
  final CoreOutlinedContainerStyle disabledContainerStyle;

  /// Chrome for the selected card — fill = `selectedBackgroundColor`
  /// token, border = `selectedBorderColor` token. The bundles carry the
  /// same authored padding; any border-width difference is made up by
  /// [restingInset] / [selectedInset] (zero with the default widths, which
  /// are equal).
  final CoreOutlinedContainerStyle selectedContainerStyle;

  /// Content inset of the idle and hovered card — the difference between
  /// the thicker border and this state's (logical px, paint-ready).
  ///
  /// The widget animates it with [transitionDuration] and
  /// [transitionCurve], the duration and curve `OutlinedContainer` lerps
  /// its border with, so border + inset is the same on every frame of the
  /// swap and the content never moves.
  final EdgeInsets restingInset;

  /// Content inset of the selected card — see [restingInset].
  final EdgeInsets selectedInset;

  /// Paint-ready body text style for the caller-supplied child —
  /// design-system base typography (`bodyLarge` + `onSurface`) merged
  /// with the per-instance override, applied via `DefaultTextStyle` so
  /// the card text matches the Web side's inherited base.
  final TextStyle bodyTextStyle;

  /// Paint-ready body text style while the card is selected (enabled).
  final TextStyle selectedBodyTextStyle;

  /// Paint-ready body text style while the card is disabled.
  final TextStyle disabledBodyTextStyle;

  /// Gap between the answer content and the trailing checkbox —
  /// `defaultCheckboxGapStyle` merged with the override, raw-forwarded to
  /// `Gap(gapStyle:)`.
  final CoreGapStyle checkboxGapStyle;

  /// Nested [CoreCheckboxStyle] slot for the composed trailing
  /// `Checkbox` — `defaultCheckboxStyle` merged with the override,
  /// raw-forwarded to `Checkbox(checkboxStyle:)`.
  final CoreCheckboxStyle checkboxStyle;

  /// Size of the composed trailing `Checkbox`.
  final CoreComponentSize checkboxSize;

  /// Transition duration for selected / hover state changes.
  final Duration transitionDuration;

  /// The shape of that transition — the alias `OutlinedContainer` names
  /// for its own chrome lerp, so the content inset moves in step with
  /// the border it makes up for.
  final Curve transitionCurve;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// `CoreMultiAnswerCardStyle.defaultClickableStyle` merged with the
  /// per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// resolveMultiAnswerCard — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMultiAnswerCard] for the given [context].
///
/// Walks the nested-merge chain plus token / dimensional fallback:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.multiAnswerCard.style
///   → widget.multiAnswerCardStyle
/// ```
ResolvedMultiAnswerCard resolveMultiAnswerCard(
  BuildContext context, {
  CoreMultiAnswerCardStyle? multiAnswerCardStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final cardTheme = theme.coreComponentTheme?.multiAnswerCard;

  final merged = resolveStyleChain(const CoreMultiAnswerCardStyle(), [
    cardTheme?.style,
    multiAnswerCardStyle,
  ]);

  // Stage1 RESOLVE — merge chain + named default fallback (raw Core
  // tokens; `OutlinedContainer` runs scheme.resolve / geometry / scaling
  // itself for whatever flows through `containerStyle`).
  final backgroundColorCore =
      merged.backgroundColor ?? CoreMultiAnswerCardStyle.defaultBackgroundColor;
  final selectedBackgroundColorCore =
      merged.selectedBackgroundColor ??
      CoreMultiAnswerCardStyle.defaultSelectedBackgroundColor;
  final borderColorCore =
      merged.borderColor ?? CoreMultiAnswerCardStyle.defaultBorderColor;
  final selectedBorderColorCore =
      merged.selectedBorderColor ??
      CoreMultiAnswerCardStyle.defaultSelectedBorderColor;
  final hoverColorCore =
      merged.hoverColor ?? CoreMultiAnswerCardStyle.defaultHoverColor;
  final hoverBorderColorCore =
      merged.hoverBorderColor ??
      CoreMultiAnswerCardStyle.defaultHoverBorderColor;
  final disabledBackgroundColorCore =
      merged.disabledBackgroundColor ??
      CoreMultiAnswerCardStyle.defaultDisabledBackgroundColor;
  final disabledBorderColorCore =
      merged.disabledBorderColor ??
      CoreMultiAnswerCardStyle.defaultDisabledBorderColor;
  final borderWidthCore =
      merged.borderWidth ?? CoreMultiAnswerCardStyle.defaultBorderWidth;
  final selectedBorderWidthCore =
      merged.selectedBorderWidth ??
      CoreMultiAnswerCardStyle.defaultSelectedBorderWidth;
  final borderRadiusCore =
      merged.borderRadius ?? CoreMultiAnswerCardStyle.defaultBorderRadius;

  final bodyTextStyle = CoreMultiAnswerCardStyle.defaultBodyTextStyle
      .merge(merged.bodyTextStyle)
      .toValue(theme: theme);
  final selectedBodyTextStyle = CoreMultiAnswerCardStyle
      .defaultSelectedBodyTextStyle
      .merge(merged.selectedBodyTextStyle)
      .toValue(theme: theme);
  final disabledBodyTextStyle = CoreMultiAnswerCardStyle
      .defaultDisabledBodyTextStyle
      .merge(merged.disabledBodyTextStyle)
      .toValue(theme: theme);
  // Nested slots — partial defaults merged with the override and
  // raw-forwarded (the composed Gap / Checkbox resolve the rest).
  final checkboxGapStyle = CoreMultiAnswerCardStyle.defaultCheckboxGapStyle
      .merge(merged.checkboxGapStyle);
  final checkboxStyle = CoreMultiAnswerCardStyle.defaultCheckboxStyle.merge(
    merged.checkboxStyle,
  );

  // Size-stability compensation — the decoration border participates
  // in layout, so each state insets its content by the difference to the
  // thicker state: content position and total card size stay identical
  // when selection toggles.
  //
  // The compensation is stroke geometry, not spacing, so it stays out of
  // `containerStyle.padding`. `OutlinedContainer` moves that padding
  // through the theme density and the size factor itself, and a density
  // applied to padding + compensation does not keep the difference — one
  // rung down, 16 + 1 lands on 16 and 16 lands on 12, so a one-pixel
  // difference becomes four. The authored padding goes to
  // `OutlinedContainer` as authored, and the compensation reaches the
  // widget as a paint-ready inset.
  //
  // Both widths go through the same `theme.geometry.stroke()` bend
  // `OutlinedContainer` itself applies to whatever raw value flows into
  // `containerStyle.borderWidth` — a plain `* scaling` here would
  // under/over-compensate under any preset that bends stroke width
  // non-linearly (e.g. neo-brutalism's thicker strokes), since the two
  // states would then predict different widths than what actually gets
  // painted.
  final borderWidthScaled = theme.geometry.stroke(
    borderWidthCore,
    scaling: scaling,
  );
  final selectedBorderWidthScaled = theme.geometry.stroke(
    selectedBorderWidthCore,
    scaling: scaling,
  );
  final maxBorderWidthScaled = borderWidthScaled > selectedBorderWidthScaled
      ? borderWidthScaled
      : selectedBorderWidthScaled;
  final restingInset = EdgeInsets.all(
    maxBorderWidthScaled - borderWidthScaled,
  );
  final selectedInset = EdgeInsets.all(
    maxBorderWidthScaled - selectedBorderWidthScaled,
  );
  final paddingCore = merged.padding ?? CoreMultiAnswerCardStyle.defaultPadding;

  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ??
        CoreMultiAnswerCardStyle.defaultTransitionDuration,
  );
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreMultiAnswerCardStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──
  // The face is the box `Card` / `Checkbox` compose, not a hand-rolled
  // decoration: passing Core values (not resolved ones) is what keeps
  // the scheme-resolve / geometry / scaling bend applied exactly once —
  // `OutlinedContainer` runs those steps itself. Every bundle shares
  // radius/duration so swapping between them animates through the one
  // `AnimatedContainer` `OutlinedContainer` owns rather than a widget
  // rebuild.
  final idleContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundColorCore,
    borderColor: borderColorCore,
    borderRadius: borderRadiusCore,
    borderWidth: borderWidthCore,
    padding: paddingCore,
    duration: transitionDuration,
  );
  final hoverContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: hoverColorCore,
    borderColor: hoverBorderColorCore,
    borderRadius: borderRadiusCore,
    borderWidth: borderWidthCore,
    padding: paddingCore,
    duration: transitionDuration,
  );
  final selectedContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: selectedBackgroundColorCore,
    borderColor: selectedBorderColorCore,
    borderRadius: borderRadiusCore,
    borderWidth: selectedBorderWidthCore,
    padding: paddingCore,
    duration: transitionDuration,
  );

  final disabledContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: disabledBackgroundColorCore,
    borderColor: disabledBorderColorCore,
    borderRadius: borderRadiusCore,
    borderWidth: borderWidthCore,
    padding: paddingCore,
    duration: transitionDuration,
  );

  return ResolvedMultiAnswerCard(
    idleContainerStyle: idleContainerStyle,
    hoverContainerStyle: hoverContainerStyle,
    selectedContainerStyle: selectedContainerStyle,
    disabledContainerStyle: disabledContainerStyle,
    restingInset: restingInset,
    selectedInset: selectedInset,
    bodyTextStyle: bodyTextStyle,
    selectedBodyTextStyle: selectedBodyTextStyle,
    disabledBodyTextStyle: disabledBodyTextStyle,
    checkboxGapStyle: checkboxGapStyle,
    checkboxStyle: checkboxStyle,
    checkboxSize: CoreMultiAnswerCardStyle.defaultCheckboxSize,
    transitionDuration: transitionDuration,
    // The alias `OutlinedContainer` names for its chrome lerp — the inset
    // has to move on the same curve as the border it makes up for.
    transitionCurve: CoreEasing.move.toValue(),
    clickableStyle: clickableStyle,
  );
}

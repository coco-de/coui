import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Stepper`.
///
/// Widget tree (`co_stepper.dart` decides which optional branches render):
///
/// ```text
/// vertical — IntrinsicWidth > Column of rows, one per step:
///   ├─ Column: indicator, then Divider between connectorMarginVertical
///   │     margins (connector{Active|Inactive}DividerStyle, by isCompleted)
///   ├─ Gap (indicatorContentGapStyle)
///   ├─ Text (label, label{Active|Inactive|Upcoming}TextStyle)
///   ├─ Gap (descriptionGapStyle — with a description)
///   └─ Text (description, descriptionTextStyle)
///
/// horizontal — a row of equal-width step columns, one per step:
///   ├─ track Row: half-line · indicator · half-line
///   │     (half-lines are Dividers, connector{Active|Inactive}DividerStyle
///   │      selected per half; the first step's leading and the last step's
///   │      trailing half draw nothing but keep their width)
///   ├─ Gap (labelGapStyle)
///   └─ Text (label, label{Active|Inactive|Upcoming}TextStyle)
///
/// indicator — Clickable (navigable only — clickableStyle raw-forward)
///   └─ composed OutlinedContainer, radius9999
///        └─ Icon (check, indicatorIconStyle)
///           | Text (number, indicatorNumber{Active|Inactive}TextStyle)
/// ```
///
/// The widget is **render-only**: it never resolves a colour, typography
/// role or scales a size itself. Every per-state value is baked here so
/// the build methods only pick a field by runtime step state and render.
///
/// Field grouping:
///
/// 1. **State-resolved indicator chrome** —
///    `indicator{Completed|Current|Inactive}ContainerStyle` (Epic #4349).
///    Pre-EMIT `CoreOutlinedContainerStyle` bundles for the composed
///    indicator circle (the widget selects by `isCompleted` / `isCurrent`,
///    then composes `OutlinedContainer`).
/// 2. **Dimensional chrome** — plain `double` (scaling pre-applied where
///    the consuming widget does not self-scale).
/// 3. **Child-component slots (raw forward)** — `indicatorIconStyle`
///    (`CoreIconStyle`, baked raw size + `onPrimary` token),
///    `connector{Active|Inactive}DividerStyle` (`CoreDividerStyle`, token
///    colour + raw thickness) and `clickableStyle`
///    (`CoreClickableStyle`, partial default merged with the override).
///    Forwarded straight to the composed `Icon` / `Divider` /
///    `Clickable`, which resolve the token + apply scaling themselves
///    (no paint→domain round-trip, no double-scale).
/// 4. **Paint-ready text styles** — the number / label / description
///    `TextStyle`s synthesised from the typography role + resolved colour
///    + per-instance override, forwarded straight to `Text(style: …)`.
class ResolvedStepper {
  /// Creates a [ResolvedStepper].
  const ResolvedStepper({
    required this.indicatorSize,
    required this.indicatorContentGapStyle,
    required this.stepPadding,
    required this.connectorMargin,
    required this.connectorMarginVertical,
    required this.labelGapStyle,
    required this.descriptionGapStyle,
    required this.connectorMinExtent,
    required this.indicatorCompletedContainerStyle,
    required this.indicatorCurrentContainerStyle,
    required this.indicatorInactiveContainerStyle,
    required this.connectorActiveDividerStyle,
    required this.connectorInactiveDividerStyle,
    required this.indicatorIconStyle,
    required this.clickableStyle,
    required this.indicatorNumberActiveTextStyle,
    required this.indicatorNumberInactiveTextStyle,
    required this.labelActiveTextStyle,
    required this.labelInactiveTextStyle,
    required this.labelUpcomingTextStyle,
    required this.descriptionTextStyle,
    required this.labelTextScaler,
    required this.labelTextDirection,
    required this.labelLocale,
    required this.labelHeightBehavior,
  });

  /// Actual paragraph context for the vertical layout's first-line measure.
  /// These are rendering inputs, not additional authored spacing or typography.
  final TextScaler labelTextScaler;

  /// Direction used by the visible title paragraph.
  final TextDirection labelTextDirection;

  /// Locale used for fallback shaping.
  final Locale? labelLocale;

  /// The same first/last-line leading behavior as Text.
  final TextHeightBehavior? labelHeightBehavior;

  // ── Dimensional chrome (plain double) ───────────────────────

  /// Diameter of the step indicator circle. The design default is
  /// scaled by `theme.scaling`; an explicit `indicatorSize` override
  /// is used as-is (parity with the pre-resolver widget behaviour).
  final double indicatorSize;

  /// Nested [CoreGapStyle] for the gap between the indicator column and
  /// the step content — forwarded straight to `Gap(gapStyle: …)` inside
  /// `co_stepper`. The slot is **not** pre-scaled here; `Gap` applies
  /// `theme.scaling` itself in its own resolver, so the forwarded slot
  /// stays in pre-scaling units (avoids double-scaling under non-default
  /// text scaler).
  final CoreGapStyle indicatorContentGapStyle;

  /// Padding below each vertical step (paint-ready Flutter
  /// `EdgeInsets`, scaling pre-applied).
  final EdgeInsets stepPadding;

  /// Margin between the indicator and each half-line beside it in the
  /// horizontal layout (already scaled).
  final double connectorMargin;

  /// Margin above and below a connector in the vertical layout (already
  /// scaled).
  final double connectorMarginVertical;

  /// Nested [CoreGapStyle] for the gap between the indicator and its
  /// label in the horizontal layout — forwarded straight to
  /// `Gap(gapStyle: …)` inside `co_stepper`. The slot is **not**
  /// pre-scaled here; `Gap` applies `theme.scaling` itself in its own
  /// resolver, so the forwarded slot stays in pre-scaling units (avoids
  /// double-scaling under non-default text scaler).
  final CoreGapStyle labelGapStyle;

  /// Nested [CoreGapStyle] for the gap between a step's label and its
  /// description (vertical layout) — forwarded straight to
  /// `Gap(gapStyle: …)`, not pre-scaled (the `Gap` scales it itself).
  final CoreGapStyle descriptionGapStyle;

  /// Minimum extent (length) of the connector in the vertical layout
  /// (already scaled).
  final double connectorMinExtent;

  // ── Composed `OutlinedContainer` chrome (pre-EMIT, per state) ─

  /// Composed-`OutlinedContainer` chrome for a completed step's indicator
  /// circle (pre-EMIT `CoreOutlinedContainerStyle`) — fill = the
  /// per-instance `indicatorActiveColor` override else the `primary` token
  /// (a disabled stepper: `indicatorDisabledColor` else `disabledContainer`),
  /// `borderRadius: radius9999` (full circle), `width`/`height:
  /// indicatorSize`. No ring unless the caller states one.
  /// `OutlinedContainer` runs the scheme-resolve / geometry / scaling
  /// bend itself — carrying Core values (not resolved Flutter ones)
  /// keeps that bend applied exactly once. `boxShadow: []` is forced
  /// because this indicator never painted a cast of its own.
  final CoreOutlinedContainerStyle indicatorCompletedContainerStyle;

  /// Composed-`OutlinedContainer` chrome for the current step's indicator
  /// circle — fill = the per-instance `indicatorCurrentColor` override else
  /// the `surface` token, drawn as a ring (`indicatorBorderColor`, else
  /// `indicatorCurrentBorderColor`, else `primary`; a disabled stepper:
  /// `indicatorDisabledBorderColor` else `disabledOutline`). Otherwise
  /// identical shape to [indicatorCompletedContainerStyle].
  final CoreOutlinedContainerStyle indicatorCurrentContainerStyle;

  /// Composed-`OutlinedContainer` chrome for an upcoming (pending)
  /// step's indicator circle — fill = the per-instance
  /// `indicatorInactiveColor` override else the `surface` token, drawn as
  /// a ring (`indicatorBorderColor`, else `indicatorInactiveBorderColor`,
  /// else `outlineVariant`; a disabled stepper:
  /// `indicatorDisabledBorderColor` else `disabledOutline`). Otherwise
  /// identical shape to [indicatorCompletedContainerStyle].
  final CoreOutlinedContainerStyle indicatorInactiveContainerStyle;

  // ── Child-component slots (raw forward) ─────────────────────

  /// Connector line slot for completed segments — a [CoreDividerStyle]
  /// carrying the `connectorActiveColor` override (else the `primary`
  /// token; a disabled stepper: `connectorDisabledColor` else
  /// `disabledOutline`) and the **raw** (pre-scaling) connector thickness.
  /// Forwarded straight to `Divider(dividerStyle: …)`, which resolves the
  /// token and scales the thickness itself.
  final CoreDividerStyle connectorActiveDividerStyle;

  /// Connector line slot for upcoming segments — a [CoreDividerStyle]
  /// carrying the `connectorInactiveColor` override (else the
  /// `outlineVariant` token; a disabled stepper: the same disabled colour
  /// as [connectorActiveDividerStyle]) and the **raw** connector
  /// thickness.
  final CoreDividerStyle connectorInactiveDividerStyle;

  /// Completed-step check icon slot — a [CoreIconStyle] baked with the
  /// **raw** check-glyph size (`indicatorSize × iconSizeRatio`, pre-
  /// scaling) and the `onPrimary` token colour (`disabledContent` while
  /// disabled), merged with the
  /// per-instance `indicatorIconStyle` override. Forwarded straight to
  /// `Icon(iconStyle: …)`, which resolves the token + scales the size
  /// itself (so the check glyph is scaled exactly once).
  final CoreIconStyle indicatorIconStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-indicator
  /// `Clickable` — `CoreStepperStyle.defaultClickableStyle` merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)` when the stepper is navigable.
  final CoreClickableStyle clickableStyle;

  // ── Paint-ready text styles (synthesised) ───────────────────

  /// Indicator number [TextStyle] for the current step — the `labelMedium`
  /// role, semi-bold, with the resolved `onSurface` foreground baked in (it
  /// sits on the `surface` fill; `disabledContent` while disabled).
  final TextStyle indicatorNumberActiveTextStyle;

  /// Indicator number [TextStyle] for pending steps — the `labelMedium`
  /// role, semi-bold, with the resolved `onSurfaceVariant` foreground
  /// baked in (`disabledContent` while disabled).
  final TextStyle indicatorNumberInactiveTextStyle;

  /// Step label [TextStyle] for the current step — the orientation role
  /// (`titleSmall` vertical / `labelLarge` horizontal) with the resolved
  /// label colour, the current-step overlay (semi-bold
  /// `CoreStepperStyle.defaultLabelActiveStyle` + per-instance
  /// `labelActiveStyle`), then the per-instance `labelStyle` overlay.
  final TextStyle labelActiveTextStyle;

  /// Step label [TextStyle] for completed steps — the orientation
  /// default (semi-bold `titleSmall` vertical / `labelLarge` horizontal)
  /// with the resolved label colour + per-instance `labelStyle` overlay.
  final TextStyle labelInactiveTextStyle;

  /// Step label [TextStyle] for upcoming steps — the same default as
  /// [labelInactiveTextStyle] under the `onSurfaceVariant` overlay
  /// (`CoreStepperStyle.defaultLabelUpcomingStyle` + per-instance
  /// `labelUpcomingStyle`), then the per-instance `labelStyle` overlay.
  /// While disabled every label reads in the one disabled ink, so the
  /// three styles differ only by weight.
  final TextStyle labelUpcomingTextStyle;

  /// Paint-ready step description [TextStyle] — the `bodySmall`
  /// typography role with the per-instance `descriptionStyle`
  /// typography overlay (font-size / weight / letter-spacing /
  /// line-height) and the resolved `onSurfaceVariant` (or override)
  /// colour baked in. The widget forwards it straight to
  /// `Text(style: …)` — no widget-side `theme.typography.X.copyWith(…)`.
  final TextStyle descriptionTextStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStepper] for the given [context].
///
/// [orientation] selects the label typography role (`titleSmall`
/// vertical / `labelLarge` horizontal) so the widget paints labels
/// without re-keying the role per layout. [enabled] picks the disabled
/// palette — `disabledContainer` / `disabledOutline` / `disabledContent` —
/// instead of the state colours; it is a semantic state, not an interaction
/// one, so it is a resolver input.
///
/// Merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.stepper.style
///   → widget.stepperStyle
/// ```
ResolvedStepper resolveStepper(
  BuildContext context, {
  required CoreStepperOrientation orientation,
  required bool enabled,
  CoreStepperStyle? stepperStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;

  final stepperTheme = theme.coreComponentTheme?.stepper;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreStepperStyle(), [
    stepperTheme?.style,
    stepperStyle,
  ]);

  // ─── Indicator fill (override else design-system default, per state) ─
  // Completed steps use the `primary` token, or `disabledContainer` while
  // the stepper is disabled; the current and upcoming steps use the
  // `surface` token either way (each inside its own ring, below). The
  // design defaults live as named Core constants so the same token is
  // shared across both platforms.
  final indicatorCompletedToken = enabled
      ? (merged.indicatorActiveColor ??
            CoreStepperStyle.defaultIndicatorActiveColor)
      : (merged.indicatorDisabledColor ??
            CoreStepperStyle.defaultIndicatorDisabledColor);
  final indicatorCurrentToken =
      merged.indicatorCurrentColor ??
      CoreStepperStyle.defaultIndicatorCurrentColor;
  final indicatorInactiveToken =
      merged.indicatorInactiveColor ??
      CoreStepperStyle.defaultIndicatorInactiveColor;

  // The disabled ink — the one colour a disabled stepper writes and draws
  // in, laid over whatever the state would have chosen.
  final disabledForegroundToken =
      merged.disabledForegroundColor ??
      CoreStepperStyle.defaultDisabledForegroundColor;
  final disabledInk = CoreTextStyle(color: disabledForegroundToken);

  // ─── Connector line slots (token colour + RAW thickness) ──
  // The colour stays a `CoreColor` token and the thickness stays
  // pre-scaling: the sibling `Divider` resolves the token and scales
  // the thickness itself, so the widget forwards the slot raw (no
  // paint→domain round-trip, no connector-thickness double-scale).
  // Disabled, every segment takes the one disabled colour.
  final connectorThickness =
      merged.connectorThickness ?? CoreStepperStyle.defaultConnectorThickness;
  final connectorDisabledToken =
      merged.connectorDisabledColor ??
      CoreStepperStyle.defaultConnectorDisabledColor;
  final connectorActiveDividerStyle = CoreDividerStyle(
    color: enabled
        ? (merged.connectorActiveColor ??
              CoreStepperStyle.defaultConnectorActiveColor)
        : connectorDisabledToken,
    thickness: connectorThickness,
  );
  final connectorInactiveDividerStyle = CoreDividerStyle(
    color: enabled
        ? (merged.connectorInactiveColor ??
              CoreStepperStyle.defaultConnectorInactiveColor)
        : connectorDisabledToken,
    thickness: connectorThickness,
  );

  // ─── Completed-step check icon slot (RAW size + onPrimary) ─
  // Design size = raw indicator diameter × ratio so the sibling `Icon`
  // scales the glyph exactly once. The check glyph only renders on
  // completed steps, whose foreground is always `onPrimary` (painted
  // over the `primary` indicator fill) — or the disabled ink while the
  // stepper is disabled; the per-instance `indicatorIconStyle` override
  // wins on top when enabled.
  // guard-nested-override: indicatorIconColor — the default is baked
  // into the named `CoreStepperStyle.defaultIndicatorIconStyle`
  // composite, then `.copyWith(size:)` + `.merge(merged
  // .indicatorIconStyle)` lets a caller-supplied `indicatorIconStyle
  // .color` win (base-then-merge, not a bare top-level reference).
  // Web mirrors the same base-then-merge path (verified both
  // platforms consult it).
  final indicatorSizeRaw =
      merged.indicatorSize ?? CoreStepperStyle.defaultIndicatorSize;
  final iconSizeRatio =
      merged.iconSizeRatio ?? CoreStepperStyle.defaultIconSizeRatio;
  final indicatorIconEnabledStyle = CoreStepperStyle.defaultIndicatorIconStyle
      .copyWith(size: indicatorSizeRaw * iconSizeRatio)
      .merge(merged.indicatorIconStyle);
  final indicatorIconStyle = enabled
      ? indicatorIconEnabledStyle
      : indicatorIconEnabledStyle.copyWith(color: disabledForegroundToken);

  // ─── Nested Clickable slot (raw forward) ──────────────
  // Partial default merged with the per-instance override,
  // raw-forwarded — the composed Clickable's own resolver fills the
  // rest (press scale / focus ring / durations).
  final clickableStyle = CoreStepperStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Indicator number text (labelMedium + semi-bold, per-state fg) ─
  // The current step paints `onSurface` and upcoming steps
  // `onSurfaceVariant` (both over the surface fill); a disabled
  // stepper paints its disabled ink on both. Both roles come from named
  // Core defaults and are materialised through the single
  // `.toValue(theme:)` primitive (no hand-rolled role/weight assembly).
  // The check glyph replaces the number on completed steps, so two styles
  // cover every rendered number.
  final indicatorNumberActiveCore = CoreStepperStyle
      .defaultIndicatorNumberActiveStyle
      .merge(merged.indicatorNumberActiveStyle);
  final indicatorNumberInactiveCore = CoreStepperStyle
      .defaultIndicatorNumberInactiveStyle
      .merge(merged.indicatorNumberInactiveStyle);
  final indicatorNumberActiveTextStyle =
      (enabled
              ? indicatorNumberActiveCore
              : indicatorNumberActiveCore.merge(disabledInk))
          .toValue(theme: theme);
  final indicatorNumberInactiveTextStyle =
      (enabled
              ? indicatorNumberInactiveCore
              : indicatorNumberInactiveCore.merge(disabledInk))
          .toValue(theme: theme);

  // ─── Step label text (role by orientation + per-state overlay) ─
  // The orientation-specific role + `onSurface` colour come from named
  // Core defaults (merged with the orientation-specific override), then
  // the per-instance `labelStyle` overlays on top through the single
  // `.toValue(theme:)` primitive. The current step's label takes its
  // overlay (semi-bold by default) and an upcoming step's its own
  // (`onSurfaceVariant` by default) between the two, so a weight or colour
  // stated on `labelStyle` still reaches every step. A disabled stepper
  // writes every label in the one disabled ink.
  final labelDefault = orientation == .vertical
      ? CoreStepperStyle.defaultLabelVerticalStyle.merge(
          merged.labelVerticalStyle,
        )
      : CoreStepperStyle.defaultLabelHorizontalStyle.merge(
          merged.labelHorizontalStyle,
        );
  final labelActiveOverlay = CoreStepperStyle.defaultLabelActiveStyle.merge(
    merged.labelActiveStyle,
  );
  final labelUpcomingOverlay = CoreStepperStyle.defaultLabelUpcomingStyle.merge(
    merged.labelUpcomingStyle,
  );
  final labelInactiveCore = labelDefault.merge(merged.labelStyle);
  final labelActiveCore = labelDefault
      .merge(labelActiveOverlay)
      .merge(merged.labelStyle);
  final labelUpcomingCore = labelDefault
      .merge(labelUpcomingOverlay)
      .merge(merged.labelStyle);
  final labelInactiveTextStyle =
      (enabled ? labelInactiveCore : labelInactiveCore.merge(disabledInk))
          .toValue(theme: theme);
  final labelActiveTextStyle =
      (enabled ? labelActiveCore : labelActiveCore.merge(disabledInk)).toValue(
        theme: theme,
      );
  final labelUpcomingTextStyle =
      (enabled ? labelUpcomingCore : labelUpcomingCore.merge(disabledInk))
          .toValue(theme: theme);

  // ─── Description text style (typography role + slot overlay) ─
  // The bodySmall role token + `onSurfaceVariant` colour live on the
  // named `defaultDescriptionStyle`; the per-instance `descriptionStyle`
  // overlays font-size / weight / letter-spacing / line-height / colour
  // through the single `.toValue(theme:)` primitive — no widget-side merge.
  final descriptionCore = CoreStepperStyle.defaultDescriptionStyle.merge(
    merged.descriptionStyle,
  );
  final descriptionTextStyle =
      (enabled ? descriptionCore : descriptionCore.merge(disabledInk)).toValue(
        theme: theme,
      );

  // ─── Nested gap slots ─────────────────────────────────
  // Merge the design-system default `CoreGapStyle` with the per-instance
  // override and forward the resulting slot raw. `Gap`'s own resolver
  // multiplies `size` by `theme.scaling`, so pre-applying scaling here
  // would double-scale under non-default text scaler (Epic #1603 옵션 B —
  // parent forwards raw nested style slots).
  final indicatorContentGapStyle = CoreStepperStyle
      .defaultIndicatorContentGapStyle
      .merge(merged.indicatorContentGapStyle);
  final labelGapStyle = CoreStepperStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  final descriptionGapStyle = CoreStepperStyle.defaultDescriptionGapStyle.merge(
    merged.descriptionGapStyle,
  );

  // ─── Step padding (paint-ready EdgeInsets before scaling) ─
  final stepPadding =
      ((merged.stepPadding ?? CoreStepperStyle.defaultStepPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;

  // ─── Dimensional fallbacks (paint-ready before scaling) ──
  // Override is used as-is; only the design default is scaled — matching
  // the pre-resolver `merged.X ?? scaling * default`. Synthesised here so
  // the return literal stays a bare mapping (chaining gate).
  final indicatorSize =
      merged.indicatorSize ?? (scaling * CoreStepperStyle.defaultIndicatorSize);
  final connectorMargin =
      theme.geometry.space(
        merged.connectorMargin ?? CoreStepperStyle.defaultConnectorMargin,
      ) *
      scaling;
  final connectorMarginVertical =
      theme.geometry.space(
        merged.connectorMarginVertical ??
            CoreStepperStyle.defaultConnectorMarginVertical,
      ) *
      scaling;
  final connectorMinExtent =
      (merged.connectorMinExtent ??
          CoreStepperStyle.defaultConnectorMinExtent) *
      scaling;

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──────
  // The indicator circle is the box `Card` / `Fieldset` compose, not a
  // hand-rolled decoration (Epic #4349) — passing Core values (not
  // resolved ones) keeps the scheme-resolve / geometry / scaling bend
  // applied exactly once, by `OutlinedContainer` itself.
  //
  // A completed circle draws a ring only when a colour or width override is
  // given at all (`hasBorder`) — no border override means `borderWidth: 0` —
  // and a width override with no colour falls back to the indicator's own
  // fill token. The current and upcoming circles are outlined by design:
  // the current one's ring takes the per-instance `indicatorBorderColor`,
  // else `indicatorCurrentBorderColor`, else `primary`; the upcoming one's
  // `indicatorBorderColor`, else `indicatorInactiveBorderColor`, else
  // `outlineVariant` (a disabled stepper: `indicatorDisabledBorderColor`,
  // else `disabledOutline`, for both).
  final hasIndicatorBorderOverride =
      merged.indicatorBorderColor != null ||
      merged.indicatorBorderWidth != null;
  final indicatorBorderWidth =
      merged.indicatorBorderWidth ??
      CoreStepperStyle.defaultIndicatorBorderWidth;
  final indicatorCompletedBorderWidth = hasIndicatorBorderOverride
      ? indicatorBorderWidth
      : 0.0;
  final indicatorCurrentBorderToken = enabled
      ? (merged.indicatorBorderColor ??
            merged.indicatorCurrentBorderColor ??
            CoreStepperStyle.defaultIndicatorCurrentBorderColor)
      : (merged.indicatorDisabledBorderColor ??
            CoreStepperStyle.defaultIndicatorDisabledBorderColor);
  final indicatorInactiveBorderToken = enabled
      ? (merged.indicatorBorderColor ??
            merged.indicatorInactiveBorderColor ??
            CoreStepperStyle.defaultIndicatorInactiveBorderColor)
      : (merged.indicatorDisabledBorderColor ??
            CoreStepperStyle.defaultIndicatorDisabledBorderColor);
  final indicatorBorderRadius =
      merged.indicatorBorderRadius ??
      CoreStepperStyle.defaultIndicatorBorderRadius;
  final indicatorCompletedContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: indicatorCompletedToken,
    borderColor: merged.indicatorBorderColor ?? indicatorCompletedToken,
    borderRadius: indicatorBorderRadius,
    borderWidth: indicatorCompletedBorderWidth,
    boxShadow: const [],
    width: indicatorSize,
    height: indicatorSize,
  );
  final indicatorCurrentContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: indicatorCurrentToken,
    borderColor: indicatorCurrentBorderToken,
    borderRadius: indicatorBorderRadius,
    borderWidth: indicatorBorderWidth,
    boxShadow: const [],
    width: indicatorSize,
    height: indicatorSize,
  );
  final indicatorInactiveContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: indicatorInactiveToken,
    borderColor: indicatorInactiveBorderToken,
    borderRadius: indicatorBorderRadius,
    borderWidth: indicatorBorderWidth,
    boxShadow: const [],
    width: indicatorSize,
    height: indicatorSize,
  );

  final labelTextScaler = MediaQuery.textScalerOf(context);
  final labelTextDirection = Directionality.of(context);
  final labelLocale = Localizations.maybeLocaleOf(context);
  final labelHeightBehavior =
      DefaultTextStyle.of(context).textHeightBehavior ??
      DefaultTextHeightBehavior.maybeOf(context);

  return ResolvedStepper(
    indicatorSize: indicatorSize,
    indicatorContentGapStyle: indicatorContentGapStyle,
    stepPadding: stepPadding,
    connectorMargin: connectorMargin,
    connectorMarginVertical: connectorMarginVertical,
    labelGapStyle: labelGapStyle,
    descriptionGapStyle: descriptionGapStyle,
    connectorMinExtent: connectorMinExtent,
    indicatorCompletedContainerStyle: indicatorCompletedContainerStyle,
    indicatorCurrentContainerStyle: indicatorCurrentContainerStyle,
    indicatorInactiveContainerStyle: indicatorInactiveContainerStyle,
    connectorActiveDividerStyle: connectorActiveDividerStyle,
    connectorInactiveDividerStyle: connectorInactiveDividerStyle,
    indicatorIconStyle: indicatorIconStyle,
    clickableStyle: clickableStyle,
    indicatorNumberActiveTextStyle: indicatorNumberActiveTextStyle,
    indicatorNumberInactiveTextStyle: indicatorNumberInactiveTextStyle,
    labelActiveTextStyle: labelActiveTextStyle,
    labelInactiveTextStyle: labelInactiveTextStyle,
    labelUpcomingTextStyle: labelUpcomingTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    labelTextScaler: labelTextScaler,
    labelTextDirection: labelTextDirection,
    labelLocale: labelLocale,
    labelHeightBehavior: labelHeightBehavior,
  );
}

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Steps`.
///
/// Widget tree (`Steps` picks the list, vertical or horizontal branch):
///
/// ```text
/// IntrinsicWidth | Row              // numbered: vertical | horizontal
///   └─ per step (status from CoreStepStatus.effective):
///        ├─ indicator OutlinedContainer (active/inactive/failedIndicatorContainerStyle)
///        │    └─ Center
///        │         ├─ Icon (checkIconStyle)         // done
///        │         ├─ Icon (failedIconStyle)        // failed
///        │         └─ Text (active/inactiveLabelColor) // current / todo
///        ├─ Gap (indicatorConnectorGapStyle)        // before connector
///        ├─ connector                                 // between steps
///        │    └─ Divider (active/inactiveConnectorStyle,
///        │                  vertical | horizontal)
///        ├─ Gap (indicatorConnectorGapStyle)        // after connector
///        ├─ Gap (indicatorContentGapStyle)          // indicator ↔ content
///        └─ content Column
///             ├─ Text title       (current/titleTextStyle, titleColor)
///             └─ Text description (descriptionColor)
///
/// Column (stretch)                  // list
///   └─ per step: StepItem (stepItemStyle ← raw-forwarded)
/// ```
///
/// Field grouping:
///
/// 1. **Geometry** — sizes / paddings, all with `theme.scaling`
///    pre-applied so the widget is render-only (Epic #1603 C11).
/// 2. **Paint-ready colours** — Flutter [Color]s the widget assigns
///    directly to `Container` fill / `Text` colour, resolved once via
///    `scheme.resolve(token).toValue()` (Epic #1603 C7).
/// 3. **Child-component slot styles** — [CoreIconStyle] /
///    [CoreDividerStyle] / [CoreGapStyle] forwarded to the unified
///    `Icon` / `Divider` / `Gap` widgets, which run their own
///    colour resolution (Epic #1603 C8).
class ResolvedSteps {
  /// Creates a [ResolvedSteps].
  const ResolvedSteps({
    required this.indicatorSize,
    required this.indicatorContentGapStyle,
    required this.indicatorConnectorGapStyle,
    required this.indicatorConnectorGapHorizontalStyle,
    required this.stepPadding,
    required this.stepPaddingHorizontal,
    required this.lastStepPaddingHorizontal,
    required this.connectorThickness,
    required this.activeIndicatorContainerStyle,
    required this.inactiveIndicatorContainerStyle,
    required this.failedIndicatorContainerStyle,
    required this.activeLabelColor,
    required this.inactiveLabelColor,
    required this.titleColor,
    required this.inactiveTitleColor,
    required this.descriptionColor,
    required this.checkIconStyle,
    required this.failedIconStyle,
    required this.activeConnectorStyle,
    required this.inactiveConnectorStyle,
    required this.labelTextStyle,
    required this.titleTextStyle,
    required this.currentTitleTextStyle,
    required this.descriptionTextStyle,
    required this.stepItemStyle,
  });

  // ── Geometry (scaling pre-applied) ──────────────────────────

  /// Diameter of the indicator circle (already scaled).
  final double indicatorSize;

  /// Padding below each step content in the vertical layout
  /// (paint-ready Flutter `EdgeInsets`, scaling pre-applied).
  final EdgeInsets stepPadding;

  /// Outer padding around each step content in the horizontal layout
  /// (already scaled). Carries the top + right insets; the widget
  /// zeroes the right inset on the last item.
  final EdgeInsetsGeometry stepPaddingHorizontal;

  /// The same padding for the final step, which has no next step to be
  /// separated from.
  ///
  /// Resolved here rather than reconstructed at the call site. The widget
  /// used to drop the trailing inset itself, which is a recomputation the
  /// render-only rule forbids — and it named a physical side, so it was
  /// also the one place that would have kept a right-to-left layout
  /// padded on the wrong edge.
  final EdgeInsetsGeometry lastStepPaddingHorizontal;

  /// Connector line thickness (already scaled).
  final double connectorThickness;

  // ── Child-component slot styles (forwarded) ─────────────────

  /// Nested [CoreGapStyle] slot forwarded to the `Gap` sibling
  /// rendered between the indicator column and the step content.
  final CoreGapStyle indicatorContentGapStyle;

  /// Nested [CoreGapStyle] slot forwarded to the two `Gap` siblings
  /// rendered above and below the connector line inside the indicator
  /// column.
  final CoreGapStyle indicatorConnectorGapStyle;

  /// Nested [CoreGapStyle] slot forwarded to the two `Gap` siblings
  /// rendered on either side of the connector line inside the indicator
  /// **row** of the horizontal layout — the vertical column reads
  /// [indicatorConnectorGapStyle].
  final CoreGapStyle indicatorConnectorGapHorizontalStyle;

  // ── Composed `OutlinedContainer` chrome (pre-EMIT, per state) ─

  /// Composed-`OutlinedContainer` chrome for a completed **or** current
  /// step's indicator circle (pre-EMIT `CoreOutlinedContainerStyle`) —
  /// fill = the per-instance `activeIndicatorColor` override else the
  /// named `defaultActiveIndicatorColor` token, `borderRadius:
  /// radius9999` (full circle), `width`/`height: indicatorSize`.
  /// `OutlinedContainer` runs the scheme-resolve / geometry / scaling
  /// bend itself — carrying Core values (not resolved Flutter ones)
  /// keeps that bend applied exactly once. `boxShadow: []` is forced
  /// because this indicator never painted a cast of its own.
  final CoreOutlinedContainerStyle activeIndicatorContainerStyle;

  /// Composed-`OutlinedContainer` chrome for an upcoming (pending)
  /// step's indicator circle — an outlined circle: fill = the per-instance
  /// `indicatorColor` override else the named `defaultIndicatorColor`
  /// token, ring = `indicatorBorderColor` / `indicatorBorderWidth`
  /// (scaling is applied by `OutlinedContainer`'s own bend, not here).
  /// Otherwise identical shape to [activeIndicatorContainerStyle].
  final CoreOutlinedContainerStyle inactiveIndicatorContainerStyle;

  /// Composed-`OutlinedContainer` chrome for a failed step's indicator
  /// circle — fill = the per-instance `failedIndicatorColor` override else
  /// the named `defaultFailedIndicatorColor` token. Otherwise identical
  /// shape to [activeIndicatorContainerStyle].
  final CoreOutlinedContainerStyle failedIndicatorContainerStyle;

  // ── Paint-ready colours (scheme.resolve(...).toValue()) ─────

  /// Label colour inside completed / current step indicators (on the
  /// active fill).
  final Color activeLabelColor;

  /// Label colour inside upcoming step indicators (on the inactive fill).
  final Color inactiveLabelColor;

  /// Content title colour of every step that has been reached and of a
  /// failed one.
  final Color titleColor;

  /// Content title colour of an upcoming step.
  final Color inactiveTitleColor;

  /// Content description colour.
  final Color descriptionColor;

  /// [CoreIconStyle] for the completed-step check icon — `size` carries
  /// the indicator diameter × `iconSizeRatio` (scaling pre-applied) and
  /// `color` forwards the resolved active label colour to `Icon`.
  final CoreIconStyle checkIconStyle;

  /// [CoreIconStyle] for the failed-step cross — the same size as
  /// [checkIconStyle], coloured with the failed label colour (on the failed
  /// fill).
  final CoreIconStyle failedIconStyle;

  /// [CoreDividerStyle] for the connector leading out of a completed step —
  /// forwarded straight to `Divider`.
  final CoreDividerStyle activeConnectorStyle;

  /// [CoreDividerStyle] for the connector leading out of a current,
  /// upcoming or failed step — forwarded straight to `Divider`.
  final CoreDividerStyle inactiveConnectorStyle;

  /// Indicator label [TextStyle] (typography only — colour applied by
  /// the widget per step via [activeLabelColor] / [inactiveLabelColor]).
  final TextStyle labelTextStyle;

  /// Content title [TextStyle] for every step except the current one
  /// (typography only — colour from [titleColor] / [inactiveTitleColor]).
  /// Semi-bold, from `CoreStepsStyle.defaultTitleStyle`.
  final TextStyle titleTextStyle;

  /// Content title [TextStyle] for the current step (typography only —
  /// colour from [titleColor]). The title default, the current-step overlay
  /// (`CoreStepsStyle.defaultCurrentTitleStyle` + per-instance
  /// `currentTitleStyle`), then the per-instance `titleStyle`.
  final TextStyle currentTitleTextStyle;

  /// Content description [TextStyle] (typography only — colour from
  /// [descriptionColor]).
  final TextStyle descriptionTextStyle;

  // ── Child-component slot style (list variant) ───────────────

  /// Nested [CoreStepItemStyle] forwarded raw to every `StepItem` the list
  /// variant stacks — `CoreStepsStyle.defaultStepItemStyle` under the
  /// merged override. The row resolver fills the rest and applies the
  /// status row and scaling itself.
  final CoreStepItemStyle stepItemStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSteps] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreStepsStyle.default*)
///   → theme.coreComponentTheme.steps.style
///   → theme.coreComponentTheme.steps.variantStyles[variant]
///   → widget.stepsStyle
/// ```
ResolvedSteps resolveSteps(
  BuildContext context, {
  required CoreStepsVariant variant,
  CoreStepsStyle? stepsStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final stepsTheme = theme.coreComponentTheme?.steps;

  // ─── Merge chain ──────────────────────────────────────
  // `variant` comes straight from the widget — the theme only answers how
  // each variant looks (render-only.md (c)).
  final merged = resolveStyleChain(const CoreStepsStyle(), [
    stepsTheme?.style,
    stepsTheme?.variantStyles?[variant],
    stepsStyle,
  ]);

  // ─── Stage 1 RESOLVE — geometry (override else design-system default) ─
  final indicatorSize =
      merged.indicatorSize ?? CoreStepsStyle.defaultIndicatorSize;
  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override and forward the resulting slot straight
  // to the `Gap` siblings rendered by the widget.
  final indicatorContentGapStyle = CoreStepsStyle
      .defaultIndicatorContentGapStyle
      .merge(merged.indicatorContentGapStyle);
  final indicatorConnectorGapStyle = CoreStepsStyle
      .defaultIndicatorConnectorGapStyle
      .merge(merged.indicatorConnectorGapStyle);
  final indicatorConnectorGapHorizontalStyle = CoreStepsStyle
      .defaultIndicatorConnectorGapHorizontalStyle
      .merge(merged.indicatorConnectorGapHorizontalStyle);
  final stepPadding = (merged.stepPadding ?? CoreStepsStyle.defaultStepPadding)
      .toValue(geometry: theme.geometry);
  final stepPaddingHorizontal =
      (merged.stepPaddingHorizontal ??
              CoreStepsStyle.defaultStepPaddingHorizontal)
          .toGeometry(geometry: theme.geometry);
  final stepPaddingHorizontalSource =
      merged.stepPaddingHorizontal ??
      CoreStepsStyle.defaultStepPaddingHorizontal;
  final lastStepPaddingHorizontal = CoreEdgeInsets.directional(
    start: stepPaddingHorizontalSource.start,
    top: stepPaddingHorizontalSource.top,
    bottom: stepPaddingHorizontalSource.bottom,
  ).toGeometry(geometry: theme.geometry);
  final connectorThickness =
      merged.connectorThickness ?? CoreStepsStyle.defaultConnectorThickness;
  final iconSizeRatio =
      merged.iconSizeRatio ?? CoreStepsStyle.defaultIconSizeRatio;
  final scaledIndicatorSize = scaling * indicatorSize; // scaled-shared
  final scaledConnectorThickness =
      scaling * connectorThickness; // scaled-shared
  final scaledStepPadding = stepPadding * scaling;
  final scaledStepPaddingHorizontal = stepPaddingHorizontal * scaling;
  final scaledLastStepPaddingHorizontal = lastStepPaddingHorizontal * scaling;
  final scaledCheckIconSize = scaledIndicatorSize * iconSizeRatio;

  // ─── Stage 1 RESOLVE — colour tokens (override else named default) ──
  // Every colour resolves through `merged.X ?? CoreStepsStyle.defaultX`
  // so the single Core source of truth feeds both platforms; the active
  // indicator / label / title / description carry their own named token
  // defaults instead of an inline `CoreColor.token(...)` literal.
  final activeIndicatorCoreValue =
      merged.activeIndicatorColor ?? CoreStepsStyle.defaultActiveIndicatorColor;
  final inactiveIndicatorCoreValue =
      merged.indicatorColor ?? CoreStepsStyle.defaultIndicatorColor;
  final failedIndicatorCoreValue =
      merged.failedIndicatorColor ?? CoreStepsStyle.defaultFailedIndicatorColor;
  // Connector — its own pair of values: the segment leaving a completed step
  // fills in with `activeConnectorColor`, every other one stays
  // `connectorColor`. The indicator's own fill is not reused.
  final connectorCoreValue =
      merged.connectorColor ?? CoreStepsStyle.defaultConnectorColor;
  final activeConnectorCoreValue =
      merged.activeConnectorColor ?? CoreStepsStyle.defaultActiveConnectorColor;
  // Ring of an upcoming indicator (the fill is the page's own).
  final indicatorBorderCoreValue =
      merged.indicatorBorderColor ?? CoreStepsStyle.defaultIndicatorBorderColor;
  final indicatorBorderWidth =
      merged.indicatorBorderWidth ?? CoreStepsStyle.defaultIndicatorBorderWidth;
  final activeLabelCoreValue =
      merged.activeLabelColor ?? CoreStepsStyle.defaultActiveLabelColor;
  final inactiveLabelCoreValue =
      merged.inactiveLabelColor ?? CoreStepsStyle.defaultInactiveLabelColor;
  final failedLabelCoreValue =
      merged.failedLabelColor ?? CoreStepsStyle.defaultFailedLabelColor;
  final titleCoreValue = merged.titleColor ?? CoreStepsStyle.defaultTitleColor;
  final inactiveTitleCoreValue =
      merged.inactiveTitleColor ?? CoreStepsStyle.defaultInactiveTitleColor;
  final descriptionCoreValue =
      merged.descriptionColor ?? CoreStepsStyle.defaultDescriptionColor;

  // ─── Stage 1 RESOLVE — typography (default.merge(override)) ─────────
  final labelCore = CoreStepsStyle.defaultLabelStyle.merge(merged.labelStyle);
  // The current step's title takes its overlay (bold by default) between
  // the title default and the per-instance `titleStyle`, so a weight
  // stated on `titleStyle` still reaches every step.
  final titleCore = CoreStepsStyle.defaultTitleStyle.merge(merged.titleStyle);
  final currentTitleOverlay = CoreStepsStyle.defaultCurrentTitleStyle.merge(
    merged.currentTitleStyle,
  );
  final currentTitleCore = CoreStepsStyle.defaultTitleStyle
      .merge(currentTitleOverlay)
      .merge(merged.titleStyle);
  final descriptionCore = CoreStepsStyle.defaultDescriptionStyle.merge(
    merged.descriptionStyle,
  );

  // ─── Stage 2 EMIT (Flutter) — colours via scheme.resolve(c).toValue() ─
  final activeLabelColor = scheme.resolve(activeLabelCoreValue).toValue();
  final inactiveLabelColor = scheme.resolve(inactiveLabelCoreValue).toValue();
  final titleColor = scheme.resolve(titleCoreValue).toValue();
  final inactiveTitleColor = scheme.resolve(inactiveTitleCoreValue).toValue();
  final descriptionColor = scheme.resolve(descriptionCoreValue).toValue();

  // ─── Stage 2 EMIT (Flutter) — typography via .toValue(theme:) ───────
  // Single primitive — `style.toValue(theme:)` materialises the token
  // role and resolves its colour through the active scheme. Per-step
  // colour is applied by the widget (`labelTextStyle.copyWith(color:)`),
  // so the role is emitted colour-free here.
  final labelTextStyle = labelCore.toValue(theme: theme);
  final titleTextStyle = titleCore.toValue(theme: theme);
  final currentTitleTextStyle = currentTitleCore.toValue(theme: theme);
  final descriptionTextStyle = descriptionCore.toValue(theme: theme);

  // ─── Stage 2 EMIT (Flutter) — child slot styles (Icon / Divider) ─
  // Check icon: diameter × ratio (scaling pre-applied to match the
  // scaled indicator) + the active label colour forwarded as `CoreColor`
  // so `Icon` runs the final resolution itself (Epic #1603 C8).
  final checkIconStyle = CoreIconStyle(
    size: scaledCheckIconSize,
    color: activeLabelCoreValue,
  );
  // Failed-step cross: the same glyph box as the check, in the failed
  // label colour (the ink paired with the failed fill).
  final failedIconStyle = CoreIconStyle(
    size: scaledCheckIconSize,
    color: failedLabelCoreValue,
  );
  // Connectors: forward the resolved `CoreColor` to `Divider` (thickness
  // scaling-applied to match `connectorThickness`). The segment leaving a
  // completed step wears `activeConnectorColor`; every other one wears
  // `connectorColor`.
  final activeConnectorStyle = CoreDividerStyle(
    color: activeConnectorCoreValue,
    thickness: scaledConnectorThickness,
  );
  final inactiveConnectorStyle = CoreDividerStyle(
    color: connectorCoreValue,
    thickness: scaledConnectorThickness,
  );

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──────
  // The indicator circle is the box `Card` / `Fieldset` compose, not a
  // hand-rolled decoration (Epic #4349) — passing Core values (not
  // resolved ones) keeps the scheme-resolve / geometry / scaling bend
  // applied exactly once, by `OutlinedContainer` itself.
  final indicatorBorderRadius =
      merged.indicatorBorderRadius ??
      CoreStepsStyle.defaultIndicatorBorderRadius;
  final activeIndicatorContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: activeIndicatorCoreValue,
    borderRadius: indicatorBorderRadius,
    borderWidth: 0,
    boxShadow: const [],
    width: scaledIndicatorSize,
    height: scaledIndicatorSize,
  );
  // An upcoming indicator is an outlined circle: the page's own fill plus a
  // ring. `borderWidth` is the unscaled token — `OutlinedContainer` bends
  // it itself, like every other composed box.
  final inactiveIndicatorContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: inactiveIndicatorCoreValue,
    borderColor: indicatorBorderCoreValue,
    borderRadius: indicatorBorderRadius,
    borderWidth: indicatorBorderWidth,
    boxShadow: const [],
    width: scaledIndicatorSize,
    height: scaledIndicatorSize,
  );
  final failedIndicatorContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: failedIndicatorCoreValue,
    borderRadius: indicatorBorderRadius,
    borderWidth: 0,
    boxShadow: const [],
    width: scaledIndicatorSize,
    height: scaledIndicatorSize,
  );

  // ─── List variant — the row slot, raw-forwarded ─────────────────────
  // `StepItem` resolves its own status row, geometry and scaling; this
  // resolver only lays the Steps partial under the caller's override
  // (style-contract.md "합성 = 재구현 금지" facet 3).
  final stepItemStyle = CoreStepsStyle.defaultStepItemStyle.merge(
    merged.stepItemStyle,
  );

  return ResolvedSteps(
    indicatorSize: scaledIndicatorSize,
    indicatorContentGapStyle: indicatorContentGapStyle,
    indicatorConnectorGapStyle: indicatorConnectorGapStyle,
    indicatorConnectorGapHorizontalStyle: indicatorConnectorGapHorizontalStyle,
    stepPadding: scaledStepPadding,
    stepPaddingHorizontal: scaledStepPaddingHorizontal,
    lastStepPaddingHorizontal: scaledLastStepPaddingHorizontal,
    connectorThickness: scaledConnectorThickness,
    activeIndicatorContainerStyle: activeIndicatorContainerStyle,
    inactiveIndicatorContainerStyle: inactiveIndicatorContainerStyle,
    failedIndicatorContainerStyle: failedIndicatorContainerStyle,
    activeLabelColor: activeLabelColor,
    inactiveLabelColor: inactiveLabelColor,
    titleColor: titleColor,
    inactiveTitleColor: inactiveTitleColor,
    descriptionColor: descriptionColor,
    checkIconStyle: checkIconStyle,
    failedIconStyle: failedIconStyle,
    activeConnectorStyle: activeConnectorStyle,
    inactiveConnectorStyle: inactiveConnectorStyle,
    labelTextStyle: labelTextStyle,
    titleTextStyle: titleTextStyle,
    currentTitleTextStyle: currentTitleTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    stepItemStyle: stepItemStyle,
  );
}

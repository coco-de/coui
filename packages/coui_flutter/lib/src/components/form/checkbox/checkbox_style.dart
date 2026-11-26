import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Checkbox`.
///
/// Widget tree (`checkbox.dart` decides which optional branches render):
///
/// ```text
/// TouchTarget > Semantics
///   └─ Clickable (onPressed / onHover / onPressedChange / onFocus, no ring)
///        └─ Row (mainAxisSize.min)
///             ├─ prefix                          // caller-supplied Widget, optional
///             ├─ Gap(gapStyle: indicatorLabelGapStyle)
///             ├─ FocusOutline (focused, focusOutlineStyle)   // ring hugs the BOX
///             │    └─ Stacks (clip none)
///             │         ├─ Position(-stateLayerSpread) halo   // hover / pressed wash
///             │         └─ OutlinedContainer (containerStyle[state])
///             │              └─ Center > Stacks
///             │                   ├─ check glyph   (Icon, scaled in/out)
///             │                   └─ dash glyph    (pill, scaled in/out)
///             ├─ Gap(gapStyle: indicatorLabelGapStyle)
///             ├─ Flexible > suffix | Column(label, Gap, description)
///             └─ trailing                        // caller-supplied Widget, optional
/// ```
///
/// Field grouping:
///
/// 1. **Composed `OutlinedContainer` chrome (pre-EMIT, per value)** — the
///    checkbox's checked / indeterminate / unchecked / disabled looks are
///    *widget* props, not Flutter `WidgetState`s, so the resolver builds
///    one [CoreOutlinedContainerStyle] bundle per look up front and the
///    widget selects among them. Carrying pre-EMIT Core values is what
///    keeps the scheme-resolve / geometry / scaling bend applied exactly
///    once — `OutlinedContainer` runs those steps itself.
/// 2. **State layer (hover / pressed halo)** — three paint-ready colours
///    the widget selects among by the `Clickable`'s DETECTION callbacks
///    (rest → hover → pressed), plus the halo's reach and corner.
/// 3. **Focus ring** — a [CoreFocusOutlineStyle] raw-forwarded to the
///    `FocusOutline` the widget wraps around the box (not the row).
/// 4. **Nested slot styles** — [checkmarkIconStyle] /
///    [disabledCheckmarkIconStyle] forwarded to the `Icon` glyph; gap slots
///    forwarded to `Gap`. Both children run their own resolve step, so the
///    slots stay in pre-scaling units: the glyph's size is a token size,
///    because the `Icon` scales its own box and its stroke rule reads the
///    size before that scaling.
/// 5. **Paint-ready dimensionals** — logical px with `theme.scaling`
///    pre-applied.
/// 6. **Typography** — paint-ready enabled / disabled [TextStyle]s.
class ResolvedCheckbox {
  /// Creates a [ResolvedCheckbox].
  const ResolvedCheckbox({
    required this.checkmarkIconStyle,
    required this.disabledCheckmarkIconStyle,
    required this.checkmarkColor,
    required this.disabledCheckmarkColor,
    required this.indeterminateLength,
    required this.markThickness,
    required this.indeterminateBorderRadius,
    required this.indicatorLabelGapStyle,
    required this.clickableStyle,
    required this.focusOutlineStyle,
    required this.transitionDuration,
    required this.activeContainerStyle,
    required this.uncheckedContainerStyle,
    required this.disabledContainerStyle,
    required this.stateLayerRestColor,
    required this.stateLayerHoverColor,
    required this.stateLayerPressedColor,
    required this.stateLayerSpread,
    required this.stateLayerBorderRadius,
    required this.enabledLabelTextStyle,
    required this.disabledLabelTextStyle,
    required this.enabledDescriptionTextStyle,
    required this.disabledDescriptionTextStyle,
    required this.labelDescriptionGapStyle,
    required this.minHeight,
  });

  // ── Nested slot styles (size + colour) ────────────────────────

  /// Resolved checkmark icon style while enabled (token size + default ink +
  /// per-instance override), forwarded raw to the check `Icon`. The size is a
  /// token size, not scaled: the `Icon` scales its own box, and its stroke
  /// rule reads the size before that scaling.
  final CoreIconStyle checkmarkIconStyle;

  /// [checkmarkIconStyle] with the disabled ramp's ink — the same glyph size,
  /// so enabling and disabling never moves the mark.
  final CoreIconStyle disabledCheckmarkIconStyle;

  // ── Paint-ready dimensionals (scaling pre-applied) ────────────

  /// Dash ink while enabled — the check takes the same ink through
  /// [checkmarkIconStyle].
  final Color checkmarkColor;

  /// Dash ink while disabled — the disabled ramp's own token, so a disabled
  /// indeterminate box still shows its mark. The check takes the same ink
  /// through [disabledCheckmarkIconStyle].
  final Color disabledCheckmarkColor;

  /// Indeterminate dash length (logical px, scaling pre-applied).
  final double indeterminateLength;

  /// Indeterminate dash thickness (logical px, scaling pre-applied) — one
  /// constant across sizes. The checkmark is an icon and follows the icon
  /// stroke rule, not this value.
  final double markThickness;

  /// Corner of the indeterminate dash — a pill, not the box's corner.
  /// Paint-ready Flutter [BorderRadius], resolved once here so the widget
  /// does no `.toValue(geometry:)` of its own (render-only).
  final BorderRadius indeterminateBorderRadius;

  /// Nested [CoreGapStyle] slot for the gap between the checkbox
  /// indicator and the label / prefix / suffix slot — forwarded straight
  /// to `Gap(gapStyle: …)`. `Gap` runs its own resolve step, so this
  /// slot is the merged design-system default + per-instance override in
  /// pre-scaling units (the receiving widget owns scaling).
  final CoreGapStyle indicatorLabelGapStyle;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// design default (`CoreCheckboxStyle.defaultClickableStyle`, which
  /// keeps the Clickable's generic disabled fade off because the
  /// checkbox paints its own disabled tokens) merged with the
  /// per-instance override, raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreFocusOutlineStyle] for the ring the widget draws around
  /// the box while focused — the checkbox's own `focusOutlineStyle` slot
  /// over a corner derived from the box's own, raw-forwarded to
  /// `FocusOutline` (which runs its own resolve / scaling step). The
  /// `Clickable` does not draw a ring of its own: the ring stands around
  /// the box, not the row.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// State-change transition duration (box colour fade, glyph slot
  /// scale / opacity, halo fade). Per-instance `transitionDuration`
  /// override, else `CoreCheckboxStyle.defaultTransitionDuration`, through
  /// the reduced-motion seat. Also carried inside each `*ContainerStyle`
  /// bundle so the composed box animates on the same clock as the glyph.
  final Duration transitionDuration;

  // ── Composed `OutlinedContainer` chrome (pre-EMIT, per value) ──

  /// Chrome for the checked / indeterminate box — fill = active token
  /// (border reuses the same token, so the stroke blends into the fill
  /// rather than reading as a second colour). `surfaceBlur: 0` is forced:
  /// a glyph rides on top of this fill, and a paled checked fill drops the
  /// glyph's contrast — a fill that cannot stay legible under material is
  /// not a standing surface declaration.
  final CoreOutlinedContainerStyle activeContainerStyle;

  /// Chrome for the resting (unchecked) box — the only look with no glyph
  /// riding on the fill, so `surfaceBlur` is left unset and a material
  /// preset can reach it.
  final CoreOutlinedContainerStyle uncheckedContainerStyle;

  /// Chrome for the disabled box — `surfaceBlur: 0` forced for the same
  /// contrast reason as [activeContainerStyle] (a glyph can still be
  /// riding on a disabled + checked box).
  final CoreOutlinedContainerStyle disabledContainerStyle;

  // ── State layer (hover / pressed halo) ────────────────────────

  /// Halo colour at rest — the ink at zero alpha, so the halo tweens in
  /// from its own colour rather than from black.
  final Color stateLayerRestColor;

  /// Halo colour while hovered — ink at the ramp's hover weight.
  final Color stateLayerHoverColor;

  /// Halo colour while pressed — ink at the ramp's pressed weight.
  final Color stateLayerPressedColor;

  /// How far the halo reaches beyond the box on each side (logical px,
  /// scaling pre-applied).
  final double stateLayerSpread;

  /// Halo corner — paint-ready [BorderRadius].
  final BorderRadius stateLayerBorderRadius;

  // ── Label typography (paint-ready TextStyle per state) ────────

  /// Paint-ready label [TextStyle] when enabled.
  final TextStyle enabledLabelTextStyle;

  /// Paint-ready label [TextStyle] when disabled.
  final TextStyle disabledLabelTextStyle;

  /// Paint-ready description [TextStyle] when enabled — the supporting
  /// line under the label, in the quieter `onSurfaceVariant` foreground.
  final TextStyle enabledDescriptionTextStyle;

  /// Paint-ready description [TextStyle] when disabled — folded to the
  /// same `disabledForegroundColor` the label takes, so a disabled row
  /// reads as one dimmed block.
  final TextStyle disabledDescriptionTextStyle;

  /// Nested [CoreGapStyle] slot for the vertical gap between the label
  /// and the description — forwarded straight to `Gap(gapStyle: …)`,
  /// which runs its own resolve / scaling step.
  final CoreGapStyle labelDescriptionGapStyle;

  /// Minimum height of the pressable row, already scaled.
  final double minHeight;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCheckbox] for the given [context].
///
/// Walks the nested-merge chain plus `CoreCheckboxStyle.defaultsBySize`
/// and the flat `default*` fallbacks in a single pass, then runs every
/// `CoreColor → Color` conversion through `scheme.resolve(x).toValue()`
/// so the widget reads paint-ready values:
///
/// ```text
/// design system default (flat defaults + defaultsBySize)
///   → theme.coreComponentTheme.checkbox.style
///   → widget.checkboxStyle
/// ```
ResolvedCheckbox resolveCheckbox(
  BuildContext context, {
  required CoreComponentSize size,
  CoreCheckboxStyle? checkboxStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final checkboxTheme = theme.coreComponentTheme?.checkbox;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCheckboxStyle(), [
    checkboxTheme?.style,
    checkboxStyle,
  ]);

  // ─── Size table ───────────────────────────────────────
  final ss = CoreCheckboxStyle.defaultsBySize[size]!;

  // ─── Nested slot: checkmark icon (size from the ladder, ink from the
  // default partial, per-instance override last) ─────────
  // The size stays a token size (no `* scaling`): the `Icon` the style is
  // forwarded to scales its own box, and its stroke rule reads the size before
  // that scaling.
  final checkmarkSize =
      merged.checkmarkSize ??
      merged.checkmarkIconStyle?.size ??
      ss.checkmarkSize!;
  final checkmarkIconStyle = CoreIconStyle(size: checkmarkSize)
      .merge(CoreCheckboxStyle.defaultCheckmarkIconStyle)
      .merge(merged.checkmarkIconStyle);
  final disabledCheckmarkIconStyle = checkmarkIconStyle.copyWith(
    color:
        merged.disabledCheckmarkColor ??
        CoreCheckboxStyle.defaultDisabledCheckmarkColor,
  );
  // The dash is a plain `Container`, so it takes the ink as a paint-ready
  // `Color`; the check takes the same ink through its icon style.
  final checkmarkColor = scheme.resolve(checkmarkIconStyle.color!).toValue();
  final disabledCheckmarkColor = scheme
      .resolve(disabledCheckmarkIconStyle.color!)
      .toValue();

  // ─── Label typography (paint-ready TextStyle per state) ─
  // The token-backed `defaultLabelStyle` role, the size table's `fontSize`
  // step, then the per-instance override — materialised in one step that
  // resolves the role + binds the per-state foreground colour. The enabled
  // colour is the label slot's own colour (override else the default
  // `onSurface`); the disabled colour is forced to
  // `disabledForegroundColor` unless the caller overrides the label colour.
  final disabledForegroundColor =
      merged.disabledForegroundColor ??
      CoreCheckboxStyle.defaultDisabledForegroundColor;
  final mergedLabelStyle = CoreCheckboxStyle.defaultLabelStyle
      .merge(ss.labelStyle)
      .merge(merged.labelStyle);
  final overrideLabelColor = merged.labelStyle?.color;
  final enabledLabelColor = scheme
      .resolve(overrideLabelColor ?? CoreCheckboxStyle.defaultLabelStyle.color!)
      .toValue();
  final disabledLabelColor = scheme
      .resolve(overrideLabelColor ?? disabledForegroundColor)
      .toValue();
  final enabledLabelTextStyle = mergedLabelStyle.toValue(
    color: enabledLabelColor,
    theme: theme,
  );
  final disabledLabelTextStyle = mergedLabelStyle.toValue(
    color: disabledLabelColor,
    theme: theme,
  );

  // Description — the same three-step chain as the label above, with the
  // quieter default foreground. Disabled folds both texts onto the one
  // `disabledForegroundColor` so the row dims as a block.
  final mergedDescriptionStyle = CoreCheckboxStyle.defaultDescriptionStyle
      .merge(ss.descriptionStyle)
      .merge(merged.descriptionStyle);
  final overrideDescriptionColor = merged.descriptionStyle?.color;
  final enabledDescriptionColor = scheme
      .resolve(
        overrideDescriptionColor ??
            CoreCheckboxStyle.defaultDescriptionStyle.color!,
      )
      .toValue();
  final disabledDescriptionColor = scheme
      .resolve(overrideDescriptionColor ?? disabledForegroundColor)
      .toValue();
  final enabledDescriptionTextStyle = mergedDescriptionStyle.toValue(
    color: enabledDescriptionColor,
    theme: theme,
  );
  final disabledDescriptionTextStyle = mergedDescriptionStyle.toValue(
    color: disabledDescriptionColor,
    theme: theme,
  );
  final labelDescriptionGapStyle = CoreCheckboxStyle
      .defaultLabelDescriptionGapStyle
      .merge(
        merged.labelDescriptionGapStyle,
      );

  // ─── Paint-ready dimensionals (scaling pre-applied) ───
  // Every synthesis (fallback + `* scaling`) lands in a local var so the
  // return literal stays a bare mapping (resolver-pattern.md "체이닝 위치").
  //
  // Pre-scaled: `OutlinedContainer` does not scale `width` / `height`
  // itself (it hands them straight through), so the composed box needs
  // the already-scaled size.
  final boxSize = (merged.boxSize ?? ss.boxSize!) * scaling;
  final indeterminateLength =
      (merged.indeterminateLength ?? ss.indeterminateLength!) * scaling;
  final markThickness =
      (merged.markThickness ?? CoreCheckboxStyle.defaultMarkThickness) *
      scaling;
  // Raw (pre-EMIT) — `OutlinedContainer` runs its own `theme.geometry
  // .stroke(...)` / `.toValue(geometry:)` steps, so scaling or converting
  // these here would bend them twice.
  final boxBorderWidth =
      merged.boxBorderWidth ?? CoreCheckboxStyle.defaultBoxBorderWidth;
  final boxBorderRadius =
      merged.boxBorderRadius ?? CoreCheckboxStyle.defaultBoxBorderRadius;
  // The dash is a pill regardless of the box's corner — a glyph, not a
  // surface, so it has its own paint-ready radius rather than the composed
  // box's raw one.
  final indeterminateBorderRadius =
      (merged.indeterminateBorderRadius ??
              CoreCheckboxStyle.defaultIndeterminateBorderRadius)
          .toValue(geometry: theme.geometry);
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreCheckboxStyle.defaultTransitionDuration,
  );
  // Nested `CoreGapStyle` slot — merge the size-bucket default with the
  // per-instance override and forward raw (pre-scaling) to `Gap`,
  // which runs its own resolve / scaling step. The size-bucket default
  // already carries a `size` for every `CoreComponentSize`; fall back to
  // the global default only if a custom design-system theme strips it.
  final indicatorLabelGapStyle =
      (ss.indicatorLabelGapStyle ??
              CoreCheckboxStyle.defaultIndicatorLabelGapStyle)
          .merge(merged.indicatorLabelGapStyle);
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreCheckboxStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  // The ring's corner derives from the box's so it stays concentric with a
  // rounder box; everything else (offset, width, both colours, opacity) is
  // the checkbox's own slot over its complete default.
  final focusOutlineStyle =
      CoreFocusOutlineStyle(
            borderRadius: boxBorderRadius,
          )
          .merge(CoreCheckboxStyle.defaultFocusOutlineStyle)
          .merge(
            merged.focusOutlineStyle,
          );

  // ─── State layer (hover / pressed halo) ──────────────
  // Three colours the widget selects among — the ink at the ramp's two
  // weights and at zero, so the `AnimatedContainer` tweens alpha only.
  final stateLayer = merged.stateLayer ?? CoreCheckboxStyle.defaultStateLayer;
  final stateLayerInk =
      merged.stateLayerColor ?? CoreCheckboxStyle.defaultStateLayerColor;
  final stateLayerRestColor = scheme
      .resolve(stateLayerInk.withOpacity(0))
      .toValue();
  final stateLayerHoverColor = scheme
      .resolve(stateLayerInk.scaleAlpha(stateLayer.hover))
      .toValue();
  final stateLayerPressedColor = scheme
      .resolve(stateLayerInk.scaleAlpha(stateLayer.pressed))
      .toValue();
  final stateLayerSpread =
      (merged.stateLayerSpread ?? CoreCheckboxStyle.defaultStateLayerSpread) *
      scaling;
  final stateLayerBorderRadius =
      (merged.stateLayerBorderRadius ??
              CoreCheckboxStyle.defaultStateLayerBorderRadius)
          .toValue(geometry: theme.geometry);

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per value ──
  // Passing Core values (not resolved ones) is what keeps the
  // scheme-resolve / geometry / scaling bend applied exactly once —
  // `OutlinedContainer` runs those steps itself. Every bundle shares
  // size/radius/width/duration so swapping between them animates through
  // the one `AnimatedContainer` `OutlinedContainer` owns rather than a
  // widget rebuild.
  //
  // The checked / indeterminate border reuses the active background
  // token so the stroke blends into the fill.
  final activeBackgroundToken =
      merged.boxActiveColor ?? CoreCheckboxStyle.defaultBoxActiveColor;
  final uncheckedBackgroundToken =
      merged.boxBackgroundColor ?? CoreCheckboxStyle.defaultBoxBackgroundColor;
  final uncheckedBorderToken =
      merged.boxBorderColor ?? CoreCheckboxStyle.defaultBoxBorderColor;
  final disabledBackgroundToken =
      merged.disabledBackgroundColor ??
      CoreCheckboxStyle.defaultDisabledBackgroundColor;
  final disabledBorderToken =
      merged.disabledBorderColor ??
      CoreCheckboxStyle.defaultDisabledBorderColor;
  final activeContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: activeBackgroundToken,
    borderColor: activeBackgroundToken,
    borderRadius: boxBorderRadius,
    borderWidth: boxBorderWidth,
    surfaceBlur: 0,
    width: boxSize,
    height: boxSize,
    duration: transitionDuration,
  );
  final uncheckedContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: uncheckedBackgroundToken,
    borderColor: uncheckedBorderToken,
    borderRadius: boxBorderRadius,
    borderWidth: boxBorderWidth,
    width: boxSize,
    height: boxSize,
    duration: transitionDuration,
  );
  final disabledContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: disabledBackgroundToken,
    borderColor: disabledBorderToken,
    borderRadius: boxBorderRadius,
    borderWidth: boxBorderWidth,
    surfaceBlur: 0,
    width: boxSize,
    height: boxSize,
    duration: transitionDuration,
  );

  final minHeight =
      (merged.minHeight ?? CoreCheckboxStyle.defaultMinHeight) * scaling;

  return ResolvedCheckbox(
    checkmarkIconStyle: checkmarkIconStyle,
    disabledCheckmarkIconStyle: disabledCheckmarkIconStyle,
    checkmarkColor: checkmarkColor,
    disabledCheckmarkColor: disabledCheckmarkColor,
    indeterminateLength: indeterminateLength,
    markThickness: markThickness,
    indeterminateBorderRadius: indeterminateBorderRadius,
    indicatorLabelGapStyle: indicatorLabelGapStyle,
    clickableStyle: clickableStyle,
    focusOutlineStyle: focusOutlineStyle,
    transitionDuration: transitionDuration,
    activeContainerStyle: activeContainerStyle,
    uncheckedContainerStyle: uncheckedContainerStyle,
    disabledContainerStyle: disabledContainerStyle,
    stateLayerRestColor: stateLayerRestColor,
    stateLayerHoverColor: stateLayerHoverColor,
    stateLayerPressedColor: stateLayerPressedColor,
    stateLayerSpread: stateLayerSpread,
    stateLayerBorderRadius: stateLayerBorderRadius,
    enabledLabelTextStyle: enabledLabelTextStyle,
    disabledLabelTextStyle: disabledLabelTextStyle,
    enabledDescriptionTextStyle: enabledDescriptionTextStyle,
    disabledDescriptionTextStyle: disabledDescriptionTextStyle,
    labelDescriptionGapStyle: labelDescriptionGapStyle,
    minHeight: minHeight,
  );
}

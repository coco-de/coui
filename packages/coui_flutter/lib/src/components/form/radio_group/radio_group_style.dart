import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedRadioGroup
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `RadioGroup` / `Radio`.
///
/// Widget tree (`radio_group.dart` renders the group container plus
/// one `_RadioState` per item):
///
/// ```text
/// FocusTraversalGroup
///   └─ Wrap | Column                    // orientation-driven, native spacing
///        └─ Radio (× N)
///             └─ Shortcuts > Actions > Clickable (hover / press / focus DETECTION) > Row
///                  ├─ prefix                    // caller-supplied, optional
///                  ├─ Gap(indicatorLabelGapStyle)   // rendered only when prefix != null
///                  ├─ FocusOutline (circle)
///                  │    └─ Stacks (clip: none)
///                  │         ├─ Position(-spread) > AnimatedContainer   // hover / pressed halo
///                  │         └─ OutlinedContainer (ringContainerStyle[state])
///                  │              └─ Center > AnimatedContainer   // inner dot (zero-size unless restated)
///                  ├─ Gap(indicatorLabelGapStyle)   // rendered only when suffix != null
///                  └─ Flexible > content
///
/// content = suffix
///         | Text(label, labelTextStyle[state])
///         | Column
///             ├─ Text(label, labelTextStyle[state])
///             ├─ Gap(labelDescriptionGapStyle)
///             └─ Text(description, descriptionTextStyle[state])
/// ```
///
/// The `card` variant wraps the same row in a tile, and moves the state
/// layer and the focus ring from the indicator onto it:
///
/// ```text
/// Clickable
///   └─ FocusOutline (rectangle, tileFocusOutlineStyle)
///        └─ OutlinedContainer (tileContainerStyle[state], clipped)
///             └─ Stacks
///                  ├─ Position.fill > AnimatedContainer   // state layer
///                  └─ AnimatedPadding(tilePadding[state]) > Row(…) // no halo / ring
/// ```
///
/// The ring is composed (Epic #4349) — `selectedRingContainerStyle` /
/// `unselectedRingContainerStyle` / `disabledSelectedRingContainerStyle` /
/// `disabledUnselectedRingContainerStyle` carry
/// pre-EMIT `CoreOutlinedContainerStyle` bundles (`borderRadius:
/// radius9999`, which a square box renders as a perfect circle on both
/// platforms — `OutlinedContainer` has no separate "circle shape"), and
/// `OutlinedContainer` runs the scheme-resolve / geometry / scaling bend
/// itself. The inner dot stays a plain decorative `AnimatedContainer`,
/// not composed — it is a selection glyph, not a surface (mirrors
/// `Checkbox`'s indeterminate dash), and its colour is independent of
/// the ring's fill either way (see [dotColor]'s doc).
///
/// Single struct the widget reads — every field has had the nested-merge
/// chain applied plus `defaultsBySize` / `defaultsByVariant` fallback and
/// Flutter type conversion. State-dependent indicator / label colours are
/// resolved here to paint-ready [Color]s (the variant token table is
/// keyed by `variant`, known at resolve time); the widget only branches
/// on the per-item `isSelected` / `isEnabled` runtime flags.
class ResolvedRadioGroup {
  /// Creates a [ResolvedRadioGroup].
  const ResolvedRadioGroup({
    required this.indicatorSize,
    required this.innerDotSize,
    required this.indicatorLabelGapStyle,
    required this.itemSpacing,
    required this.indicatorDotStyle,
    required this.labelTextStyle,
    required this.disabledLabelTextStyle,
    required this.descriptionTextStyle,
    required this.disabledDescriptionTextStyle,
    required this.labelDescriptionGapStyle,
    required this.dotTransitionDuration,
    required this.colorTransitionDuration,
    required this.selectedRingContainerStyle,
    required this.unselectedRingContainerStyle,
    required this.disabledSelectedRingContainerStyle,
    required this.disabledUnselectedRingContainerStyle,
    required this.dotColor,
    required this.disabledActiveColor,
    required this.stateLayerSpread,
    required this.restStateLayerColor,
    required this.hoverStateLayerColor,
    required this.pressedStateLayerColor,
    required this.tilePadding,
    required this.selectedTilePadding,
    required this.selectedTileContainerStyle,
    required this.unselectedTileContainerStyle,
    required this.disabledSelectedTileContainerStyle,
    required this.disabledUnselectedTileContainerStyle,
    required this.tileFocusOutlineStyle,
  });

  // ── Paint-ready dimensionals (scaling pre-applied) ─

  /// Indicator width = height (logical px, scaling pre-applied).
  final double indicatorSize;

  /// Inner dot size (logical px, scaling pre-applied) — applied when
  /// selected. Already folds the per-instance `indicatorDotStyle.size`
  /// override on top of the size-bucket default before scaling. `0` by
  /// default (the size rows state no dot — the selected ring carries the
  /// selection); a restated size draws the dot.
  final double innerDotSize;

  // ── Nested gap-style slots (CoreGapStyle, pre-scaling) ──
  //    + native-API spacing scalars (paint-ready post-scaling) ─────

  /// Nested [CoreGapStyle] slot for the gap between the radio indicator
  /// and the item label / prefix / suffix slot — forwarded straight to
  /// `Gap(gapStyle: …)`. `Gap` runs its own resolve step, so this
  /// slot is the merged design-system default + per-instance override in
  /// pre-scaling units (the receiving widget owns scaling).
  final CoreGapStyle indicatorLabelGapStyle;

  /// Inter-item spacing (logical px, scaling pre-applied) between sibling
  /// radio items. Flows directly into `Wrap.spacing` / `Wrap.runSpacing`
  /// (horizontal orientation) or `Column.spacing` (vertical orientation)
  /// — both are native paint-API arguments that consume raw doubles, so
  /// this slot stays scalar (`double`) rather than the nested
  /// [CoreGapStyle] shape used for Gap slots. The widget reads this
  /// value directly without re-multiplying by scaling.
  final double itemSpacing;

  // ── Nested slot styles (CoreXxxStyle) ──────────────

  /// Resolved inner-dot icon style (size + optional colour override) in
  /// pre-scaling units. Forwarded as `coui_core` type so the widget can
  /// re-emit it through a `Icon` widget that self-scales. The
  /// paint-ready post-scaling [innerDotSize] already incorporates the
  /// per-instance size override, so the widget does not re-read
  /// `indicatorDotStyle.size`.
  final CoreIconStyle indicatorDotStyle;

  /// Paint-ready label text style while enabled — the role from
  /// `CoreRadioGroupStyle.defaultLabelStyle`, this size's `fontSize`
  /// step from `defaultsBySize`, and the per-instance `labelStyle`
  /// overlay, materialised against the active theme.
  final TextStyle labelTextStyle;

  /// [labelTextStyle] with the variant's disabled foreground in place of
  /// whatever colour the enabled style resolved to.
  final TextStyle disabledLabelTextStyle;

  /// Paint-ready description text style while enabled — the foreground
  /// from `CoreRadioGroupStyle.defaultDescriptionStyle`, this size's role
  /// from the size layer, and the per-instance `descriptionStyle` overlay.
  final TextStyle descriptionTextStyle;

  /// [descriptionTextStyle] with the variant's disabled foreground — the
  /// same fold the label takes, so a disabled row dims as one block.
  final TextStyle disabledDescriptionTextStyle;

  /// Nested [CoreGapStyle] slot for the vertical gap between the label and
  /// the description — forwarded straight to `Gap(gapStyle: …)`, which
  /// self-scales, so it stays in pre-scaling units.
  final CoreGapStyle labelDescriptionGapStyle;

  // ── Durations ──────────────────────────────────────

  /// Inner-dot scale-transition duration.
  final Duration dotTransitionDuration;

  /// Ring colour + halo transition duration — the halo fades on the same
  /// clock the ring recolours on.
  final Duration colorTransitionDuration;

  // ── Composed `OutlinedContainer` chrome (pre-EMIT, per state) ──

  /// Chrome for the ring when selected — fill = `uncheckedBackground`
  /// (the ring's fill does not change on selection; only the border
  /// colour and width, and the inner dot when one is restated, do),
  /// border = active token at the selected width
  /// (`selectedIndicatorBorderWidth`, thicker than the resting ring).
  /// `surfaceBlur` left unset — the inner dot's colour is fixed
  /// (independent of the ring's fill either way, see [dotColor]'s doc),
  /// so there is no glyph-contrast risk in letting a material preset
  /// reach this ring, unlike `Checkbox`'s checked fill.
  final CoreOutlinedContainerStyle selectedRingContainerStyle;

  /// Chrome for the ring when unselected — same fill as
  /// [selectedRingContainerStyle], border = the unchecked border token at
  /// the resting width. `surfaceBlur` left unset for the same reason.
  final CoreOutlinedContainerStyle unselectedRingContainerStyle;

  /// Chrome for the ring when disabled and selected — the selection is the
  /// ring, so a disabled selected ring keeps the selected width
  /// (`selectedIndicatorBorderWidth`) and draws it in the variant's
  /// disabled-content colour, the one a disabled "on" state reads in. That
  /// is what tells it from [disabledUnselectedRingContainerStyle]: the two
  /// share a fill, and a disabled ring that kept the resting width in the
  /// outline colour would be the unselected ring. `surfaceBlur: 0` forced (a
  /// disabled control does not read as a floating material surface,
  /// matching `Checkbox`/`Toggle`).
  final CoreOutlinedContainerStyle disabledSelectedRingContainerStyle;

  /// Chrome for the ring when disabled and unselected — the resting width in
  /// the variant's disabled-outline colour. `surfaceBlur: 0` forced, like
  /// [disabledSelectedRingContainerStyle].
  final CoreOutlinedContainerStyle disabledUnselectedRingContainerStyle;

  /// Inner dot colour — slot-level `indicatorDotStyle.color` override
  /// else the resolved active token. Not composed (a selection glyph,
  /// not a surface — mirrors `Checkbox`'s indeterminate dash).
  final Color dotColor;

  /// Inner dot colour when disabled + selected (variant
  /// disabled-active token).
  final Color disabledActiveColor;

  // ── State layer (hover / pressed halo) ─────────────

  /// How far the halo reaches past the indicator on each side (logical
  /// px, scaling pre-applied). The halo is a circle of
  /// `indicatorSize + 2 × stateLayerSpread`, centred on the ring.
  final double stateLayerSpread;

  /// Halo colour at rest — the ink at alpha 0, so the fade-in animates
  /// from the same hue instead of from a transparent black.
  final Color restStateLayerColor;

  /// Halo colour while the row is hovered — the ink at the ramp's hover
  /// weight.
  final Color hoverStateLayerColor;

  /// Halo colour while the row is pressed — the ink at the ramp's
  /// pressed weight.
  final Color pressedStateLayerColor;

  // ── Card tile (variant `card`) ─────────────────────
  //
  // Resolved for every variant so the struct stays non-null; only the `card`
  // variant's widget path reads them. The tile's state layer reuses the three
  // halo colours above — the same ink at the same ramp, laid over the tile
  // instead of around the indicator.

  /// Inset between an unselected tile's border and its content (logical px,
  /// scaling pre-applied). Applied by an `AnimatedPadding` inside the tile
  /// rather than by the container, so the state layer under it covers the
  /// padding too.
  final EdgeInsetsGeometry tilePadding;

  /// [tilePadding] less the selected stroke's extra width — what keeps the
  /// content of a selected tile where an unselected tile's sits, since
  /// `OutlinedContainer`'s border takes part in layout. The difference is
  /// measured through the same `theme.geometry.stroke()` bend the container
  /// applies, so it holds under a style that bends strokes.
  final EdgeInsetsGeometry selectedTilePadding;

  /// Chrome for the selected tile — the selected face and border at the
  /// selected width, clipped to the corner so the state layer inside
  /// follows it. Pre-EMIT: `OutlinedContainer` runs the scheme-resolve /
  /// geometry / scaling bend itself, as it does for the ring.
  final CoreOutlinedContainerStyle selectedTileContainerStyle;

  /// Chrome for an unselected tile — the resting face and border at the
  /// resting width, same corner as [selectedTileContainerStyle].
  final CoreOutlinedContainerStyle unselectedTileContainerStyle;

  /// Chrome for a disabled selected tile — the selected face at the selected
  /// width, with the variant's disabled outline for its border.
  /// `surfaceBlur: 0` forced, like the disabled ring.
  final CoreOutlinedContainerStyle disabledSelectedTileContainerStyle;

  /// Chrome for a disabled unselected tile — the resting face at the resting
  /// width, with the variant's disabled outline for its border.
  /// `surfaceBlur: 0` forced, like the disabled ring.
  final CoreOutlinedContainerStyle disabledUnselectedTileContainerStyle;

  /// Focus-ring slot for the tile — the tile's own corner, raw, so
  /// `FocusOutline` bends and scales it once and the ring stays concentric
  /// with the tile.
  final CoreFocusOutlineStyle tileFocusOutlineStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedRadioGroup] for the given [context].
///
/// Walks the nested-merge chain plus `CoreRadioGroupStyle.defaultsBySize`
/// / `defaultsByVariant` fallback in a single pass:
///
/// ```text
/// design system default (defaultsBySize + defaultsByVariant)
///   → cardDefaultsBySize[size]            // variant `card` only
///   → theme.coreComponentTheme.radioGroup.style
///   → theme.coreComponentTheme.radioGroup.variantStyles[variant]
///   → widget.radioGroupStyle
/// ```
///
/// Colour resolution flows through `scheme.resolve(...).toValue()` (the
/// `CoreColorScheme` Flutter-side extension) so the widget reads
/// paint-ready [Color]s and never re-runs the merge / conversion chain.
ResolvedRadioGroup resolveRadioGroup(
  BuildContext context, {
  required CoreRadioGroupVariant variant,
  required CoreComponentSize size,
  CoreRadioGroupStyle? radioGroupStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final radioTheme = theme.coreComponentTheme?.radioGroup;

  // ─── Merge chain ──────────────────────────────────────
  // theme.style → theme.variantStyles[variant] → widget.radioGroupStyle.
  final merged = resolveStyleChain(const CoreRadioGroupStyle(), [
    radioTheme?.style,
    radioTheme?.variantStyles?[variant],
    radioGroupStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final vs = CoreRadioGroupStyle.defaultsByVariant[variant]!;
  // The size layer — the `card` variant's tile row laid over the size row
  // (`CoreRadioGroupStyle.sizeDefaultsFor` owns the order and replaces the
  // two text slots), so every `?? ss.X` below reads the tile's indicator,
  // gaps and text roles when the group is a card.
  final ss = CoreRadioGroupStyle.sizeDefaultsFor(variant, size);
  // The tile's own geometry, read straight off the card table so the tile
  // chrome below resolves for every variant (only `card` draws it).
  final tileRow = CoreRadioGroupStyle.cardDefaultsBySize[size]!;

  // ─── Dimensionals — radioGroupStyle wins, else size token default ──
  // Scaling pre-applied so the widget reads paint-ready values.
  final scaling = theme.scaling;
  // Pre-scaled: `OutlinedContainer` does not scale `width` / `height`
  // itself, so the composed ring needs the already-scaled size.
  final indicatorSize = (merged.indicatorSize ?? ss.indicatorSize!) * scaling;
  // Inner dot raw size — the per-instance `indicatorDotStyle.size`
  // override wins over the flat `innerDotSize` override, both win over
  // the size-bucket token. Scaling is applied at the return site so the
  // widget reads a paint-ready value.
  final innerDotSizeRaw =
      (merged.innerDotSize ??
          merged.indicatorDotStyle?.size ??
          ss.innerDotSize!) *
      scaling;
  // Raw (pre-EMIT) — `OutlinedContainer` runs its own `theme.geometry
  // .stroke(...)` step, so scaling this here would bend it twice.
  final indicatorBorderWidth =
      merged.indicatorBorderWidth ?? ss.indicatorBorderWidth!;
  // The selected ring is thicker than the resting one — the selection is
  // the ring, not a dot. Its own statement wins, else this size's row, else
  // (a size whose row states none) the resting width. Raw for the same
  // reason as above.
  final selectedIndicatorBorderWidth =
      merged.selectedIndicatorBorderWidth ??
      ss.selectedIndicatorBorderWidth ??
      indicatorBorderWidth;

  // ─── Nested gap-style slots (pre-scaling — Gap self-scales) ──
  // Merge the size-bucket default with the per-instance override and
  // forward raw (pre-scaling) to `Gap`, which runs its own resolve /
  // scaling step.
  final indicatorLabelGapStyle =
      (ss.indicatorLabelGapStyle ?? const CoreGapStyle()).merge(
        merged.indicatorLabelGapStyle,
      );

  // ─── Native-API spacing (paint-ready, scaling pre-applied) ─────
  // `itemSpacing` flows directly into `Wrap.spacing` / `Column.spacing`
  // — both consume raw doubles. Per-instance override wins, else the
  // size-bucket token. Scaling is applied in this local var so the
  // return literal stays a bare mapping and the widget reads a
  // paint-ready value (no widget-side `* scaling` Anti-C).
  final itemSpacing =
      theme.geometry.space(merged.itemSpacing ?? ss.itemSpacing!) * scaling;

  // ─── Nested slot styles ───────────────────────────────
  // Inner dot icon style: the design-system default slot merged with the
  // per-instance override. Stays in pre-scaling units — the widget
  // forwards it to a `Icon` that self-scales (Anti-A fix; the resolver
  // no longer applies `* scaling` to the slot directly).
  final indicatorDotStyle = CoreRadioGroupStyle.defaultIndicatorDotStyle.merge(
    merged.indicatorDotStyle,
  );

  // Label text — role + colour from the design-system default, this
  // size's `fontSize` step from the size row (the card's title role in its
  // place, for a card), then the per-instance overlay. Composite, so
  // `.merge` rather than `??` (a caller that overrides only the weight keeps
  // the role and the size step).
  final labelCore = CoreRadioGroupStyle.defaultLabelStyle
      .merge(ss.labelStyle)
      .merge(merged.labelStyle);
  final labelTextStyle = labelCore.toValue(theme: theme);
  // Disabled swaps only the foreground for the variant's disabled token —
  // the role, size and any weight override stay.
  final disabledLabelTextStyle = labelCore
      .copyWith(color: vs.disabledForegroundColor)
      .toValue(theme: theme);

  // Description — the same three-step chain with the quieter foreground:
  // the default's colour, this size's role, then the per-instance overlay.
  // Disabled takes the label's fold onto the variant's disabled foreground.
  final descriptionCore = CoreRadioGroupStyle.defaultDescriptionStyle
      .merge(ss.descriptionStyle)
      .merge(merged.descriptionStyle);
  final descriptionTextStyle = descriptionCore.toValue(theme: theme);
  final disabledDescriptionTextStyle = descriptionCore
      .copyWith(color: vs.disabledForegroundColor)
      .toValue(theme: theme);
  // The size layer states this gap only for the card; a plain row falls to
  // the design-system default beneath it.
  final labelDescriptionGapStyle = CoreRadioGroupStyle
      .defaultLabelDescriptionGapStyle
      .merge(ss.labelDescriptionGapStyle)
      .merge(merged.labelDescriptionGapStyle);

  // ─── Durations — caller override wins, else design-system default.
  final colorTransitionDuration = resolveMotionDuration(
    context,
    merged.colorTransitionDuration ??
        CoreRadioGroupStyle.defaultColorTransitionDuration,
  );
  final dotTransitionDuration = resolveMotionDuration(
    context,
    merged.dotTransitionDuration ??
        CoreRadioGroupStyle.defaultDotTransitionDuration,
  );

  // ─── Paint-ready colours ──────────────────────────────
  // Per-instance override wins per-channel, else the variant token; every
  // CoreColor → Color goes through `scheme.resolve(...).toValue()`.
  final activeColorToken = merged.indicatorActiveColor ?? vs.activeColor;
  final activeColor = scheme.resolve(activeColorToken).toValue();
  final disabledActiveColor = scheme.resolve(vs.disabledActiveColor).toValue();
  // Inner dot colour — slot-level override wins, else the active fill.
  final dotColor = indicatorDotStyle.color != null
      ? scheme.resolve(indicatorDotStyle.color!).toValue()
      : activeColor;

  // ─── State layer — the halo around the ring ───────────
  // The ink at each rung's weight, pre-baked as three colours the widget
  // SELECTS between (rest / hover / pressed are mutually exclusive under
  // strongest-wins, so this is O(3) — the shape `widget/render-only.md`
  // names for exclusive states). Rest keeps the hue at alpha 0 so the
  // `AnimatedContainer` fades between two colours of one hue rather than
  // through transparent black.
  final stateLayer = merged.stateLayer ?? CoreRadioGroupStyle.defaultStateLayer;
  final stateLayerInk = scheme
      .resolve(
        merged.stateLayerColor ?? CoreRadioGroupStyle.defaultStateLayerColor,
      )
      .toValue();
  final restStateLayerColor = stateLayerInk.withValues(alpha: 0);
  final hoverStateLayerColor = stateLayerInk.withValues(
    alpha: stateLayerInk.a * stateLayer.hover,
  );
  final pressedStateLayerColor = stateLayerInk.withValues(
    alpha: stateLayerInk.a * stateLayer.pressed,
  );
  final stateLayerSpread =
      (merged.stateLayerSpread ?? CoreRadioGroupStyle.defaultStateLayerSpread) *
      scaling;

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──
  // The face is the ring `Card` / `Checkbox` compose, not a hand-rolled
  // decoration: passing Core values (not resolved ones) is what keeps
  // the scheme-resolve / geometry / scaling bend applied exactly once —
  // `OutlinedContainer` runs those steps itself. `borderRadius:
  // radius9999` on a square box (width == height) renders as a perfect
  // circle (mirrors CSS `border-radius: 50%` on a square). Every bundle
  // shares size/radius/duration so swapping between them animates through
  // the one `AnimatedContainer` `OutlinedContainer` owns — the border
  // width included, which is how a selection grows the ring on the same
  // clock the colour changes on.
  //
  // Selected and unselected share the same fill (`uncheckedBackground`
  // token) — only the border colour and width (and the inner dot, when
  // restated) differ by state — and both leave `surfaceBlur` unset: the dot's
  // colour is fixed either way (see [ResolvedRadioGroup.dotColor]'s
  // doc), so there is no glyph-contrast risk in letting material reach
  // this ring. Disabled forces `surfaceBlur: 0`, matching
  // `Checkbox`/`Toggle`.
  final ringRadius =
      merged.indicatorBorderRadius ??
      CoreRadioGroupStyle.defaultIndicatorBorderRadius;
  final backgroundToken =
      merged.indicatorBackgroundColor ?? vs.uncheckedBackground;
  final selectedRingContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundToken,
    borderColor: activeColorToken,
    borderRadius: ringRadius,
    borderWidth: selectedIndicatorBorderWidth,
    width: indicatorSize,
    height: indicatorSize,
    duration: colorTransitionDuration,
  );
  final unselectedRingContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundToken,
    borderColor: merged.indicatorBorderColor ?? vs.borderColor,
    borderRadius: ringRadius,
    borderWidth: indicatorBorderWidth,
    width: indicatorSize,
    height: indicatorSize,
    duration: colorTransitionDuration,
  );
  // Disabled splits on selection, like the enabled pair: the selection is the
  // ring, so a disabled selected ring keeps the selected width and reads in
  // the disabled-content colour; only the unselected one rests on the
  // disabled outline at the resting width.
  final disabledSelectedRingContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: vs.disabledBackgroundColor,
    borderColor: vs.disabledActiveColor,
    borderRadius: ringRadius,
    borderWidth: selectedIndicatorBorderWidth,
    surfaceBlur: 0,
    width: indicatorSize,
    height: indicatorSize,
    duration: colorTransitionDuration,
  );
  final disabledUnselectedRingContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: vs.disabledBackgroundColor,
    borderColor: vs.disabledBorderColor,
    borderRadius: ringRadius,
    borderWidth: indicatorBorderWidth,
    surfaceBlur: 0,
    width: indicatorSize,
    height: indicatorSize,
    duration: colorTransitionDuration,
  );

  // ─── Card tile chrome — pre-EMIT, per state ──
  // Composed like the ring: Core values handed to `OutlinedContainer`, which
  // owns the scheme-resolve / geometry / scaling bend. The selected tile
  // wears a heavier stroke, and the border takes part in layout, so the
  // selected tile's padding gives the difference back — content and outer
  // box stay put when a tile is picked (see
  // `CoreRadioGroupStyle.defaultTileSelectedBorderWidth`). The clip keeps the
  // state layer inside the tile's corner — the layer is a child of the
  // container, and an unclipped child paints square corners over the
  // rounded face.
  final tileBorderRadius = merged.tileBorderRadius ?? tileRow.tileBorderRadius!;
  final tileBorderWidth =
      merged.tileBorderWidth ?? CoreRadioGroupStyle.defaultTileBorderWidth;
  final tileSelectedBorderWidthRaw =
      merged.tileSelectedBorderWidth ??
      CoreRadioGroupStyle.defaultTileSelectedBorderWidth;
  // Never under the resting width — a thinner selected stroke would have to
  // grow the padding, and the Web twin draws the extra as an inset layer
  // that cannot be negative.
  final tileSelectedBorderWidth = tileSelectedBorderWidthRaw < tileBorderWidth
      ? tileBorderWidth
      : tileSelectedBorderWidthRaw;
  // Pre-scaled: a plain `AnimatedPadding` inside the tile applies it, not
  // the container, so the state layer under it spans the padding as well.
  final tilePadding =
      (merged.tilePadding ?? tileRow.tilePadding!).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  // The compensation is stroke geometry, measured through the bend
  // `OutlinedContainer` puts the two widths through — a plain `* scaling`
  // would mispredict under a style that bends strokes non-linearly.
  final tileStrokeDelta =
      theme.geometry.stroke(tileSelectedBorderWidth, scaling: scaling) -
      theme.geometry.stroke(tileBorderWidth, scaling: scaling);
  final selectedPaddingOverride = merged.tileSelectedPadding;
  final selectedTilePadding = selectedPaddingOverride == null
      ? tilePadding
            .subtract(EdgeInsets.all(tileStrokeDelta))
            .clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity)
      : selectedPaddingOverride.toValue(geometry: theme.geometry) * scaling;
  final tileBackgroundColor =
      merged.tileBackgroundColor ??
      CoreRadioGroupStyle.defaultTileBackgroundColor;
  final tileSelectedBackgroundColor =
      merged.tileSelectedBackgroundColor ??
      CoreRadioGroupStyle.defaultTileSelectedBackgroundColor;
  final selectedTileContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: tileSelectedBackgroundColor,
    borderColor:
        merged.tileSelectedBorderColor ??
        CoreRadioGroupStyle.defaultTileSelectedBorderColor,
    borderRadius: tileBorderRadius,
    borderWidth: tileSelectedBorderWidth,
    duration: colorTransitionDuration,
    clipBehavior: CoreClipBehavior.antiAlias,
  );
  final unselectedTileContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: tileBackgroundColor,
    borderColor:
        merged.tileBorderColor ?? CoreRadioGroupStyle.defaultTileBorderColor,
    borderRadius: tileBorderRadius,
    borderWidth: tileBorderWidth,
    duration: colorTransitionDuration,
    clipBehavior: CoreClipBehavior.antiAlias,
  );
  // A disabled tile keeps its face and its width — the face still says
  // which tile is chosen — and takes the disabled outline for its edge; the
  // dimmed text says it cannot be changed.
  final disabledSelectedTileContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: tileSelectedBackgroundColor,
    borderColor: vs.disabledBorderColor,
    borderRadius: tileBorderRadius,
    borderWidth: tileSelectedBorderWidth,
    surfaceBlur: 0,
    duration: colorTransitionDuration,
    clipBehavior: CoreClipBehavior.antiAlias,
  );
  final disabledUnselectedTileContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: tileBackgroundColor,
    borderColor: vs.disabledBorderColor,
    borderRadius: tileBorderRadius,
    borderWidth: tileBorderWidth,
    surfaceBlur: 0,
    duration: colorTransitionDuration,
    clipBehavior: CoreClipBehavior.antiAlias,
  );
  // The ring around a focused tile follows the tile's corner — raw, so
  // `FocusOutline` bends and scales it exactly once.
  final tileFocusOutlineStyle = CoreFocusOutlineStyle(
    borderRadius: tileBorderRadius,
  );

  return ResolvedRadioGroup(
    indicatorSize: indicatorSize,
    innerDotSize: innerDotSizeRaw,
    indicatorLabelGapStyle: indicatorLabelGapStyle,
    itemSpacing: itemSpacing,
    indicatorDotStyle: indicatorDotStyle,
    labelTextStyle: labelTextStyle,
    disabledLabelTextStyle: disabledLabelTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    disabledDescriptionTextStyle: disabledDescriptionTextStyle,
    labelDescriptionGapStyle: labelDescriptionGapStyle,
    dotTransitionDuration: dotTransitionDuration,
    colorTransitionDuration: colorTransitionDuration,
    selectedRingContainerStyle: selectedRingContainerStyle,
    unselectedRingContainerStyle: unselectedRingContainerStyle,
    disabledSelectedRingContainerStyle: disabledSelectedRingContainerStyle,
    disabledUnselectedRingContainerStyle: disabledUnselectedRingContainerStyle,
    dotColor: dotColor,
    disabledActiveColor: disabledActiveColor,
    stateLayerSpread: stateLayerSpread,
    restStateLayerColor: restStateLayerColor,
    hoverStateLayerColor: hoverStateLayerColor,
    pressedStateLayerColor: pressedStateLayerColor,
    tilePadding: tilePadding,
    selectedTilePadding: selectedTilePadding,
    selectedTileContainerStyle: selectedTileContainerStyle,
    unselectedTileContainerStyle: unselectedTileContainerStyle,
    disabledSelectedTileContainerStyle: disabledSelectedTileContainerStyle,
    disabledUnselectedTileContainerStyle: disabledUnselectedTileContainerStyle,
    tileFocusOutlineStyle: tileFocusOutlineStyle,
  );
}

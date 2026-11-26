import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedToggle
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Toggle`.
///
/// Widget tree (`toggle.dart` is render-only — it reads these fields
/// directly without re-running any merge / token / colour resolution):
///
/// ```text
/// Clickable (focusOutline: false — the ring is the track's, below)
///   └─ Row (prefix? · Gap · FocusOutline(track) · Gap · label/suffix?)
///        └─ FocusOutline (focused, focusOutlineStyle)
///             └─ Stacks (clip none — the lens spills past the track)
///                  ├─ OutlinedContainer (trackContainerStyle[state])
///                  │    └─ Padding (trackInset)
///                  │         └─ Stacks > AnimatedPositioned > AspectRatio
///                  │              └─ Container (thumbColor, thumbBorderRadius)
///                  └─ Position (lensOriginX + travel, lensTop)  // in transit only
///                       └─ Opacity (lensEnvelope)
///                            └─ OutlinedContainer (lensContainerStyle,
///                                                  role: functional)
/// ```
///
/// The lens is a sibling of the track, not a child of it. Inside the track
/// it would sit in the track's surface, and a material that thins nested
/// glass would take its backdrop pass away — the one thing the lens is
/// there to show. At rest the lens is not in the tree at all, so the
/// resting switch paints exactly what it painted before the lens existed.
///
/// The track is composed — the eight `*TrackContainerStyle` bundles carry
/// pre-EMIT `CoreOutlinedContainerStyle`, and `OutlinedContainer` runs the
/// scheme-resolve / geometry / scaling bend itself. Eight, because the
/// track's states are mutually exclusive (rest / hover / pressed /
/// disabled, each for on and off), the shape `widget/render-only.md`
/// names for pre-baked selection — O(8), not the O(2ⁿ) that pushes
/// `button` to lazy closures. The widget SELECTS one; it never composes
/// chrome.
///
/// Hover and pressed are the rest fill with the track's own ink laid over
/// it at the ramp's weight (the state layer), composited here so the
/// blend happens once, against the scheme-resolved colours.
///
/// The thumb stays a plain decorative `Container`, not composed — it is
/// the affordance glyph riding on the track surface (mirrors `Checkbox`'s
/// indeterminate dash), and per the issue this
/// box exists to compose against, it must stay opaque regardless of
/// which material preset is active. Its colour therefore still resolves
/// through the plain `Color` fields below.
///
/// Every colour is already converted from [CoreColor] to Flutter
/// [Color] via `scheme.resolve(x).toValue()` (per-instance overrides win
/// over the variant token before conversion). Every dimensional has
/// `theme.scaling` pre-applied, and the radii are Flutter [BorderRadius].
class ResolvedToggle {
  /// Creates a [ResolvedToggle].
  const ResolvedToggle({
    required this.labelStyle,
    required this.labelColor,
    required this.disabledLabelColor,
    required this.thumbSize,
    required this.thumbOffset,
    required this.inactiveThumbOffset,
    required this.trackInset,
    required this.iconLabelGapStyle,
    required this.focusOutlineStyle,
    required this.clickableStyle,
    required this.thumbTransitionDuration,
    required this.thumbTransitionCurve,
    required this.thumbBorderRadius,
    required this.thumbShadow,
    required this.activeTrackContainerStyle,
    required this.inactiveTrackContainerStyle,
    required this.activeHoverTrackContainerStyle,
    required this.inactiveHoverTrackContainerStyle,
    required this.activePressedTrackContainerStyle,
    required this.inactivePressedTrackContainerStyle,
    required this.disabledActiveTrackContainerStyle,
    required this.disabledInactiveTrackContainerStyle,
    required this.thumbActiveColor,
    required this.thumbInactiveColor,
    required this.thumbDisabledColor,
    required this.thumbDisabledInactiveColor,
    required this.lensContainerStyle,
    required this.lensOriginX,
    required this.lensTop,
    required this.lensEnvelope,
  });

  // ── Nested slot style (typography overlay) ────

  /// Paint-ready label [TextStyle] (typography role for the size + per-
  /// instance metric overrides). Colour is applied by the widget via
  /// `copyWith(color: …)` per enabled / disabled state from
  /// [labelColor] / [disabledLabelColor] so the colour resolution
  /// stays single-source in the resolver.
  final TextStyle labelStyle;

  /// Resolved label foreground colour for the enabled state.
  final Color labelColor;

  /// Resolved label foreground colour for the disabled state.
  final Color disabledLabelColor;

  // ── Dimensionals (scaling pre-applied) ────────

  /// Thumb size (logical px, scaling pre-applied).
  final double thumbSize;

  /// Thumb travel offset when on (logical px, scaling pre-applied).
  final double thumbOffset;

  /// Thumb resting (off-state) X translation (logical px, scaling
  /// pre-applied).
  final double inactiveThumbOffset;

  /// The band between the track's edge and the thumb (paint-ready,
  /// scaling pre-applied), laid by the widget inside the composed track
  /// rather than handed to `OutlinedContainer` as its padding.
  ///
  /// The band is part of the switch, not spacing around it. The thumb
  /// fills the track's height inside it, and the thumb's travel
  /// ([thumbOffset]) and the lens's place ([lensOriginX], [lensTop]) are
  /// lengths derived from these same sides — none of which the density
  /// moves, because the track keeps its size under every density. The
  /// container's padding does take the density, so a band handed to it
  /// moved on its own and the thumb left the place its travel and its
  /// lens were computed for. Converted at the standard density, the band
  /// stays the length they were derived from.
  final EdgeInsetsGeometry trackInset;

  /// Nested [CoreGapStyle] slot for the gap between the toggle track
  /// and the prefix / suffix / label slots — forwarded straight to
  /// `Gap(gapStyle: …)`. `Gap` runs its own resolve step, so this
  /// slot is the merged design-system default + per-instance override
  /// in pre-scaling units (the receiving widget owns scaling).
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreFocusOutlineStyle] slot for the ring around the
  /// **track** — design default (`CoreToggleStyle.defaultFocusOutlineStyle`,
  /// a pill) merged with the per-instance override, raw-forwarded to
  /// `FocusOutline(focusOutlineStyle:)`, whose own resolver settles the
  /// offset band / ring width / colours.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// design default (`CoreToggleStyle.defaultClickableStyle`: generic
  /// disabled fade off, no press shrink) merged with the per-instance
  /// override, raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Thumb travel transition duration — reduced-motion already applied
  /// (`resolveMotionDuration`), so it is [Duration.zero] when the platform
  /// asks for no motion. The transient lens lives for exactly this long,
  /// which is how it inherits the transition tier's suppression.
  final Duration thumbTransitionDuration;

  /// Easing the thumb travels on — and the lens with it, so the two stay
  /// aligned frame by frame.
  final Curve thumbTransitionCurve;

  // ── Shape (paint-ready BorderRadius) ──────────

  /// Thumb border radius (scaling pre-applied). `null` keeps the thumb
  /// fully circular (`BoxShape.circle`).
  final BorderRadius? thumbBorderRadius;

  /// Theme-resolved, scaled cast on the moving thumb.
  final List<BoxShadow> thumbShadow;

  // ── Composed `OutlinedContainer` chrome (pre-EMIT, per state) ──

  /// Chrome for the track at rest when on — fill = active track token.
  /// `surfaceBlur` left unset: the track can receive material because
  /// the thumb (opaque, positioned independently) already carries the
  /// on/off distinction on an axis material cannot dim — see
  /// `core/theme-axis-composition.md`'s "상태 구분을 색만으로 하지
  /// 않는다".
  final CoreOutlinedContainerStyle activeTrackContainerStyle;

  /// Chrome for the track at rest when off — fill = inactive track token.
  final CoreOutlinedContainerStyle inactiveTrackContainerStyle;

  /// On track under a pointer — rest fill washed with the active ink at
  /// the ramp's `hover` weight.
  final CoreOutlinedContainerStyle activeHoverTrackContainerStyle;

  /// Off track under a pointer — rest fill washed with the inactive ink
  /// at the ramp's `hover` weight.
  final CoreOutlinedContainerStyle inactiveHoverTrackContainerStyle;

  /// On track held down — washed at the ramp's `pressed` weight.
  final CoreOutlinedContainerStyle activePressedTrackContainerStyle;

  /// Off track held down — washed at the ramp's `pressed` weight.
  final CoreOutlinedContainerStyle inactivePressedTrackContainerStyle;

  /// Chrome for the track when disabled and on — `surfaceBlur: 0` forced
  /// (a disabled control does not read as a floating material surface).
  final CoreOutlinedContainerStyle disabledActiveTrackContainerStyle;

  /// Chrome for the track when disabled and off — `surfaceBlur: 0`.
  final CoreOutlinedContainerStyle disabledInactiveTrackContainerStyle;

  // ── Thumb state colours (paint-ready Color — not composed) ───

  /// Thumb fill colour when on.
  final Color thumbActiveColor;

  /// Thumb fill colour when off.
  final Color thumbInactiveColor;

  /// Thumb fill colour when disabled and on.
  final Color thumbDisabledColor;

  /// Thumb fill colour when disabled and off — separate from
  /// [thumbDisabledColor] because the off thumb has to stand off the
  /// disabled off track, a different ground.
  final Color thumbDisabledInactiveColor;

  // ── Transient lens (only while the thumb travels) ───

  /// Chrome for the lens capsule — pre-EMIT, composed into an
  /// `OutlinedContainer` marked as a floating surface.
  ///
  /// `CoreToggleStyle.defaultLensContainerStyle` (a clear pill: no fill, no
  /// stroke, no cast) merged with the per-instance `lensContainerStyle`
  /// override and raw-forwarded — `OutlinedContainer` runs its own scheme /
  /// geometry / scaling bend. The resolver lays only the computed size over
  /// it (`width` / `height`, pre-scaled for the same reason the track's are),
  /// because the lens's size is the thumb grown by `lensOutset`.
  final CoreOutlinedContainerStyle lensContainerStyle;

  /// The lens's left edge, in the track's box, when the thumb sits at X
  /// offset 0 (logical px, scaling pre-applied). The widget adds the
  /// thumb's travel to it frame by frame.
  final double lensOriginX;

  /// The lens's top edge in the track's box (logical px, scaling
  /// pre-applied) — the thumb's own top, raised by the lens's upper reach.
  /// Negative whenever the lens spills past the track, which is the point.
  final double lensTop;

  /// The lens's opacity over one travel, keyed by the travel's progress
  /// (0 → 1): in over the first `lensFadeFraction` of it, held, out over the
  /// last. The Web twin writes the same stops into its envelope keyframes,
  /// so the two lenses appear and leave at the same moments.
  final Animatable<double> lensEnvelope;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedToggle] for the given [context].
///
/// Walks the nested-merge chain plus
/// `CoreToggleStyle.sizeDefaults` / `defaultsByVariant` fallback in
/// a single pass, then converts every value to a paint-ready Flutter
/// type:
///
/// ```text
/// design system default (sizeDefaults + defaultsByVariant)
///   → theme.coreComponentTheme.toggle.style
///   → theme.coreComponentTheme.toggle.variantStyles[variant]
///   → widget.toggleStyle
/// ```
ResolvedToggle resolveToggle(
  BuildContext context, {
  required CoreToggleVariant variant,
  required CoreComponentSize size,
  CoreToggleStyle? toggleStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final toggleTheme = theme.coreComponentTheme?.toggle;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreToggleStyle(), [
    toggleTheme?.style,
    toggleTheme?.variantStyles?[variant],
    toggleStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final vs = CoreToggleStyle.defaultsByVariant[variant]!;
  final ss = CoreToggleStyle.sizeDefaults(size);
  // A retiring size renders as before; a run with asserts on logs it once
  // (asserts stripped: nothing), so the caller hears before the step goes.
  noticeRetiringSize(
    component: 'Toggle',
    size: size,
    retiring: CoreToggleContract.retiringSizes,
  );

  // ─── Stage 1 RESOLVE — Core values ────────────────────
  final trackActiveColor = merged.trackActiveColor ?? vs.activeTrack;
  final trackInactiveColor = merged.trackInactiveColor ?? vs.inactiveTrack;
  final stateLayer = merged.stateLayer ?? CoreToggleStyle.defaultStateLayer;
  final stateLayerActiveColor =
      merged.stateLayerActiveColor ?? vs.activeStateLayer;
  final stateLayerInactiveColor =
      merged.stateLayerInactiveColor ?? vs.inactiveStateLayer;
  final trackBorderRadius = merged.trackBorderRadius ?? ss.trackBorderRadius!;
  final trackPadding = merged.padding ?? ss.padding!;
  // Size row's role first, then the per-instance override — both on top of
  // the design default that carries the colour. Same order Web composes.
  final labelCore = CoreToggleStyle.defaultLabelStyle
      .merge(ss.labelStyle)
      .merge(merged.labelStyle);
  final lensOutset = merged.lensOutset ?? CoreToggleStyle.defaultLensOutset;
  // Clamped: past half the travel the fade in and the fade out would
  // overlap (`maxLensFadeFraction` doc). The Web resolver clamps the same.
  final lensFadeFraction =
      (merged.lensFadeFraction ?? CoreToggleStyle.defaultLensFadeFraction)
          .clamp(0.0, CoreToggleStyle.maxLensFadeFraction);

  // ─── Stage 2 EMIT — thumb colours ─────────────────────
  // Per-instance override wins over the variant token, then CoreColor →
  // Color via `scheme.resolve(...).toValue()`. The thumb is not composed
  // (field doc), so it keeps its own resolved Color path rather than a
  // Core token in a containerStyle bundle.
  final thumbActiveColor = scheme
      .resolve(merged.thumbActiveColor ?? vs.activeThumb)
      .toValue();
  final thumbInactiveColor = scheme
      .resolve(merged.thumbInactiveColor ?? vs.inactiveThumb)
      .toValue();
  final thumbDisabledColor = scheme.resolve(vs.disabledThumb).toValue();
  final thumbDisabledInactiveColor = scheme
      .resolve(vs.disabledInactiveThumb)
      .toValue();
  // Enabled label colour — per-instance `labelStyle.color` override wins
  // over the design-system default, then resolves through the scheme.
  // The disabled state always uses the variant `disabledForegroundColor`
  // token (the override does not apply when disabled).
  final labelColor = scheme.resolve(labelCore.color!).toValue();
  final disabledLabelColor = scheme
      .resolve(vs.disabledForegroundColor)
      .toValue();

  // ─── Label typography (paint-ready TextStyle — the widget layers
  //     labelColor / disabledLabelColor per state via copyWith) ──
  final labelStyle = labelCore.toValue(theme: theme);

  // ─── Dimensionals (scaling in local, return bare) ──
  // Pre-scaled: `OutlinedContainer` does not scale `width` / `height`
  // itself, so the composed track needs the already-scaled size.
  final trackWidth = (merged.trackWidth ?? ss.trackWidth!) * scaling;
  final trackHeight = (merged.trackHeight ?? ss.trackHeight!) * scaling;
  final thumbSize = (merged.thumbSize ?? ss.thumbSize!) * scaling;
  final thumbOffset = (merged.thumbOffset ?? ss.thumbOffset!) * scaling;
  final inactiveThumbOffset =
      (merged.inactiveThumbOffset ??
          CoreToggleStyle.defaultInactiveThumbOffset) *
      scaling;
  // Nested `CoreGapStyle` slot — merge the per-size default with the
  // per-instance override and forward raw (pre-scaling) to `Gap`,
  // which runs its own resolve / scaling step.
  final iconLabelGapStyle =
      (ss.iconLabelGapStyle ?? CoreToggleStyle.defaultIconLabelGapStyle).merge(
        merged.iconLabelGapStyle,
      );
  // Nested slots — partial default merged with the override, raw-forwarded
  // (each child's own resolver fills the rest).
  final focusOutlineStyle = CoreToggleStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );
  final clickableStyle = CoreToggleStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Transient lens geometry (scaling in local) ───────
  // The thumb is centred vertically in the track and sits `padding.left +
  // travel` from its left; the lens is that box grown by its outset on
  // each side. Computed from the unscaled values and scaled once — the
  // same numbers the Web resolver emits as rem.
  final unscaledTrackHeight = merged.trackHeight ?? ss.trackHeight!;
  final unscaledThumbSize = merged.thumbSize ?? ss.thumbSize!;
  final lensWidth =
      (unscaledThumbSize + lensOutset.left + lensOutset.right) * scaling;
  final lensHeight =
      (unscaledThumbSize + lensOutset.top + lensOutset.bottom) * scaling;
  final lensOriginX = (trackPadding.left - lensOutset.left) * scaling;
  final lensTop =
      ((unscaledTrackHeight - unscaledThumbSize) / 2 - lensOutset.top) *
      scaling;
  // The band the thumb sits in — at the standard density, because the
  // lengths above (and the thumb's travel) are derived from the authored
  // sides, and the track around them keeps its size under every density
  // (field doc). Through the inset conversion all the same, so a
  // directional band still resolves against the ambient direction.
  final trackInset =
      trackPadding.toGeometry(
        geometry: theme.geometry.atDensity(.standard),
      ) *
      scaling;

  // ─── Motion (settled durations) ──────────────────────
  final colorTransitionDuration = resolveMotionDuration(
    context,
    merged.colorTransitionDuration ??
        CoreToggleStyle.defaultColorTransitionDuration,
  );
  final thumbTransitionDuration = resolveMotionDuration(
    context,
    merged.thumbTransitionDuration ??
        CoreToggleStyle.defaultThumbTransitionDuration,
  );
  // The alias the Web resolver names for the same transform transition.
  final thumbTransitionCurve = CoreEasing.move.toValue();

  // Thumb border radius is still resolved here — the thumb is not
  // composed (field doc), so it needs its own paint-ready value.
  // `null` keeps the thumb fully circular (`BoxShape.circle`).
  final thumbBorderRadiusRaw = merged.thumbBorderRadius?.toValue(
    geometry: theme.geometry,
  );
  final thumbBorderRadius = thumbBorderRadiusRaw == null
      ? null
      : thumbBorderRadiusRaw * scaling;

  final thumbShadow = (merged.thumbShadow ?? CoreToggleStyle.defaultThumbShadow)
      .toValue(
        base: scheme
            .resolve(
              merged.thumbShadowBaseColor ??
                  CoreToggleStyle.defaultThumbShadowBaseColor,
            )
            .toValue(),
        geometry: theme.geometry,
        scale: scaling,
      );

  // ─── State layer wash ─────────────────────────────────
  // The track's own ink over its rest fill at the ramp's weight — blended
  // against the scheme-resolved colours (Flutter EMIT is theme-bound, so
  // the composite has to be too), then bridged back to a raw `CoreColor`
  // so the composed `OutlinedContainer` paints it like any other fill.
  CoreColor washedFill(CoreColor base, CoreColor ink, double weight) {
    final baseColor = scheme.resolve(base).toValue();
    final inkColor = scheme.resolve(ink).toValue();
    final blended = Color.alphaBlend(
      inkColor.withValues(alpha: weight),
      baseColor,
    );
    return CoreColor(blended.toARGB32());
  }

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──
  // The face is the box `Card` / `Checkbox` compose, not a hand-rolled
  // decoration: passing Core values (not resolved ones) is what keeps
  // the scheme-resolve / geometry / scaling bend applied exactly once —
  // `OutlinedContainer` runs those steps itself. Every bundle shares
  // size/radius/duration so swapping between them animates through the
  // one `AnimatedContainer` `OutlinedContainer` owns rather than a widget
  // rebuild. `borderWidth: 0` — a toggle track never draws a stroke. No
  // padding: the band around the thumb is [trackInset], which the widget
  // lays inside the box — the container's padding would take the density.
  CoreOutlinedContainerStyle trackContainer(
    CoreColor fill, {
    double? surfaceBlur,
  }) => CoreOutlinedContainerStyle(
    backgroundColor: fill,
    borderRadius: trackBorderRadius,
    borderWidth: 0,
    padding: CoreEdgeInsets.zero,
    surfaceBlur: surfaceBlur,
    width: trackWidth,
    height: trackHeight,
    duration: colorTransitionDuration,
  );

  final activeTrackContainerStyle = trackContainer(trackActiveColor);
  final inactiveTrackContainerStyle = trackContainer(trackInactiveColor);
  final activeHoverTrackContainerStyle = trackContainer(
    washedFill(trackActiveColor, stateLayerActiveColor, stateLayer.hover),
  );
  final inactiveHoverTrackContainerStyle = trackContainer(
    washedFill(trackInactiveColor, stateLayerInactiveColor, stateLayer.hover),
  );
  final activePressedTrackContainerStyle = trackContainer(
    washedFill(trackActiveColor, stateLayerActiveColor, stateLayer.pressed),
  );
  final inactivePressedTrackContainerStyle = trackContainer(
    washedFill(
      trackInactiveColor,
      stateLayerInactiveColor,
      stateLayer.pressed,
    ),
  );
  final disabledActiveTrackContainerStyle = trackContainer(
    vs.disabledActiveTrack,
    surfaceBlur: 0,
  );
  final disabledInactiveTrackContainerStyle = trackContainer(
    vs.disabledInactiveTrack,
    surfaceBlur: 0,
  );

  // The lens chrome — the design default (a clear pill that casts nothing)
  // under the per-instance slot, raw-forwarded; only the computed size is
  // laid over it, pre-scaled for the same reason the track's is.
  final lensContainerStyle = CoreToggleStyle.defaultLensContainerStyle
      .merge(merged.lensContainerStyle)
      .copyWith(width: lensWidth, height: lensHeight);

  // The lens's opacity envelope — in, held, out. A zero-weight stage is
  // left out rather than handed to `TweenSequence` (which asserts every
  // weight is positive): at `0` the lens is fully shown for the whole
  // travel, and at `maxLensFadeFraction` it has no hold.
  final lensHold = 1 - 2 * lensFadeFraction;
  final lensEnvelope = TweenSequence<double>([
    if (lensFadeFraction > 0)
      TweenSequenceItem(
        tween: Tween(begin: CoreOpacity.opacity0, end: CoreOpacity.opacity100),
        weight: lensFadeFraction,
      ),
    if (lensHold > 0)
      TweenSequenceItem(
        tween: ConstantTween(CoreOpacity.opacity100),
        weight: lensHold,
      ),
    if (lensFadeFraction > 0)
      TweenSequenceItem(
        tween: Tween(begin: CoreOpacity.opacity100, end: CoreOpacity.opacity0),
        weight: lensFadeFraction,
      ),
  ]);

  return ResolvedToggle(
    labelStyle: labelStyle,
    labelColor: labelColor,
    disabledLabelColor: disabledLabelColor,
    thumbSize: thumbSize,
    thumbOffset: thumbOffset,
    inactiveThumbOffset: inactiveThumbOffset,
    trackInset: trackInset,
    iconLabelGapStyle: iconLabelGapStyle,
    focusOutlineStyle: focusOutlineStyle,
    clickableStyle: clickableStyle,
    thumbTransitionDuration: thumbTransitionDuration,
    thumbTransitionCurve: thumbTransitionCurve,
    thumbBorderRadius: thumbBorderRadius,
    thumbShadow: thumbShadow,
    activeTrackContainerStyle: activeTrackContainerStyle,
    inactiveTrackContainerStyle: inactiveTrackContainerStyle,
    activeHoverTrackContainerStyle: activeHoverTrackContainerStyle,
    inactiveHoverTrackContainerStyle: inactiveHoverTrackContainerStyle,
    activePressedTrackContainerStyle: activePressedTrackContainerStyle,
    inactivePressedTrackContainerStyle: inactivePressedTrackContainerStyle,
    disabledActiveTrackContainerStyle: disabledActiveTrackContainerStyle,
    disabledInactiveTrackContainerStyle: disabledInactiveTrackContainerStyle,
    thumbActiveColor: thumbActiveColor,
    thumbInactiveColor: thumbInactiveColor,
    thumbDisabledColor: thumbDisabledColor,
    thumbDisabledInactiveColor: thumbDisabledInactiveColor,
    lensContainerStyle: lensContainerStyle,
    lensOriginX: lensOriginX,
    lensTop: lensTop,
    lensEnvelope: lensEnvelope,
  );
}

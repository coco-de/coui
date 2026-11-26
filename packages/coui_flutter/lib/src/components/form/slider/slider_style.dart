library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Slider`.
///
/// Widget tree (`co_slider.dart` owns layout / geometry only):
///
/// ```text
/// DefaultTextStyle.merge (tickLabelTextStyle)
///   └─ LayoutBuilder
///        └─ optional Padding (containerPadding)
///             └─ [Row: leading · Gap · Expanded(track) · Gap · trailing]
///                  GestureDetector > MouseRegion > SizedBox (thumbSize)
///                  └─ Stacks
///                       ├─ track Container (trackColor, trackHeight, borderRadius)
///                       ├─ fill  Container (activeColor, trackHeight, borderRadius)
///                       └─ thumb Container (thumbColor, thumbBorderColor,
///                                           thumbSize, thumbBorderWidth, borderRadius)
/// ```
///
/// Every field is paint-ready: Flutter framework widgets receive their
/// native type (`Color`, `BorderRadius`, `double`, `TextStyle`). Scaling
/// is pre-applied to the dimensional fields (`trackHeight` / `thumbSize`
/// / `thumbBorderWidth` / `containerPadding`) so the widget never
/// multiplies by `theme.scaling` itself (Epic #1603 C11/C12 — scaling
/// resolved in one place).
///
/// The colour fields are resolved per the `enabled` runtime state passed
/// into [resolveSlider] (the disabled tokens swap in), mirroring the
/// Web resolver's `enabled`-keyed colour selection. Slider has no public
/// variant enum — there is no semantic identifier to carry here.
class ResolvedSlider {
  /// Creates a [ResolvedSlider].
  const ResolvedSlider({
    required this.trackColor,
    required this.activeColor,
    required this.thumbColor,
    required this.thumbBorderColor,
    required this.trackHeight,
    required this.thumbSize,
    required this.thumbBorderWidth,
    required this.borderRadius,
    required this.containerPadding,
    required this.tickLabelTextStyle,
    required this.thumbShadow,
    required this.slotGapStyle,
    required this.focusOutlineStyle,
  });

  /// Effective inactive-track fill colour (disabled token swapped in when
  /// the slider is disabled).
  final Color trackColor;

  /// Effective active (filled) track colour (disabled token swapped in
  /// when the slider is disabled).
  final Color activeColor;

  /// Effective thumb fill colour.
  final Color thumbColor;

  /// Effective thumb border stroke colour — the active colour doubles as
  /// the border when no dedicated override is set; disabled token swapped
  /// in when disabled.
  final Color thumbBorderColor;

  /// Effective track height (logical px, scaling pre-applied).
  final double trackHeight;

  /// Effective thumb size — width = height (logical px, scaling
  /// pre-applied).
  final double thumbSize;

  /// Effective thumb border stroke width (logical px, scaling
  /// pre-applied).
  final double thumbBorderWidth;

  /// Effective corner radius for the track / fill / thumb (full pill by
  /// default — a large radius renders the square thumb as a circle).
  final BorderRadius borderRadius;

  /// Effective container padding (paint-ready Flutter `EdgeInsets`,
  /// scaling pre-applied). Provides hit-area room above / below the
  /// track (symmetric vertical padding by default).
  final EdgeInsets containerPadding;

  /// Paint-ready tick-label [TextStyle] — typography role base composed
  /// with the per-instance `tickLabelStyle` slot override (font / weight /
  /// colour / line-height / letter-spacing / family). Forwarded to
  /// `DefaultTextStyle.merge` so any discrete tick labels inherit it.
  final TextStyle tickLabelTextStyle;

  /// Thumb drop shadow (scaling pre-applied, tinted with the palette's
  /// `shadow` colour).
  final List<BoxShadow> thumbShadow;

  /// Gap between the track and the leading / trailing slots, raw-forwarded
  /// to `Gap` (which resolves its own scaling).
  final CoreGapStyle slotGapStyle;

  /// Keyboard focus ring style forwarded to the composed `FocusOutline`,
  /// which draws the ring on both platforms. Raw-forwarded: `FocusOutline`'s
  /// own resolver resolves the tokens and applies scaling, so nothing is
  /// resolved here (reaching into its defaults would duplicate them).
  final CoreFocusOutlineStyle focusOutlineStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSlider] for the given [context].
///
/// Single entry point — reads [CoreSliderTheme] from
/// `Theme.of(context).coreComponentTheme` itself so callers never touch
/// `coreComponentTheme` directly.
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.slider.style
///   → widget.sliderStyle
/// ```
///
/// The [enabled] runtime state selects between the active and disabled
/// colour tokens (matches the Web resolver's `enabled`-keyed selection),
/// so the widget reads paint-ready `Color`s without re-running any
/// fallback or `scheme.resolve` itself.
ResolvedSlider resolveSlider(
  BuildContext context, {
  required bool enabled,
  CoreSliderStyle? sliderStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final sliderTheme = theme.coreComponentTheme?.slider;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreSliderStyle(), [
    sliderTheme?.style,
    sliderStyle,
  ]);

  // ─── Resolved chrome colours (enabled-keyed, paint-ready) ─
  // Per-instance override wins, else the design-system default token.
  // Disabled state swaps the colour source to the disabled tokens
  // (matches Web parity). Every `CoreColor → Color` conversion routes
  // through `scheme.resolve(...).toValue()` (the `CoreColorScheme`
  // Flutter-side extension) so token colours honour the active dark /
  // light scheme (Epic #1603 C7 / #1601 dark-mode regression class).
  final trackColor = scheme
      .resolve(
        enabled
            ? (merged.trackColor ?? CoreSliderStyle.defaultTrackColor)
            : (merged.disabledTrackColor ??
                  CoreSliderStyle.defaultDisabledTrackColor),
      )
      .toValue();
  final activeColor = scheme
      .resolve(
        enabled
            ? (merged.activeColor ?? CoreSliderStyle.defaultActiveColor)
            : (merged.disabledActiveColor ??
                  CoreSliderStyle.defaultDisabledActiveColor),
      )
      .toValue();
  // Thumb fill — the disabled thumb has its own fill (`disabledThumbColor`).
  final thumbColor = scheme
      .resolve(
        enabled
            ? (merged.thumbColor ?? CoreSliderStyle.defaultThumbColor)
            : (merged.disabledThumbColor ??
                  CoreSliderStyle.defaultDisabledThumbColor),
      )
      .toValue();
  // Thumb border — dedicated `thumbBorderColor` wins, else the active
  // colour doubles as the border (matches Web parity); when disabled the
  // thumb states its own border (`disabledThumbBorderColor`).
  final thumbBorderColor = scheme
      .resolve(
        enabled
            ? (merged.thumbBorderColor ??
                  merged.activeColor ??
                  CoreSliderStyle.defaultThumbBorderColor)
            : (merged.disabledThumbBorderColor ??
                  CoreSliderStyle.defaultDisabledThumbBorderColor),
      )
      .toValue();

  // ─── Resolved dimensional chrome (paint-ready; scaling applied in
  //     the return literal) ─
  final trackHeight =
      (merged.trackHeight ?? CoreSliderStyle.defaultTrackHeight) * scaling;
  final thumbSize =
      (merged.thumbSize ?? CoreSliderStyle.defaultThumbSize) * scaling;
  final thumbBorderWidth = theme.geometry.stroke(
    merged.thumbBorderWidth ?? CoreSliderStyle.defaultThumbBorderWidth,
    scaling: scaling,
  );
  final containerPadding =
      ((merged.containerPadding ?? CoreSliderStyle.defaultContainerPadding)
          .toValue(geometry: theme.geometry)) *
      scaling;

  // Pill / circle radius — slider corners are fully rounded by default
  // (`CoreSliderStyle.defaultBorderRadius`). A large radius renders the
  // square thumb as a circle and clamps the thin track to a pill, so a
  // single resolved value drives all three elements (matches Web's single
  // `pillRadius` applied to track / fill / thumb).
  final borderRadius =
      (merged.borderRadius ?? CoreSliderStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      );

  // ─── Paint-ready tick-label typography ────────────────
  // EMIT Stage 2 (Flutter) — single primitive
  // `default.merge(override).toValue(theme:)` materialises the size-aware
  // token role (`bodySmall`), overlays the per-instance `tickLabelStyle`
  // (font / weight / colour / line-height / letter-spacing / family) and
  // resolves any overlay colour through the active scheme. No `color:`
  // override is forced, so when the override carries no colour the
  // surrounding `DefaultTextStyle` cascade supplies it. `co_slider`
  // forwards this straight to `DefaultTextStyle.merge`.
  final tickLabelTextStyle = CoreSliderStyle.defaultTickLabelStyle
      .merge(merged.tickLabelStyle)
      .toValue(theme: theme);

  // ─── Keyboard focus ring (raw-forwarded nested slot) ──
  // Only the fields this component diverges on are stated; the rest stay
  // null so `FocusOutline`'s resolver supplies its own defaults.
  final focusOutlineStyle = CoreSliderStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );

  final thumbShadow = (merged.thumbShadow ?? CoreSliderStyle.defaultThumbShadow)
      .toValue(
        base: scheme
            .resolve(const CoreColor.token(CoreColors.shadow))
            .toValue(),
        geometry: theme.geometry,
        scale: scaling,
      );
  final slotGapStyle = CoreSliderStyle.defaultSlotGapStyle.merge(
    merged.slotGapStyle,
  );

  return ResolvedSlider(
    trackColor: trackColor,
    activeColor: activeColor,
    thumbColor: thumbColor,
    thumbBorderColor: thumbBorderColor,
    trackHeight: trackHeight,
    thumbSize: thumbSize,
    thumbBorderWidth: thumbBorderWidth,
    borderRadius: borderRadius,
    containerPadding: containerPadding,
    tickLabelTextStyle: tickLabelTextStyle,
    thumbShadow: thumbShadow,
    slotGapStyle: slotGapStyle,
    focusOutlineStyle: focusOutlineStyle,
  );
}

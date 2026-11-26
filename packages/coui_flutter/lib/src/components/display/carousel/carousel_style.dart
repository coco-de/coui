import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Carousel`.
///
/// Widget tree (`co_carousel` decides which optional branches render;
/// `variant` decides where the dots go):
///
/// ```text
/// [below only] Column
///   ├─ ClipRRect (borderRadius)                          // the viewport
///   │    └─ Stacks
///   │         ├─ ghost slide (invisible sizing anchor)
///   │         └─ Position.fill
///   │              └─ LayoutBuilder > Stacks
///   │                   ├─ transition layout (+ optional dragger)
///   │                   ├─ Position.fill                  // showNavigation
///   │                   │    └─ AnimatedOpacity (navFadeDuration, on hover)
///   │                   │         └─ Padding (navInset) > Row
///   │                   │              ├─ Button (navButtonStyle) > Icon  // prev
///   │                   │              ├─ Gap (navGapStyle)               // banner only
///   │                   │              └─ Button (navButtonStyle) > Icon  // next
///   │                   └─ Position (bottom: indicatorInset)  // overlay && showIndicators
///   │                        └─ Center > DotIndicator (dotIndicatorStyle)
///   ├─ Gap (indicatorBelowGapStyle)                      // below && showIndicators
///   └─ Center > DotIndicator (dotIndicatorStyle)         // below && showIndicators
/// ```
///
/// Field grouping (mirrors Web `ResolvedCarousel`):
///
/// 1. **Paint-ready chrome** — [borderRadius] (Flutter [BorderRadius]),
///    [navInset] / [indicatorInset] (paint-ready [EdgeInsets] with
///    scaling pre-applied so callers can override any axis).
/// 2. **Nested style slots** — [navButtonStyle] forwarded straight to
///    the prev / next `Button(buttonStyle: …)`; [dotIndicatorStyle]
///    forwarded straight to `DotIndicator(dotIndicatorStyle: …)`;
///    [indicatorBelowGapStyle] and [navGapStyle] forwarded straight to
///    `Gap(gapStyle: …)`.
///    All keep `coui_core` domain types so the receiving unified widget
///    runs its own colour / radius / scaling resolution once — the
///    carousel resolver never re-wraps a resolved `Color` back into a
///    `CoreColor` (Epic #1603 C7 / C8).
class ResolvedCarousel {
  /// Creates a [ResolvedCarousel].
  const ResolvedCarousel({
    required this.borderRadius,
    required this.navInset,
    required this.indicatorInset,
    required this.navFadeDuration,
    required this.navButtonStyle,
    required this.dotIndicatorSize,
    required this.dotIndicatorStyle,
    required this.indicatorBelowGapStyle,
    required this.navGapStyle,
    required this.slideGap,
  });

  /// Outer carousel viewport corner radius (paint-ready
  /// [BorderRadius]) — forwarded straight to the `ClipRRect`.
  final BorderRadius borderRadius;

  /// Prev / next navigation button inset from the viewport edge
  /// (paint-ready [EdgeInsets], scaling pre-applied) — `co_carousel`
  /// applies it as the nav row `Padding`.
  final EdgeInsets navInset;

  /// Indicator-row inset from the viewport edge (paint-ready
  /// [EdgeInsets], scaling pre-applied) — `co_carousel` applies the
  /// per-side values as the indicator `Position` (typically only the
  /// `bottom` side is non-zero).
  final EdgeInsets indicatorInset;

  /// Fade duration for the prev / next nav buttons revealing on
  /// carousel hover — `co_carousel` feeds it to the nav row
  /// `AnimatedOpacity`.
  final Duration navFadeDuration;

  /// Nested [CoreButtonStyle] slot for the prev / next nav `Button` —
  /// default carousel nav chrome
  /// ([CoreCarouselStyle.defaultPrevNextButtonStyle]) merged with the
  /// per-instance `prevNextButtonStyle` override, with the
  /// `controlOverlayColor` override layered onto the background. The
  /// widget forwards it straight to `Button(buttonStyle: …)` so the
  /// button runs its own colour resolution (background / foreground /
  /// chevron icon colour all flow through the button resolver).
  final CoreButtonStyle navButtonStyle;

  /// Nested [CoreDotIndicatorStyle] slot for the indicator-row
  /// `DotIndicator` — carries the merged dot size / gap /
  /// active+inactive colour. The widget forwards it straight to
  /// `DotIndicator(dotIndicatorStyle: …)`. Colour fields stay as
  /// `CoreColor` so the dot-indicator resolver resolves them once
  /// (no carousel-side `scheme.resolve` round-trip).
  final CoreDotIndicatorStyle dotIndicatorStyle;

  /// Which dot size the indicator row draws at — the carousel's own
  /// `size` axis, mapped. Semantic rather than a number, because
  /// `DotIndicator` owns the diameter each of its sizes means and a
  /// carousel restating one would be a second copy of that table.
  final CoreDotIndicatorSize dotIndicatorSize;

  /// Nested [CoreGapStyle] slot for the viewport → indicator-row spacer
  /// the `below` placement renders — design-system default
  /// ([CoreCarouselStyle.defaultIndicatorBelowGapStyle]) merged with the
  /// per-instance override. Raw-forwarded to `Gap(gapStyle: …)`, which
  /// scales it itself. Unused by the `overlay` placement.
  final CoreGapStyle indicatorBelowGapStyle;

  /// Nested [CoreGapStyle] slot for the space between the previous and the
  /// next button — design-system default
  /// ([CoreCarouselStyle.defaultNavGapStyle]) merged with the per-instance
  /// override. Raw-forwarded to `Gap(gapStyle: …)`, which scales it itself.
  /// Drawn only by the `banner` variant, which gathers the pair at the
  /// trailing end; the `slide` variant puts one button at each end.
  final CoreGapStyle navGapStyle;

  /// Space between adjacent slides along the axis (logical px, the theme
  /// density and scaling pre-applied) — the transition's own `gap`, bent
  /// here like every other gap. The sliding layout places the slides and
  /// advances the line by this one value, so the slides stay on their
  /// stops under any density.
  final double slideGap;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCarousel] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.carousel.style
///   → widget.carouselStyle
/// ```
///
/// [variant] decides where the dots sit, which decides whether their
/// focus ring needs an opaque gap band: over a slide (`slide`) it does,
/// below the strip on the page (`banner`) it does not.
///
/// [gap] is the transition's space between slides
/// (`CoreCarouselTransition.gap`) — a caller's statement that the theme
/// density moves like any other gap; it comes back as
/// [ResolvedCarousel.slideGap].
ResolvedCarousel resolveCarousel(
  BuildContext context, {
  CoreCarouselSize size = CoreCarouselSize.defaultSize,
  CoreCarouselVariant variant = CoreCarouselVariant.defaultVariant,
  double gap = 0,
  CoreCarouselStyle? carouselStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final carouselTheme = theme.coreComponentTheme?.carousel;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCarouselStyle(), [
    carouselTheme?.style,
    carouselStyle,
  ]);

  // ─── Paint-ready chrome ───────────────────────────────
  // Border radius — override else design-system default, materialised
  // to a Flutter `BorderRadius` so the widget forwards it straight to
  // `ClipRRect` (Epic #1603 C9 — no raw `double` radius field).
  final borderRadius =
      ((merged.borderRadius ?? CoreCarouselStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final navInset =
      ((merged.navInset ?? CoreCarouselStyle.defaultNavInset).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final indicatorInset =
      ((merged.indicatorInset ?? CoreCarouselStyle.defaultIndicatorInset)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final navFadeDuration = resolveMotionDuration(
    context,
    merged.navFadeDuration ?? CoreCarouselStyle.defaultNavFadeDuration,
  );

  // ─── Nested slot: prev / next nav button ──────────────
  // Compose the design-system default nav chrome with the per-instance
  // `prevNextButtonStyle` override, then let the `controlOverlayColor`
  // override win on the background (mirrors the Web resolver, where the
  // override is emitted inline over the default surface token). The
  // background / foreground tokens stay as `CoreColor` so `Button`
  // resolves them once — the chevron `Icon` inherits the button's
  // foreground via the button's icon theme (Epic #1603 C7 / C8).
  final navButtonStyle = CoreCarouselStyle.defaultPrevNextButtonStyle
      .merge(merged.prevNextButtonStyle)
      .copyWith(backgroundColor: merged.controlOverlayColor);

  // ─── Nested slot: indicator-row dot indicator ─────────
  // Forward the per-instance dot size / gap / active+inactive colour
  // straight through as `CoreColor` — `DotIndicator` runs the final
  // `scheme.resolve` itself. `null` colour fields defer to the
  // dot-indicator's own defaults.
  //
  // Dots that overlay the slide sit on whatever the slide shows, so
  // their ring states an opaque gap band (the per-instance override
  // merged on top); dots below the strip sit on the page and keep the
  // transparent default (`null` → the dot-indicator's own slot).
  final indicatorFocusOutlineStyle = variant == CoreCarouselVariant.slide
      ? CoreCarouselStyle.defaultOverlayIndicatorFocusOutlineStyle.merge(
          merged.overlayIndicatorFocusOutlineStyle,
        )
      : null;
  final dotIndicatorStyle = CoreDotIndicatorStyle(
    spacing: merged.indicatorSpacing,
    dotSize: merged.indicatorSize,
    activeColor:
        merged.indicatorActiveColor ??
        CoreCarouselStyle.defaultIndicatorActiveColor,
    inactiveColor:
        merged.indicatorInactiveColor ??
        CoreCarouselStyle.defaultIndicatorInactiveColor,
    focusOutlineStyle: indicatorFocusOutlineStyle,
  );

  // ─── Nested slot: viewport → indicator-row spacer (below) ──
  // Composite default merged with the override, then raw-forwarded —
  // `Gap` applies its own scaling, so no `* scaling` here.
  final indicatorBelowGapStyle = CoreCarouselStyle.defaultIndicatorBelowGapStyle
      .merge(merged.indicatorBelowGapStyle);

  // Prev ↔ next spacer (the `banner` placement) — composite default merged
  // with the override, raw-forwarded: `Gap` applies its own scaling.
  final navGapStyle = CoreCarouselStyle.defaultNavGapStyle.merge(
    merged.navGapStyle,
  );

  // The carousel's size axis, in the vocabulary the indicator owns — the
  // enum converts itself so Web reads the same answer.
  final dotIndicatorSize = size.toDotIndicatorSize();

  // Space between slides — the transition states it, the theme density
  // moves it (Web moves the same gap through the spacing variable both its
  // flex gap and its translate read), then the size factor applies.
  final slideGap = theme.geometry.space(gap) * scaling;

  return ResolvedCarousel(
    dotIndicatorSize: dotIndicatorSize,
    borderRadius: borderRadius,
    navInset: navInset,
    indicatorInset: indicatorInset,
    navFadeDuration: navFadeDuration,
    navButtonStyle: navButtonStyle,
    dotIndicatorStyle: dotIndicatorStyle,
    indicatorBelowGapStyle: indicatorBelowGapStyle,
    navGapStyle: navGapStyle,
    slideGap: slideGap,
  );
}

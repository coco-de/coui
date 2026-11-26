/// Per-instance style for `Carousel`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Carousel` should render.
///
/// `CoreCarouselStyle` carries chrome flat fields plus nested
/// indicator dot + prev/next button slot styles, and the one-off spacer
/// between the viewport and an indicator row placed `below` it.
///
/// **Semantic enums (`autoPlay` / `loop` / `transition`) live on the
/// widget, not on this style** (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default
///   → CoreCarouselTheme.style
///   → parent component slot override
///   → widget.carouselStyle
/// ```
@immutable
class CoreCarouselStyle implements CoreStyle<CoreCarouselStyle> {
  /// Creates a [CoreCarouselStyle].
  const CoreCarouselStyle({
    this.borderRadius,
    this.indicatorActiveColor,
    this.indicatorInactiveColor,
    this.indicatorSize,
    this.indicatorSpacing,
    this.indicatorInset,
    this.navInset,
    this.controlOverlayColor,
    this.navFadeDuration,
    this.indicatorBelowGapStyle,
    this.navGapStyle,
    this.prevNextButtonStyle,
    this.overlayIndicatorFocusOutlineStyle,
  });

  // ── Outer chrome (flat) ──────────────────────

  /// Outer carousel viewport corner radius. Falls back to
  /// [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  // ── Indicator chrome (flat) ──────────────────

  /// Active indicator dot fill colour.
  final CoreColor? indicatorActiveColor;

  /// Inactive indicator dot fill colour.
  final CoreColor? indicatorInactiveColor;

  /// Indicator dot diameter (logical px).
  ///
  /// No paired `default*`: this is a partial forward into the nested
  /// `CoreDotIndicatorStyle` (`dotSize`), so `null` lets `DotIndicator`'s
  /// own resolver supply its per-size default (`defaultsBySize[size]`). A
  /// default here would copy the
  /// child's default into the parent — what `style-contract.md` forbids
  /// ("자식 default 에 reach 하지 마라") — and the two would diverge the
  /// first time the child's moves.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Partial
  /// forward into the nested CoreDotIndicatorStyle (`dotSize:
  /// merged.indicatorSize`, raw on both platforms) so null lets
  /// DotIndicator's own resolver supply its per-size default. A default here
  /// copies the child's default into the parent — the `??
  /// CoreYStyle.defaultX` reach style-contract.md forbids — and the two
  /// diverge the first time the child's dot size moves.
  final double? indicatorSize;

  /// Native `Row.spacing` between indicator dots — forwarded to
  /// `CoreDotIndicatorStyle.spacing`, applied as inter-dot Flex spacing
  /// (not a `Gap` widget) in logical px.
  final double? indicatorSpacing;

  /// Inset of the indicator row from the viewport edge. Typically only the
  /// `bottom` side is non-zero (default
  /// `CoreEdgeInsets.only(bottom: CoreSpace.space16)`); each side applies
  /// on its own, so you can set any side (e.g. push the row up or pad it
  /// horizontally).
  final CoreEdgeInsets? indicatorInset;

  // ── Navigation chrome (flat) ─────────────────

  /// Inset of the previous / next buttons from the viewport edge —
  /// typically symmetric horizontal (default
  /// `CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16)`). It becomes
  /// the padding around the buttons, so you can pad any side.
  final CoreEdgeInsets? navInset;

  /// Surface (background) colour applied behind the prev / next nav
  /// controls. `null` → [defaultControlOverlayColor].
  final CoreColor? controlOverlayColor;

  /// Fade duration for the prev / next nav buttons revealing on
  /// carousel hover (hidden until the pointer is over the viewport).
  /// `null` → [defaultNavFadeDuration].
  final Duration? navFadeDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Spacer between the viewport and the indicator row when the widget's
  /// `variant` is `banner` — forwarded straight to
  /// `Gap(gapStyle: …)`. Unused by the `overlay` placement, whose row is
  /// anchored by [indicatorInset] instead. `null` →
  /// [defaultIndicatorBelowGapStyle].
  final CoreGapStyle? indicatorBelowGapStyle;

  /// Space between the previous and the next button when the widget's
  /// `variant` is `banner`, passed as is to `Gap(gapStyle: …)`. `null`
  /// uses [defaultNavGapStyle].
  ///
  /// The `banner` variant gathers the pair at the trailing end of the strip
  /// (the strip is too short to leave a button at each end), so the two sit
  /// side by side and this is the space between them. The `slide` variant
  /// puts one button at each end of the viewport, where there is nothing to
  /// space, so the slot is unused there.
  final CoreGapStyle? navGapStyle;

  /// Look of the previous / next buttons — colours, border, padding,
  /// shadow. Laid over [defaultPrevNextButtonStyle].
  final CoreButtonStyle? prevNextButtonStyle;

  /// Focus ring of the indicator dots when they overlay the slide (the
  /// `slide` variant), passed on as the indicator row's
  /// `CoreDotIndicatorStyle.focusOutlineStyle`. Laid over
  /// [defaultOverlayIndicatorFocusOutlineStyle].
  ///
  /// The `banner` variant lays the dots out below the strip, where the
  /// dot indicator's own focus-ring default applies, so this slot does
  /// not reach it.
  final CoreFocusOutlineStyle? overlayIndicatorFocusOutlineStyle;

  // ─── Design-system defaults (Phase 6f single source) ────────────

  /// Default outer carousel viewport corner — `radius16`.
  ///
  /// The docs chain ends on this step (`.radius16`) and the canvas binds
  /// the same token on the viewport clip, so the library page, the token
  /// chain, and the component corner agree.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default navigation button inner padding (logical px).
  ///
  /// Four, so the disc lands on 32 — the size the designer draws these
  /// controls at, and the size `Button`'s own `sm` row already is. At
  /// eight the disc was 40, a step larger than every other small control
  /// on the same surface.
  static const double defaultNavButtonPadding = CoreSpace.space4;

  /// Default native `Row.spacing` between indicator dots (logical px).
  static const double defaultIndicatorSpacing = CoreSpace.space8;

  /// Default indicator-row inset — bottom-only offset by 16 logical px,
  /// matching the daisyUI carousel indicator placement.
  static const CoreEdgeInsets defaultIndicatorInset = CoreEdgeInsets.only(
    bottom: CoreSpace.space16,
  );

  /// Default navigation button inset — symmetric horizontal 16 logical px,
  /// so the prev / next chevrons inset evenly from the viewport edges.
  static const CoreEdgeInsets defaultNavInset = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space16,
  );

  /// Default transition speed between slides.
  static const Duration defaultTransitionSpeed = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default autoplay interval.
  static const Duration defaultAutoplayInterval = Duration(
    milliseconds: CoreDuration.ms3000,
  );

  /// Default hover fade duration for the prev / next nav buttons.
  static const Duration defaultNavFadeDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default viewport → indicator-row spacer for the `below` placement —
  /// **zero**.
  ///
  /// `DotIndicator` carries its own eight of padding (its touch margin),
  /// and that padding is what separates the dots from the slide above
  /// them. A gap here as well stacked two of them and pushed the dots a
  /// full sixteen clear. Per-instance override flows through
  /// [indicatorBelowGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultIndicatorBelowGapStyle = CoreGapStyle(
    size: CoreSpace.space0,
  );

  /// Default size of the prev/next nav button hit area, in logical px.
  /// Equal to `2 * defaultNavButtonPadding + CoreSpace.space24` — 32 —
  /// so the chevron icon (24×24) clears the icon-shape padding on both
  /// sides.
  static const double defaultNavButtonSize =
      defaultNavButtonPadding * 2 + CoreSpace.space24;

  /// Default colour of the indicator-row active dot — `primary`.
  ///
  /// The carousel states its own tone rather than taking `DotIndicator`'s:
  /// a bare dot row says where you are and stays neutral, but the row of a
  /// carousel is the one place a slide is also the thing being walked
  /// through, and its position is worth the accent. The inactive dots sit
  /// one step down ([defaultIndicatorInactiveColor]) so the active one
  /// reads by tone alone — both are discs, nothing else tells them apart.
  static const CoreColor defaultIndicatorActiveColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default colour of the indicator-row inactive dots — `outline`.
  ///
  /// Darker than the `DotIndicator` default (`outlineVariant`): over a slide
  /// the lighter step all but disappears into the picture, and `outline` is
  /// the step that still reads as a dot on both a photograph and the page.
  static const CoreColor defaultIndicatorInactiveColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default surface (background) colour behind the prev/next nav
  /// controls — `surfaceRaised`, fully opaque.
  ///
  /// A raised face rather than a frosted one: the pair floats over a
  /// photograph or a tinted strip, and an alpha fill let whatever was
  /// underneath show through the glyph's own disc. Opaque is also what lets
  /// the cast ([defaultPrevNextButtonStyle]'s `boxShadow`) read as the
  /// shadow of a body and not as a smear. Named to mirror the
  /// [controlOverlayColor] override field so the Web resolver emits
  /// `merged.controlOverlayColor ?? defaultControlOverlayColor`.
  static const CoreColor defaultControlOverlayColor = CoreColor.token(
    CoreColors.surfaceRaised,
  );

  /// Default colour of the prev/next button's edge — `outlineVariant`.
  ///
  /// The fill is a raised surface and can sit on a surface of its own tone
  /// (a strip, a pale photograph), so the edge is what keeps the disc
  /// readable where the cast alone would not.
  static const CoreColor defaultNavButtonBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default width of that edge, drawn inside the disc (it takes from the
  /// button, it does not grow it).
  static const double defaultNavButtonBorderWidth = CoreStrokeWidth.stroke1;

  /// Default space between the previous and the next button in the `banner`
  /// variant — four.
  ///
  /// Named to mirror [navGapStyle]. The pair is two 32-px discs: at four
  /// they read as one cluster, where the eight an icon-label gap would take
  /// reads as two separate controls.
  static const CoreGapStyle defaultNavGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default semantic foreground for the prev/next nav button glyph.
  static const CoreColor defaultNavButtonForegroundColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default chrome for the prev/next nav button — square hit area sized
  /// to align with the indicator row, with zero padding so the inner
  /// chevron icon sits flush against the rounded edge. Background +
  /// foreground colours come from
  /// [defaultControlOverlayColor] / [defaultNavButtonForegroundColor].
  ///
  /// The disc is a raised face: an opaque fill, a hairline edge
  /// ([defaultNavButtonBorderColor] at [defaultNavButtonBorderWidth]) and the
  /// `sm` cast ([CoreShadow.sm], the nearest step to the 0 1 3 · 12% the
  /// designer draws it with). The cast is stated here, not by `Button`:
  /// a button casts nothing of its own, and this one floats over content.
  ///
  /// Named to mirror the [prevNextButtonStyle] override field so the
  /// Web resolver composes it as
  /// `defaultPrevNextButtonStyle.merge(merged.prevNextButtonStyle)`.
  ///
  /// The focus ring's gap band is on: the nav buttons float over the
  /// slides in every variant, so the colour next to the ring is whatever
  /// the slide shows and the ring needs the two-colour band
  /// (`CoreFocusRing.opaqueOffsetColor`).
  static const CoreButtonStyle defaultPrevNextButtonStyle = CoreButtonStyle(
    backgroundColor: defaultControlOverlayColor,
    foregroundColor: defaultNavButtonForegroundColor,
    borderColor: defaultNavButtonBorderColor,
    borderWidth: defaultNavButtonBorderWidth,
    boxShadow: CoreShadow.sm,
    height: defaultNavButtonSize,
    width: defaultNavButtonSize,
    padding: .zero,
    focusOutlineStyle: CoreFocusOutlineStyle(
      offsetColor: CoreFocusRing.opaqueOffsetColor,
    ),
  );

  /// Default for [overlayIndicatorFocusOutlineStyle] — the focus-ring slot
  /// the resolvers put into the indicator row's `CoreDotIndicatorStyle`
  /// when the dots overlay the slide (the slide variant). Turns the
  /// ring's gap band on, because the colour next to a dot is whatever the
  /// slide shows.
  ///
  /// The banner variant lays the dots out below the strip, on the page's
  /// own background, so it leaves the band transparent and does not use
  /// this value.
  static const CoreFocusOutlineStyle defaultOverlayIndicatorFocusOutlineStyle =
      CoreFocusOutlineStyle(offsetColor: CoreFocusRing.opaqueOffsetColor);

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot style is
  /// merged recursively.
  @override
  CoreCarouselStyle merge(CoreCarouselStyle? other) {
    if (other == null) return this;
    return CoreCarouselStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      indicatorActiveColor: other.indicatorActiveColor ?? indicatorActiveColor,
      indicatorInactiveColor:
          other.indicatorInactiveColor ?? indicatorInactiveColor,
      indicatorSize: other.indicatorSize ?? indicatorSize,
      indicatorSpacing: other.indicatorSpacing ?? indicatorSpacing,
      indicatorInset: other.indicatorInset ?? indicatorInset,
      navInset: other.navInset ?? navInset,
      controlOverlayColor: other.controlOverlayColor ?? controlOverlayColor,
      navFadeDuration: other.navFadeDuration ?? navFadeDuration,
      indicatorBelowGapStyle: _mergeGap(
        indicatorBelowGapStyle,
        other.indicatorBelowGapStyle,
      ),
      navGapStyle: _mergeGap(navGapStyle, other.navGapStyle),
      prevNextButtonStyle: _mergeButton(
        prevNextButtonStyle,
        other.prevNextButtonStyle,
      ),
      overlayIndicatorFocusOutlineStyle:
          overlayIndicatorFocusOutlineStyle?.merge(
            other.overlayIndicatorFocusOutlineStyle,
          ) ??
          other.overlayIndicatorFocusOutlineStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreCarouselStyle copyWith({
    CoreBorderRadius? borderRadius,
    CoreColor? indicatorActiveColor,
    CoreColor? indicatorInactiveColor,
    double? indicatorSize,
    double? indicatorSpacing,
    CoreEdgeInsets? indicatorInset,
    CoreEdgeInsets? navInset,
    CoreColor? controlOverlayColor,
    Duration? navFadeDuration,
    CoreGapStyle? indicatorBelowGapStyle,
    CoreGapStyle? navGapStyle,
    CoreButtonStyle? prevNextButtonStyle,
    CoreFocusOutlineStyle? overlayIndicatorFocusOutlineStyle,
  }) {
    return CoreCarouselStyle(
      borderRadius: borderRadius ?? this.borderRadius,
      indicatorActiveColor: indicatorActiveColor ?? this.indicatorActiveColor,
      indicatorInactiveColor:
          indicatorInactiveColor ?? this.indicatorInactiveColor,
      indicatorSize: indicatorSize ?? this.indicatorSize,
      indicatorSpacing: indicatorSpacing ?? this.indicatorSpacing,
      indicatorInset: indicatorInset ?? this.indicatorInset,
      navInset: navInset ?? this.navInset,
      controlOverlayColor: controlOverlayColor ?? this.controlOverlayColor,
      navFadeDuration: navFadeDuration ?? this.navFadeDuration,
      indicatorBelowGapStyle:
          indicatorBelowGapStyle ?? this.indicatorBelowGapStyle,
      navGapStyle: navGapStyle ?? this.navGapStyle,
      prevNextButtonStyle: prevNextButtonStyle ?? this.prevNextButtonStyle,
      overlayIndicatorFocusOutlineStyle:
          overlayIndicatorFocusOutlineStyle ??
          this.overlayIndicatorFocusOutlineStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCarouselStyle &&
          runtimeType == other.runtimeType &&
          borderRadius == other.borderRadius &&
          indicatorActiveColor == other.indicatorActiveColor &&
          indicatorInactiveColor == other.indicatorInactiveColor &&
          indicatorSize == other.indicatorSize &&
          indicatorSpacing == other.indicatorSpacing &&
          indicatorInset == other.indicatorInset &&
          navInset == other.navInset &&
          controlOverlayColor == other.controlOverlayColor &&
          navFadeDuration == other.navFadeDuration &&
          indicatorBelowGapStyle == other.indicatorBelowGapStyle &&
          navGapStyle == other.navGapStyle &&
          prevNextButtonStyle == other.prevNextButtonStyle &&
          overlayIndicatorFocusOutlineStyle ==
              other.overlayIndicatorFocusOutlineStyle;

  @override
  int get hashCode => Object.hash(
    borderRadius,
    indicatorActiveColor,
    indicatorInactiveColor,
    indicatorSize,
    indicatorSpacing,
    indicatorInset,
    navInset,
    controlOverlayColor,
    navFadeDuration,
    indicatorBelowGapStyle,
    navGapStyle,
    prevNextButtonStyle,
    overlayIndicatorFocusOutlineStyle,
  );

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

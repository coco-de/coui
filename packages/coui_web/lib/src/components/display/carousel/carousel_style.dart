import 'dart:math';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Percentage multiplier for viewport-relative CSS lengths.
const _kPercent = 100;

/// Largest CSS offset treated as "no rem term" when composing a translate.
///
/// Not a design token — a formatting epsilon so a zero gap emits a plain
/// percentage translate instead of `calc(<pct>% + 0.0rem)`.
const _kZeroEpsilon = 1e-9;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Carousel`.
///
/// DOM shape — `carousel.dart` picks the branch matching
/// `transition.mode`, and `variant` decides whether the root
/// IS the viewport (`overlay`) or a column holding it (`below`):
///
/// ```text
/// root (<div role="region" aria-label="Carousel">)   // overlay: = viewport chrome; below: flex column
///   ├─ [below only] viewport (<div>)                  // relative overflow-hidden, border-radius
///   │    ├─ sizingSlide (<div aria-hidden inert>)     // fading mode only — invisible in-flow height anchor
///   │    ├─ track (<div>)                             // sliding: translated flex line; fading: static stack
///   │    │    └─ slides[i] (<div>) * rendered slides  // sliding: flex slide; fading: absolute cross-faded slide
///   │    ├─ prevNavReveal (<div>)                     // rendered only when showNavigation && count > 1
///   │    │    └─ prevNavButton (Button classes slot)
///   │    └─ nextNavReveal (<div>)                     // rendered only when showNavigation && count > 1
///   │         ├─ [banner, horizontal] prevNavButton   // the pair shares this anchor …
///   │         ├─ [banner, horizontal] Gap (navGapStyle) // … four apart
///   │         └─ nextNavButton (Button classes slot)
///   ├─ indicatorRow (<div>)                           // overlay: absolute, showIndicators && count > 1
///   ├─ Gap (indicatorBelowGapStyle)                   // below: showIndicators && count > 1
///   └─ DotIndicator (dotIndicatorStyle)               // below: showIndicators && count > 1
/// ```
///
/// (In `overlay` the sizingSlide / track / nav buttons are direct children
/// of the root — the viewport chrome is applied to the root itself.)
///
/// Carries only:
/// * Cat 1 — [WebElementChrome] slots (paint-ready chrome), including the
///   per-slide [slides] list so each cross-faded slide gets its own resolved
///   opacity without the widget composing CSS.
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified widgets.
///   [navButtonStyle] is forwarded to the prev / next `Button(buttonStyle: …)`;
///   [dotIndicatorStyle] is forwarded to `DotIndicator(dotIndicatorStyle: …)`;
///   [indicatorBelowGapStyle] and [navGapStyle] are forwarded to
///   `Gap(gapStyle: …)`.
///
/// No scalar metadata (variant / count / autoPlay / etc.) is exposed —
/// behavioural identifiers stay on the widget prop.
class ResolvedCarousel implements WebResolvedChrome {
  /// Creates a [ResolvedCarousel].
  const ResolvedCarousel({
    required this.root,
    required this.viewport,
    required this.sizingSlide,
    required this.track,
    required this.slides,
    required this.prevNavReveal,
    required this.nextNavReveal,
    required this.prevNavButton,
    required this.nextNavButton,
    required this.indicatorRow,
    required this.navButtonStyle,
    required this.dotIndicatorStyle,
    required this.indicatorBelowGapStyle,
    required this.navGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>`. For the `overlay`
  /// placement this IS the viewport chrome ([viewport]); for `below` it is
  /// the `flex flex-col items-center w-full` column that stacks the
  /// viewport, the gap and the dots.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the viewport `<div>` — `relative
  /// overflow-hidden w-full group` className plus the resolved
  /// `border-radius` inline-CSS rem rule. Always non-null — `carousel.dart`
  /// renders it as a child of [root] only for the `below` placement; in
  /// `overlay` the same chrome is already on [root].
  final WebElementChrome viewport;

  /// Paint-ready chrome for the invisible in-flow slide that gives a
  /// cross-fading carousel its height (every real slide is absolutely
  /// positioned, so without an anchor the viewport would collapse).
  /// Mirrors the Flutter ghost slide.
  final WebElementChrome sizingSlide;

  /// Paint-ready chrome for the slide container `<div>` — in `sliding` mode
  /// a flex line carrying the per-frame `transform` / `transition` and the
  /// inter-slide `gap`; in `fading` mode a static full-size stack that the
  /// absolutely positioned slides anchor to.
  final WebElementChrome track;

  /// Paint-ready chrome per rendered slide, in render order. In `sliding`
  /// mode every entry carries the same extent along the carousel axis; in
  /// `fading` mode each entry additionally carries that slide's resolved
  /// opacity and absolute offset.
  final List<WebElementChrome> slides;

  /// Paint-ready chrome for the `<div>` that anchors the prev (leading-edge)
  /// nav button and reveals it on hover — absolute positioning on the
  /// carousel axis, the resolved leading `navInset` rem rule, and the
  /// `opacity-0` → `group-hover:opacity-100` reveal with its fade clock and
  /// curve. Always non-null — `carousel.dart` decides whether to render the
  /// prev button based on `showNavigation` / `count`.
  ///
  /// The fade lives on this wrapper, never on the `Button` it holds: every
  /// `Button` carries the shared `coui-control-shadow-press` marker, whose
  /// `!important` `transition` shorthand is the control's only transition
  /// declaration and names no `opacity`. A `transition-opacity` utility or an
  /// inline `transition-duration` on the `Button` is overridden by it, so the
  /// buttons would snap on. The Flutter twin layers it the same way —
  /// `AnimatedOpacity` around the `Button`.
  final WebElementChrome prevNavReveal;

  /// Paint-ready chrome for the `<div>` that anchors the next (trailing-edge)
  /// nav button — mirror of [prevNavReveal] with the inset emitted from the
  /// trailing `navInset` side. Always non-null — `carousel.dart` decides
  /// whether to render based on `showNavigation` / `count`.
  final WebElementChrome nextNavReveal;

  /// Paint-ready chrome for the `Button` `classes` / `css` slots of the prev
  /// nav button — the subtle surface shadow className and the default surface
  /// colour token class, plus the `controlOverlayColor` override inline.
  /// Position and reveal are on [prevNavReveal], not here. Always non-null.
  final WebElementChrome prevNavButton;

  /// Paint-ready chrome for the `Button` `classes` / `css` slots of the next
  /// nav button — identical to [prevNavButton] (the sides differ only in the
  /// anchor, [nextNavReveal]). Always non-null.
  final WebElementChrome nextNavButton;

  /// Paint-ready chrome for the indicator-row `<div>` — absolute + centred
  /// flex row className plus the resolved `indicatorInset` offset
  /// inline-CSS rem rules. Always non-null — `carousel.dart` decides
  /// whether to render based on `showIndicators` / `count`.
  final WebElementChrome indicatorRow;

  /// Nested [CoreButtonStyle] slot for the prev / next nav `Button` —
  /// default carousel nav chrome
  /// ([CoreCarouselStyle.defaultPrevNextButtonStyle]) merged with the
  /// per-instance `prevNextButtonStyle` override (when set). The widget
  /// forwards it straight to `Button(buttonStyle: …)`.
  final CoreButtonStyle navButtonStyle;

  /// Nested [CoreDotIndicatorStyle] slot for the indicator-row
  /// `DotIndicator` — carries the merged dot size / gap /
  /// active+inactive colour. The widget forwards it straight to
  /// `DotIndicator(dotIndicatorStyle: …)`.
  final CoreDotIndicatorStyle dotIndicatorStyle;

  /// Nested [CoreGapStyle] slot for the viewport → indicator-row spacer
  /// the `below` placement renders — design-system default merged with
  /// the per-instance override. The widget forwards it straight to
  /// `Gap(gapStyle: …)`. Unused by the `overlay` placement.
  final CoreGapStyle indicatorBelowGapStyle;

  /// Nested [CoreGapStyle] slot for the space between the prev and the next
  /// button — design-system default
  /// ([CoreCarouselStyle.defaultNavGapStyle]) merged with the per-instance
  /// override. The widget forwards it straight to `Gap(gapStyle: …)`. Used
  /// only by the `banner` placement on a horizontal carousel, which gathers
  /// the pair at the trailing end inside the [nextNavReveal] anchor; every
  /// other arrangement anchors one button at each end and has nothing to
  /// space.
  final CoreGapStyle navGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCarousel] for the given [context].
///
/// Walks the merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.carousel.style
///   → widget.carouselStyle
/// ```
///
/// The remaining arguments are the carousel's layout policy plus its
/// per-frame runtime state — the resolver turns them into the paint-ready
/// transform / extent / opacity CSS so the widget never composes a rule:
///
/// * [variant] — whether the root is the viewport itself or a
///   column that stacks the viewport over the dots. It also decides
///   whether the dots' focus ring needs an opaque gap band: over a slide
///   (`slide`) it does, below the strip on the page (`banner`) it does
///   not.
/// * [alignment] / [sizeConstraint] — where the active slide sits and how
///   far it extends along the axis.
/// * [direction] — carousel axis (`translateX` + `min-width` vs
///   `translateY` + `min-height`).
/// * [mode] / [gap] — transition motion and inter-slide spacing.
/// * [curve] / [speed] / [animate] — transition easing, duration, and
///   whether the current frame animates at all (a drag frame and the
///   wrap-around jump both suppress it).
/// * [progress] — continuous slide position including in-flight drag.
/// * [slidePositions] — slide position of each rendered slide, in render
///   order; drives both the flex line length and each cross-faded slide's
///   opacity.
/// * [itemCount] / [wrap] — needed to measure cross-fade distance the short
///   way around a wrapping carousel.
ResolvedCarousel resolveCarousel(
  BuildContext context, {
  required CoreCarouselAlignment alignment,
  required bool animate,
  required CoreCubicBezier curve,
  required CoreAxis direction,
  required double gap,
  required CoreCarouselVariant variant,
  required int itemCount,
  required CoreCarouselTransitionMode mode,
  required double progress,
  required CoreCarouselSizeConstraint sizeConstraint,
  required List<int> slidePositions,
  required Duration speed,
  required bool wrap,
  CoreCarouselStyle? carouselStyle,
}) {
  final carouselTheme = context.theme.coreComponentTheme?.carousel;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCarouselStyle(), [
    carouselTheme?.style,
    carouselStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Border radius — single inline signature: `(merged.X ?? default)`
  // emitted as a rem rule (radius is always inline, never a `rounded-*`
  // Tailwind class).
  final borderRadius =
      (merged.borderRadius ?? CoreCarouselStyle.defaultBorderRadius).toValue();
  // Nav inset / indicator inset — inline rem offsets per side so the
  // override path and the default path share one CSS surface. Both
  // resolve to [CoreEdgeInsets] so callers can pad any axis (the prev
  // button reads the leading side, the next reads the trailing one, and the
  // indicator row emits whichever sides are non-zero).
  final navInset = merged.navInset ?? CoreCarouselStyle.defaultNavInset;
  final indicatorInset =
      merged.indicatorInset ?? CoreCarouselStyle.defaultIndicatorInset;
  // Nav hover-reveal fade duration — emitted inline as
  // `transition-duration` on the nav anchors (settled value, so the
  // override path and the default path share one CSS surface).
  final navFadeDuration =
      merged.navFadeDuration ?? CoreCarouselStyle.defaultNavFadeDuration;
  // Nav button surface — `merged.controlOverlayColor` override wins,
  // else the design-system default token (`surface-raised`). The default
  // token flows through a `bg-*` colour class (dark-mode swap) while an
  // override is emitted inline (colour token class + override inline,
  // card model). Mirrors the Flutter resolver folding
  // `controlOverlayColor` onto `navButtonStyle.backgroundColor`.
  final navButtonBackgroundColor =
      merged.controlOverlayColor ??
      CoreCarouselStyle.defaultControlOverlayColor;

  // Pre-compose the nested `Button` style — design-system default
  // carousel nav chrome merged with the per-instance override.
  final navButtonStyle = CoreCarouselStyle.defaultPrevNextButtonStyle.merge(
    merged.prevNextButtonStyle,
  );

  // Pre-compose the nested `DotIndicator` style — the per-instance
  // dot size / gap / active+inactive colour fields flow through.
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

  // Viewport → indicator-row spacer for the `below` placement —
  // composite default merged with the override, raw-forwarded to `Gap`.
  final indicatorBelowGapStyle = CoreCarouselStyle.defaultIndicatorBelowGapStyle
      .merge(merged.indicatorBelowGapStyle);
  // Prev ↔ next spacer (the `banner` pair) — composite default merged with
  // the override, raw-forwarded to `Gap`.
  final navGapStyle = CoreCarouselStyle.defaultNavGapStyle.merge(
    merged.navGapStyle,
  );
  final isBelow = variant == CoreCarouselVariant.banner;

  // ─── Geometry / motion locals (Stage 2 EMIT) ──────────
  final isVertical = direction == .vertical;
  final alignmentFraction = alignment.alignment;
  final isFading = mode == .fading;
  // Slide extent along the carousel axis, split into the two CSS units it
  // can arrive in: a viewport fraction (`fractional`) or an absolute rem
  // length (`fixed`). Exactly one is non-zero.
  final extentFraction = switch (sizeConstraint) {
    final CoreCarouselFractionalConstraint c => c.fraction,
    _ => 0.0,
  };
  final extentRem = switch (sizeConstraint) {
    final CoreCarouselFixedConstraint c => c.size / kRemDivisor,
    _ => 0.0,
  };
  // The space between slides, as the spacing variable a density
  // re-points — the line's own `gap` and the translate below read the same
  // value, so the slides keep their stops under any density, as on
  // Flutter. `null` when the transition states none.
  final slideGap = gap > 0 ? spaceCss(gap) : null;
  // Leading slack before the active slide — the leftover viewport extent
  // times the alignment fraction, in the same two units.
  final leadSlackPercent = alignmentFraction * (1 - extentFraction) * _kPercent;
  final leadSlackRem = -alignmentFraction * extentRem;
  final transitionProperty = isFading ? 'opacity' : 'transform';
  final transitionValue = animate
      ? '$transitionProperty ${speed.inMilliseconds}ms ${curve.toCss()}'
      : 'none';
  final mainAxisKey = isVertical ? 'min-height' : 'min-width';
  final extentValue = extentRem > 0
      ? '${extentRem}rem'
      : '${extentFraction * _kPercent}%';

  // ─── Local builders ───────────────────────────────────

  /// Composes a `translate`/offset CSS length out of a viewport-percentage
  /// term, a rem term and a count of slide [gaps]. CSS rejects
  /// `calc(50% + -1rem)`, so each sign is folded into its operator, and
  /// zero terms drop out — no rem and no gaps degrade to a plain
  /// percentage.
  ///
  /// The gaps stay a count times the spacing variable rather than a length
  /// folded into the rem term: a density re-points that variable, and a
  /// translate carrying the gap as a literal would advance by the authored
  /// gap while the line spaced its slides by the re-pointed one.
  String composeOffset(double percent, double rem, {double gaps = 0}) {
    final terms = [
      if (rem.abs() >= _kZeroEpsilon) '${rem < 0 ? '-' : '+'} ${rem.abs()}rem',
      if (slideGap != null && gaps.abs() >= _kZeroEpsilon)
        '${gaps < 0 ? '-' : '+'} ${gaps.abs()} * $slideGap',
    ];
    if (terms.isEmpty) return '$percent%';
    return 'calc($percent% ${terms.join(' ')})';
  }

  /// Composes the viewport `<div>` Tailwind className — relative
  /// position so children can absolutely-anchor, hides the slides outside
  /// the viewport, full container width.
  /// Border radius is emitted inline (see [buildViewportInlineStyles]).
  String buildViewportClassName() =>
      '${WebLayout.relative} ${WebLayout.overflowHidden} ${WebLayout.wFull}';

  /// Composes the viewport `<div>` inline CSS — the resolved border
  /// radius as a rem rule (`(merged.borderRadius ?? default)`).
  Styles buildViewportInlineStyles() =>
      .new(raw: {'border-radius': borderRadius});

  /// Composes the outermost `<div>` Tailwind className. `overlay` puts the
  /// viewport chrome on the root itself; `below` makes the root a
  /// full-width column that centres the dots under the viewport.
  ///
  /// The root always carries the Tailwind `group` marker that scopes the nav
  /// anchors' `group-hover:` reveal — in `below` too, so the pointer over the
  /// dots under the viewport reveals the buttons exactly as it does in
  /// Flutter, whose hover region wraps the whole carousel.
  String buildRootClassName() => isBelow
      ? '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsCenter} '
            '${WebLayout.wFull} group'
      : '${buildViewportClassName()} group';

  /// Composes the outermost `<div>` inline CSS — the viewport's radius
  /// for `overlay`, nothing for the `below` column (its viewport child
  /// carries the radius).
  Styles? buildRootInlineStyles() =>
      isBelow ? null : buildViewportInlineStyles();

  /// Composes the invisible height-anchor `<div>` inline CSS — a fully
  /// transparent, non-interactive copy of the active slide left in normal
  /// flow purely so the cross-fading viewport keeps a height.
  Styles buildSizingSlideInlineStyles() => const .new(
    raw: {
      'opacity': '0',
      'pointer-events': 'none',
    },
  );

  /// Composes the slide-container `<div>` Tailwind className — a flex line
  /// along the carousel axis for `sliding`, nothing for `fading` (its
  /// slides position themselves against the viewport).
  String buildTrackClassName() {
    if (isFading) return '';
    return isVertical
        ? '${WebLayout.flex} ${WebLayout.flexCol}'
        : '${WebLayout.flex} ${WebLayout.flexRow}';
  }

  /// Composes the slide-container `<div>` per-frame inline CSS — the
  /// resolved `transform` for the current [progress] (leading slack minus
  /// the travelled slide extents, including any in-flight drag), the
  /// `transition` mode, and the inter-slide `gap`.
  ///
  /// A vertical carousel additionally pins the line to the viewport height
  /// so percentage slide extents have a definite basis to resolve against.
  Styles buildTrackInlineStyles() {
    if (isFading) {
      return const .new(raw: {'position': 'absolute', 'inset': '0'});
    }
    // Slide `n` sits at `n * (extent + gap)` inside the line, and the
    // active slide must land on the leading slack — so the line travels
    // `leadSlack - progressFromFirstSlide * (extent + gap)`. The extent
    // part is a length; the gap part is a count of the line's own gap, so
    // the translate and the `gap` below move together when a density
    // re-points the variable. An empty carousel has no first slide to
    // measure from and nothing to move.
    final firstPosition = slidePositions.isEmpty ? 0 : slidePositions.first;
    final travelled = progress - firstPosition;
    final percent = leadSlackPercent - travelled * extentFraction * _kPercent;
    final rem = leadSlackRem - travelled * extentRem;
    final offset = composeOffset(percent, rem, gaps: -travelled);
    final raw = {
      'transform': isVertical ? 'translateY($offset)' : 'translateX($offset)',
      'transition': transitionValue,
    };
    if (slideGap != null) raw['gap'] = slideGap;
    if (isVertical) raw['height'] = '$_kPercent%';
    return .new(raw: raw);
  }

  /// Distance from [progress] to the slide at [position], measured the
  /// short way around when the carousel wraps — so the first and last
  /// slides cross-fade into each other instead of both going transparent.
  double fadeDistance(int position) {
    final linear = (progress - position).abs();
    if (!wrap || itemCount <= 1) return linear;
    final span = itemCount.toDouble();
    final folded = linear % span;
    return min(folded, span - folded);
  }

  /// Composes one slide wrapper's inline CSS.
  ///
  /// `sliding` slides are flex items pinned to the resolved extent along
  /// the carousel axis. `fading` slides are all absolutely positioned on
  /// the leading slack — only their resolved opacity differs, which is why
  /// the resolver emits one chrome per slide instead of a shared one.
  Styles buildSlideInlineStyles(int position) {
    if (!isFading) {
      return .new(
        raw: {
          mainAxisKey: extentValue,
          'flex-shrink': '0',
        },
      );
    }
    final offset = composeOffset(leadSlackPercent, leadSlackRem);
    final opacity = (1 - fadeDistance(position)).clamp(0.0, 1.0);
    return .new(
      raw: {
        'position': 'absolute',
        if (isVertical) 'top': offset else 'left': offset,
        if (isVertical) 'height': extentValue else 'width': extentValue,
        if (isVertical) 'left': '0' else 'top': '0',
        if (isVertical) 'right': '0' else 'bottom': '0',
        'opacity': '$opacity',
        'transition': transitionValue,
      },
    );
  }

  /// Composes the nav anchor `<div>` Tailwind className — absolute on the
  /// requested side, centred on the cross axis, holding the `Button` as its
  /// only flex item (a `flex` box, so the inline-flex button leaves no line
  /// descender under it).
  ///
  /// Hover-revealed on pointer devices: hidden (`opacity-0`) until the root
  /// `group` is hovered or a button holds keyboard focus, fading via
  /// `transition-opacity` with the resolved `navFadeDuration` and the
  /// `move` curve emitted inline. Touch devices never hover, so the buttons
  /// stay visually hidden there — swiping and the indicator dots remain the
  /// touch affordances (the buttons stay hit-testable and readable by screen
  /// readers). Mirrors the Flutter `AnimatedOpacity(_hovered)` gate.
  ///
  /// The reveal sits on this wrapper because the `Button` it holds owns its
  /// own `transition` (see [ResolvedCarousel.prevNavReveal]).
  String buildNavRevealClassName() {
    final classList = [
      WebLayout.absolute,
      WebLayout.flex,
      if (isVertical) WebLayout.leftHalf else WebLayout.topHalf,
      if (isVertical)
        WebLayout.negTranslateXHalf
      else
        WebLayout.negTranslateYHalf,
      'opacity-0',
      'group-hover:opacity-100',
      'group-focus-within:opacity-100',
      'transition-opacity',
    ];
    return classList.join(' ');
  }

  /// Composes the nav anchor `<div>` inline CSS — the resolved per-side inset
  /// on the leading / trailing side of the carousel axis, and the reveal's
  /// clock and curve.
  ///
  /// The inset rides `spaceCss`: the Flutter twin converts the same
  /// `CoreEdgeInsets` through the theme geometry, so a density moves it
  /// there, and a literal here would leave the Web buttons behind.
  ///
  /// The clock rides `durationMsCss` and the curve `toVarCss`, so a
  /// token-step fade keeps the `--coui-duration-*` / `--easing-*` variable
  /// that `prefers-reduced-motion` and an easing override reach — the Flutter
  /// twin's `resolveMotionDuration` and `CoreEasing.move` take the same two
  /// routes.
  Styles buildNavRevealInlineStyles({required bool isNext}) {
    final side = switch ((isVertical, isNext)) {
      (true, true) => 'bottom',
      (true, false) => 'top',
      (false, true) => 'right',
      (false, false) => 'left',
    };
    final inset = switch ((isVertical, isNext)) {
      (true, true) => navInset.bottom,
      (true, false) => navInset.top,
      (false, true) => navInset.right,
      (false, false) => navInset.left,
    };
    return .new(
      raw: {
        side: spaceCss(inset),
        // Overrides the `transition-opacity` class's built-in clock and
        // curve with the resolved tokens.
        'transition-duration': durationMsCss(navFadeDuration.inMilliseconds),
        'transition-timing-function': CoreEasing.move.toVarCss(),
      },
    );
  }

  /// Composes the nav `Button` `classes` slot className — the default
  /// surface colour token class (suppressed when `controlOverlayColor` is
  /// overridden so the inline rule wins — colour token class + override
  /// inline, card model).
  ///
  /// The cast and the edge are not here: they are fields of
  /// [navButtonStyle] (`boxShadow`, `borderColor`, `borderWidth`), so the
  /// `Button` emits them and a caller's `prevNextButtonStyle` can restate
  /// them. A `shadow-*` class on this slot would stack a second cast on the
  /// one the style states.
  ///
  /// No `opacity-*` / `transition-*` utility here, deliberately: the
  /// `Button` owns its `transition`, and the reveal is on the anchor
  /// ([buildNavRevealClassName]).
  String buildNavButtonClassName() {
    if (merged.controlOverlayColor != null) return '';
    return 'bg-${CoreCarouselStyle.defaultControlOverlayColor.tailwindColor}';
  }

  /// Composes the nav `Button` `css` slot inline CSS — the surface colour
  /// override, inline only when overridden (`null` otherwise).
  Styles? buildNavButtonInlineStyles() {
    if (merged.controlOverlayColor == null) return null;
    // EMIT (Web, theme-free) — `.toValue()` renders the token as
    // `rgb(var(--coui-X) / …)`, dark-mode reactive at runtime. No
    // `scheme.resolve` (a no-op on Web — CSS resolves tokens itself).
    return .new(
      raw: {'background-color': navButtonBackgroundColor.toValue()},
    );
  }

  /// Composes the indicator-row `<div>` Tailwind className — absolute
  /// anchor + flex row centred across the carousel's cross axis. The
  /// offsets are emitted inline (see [buildIndicatorRowInlineStyles]).
  String buildIndicatorRowClassName() {
    final crossAxisSpan = isVertical
        ? '${WebLayout.topZero} ${WebLayout.bottomZero} ${WebLayout.flexCol}'
        : '${WebLayout.leftZero} ${WebLayout.rightZero}';
    return '${WebLayout.absolute} $crossAxisSpan ${WebLayout.flex} '
        '${WebLayout.justifyCenter} ${WebLayout.itemsCenter}';
  }

  /// Composes the indicator-row `<div>` inline CSS — the resolved
  /// non-zero sides of `indicatorInset` (default
  /// `CoreEdgeInsets.only(bottom: 16)` emits only `bottom`, but callers
  /// can also push the row down from the top, etc.). Each side rides
  /// `spaceCss` for the reason [buildNavButtonInlineStyles] gives.
  Styles buildIndicatorRowInlineStyles() {
    final raw = <String, String>{};
    if (indicatorInset.top != 0) {
      raw['top'] = spaceCss(indicatorInset.top);
    }
    if (indicatorInset.right != 0) {
      raw['right'] = spaceCss(indicatorInset.right);
    }
    if (indicatorInset.bottom != 0) {
      raw['bottom'] = spaceCss(indicatorInset.bottom);
    }
    if (indicatorInset.left != 0) {
      raw['left'] = spaceCss(indicatorInset.left);
    }
    return .new(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedCarousel(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    viewport: WebElementChrome(
      className: buildViewportClassName(),
      inlineStyles: buildViewportInlineStyles(),
    ),
    sizingSlide: WebElementChrome(
      className: '',
      inlineStyles: buildSizingSlideInlineStyles(),
    ),
    track: WebElementChrome(
      className: buildTrackClassName(),
      inlineStyles: buildTrackInlineStyles(),
    ),
    slides: [
      for (final position in slidePositions)
        WebElementChrome(
          className: '',
          inlineStyles: buildSlideInlineStyles(position),
        ),
    ],
    prevNavReveal: WebElementChrome(
      className: buildNavRevealClassName(),
      inlineStyles: buildNavRevealInlineStyles(isNext: false),
    ),
    nextNavReveal: WebElementChrome(
      className: buildNavRevealClassName(),
      inlineStyles: buildNavRevealInlineStyles(isNext: true),
    ),
    prevNavButton: WebElementChrome(
      className: buildNavButtonClassName(),
      inlineStyles: buildNavButtonInlineStyles(),
    ),
    nextNavButton: WebElementChrome(
      className: buildNavButtonClassName(),
      inlineStyles: buildNavButtonInlineStyles(),
    ),
    indicatorRow: WebElementChrome(
      className: buildIndicatorRowClassName(),
      inlineStyles: buildIndicatorRowInlineStyles(),
    ),
    navButtonStyle: navButtonStyle,
    dotIndicatorStyle: dotIndicatorStyle,
    indicatorBelowGapStyle: indicatorBelowGapStyle,
    navGapStyle: navGapStyle,
  );
}

/// Resolves DotIndicator chrome and its shared value-free pseudo-state rules.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// Shared rules contain no instance values. Each visual dot owns the custom
// properties that its inherited style resolved, even when legacy scope classes
// are shared by valid local keys or a reused runtime configuration.
const _kDotHitHorizontal = 'co-dot-hit-horizontal';
const _kDotHitVertical = 'co-dot-hit-vertical';
const _kDotRawHover = 'co-dot-raw-hover';
const _kDotRawRing = 'co-dot-raw-ring';
const _kDotRingBand = 'co-dot-ring-band';

const _kDotRules =
    '''
.coui-touch-target.$_kDotHitHorizontal::after{
  left:auto;right:auto;
  inset-inline-start:calc(50% - var(--co-dot-hit-before));
  inset-inline-end:calc(50% - var(--co-dot-hit-after));
  width:auto;transform:translateY(-50%);
}
.coui-touch-target.$_kDotHitVertical::after{
  top:calc(50% - var(--co-dot-hit-before));
  bottom:calc(50% - var(--co-dot-hit-after));
  height:auto;transform:translateX(-50%);
}
.$_kDotRawHover:hover{border-color:var(--co-dot-hover-border-color);}
.$_kDotRawRing{outline-color:transparent;}
:where(.$_kDotRawRing){outline-style:solid;}
.group:focus-visible .$_kDotRawRing{
  outline-color:var(--co-dot-focus-outline-color);
  outline-width:var(--co-dot-focus-outline-width);
  outline-offset:var(--co-dot-focus-outline-offset);
}
.group:focus-visible .$_kDotRawRing:where(.$_kDotRingBand){
  box-shadow:var(--co-dot-focus-box-shadow);
}
''';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `DotIndicator`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="tablist">)             // flex row/col items-center
///   ├─ Clickable (<div role="button">)  // unified clickable wrapper (cursor /
///   │    └─ dots[0].root (<div>)          //   focus ring / keyboard) —
///   mirrors the
///   ├─ Clickable (<div role="button">)  //   Flutter `Clickable` per dot.
///   Inner
///   │    └─ dots[1].root (<div>)          //   <div> carries the per-index Cat
///   B
///   └─ ...                                //   visual bundle (active /
///   inactive /
///                                         //   hover affordances / inter-dot
///                                         spacing
///                                         //   on all but the last dot).
/// ```
///
/// `co_dot_indicator.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat B — per-dot [ResolvedDotIndicatorDot] nested chrome bundle,
///   one entry per index. Each carries its own root [WebElementChrome]
///   so the widget can render `dots[i].root.className /
///   inlineStyles` uniformly with the outer `root.className /
///   inlineStyles` pattern.
///
/// Runtime state (`direction` / `length` / `activeIndex` /
/// `isClickable`) flows in as resolver arguments — no scalar metadata
/// is exposed on the resolved struct.
class ResolvedDotIndicator implements WebResolvedChrome {
  /// Creates a [ResolvedDotIndicator].
  const ResolvedDotIndicator({required this.root, required this.dots});

  /// Paint-ready chrome for the outer container `<div>` — flex
  /// direction + `items-center` className plus the optional `padding`
  /// override inline CSS.
  @override
  final WebElementChrome root;

  /// Per-dot Cat B chrome bundles, one entry per dot indexed by
  /// position. `co_dot_indicator` iterates this list and reads
  /// `dots[i].root.className` / `dots[i].root.inlineStyles` straight
  /// off for each dot `<div>` box it renders (wrapped in `Clickable`).
  final List<ResolvedDotIndicatorDot> dots;
}

/// Paint-ready chrome for a single dot inside `DotIndicator`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                            // transition-all + colour
///                                         //   token classes (active /
///                                         //   inactive) + optional hover
///                                         //   affordances; geometry +
///                                         //   radius + border-width +
///                                         //   transition duration + inter-
///                                         //   dot spacing inline (last
///                                         //   spacing suppressed)
/// ```
///
/// The dot is the visual box only — the surrounding `Clickable`
/// (rendered by `co_dot_indicator`) owns the cursor / focus ring /
/// keyboard activation, mirroring the Flutter widget where each dot is
/// wrapped in `Clickable`.
///
/// Cat B per-list-item bundle — exposes the same [WebElementChrome]
/// `root` contract as the parent [ResolvedDotIndicator] so the
/// widget keeps `dots[i].root.className / inlineStyles` uniform with
/// the outer `root.className / inlineStyles` pattern.
class ResolvedDotIndicatorDot implements WebResolvedChrome {
  /// Creates a [ResolvedDotIndicatorDot].
  const ResolvedDotIndicatorDot({required this.root});

  /// Paint-ready chrome for the dot `<div>` box — combines the
  /// `transition-all` + active / inactive colour token classes (plus the
  /// pointer-target marker and, on inactive dots, the hover affordances
  /// when clickable) with inline CSS (geometry, radius,
  /// state border width, transition duration, inter-dot spacing suppressed
  /// on the last dot, and the optional colour overrides).
  ///
  /// The pointer-target marker sits here rather than on the `Clickable`
  /// because the overlay it turns on accepts the pointer: on an ancestor
  /// it becomes the hit target and the dot stops matching `:hover`.
  @override
  final WebElementChrome root;
}

/// Shared CSS text for `<style>` blocks in `DotIndicator`.
///
/// Rules contain only common selectors and custom-property references. Each dot
/// carries its own resolved values, so legacy scope classes shared by valid
/// local keys or a reused configuration cannot overwrite another dot's paint.
/// Class-safe rings and token hover colours keep their existing utility path.
/// A separate painted-band marker ensures a bandless ring leaves shadows alone.
class ResolvedDotIndicatorRules {
  /// Creates a [ResolvedDotIndicatorRules].
  const ResolvedDotIndicatorRules({required this.css});

  /// Raw CSS rule text — empty when the indicator is not clickable.
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDotIndicator] for `DotIndicator` (Web).
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.dotIndicator.style
///   → widget.dotIndicatorStyle
/// ```
///
/// [length] / [activeIndex] / [isClickable] are the per-build runtime
/// inputs — the resolver bakes them into the per-dot chrome bundles
/// returned via [ResolvedDotIndicator.dots].
///
/// [size] is a semantic identifier (widget-only prop — the theme cannot
/// override it, mirroring `resolveProgress`'s `size`) that selects the
/// per-size dot diameter + spacing from
/// [CoreDotIndicatorStyle.defaultsBySize].
ResolvedDotIndicator resolveDotIndicator(
  BuildContext context, {
  required CoreAxis direction,
  required CoreDotIndicatorSize size,
  required int length,
  required int activeIndex,
  required bool isClickable,
  required String scopeId,
  CoreDotIndicatorStyle? dotIndicatorStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.dotIndicator;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDotIndicatorStyle(), [
    csTheme?.style,
    dotIndicatorStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  // Semantic `size` is a widget-only prop (the theme cannot override it).
  // Resolve straight to the per-size default style (dotSize / spacing).
  // Web emits rem, so the token scales with the root font-size the way
  // Flutter's `scaling` multiplies the same default.
  final sizeStyle = CoreDotIndicatorStyle.defaultsBySize[size]!;
  final dotSize = merged.dotSize ?? sizeStyle.dotSize!;
  final activeLength =
      merged.activeLength ?? CoreDotIndicatorStyle.defaultActiveLength(dotSize);
  final spacing = merged.spacing ?? sizeStyle.spacing!;
  // Container padding — `(merged ?? default)`: the design-system default
  // (8px all sides) was previously dropped on Web (`merged.padding?`
  // without the fallback), so the Web indicator rendered 8px higher than
  // the Flutter twin, which applies the default around its dots.
  final padding = (merged.padding ?? CoreDotIndicatorStyle.defaultPadding)
      .toValue();
  // Dot radius — always emitted inline (`(merged ?? default).toValue()`),
  // never a Tailwind radius class, so the override path and the default
  // path land on the same CSS surface and reflect `merged.borderRadius`
  // directly (Epic #1603 single-signature gate — radius is always-inline).
  final borderRadius =
      (merged.borderRadius ?? CoreDotIndicatorStyle.defaultBorderRadius)
          .toValue();
  // Inactive-dot border width — always inline rem (matches the Flutter
  // `resolved.inactiveBorderWidth`). The active dot keeps the fixed
  // design-system border width (Flutter `_ActiveDotItem` uses
  // `defaultInactiveBorderWidth`), so its width is emitted separately.
  final inactiveBorderWidth =
      merged.inactiveBorderWidth ??
      CoreDotIndicatorStyle.defaultInactiveBorderWidth;
  // Transition duration — always inline `${ms}ms` (matches the card
  // resolver). Emitting it inline keeps the override path on the same
  // surface and avoids the `tailwindDuration` adapter, which only maps
  // the exact duration-scale constants and would throw on an arbitrary
  // user override.
  final transitionMs =
      (merged.transitionDuration ??
              CoreDotIndicatorStyle.defaultTransitionDuration)
          .inMilliseconds;
  // Colours — design-system token classes by default, suppressed when a
  // matching override is present so the inline rule wins (card model).
  final activeColor = merged.activeColor;
  final inactiveColor = merged.inactiveColor;
  final inactiveBorderColor = merged.inactiveBorderColor;
  const defaultBorderColor = CoreDotIndicatorStyle.defaultInactiveBorderColor;
  // Hover border colour is a `:hover` pseudo-state, which inline CSS
  // cannot express — so the merged value rides a `hover:border-*` token
  // class (pseudo-state class exception, button PoC pattern). Reading the
  // merged value keeps it on the override chain rather than baking the
  // default.
  final hoverBorderColor =
      merged.hoverBorderColor ?? CoreDotIndicatorStyle.defaultHoverBorderColor;
  // Selected-dot focus ring (roving radio-group model — the group is the
  // single tab stop; the ring paints around the selected dot while the
  // group holds keyboard focus). Web has no `FocusOutline` twin — CSS
  // pseudo classes are the Web focus engine — so the shared
  // focus-outline slot resolves here. `align` is the child-edge →
  // ring-outer-edge distance (offset + width), mirroring Flutter.
  // Every focus-ring field's override rides the nested merged.focusOutlineStyle
  // slot below (not a flat merged.<field>) — Web has no FocusOutline widget
  // twin.
  // guard-nested-override: borderWidth
  // guard-nested-override: align
  // guard-nested-override: borderColor
  // guard-nested-override: offsetColor
  // guard-nested-override: ringOpacity
  final focusOutline = CoreDotIndicatorStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );
  final focusRingWidth =
      focusOutline.borderWidth ?? CoreFocusOutlineStyle.defaultBorderWidth;
  final focusRingOffset =
      (focusOutline.align ?? CoreFocusOutlineStyle.defaultAlign) -
      focusRingWidth;
  final focusRingColor =
      focusOutline.borderColor ?? CoreFocusOutlineStyle.defaultBorderColor;
  final focusRingOffsetColor =
      focusOutline.offsetColor ?? CoreFocusOutlineStyle.defaultOffsetColor;
  final focusRingOpacity =
      focusOutline.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity;

  // Class-vs-local-value pivots. A pseudo-state colour can only ride a
  // Tailwind class when it is a design-system token: a raw (token-less)
  // hover border colour, or a focus ring whose colour / opacity /
  // geometry leaves the Tailwind `outline-*` scale or whose gap band
  // paints (a `box-shadow` layer, which no class draws), has no class. In
  // that case the dot drops the utility class and carries its resolved values
  // in custom properties for the common rules. Legacy scope classes remain
  // for compatibility; they no longer decide another dot's pseudo-state value.
  final hoverBorderRaw = isClickable && hoverBorderColor.token == null;
  final ringClassSafe = focusRingIsClassSafe(
    ringColor: focusRingColor,
    offsetColor: focusRingOffsetColor,
    ringOpacity: focusRingOpacity,
    ringWidth: focusRingWidth,
    ringOffset: focusRingOffset,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer container `<div>` Tailwind className — flex
  /// direction + `items-center`, plus the Tailwind `group` marker
  /// scoping the selected dot's `group-focus-visible:` ring and
  /// `outline-none` so the tabbable root never shows the browser's
  /// native outline (the visible ring is the selected dot's).
  String buildRootClassName() {
    final flexDir = direction == .horizontal
        ? WebLayout.flexRow
        : WebLayout.flexCol;
    return '${WebLayout.flex} $flexDir ${WebLayout.itemsCenter} '
        'group outline-none';
  }

  /// Composes the outer container `<div>` inline CSS — the resolved
  /// container padding.
  Styles buildRootInlineStyles() => .new(raw: {'padding': padding});

  /// Composes the per-dot `<div>` box Tailwind className — `transition-all`
  /// plus the active / inactive colour token classes (suppressed when the
  /// matching colour override is present so the inline rule wins), the
  /// pointer-target marker when the dot is clickable, and the hover
  /// affordances (hover border colour + scale) on clickable INACTIVE dots.
  /// The cursor is owned by the surrounding `Clickable` wrapper. Radius /
  /// border-width / transition duration / geometry are
  /// emitted inline (single-signature gate).
  String buildDotClassName({required bool isActive}) {
    return [
      'transition-all',
      if (isActive && activeColor == null)
        'bg-${CoreDotIndicatorStyle.defaultActiveColor.tailwindColor}',
      if (isActive && activeColor == null)
        'border-${CoreDotIndicatorStyle.defaultActiveColor.tailwindColor}',
      if (!isActive && inactiveColor == null)
        'bg-${CoreDotIndicatorStyle.defaultInactiveColor.tailwindColor}',
      if (!isActive && inactiveBorderColor == null)
        'border-${defaultBorderColor.tailwindColor}',
      // Pointer target expansion (WCAG 2.5.8) — mirrors Flutter's
      // `TouchTarget` wrap. The dot draws at `dotSize` (8 on the default
      // `md` rung, under the 24 floor); this only widens where a pointer is
      // accepted around it and draws nothing.
      //
      // It rides the dot rather than the surrounding `Clickable` because
      // the overlay it turns on *accepts the pointer* — that is its whole
      // job. On the wrapper, the overlay sat over the dot and became the
      // hit target, so the dot never matched `:hover` and every hover
      // affordance below was dead. The marked element itself still
      // matches `:hover`, so the marker has to sit on the element that
      // carries the hover chrome. Activation is unchanged: a pointer on
      // the ring targets the dot and bubbles to the `Clickable` root,
      // where the click handler lives.
      //
      // Gated on `isClickable` for the same reason a display-only `Chip`
      // carries no marker: an overlay that captures pointers and does
      // nothing with them is worse than a small target.
      if (isClickable) ...[
        kWebTouchTargetMarker,
        'co-dot-hit-${direction == .horizontal ? "h" : "v"}-$scopeId',
        if (direction == .horizontal) _kDotHitHorizontal else _kDotHitVertical,
      ],
      // Hover affordances belong to the INACTIVE dot only — the selected
      // dot already reads as selected, and `hoverBorderColor` is defined
      // on the contract as the colour "for clickable inactive dots".
      // Flutter draws the selected dot with `_ActiveDotItem`, which has
      // no `MouseRegion` and no `AnimatedScale`, so hovering it changes
      // nothing there either.
      if (isClickable && !isActive) ...[
        // Hover border — token → `hover:border-*` class; raw override →
        // local value marker, alongside its retained legacy scope class.
        // Invisible under the shipped defaults (zero border width); it is
        // here for callers who state a width of their own — what a hovered
        // dot shows by default is the scale step below.
        if (!hoverBorderRaw) 'hover:border-${hoverBorderColor.tailwindColor}',
        if (hoverBorderRaw) ...['co-dot-h-$scopeId', _kDotRawHover],
        'hover:scale-110',
      ],
      if (isActive && isClickable) ...[
        // Selected-dot ring — an outline. `outline-none` is its resting
        // state (`2px solid transparent`), so the group's keyboard focus
        // only moves the colour and `transition-all` fades it in.
        // Token/on-scale with no painted band →
        // `group-focus-visible:outline-*` classes; a raw / off-scale /
        // sub-1-opacity ring or a painted band → common marker reading this
        // dot's own values, alongside the retained legacy scope class.
        'outline-none',
        if (ringClassSafe)
          focusRingClassName(
            pseudo: .groupFocusVisible,
            ringColor: focusRingColor,
            ringWidth: focusRingWidth,
            ringOffset: focusRingOffset,
          ),
        if (!ringClassSafe) ...[
          'co-dot-r-$scopeId',
          _kDotRawRing,
          if (focusBandPaints(focusRingOffsetColor)) _kDotRingBand,
        ],
      ],
    ].join(' ');
  }

  /// Composes the per-dot `<div>` box inline CSS — geometry (`width` /
  /// `height`), radius, state border width, transition, inter-dot spacing
  /// along the layout axis (suppressed on the last dot), and the optional
  /// colour overrides (fill + border + hover border).
  Styles buildDotInlineStyles({required int index}) {
    final isActive = index == activeIndex;
    final isLast = index == length - 1;
    final spacingProp = direction == .horizontal
        ? 'margin-inline-end'
        : 'margin-bottom';
    // Active dot keeps the fixed design-system border width; the inactive
    // dot uses the resolved overridable width to mirror Flutter.
    final borderWidth = isActive
        ? CoreDotIndicatorStyle.defaultInactiveBorderWidth
        : inactiveBorderWidth;
    // The active dot fills and borders with the active colour; the
    // inactive dot fills with the inactive colour and borders with the
    // inactive border colour. The default token classes are dropped in
    // the className builder when the matching override is present.
    final fillColor = isActive ? activeColor : inactiveColor;
    final borderColor = isActive ? activeColor : inactiveBorderColor;
    final width = isActive && direction == .horizontal ? activeLength : dotSize;
    final height = isActive && direction == .vertical ? activeLength : dotSize;
    final raw = {
      'width': '${width / kRemDivisor}rem',
      'height': '${height / kRemDivisor}rem',
      'border-radius': borderRadius,
      'border-width': strokeWidthCss(borderWidth),
      'transition-duration': '${transitionMs}ms',
      // Logical margins must change immediately when text direction changes.
      // Animating the physical margin swap momentarily collapses the gap,
      // letting a neighbouring touch target cover this dot. Keep visual
      // state transitions but do not animate layout spacing.
      'transition-property':
          'background-color, border-color, border-width, border-radius, '
          'outline-color, outline-width, outline-offset, box-shadow, '
          'width, height, transform, opacity',
      if (!isLast) spacingProp: spaceCss(spacing),
      if (isClickable) ...{
        // Neighbours divide their gap at its midpoint. Each visible marker
        // remains fully clickable even when the active marker is much longer
        // than a dot, and no later marker covers a neighbour's painted area.
        '--co-dot-hit-before': index == 0
            ? 'max(50%, ${CoreTouchTarget.minimum / 2}px)'
            : _dotHitReach(spacing),
        '--co-dot-hit-after': isLast
            ? 'max(50%, ${CoreTouchTarget.minimum / 2}px)'
            : _dotHitReach(spacing),
      },
    };
    if (isClickable && !isActive && hoverBorderRaw) {
      raw['--co-dot-hover-border-color'] = hoverBorderColor.toValue();
    }
    if (isClickable && isActive && !ringClassSafe) {
      final ring = focusRingOpacity >= 1.0
          ? focusRingColor.toValue()
          : focusRingColor.scaleAlpha(focusRingOpacity).toValue();
      final declarations = focusRingDeclarations(
        ringColor: ring,
        ringWidth: focusRingWidth,
        ringOffset: focusRingOffset,
        bandColor: focusBandPaints(focusRingOffsetColor)
            ? focusRingOffsetColor.toValue()
            : null,
      );
      for (final declaration in declarations.entries) {
        raw['--co-dot-focus-${declaration.key}'] = declaration.value;
      }
    }
    if (fillColor != null) {
      // Web emits token names directly — `.toValue()` maps a token to
      // `var(--coui-X)` (resolved by the browser at runtime) and a raw
      // colour to `rgb(...)`. `scheme.resolve` would be a no-op here.
      raw['background-color'] = fillColor.toValue();
    }
    if (borderColor != null) {
      raw['border-color'] = borderColor.toValue();
    }
    return Styles(raw: raw);
  }

  final dots = <ResolvedDotIndicatorDot>[
    for (var i = 0; i < length; i++)
      ResolvedDotIndicatorDot(
        root: WebElementChrome(
          className: buildDotClassName(isActive: i == activeIndex),
          inlineStyles: buildDotInlineStyles(index: i),
        ),
      ),
  ];

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedDotIndicator(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    dots: dots,
  );
}

/// Resolves the shared `<style>` rules for a clickable `DotIndicator`.
///
/// The existing arguments remain for source compatibility. Resolved hover,
/// ring and hit values are carried by each dot's inline custom properties;
/// these value-free rules apply without using the legacy scope as an owner.
ResolvedDotIndicatorRules resolveDotIndicatorRules(
  BuildContext context, {
  required String scopeId,
  required bool isClickable,
  CoreDotIndicatorStyle? dotIndicatorStyle,
}) {
  // Signature retained for direct callers. Values live on the dots returned
  // by resolveDotIndicator; required scopeId still supplies their legacy
  // classes.
  if (!isClickable) return const ResolvedDotIndicatorRules(css: '');
  return const ResolvedDotIndicatorRules(css: _kDotRules);
}

/// The marker's half-length plus half the gap, capped at the existing
/// 24px reach. Keeping the gap as an operand preserves theme density and
/// custom spacing variables; no visible part is assigned to a neighbour.
String _dotHitReach(double spacing) =>
    'min(max(50%, ${CoreTouchTarget.minimum / 2}px), '
    'calc(50% + ${spaceCss(spacing)} / 2))';

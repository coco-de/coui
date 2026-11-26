import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_geometry.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Vocabulary shared by the scoped CSS and the widget
// ═══════════════════════════════════════════════════

/// The sticky, zero-height layer inside the scroller that holds the thumbs.
const kScrollbarLayerClass = 'co-scrollbar-layer';

/// A strip along the edge the thumb travels in — the part a tap pages by.
const kScrollbarTrackClass = 'co-scrollbar-track';

/// The thumb's hit area: the capsule plus the inset it keeps from the edge.
const kScrollbarThumbClass = 'co-scrollbar-thumb';

/// The visible capsule, inside the thumb's hit area.
const kScrollbarCapsuleClass = 'co-scrollbar-capsule';

/// Marks a track / thumb as the one for the vertical axis.
const kScrollbarVerticalClass = 'co-scrollbar-vertical';

/// Marks a track / thumb as the one for the horizontal axis.
const kScrollbarHorizontalClass = 'co-scrollbar-horizontal';

/// Root class while the thumb is shown because the area was just scrolled
/// (`auto` / `thin` visibility). The idle timeout takes it away again.
const kScrollbarShownClass = 'co-scrollbar-shown';

/// Root class while the vertical thumb is held, which keeps it in its
/// hovered look and shown even when the pointer leaves it.
const kScrollbarDraggingVerticalClass = 'co-scrollbar-dragging-vertical';

/// Root class while the horizontal thumb is held.
const kScrollbarDraggingHorizontalClass = 'co-scrollbar-dragging-horizontal';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Scrollbar`.
///
/// DOM shape:
///
/// ```text
/// root (<div id=$scopeId>)                         // the scroller
///   ├─ <style> (scoped)                            // hides the native bar,
///   │                                              //   skins everything below
///   ├─ phantom role="scrollbar" node(s)            // sr-only
///   ├─ layer (<div>)                               // sticky, zero height:
///   │    │                                         //   takes no layout space
///   │    ├─ verticalTrack (<div>)                  // present only while that
///   │    ├─ verticalThumb (<div>)                  //   axis can scroll
///   │    │    └─ verticalCapsule (<div>)
///   │    ├─ horizontalTrack (<div>)
///   │    └─ horizontalThumb (<div>)
///   │         └─ horizontalCapsule (<div>)
///   └─ child (caller-supplied Component, optional)
/// ```
///
/// The browser's own scrollbar is hidden and the thumb is drawn over the
/// content, the way the Flutter `RawScrollbar` overlay is — so the bar takes
/// none of the content's width. `scrollbar.dart` reads each slot's
/// `className` + `inlineStyles` straight onto its element; no merge,
/// fallback or conversion happens in the widget body.
///
/// The track and thumb slots carry the geometry measured from the scroller
/// (length and position), which is the one part of the chrome that cannot be
/// known before the page is in a browser; everything the design states
/// (thickness, inset, radius, colour, motion) is in the scoped `<style>`
/// from [resolveScrollbarCss].
class ResolvedScrollbar implements WebResolvedChrome {
  /// Creates a [ResolvedScrollbar].
  const ResolvedScrollbar({
    required this.root,
    this.layer,
    this.verticalTrack,
    this.verticalThumb,
    this.verticalCapsule,
    this.horizontalTrack,
    this.horizontalThumb,
    this.horizontalCapsule,
  });

  /// The scroller: axis-specific `overflow` and fill classes, plus the
  /// state classes the scoped CSS keys on (`shown`, `dragging`).
  @override
  final WebElementChrome root;

  /// The sticky layer the thumbs sit in. Null when the bar draws no thumb at
  /// all ([CoreScrollbarVisibility.hidden]).
  final WebElementChrome? layer;

  /// The vertical track, sized to the scroller's visible height. Null while
  /// the vertical axis has nothing to scroll (or has not been measured).
  final WebElementChrome? verticalTrack;

  /// The vertical thumb's hit area, placed along the track.
  final WebElementChrome? verticalThumb;

  /// The vertical thumb's visible capsule.
  final WebElementChrome? verticalCapsule;

  /// The horizontal track, sized to the scroller's visible width.
  final WebElementChrome? horizontalTrack;

  /// The horizontal thumb's hit area, placed along the track.
  final WebElementChrome? horizontalThumb;

  /// The horizontal thumb's visible capsule.
  final WebElementChrome? horizontalCapsule;
}

// ═══════════════════════════════════════════════════
// Shared geometry
// ═══════════════════════════════════════════════════

/// The thumb's design-stated geometry — one derivation for the chrome, the
/// scoped CSS and the behavioural thumb layout, so the three cannot disagree
/// about how thick the bar is or how far its thumb keeps from the edge.
({
  CoreScrollbarStyle merged,
  CoreScrollbarThumbGeometry geometry,
  double minThumbLength,
})
_resolveGeometry(
  BuildContext context, {
  required CoreScrollbarVisibility visibility,
  CoreScrollbarStyle? scrollbarStyle,
}) {
  final scrollbarTheme = context.theme.coreComponentTheme?.scrollbar;
  final merged = resolveStyleChain(const CoreScrollbarStyle(), [
    scrollbarTheme?.style,
    scrollbarStyle,
  ]);

  // `thin` halves both thicknesses to a hairline exactly as Flutter does
  // (the inset stays); `auto` / `always` keep them. The geometry is the one
  // shared arithmetic both platforms run, so the footprint and the grown
  // thumb's inset are not derived twice.
  final baseThickness = merged.thickness ?? CoreScrollbarStyle.defaultThickness;
  final baseHoverThickness =
      merged.hoverThickness ?? CoreScrollbarStyle.defaultHoverThickness;
  final inset = merged.thumbInset ?? CoreScrollbarStyle.defaultThumbInset;
  final thin = visibility == .thin;
  final geometry = CoreScrollbarThumbGeometry(
    thickness: thin
        ? baseThickness * CoreScrollbarStyle.thinThicknessFactor
        : baseThickness,
    hoverThickness: thin
        ? baseHoverThickness * CoreScrollbarStyle.thinThicknessFactor
        : baseHoverThickness,
    inset: inset,
  );

  return (
    merged: merged,
    geometry: geometry,
    minThumbLength:
        merged.minThumbLength ?? CoreScrollbarStyle.defaultMinThumbLength,
  );
}

/// The thumbs for the scroller's current geometry — what a drag or a tap on
/// the track turns into a scroll position.
///
/// A separate entry point from [resolveScrollbar] because it feeds the
/// widget's behaviour between builds rather than its chrome (the number
/// ticker's `resolve*Tuning` pattern), but it walks the same merge chain and
/// reads the same margin and minimum length, so the thumb a drag moves is
/// the thumb that was drawn.
({CoreScrollbarThumbLayout? vertical, CoreScrollbarThumbLayout? horizontal})
resolveScrollbarThumbs(
  BuildContext context, {
  required CoreScrollbarAxis axis,
  required CoreScrollbarVisibility visibility,
  required ScrollbarViewportGeometry viewport,
  CoreScrollbarStyle? scrollbarStyle,
}) {
  final resolved = _resolveGeometry(
    context,
    visibility: visibility,
    scrollbarStyle: scrollbarStyle,
  );

  return scrollbarThumbsOf(
    viewport,
    axis: axis,
    margin: resolved.geometry.inset,
    minLength: resolved.minThumbLength,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedScrollbar] for the given [context].
///
/// The semantic [axis] / [visibility] and behavioural [interactive] are
/// widget props; the rest is runtime state the widget holds and hands in so
/// the className / inline CSS are finished once here:
///
/// * [viewport] — the scroller's measured geometry, or null before it has
///   been measured (a server render, the first client frame). Without it no
///   track or thumb is emitted.
/// * [shown] — the area was just scrolled (`auto` / `thin` fade).
/// * [draggingAxis] — which thumb is being held, if any.
ResolvedScrollbar resolveScrollbar(
  BuildContext context, {
  required CoreScrollbarAxis axis,
  required CoreScrollbarVisibility visibility,
  required bool interactive,
  CoreScrollbarStyle? scrollbarStyle,
  ScrollbarViewportGeometry? viewport,
  bool shown = false,
  CoreScrollbarAxis? draggingAxis,
}) {
  final resolved = _resolveGeometry(
    context,
    visibility: visibility,
    scrollbarStyle: scrollbarStyle,
  );
  final geometry = resolved.geometry;
  final inset = geometry.inset;

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` Tailwind className.
  ///
  /// Stacks the axis-specific `overflow` rules and the matching fill class.
  /// The fill class makes the root adopt a sized ancestor's extent along the
  /// scroll axis — without it the root grows to its content and the
  /// overflow condition never fires (no scrolling, content spills past the
  /// host); under an auto-sized ancestor it is a no-op. The state classes
  /// are what the scoped CSS keys the thumb's look on.
  String buildRootClassName() {
    final overflowClass = switch (axis) {
      .both =>
        '${WebLayout.overflowAuto} ${WebLayout.hFull} ${WebLayout.wFull}',
      .vertical =>
        '${WebLayout.overflowYAuto} ${WebLayout.overflowXHidden} '
            '${WebLayout.hFull}',
      .horizontal =>
        '${WebLayout.overflowXAuto} ${WebLayout.overflowYHidden} '
            '${WebLayout.wFull}',
    };

    return <String>[
      overflowClass,
      if (shown) kScrollbarShownClass,
      if (draggingAxis == .vertical) kScrollbarDraggingVerticalClass,
      if (draggingAxis == .horizontal) kScrollbarDraggingHorizontalClass,
    ].join(' ');
  }

  /// Composes the root `<div>` inline-CSS bundle.
  ///
  /// Only `overscroll-behavior: contain`, emitted when the scrollbar is
  /// non-[interactive]. What that property actually does is stop scroll
  /// chaining — reaching this scroller's end no longer scrolls an
  /// ancestor — which is neither what `interactive` means nor something
  /// the Flutter twin does. Kept as-is rather than removed, since callers
  /// may have come to rely on the containment, but it is an artefact of this
  /// flag rather than an expression of it (recorded on
  /// `CoreScrollbarContract.interactive`).
  Styles buildRootInlineStyles() {
    return Styles(
      raw: {
        if (!interactive) 'overscroll-behavior': 'contain',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final root = WebElementChrome(
    className: buildRootClassName(),
    inlineStyles: buildRootInlineStyles(),
  );

  // `hidden` draws no thumb; the area still scrolls and the position is
  // still reported, so nothing here is conditional on it beyond the layer.
  if (visibility == .hidden) return ResolvedScrollbar(root: root);

  const layer = WebElementChrome(className: kScrollbarLayerClass);
  if (viewport == null) return ResolvedScrollbar(root: root, layer: layer);

  final thumbs = scrollbarThumbsOf(
    viewport,
    axis: axis,
    margin: inset,
    minLength: resolved.minThumbLength,
  );
  final footprintRem = '${geometry.footprint / kRemDivisor}rem';

  /// A slot that carries only classes — the capsule is positioned entirely
  /// by the scoped CSS.
  WebElementChrome plain(String className) =>
      WebElementChrome(className: className);

  /// The hit area is the capsule plus the inset it keeps from both ends of
  /// its track, so its box starts one inset before the capsule does.
  double hitStart(CoreScrollbarThumbLayout thumb) => thumb.offset - inset;
  double hitLength(CoreScrollbarThumbLayout thumb) => thumb.extent + 2 * inset;

  /// The horizontal bar sits against the bottom edge of the visible area,
  /// and the layer has no height of its own to anchor to.
  String horizontalTop() =>
      'calc(${measuredPxCss(viewport.clientHeight)} - $footprintRem)';

  final vertical = thumbs.vertical;
  final horizontal = thumbs.horizontal;

  return ResolvedScrollbar(
    root: root,
    layer: layer,
    verticalTrack: vertical == null
        ? null
        : WebElementChrome(
            className: '$kScrollbarTrackClass $kScrollbarVerticalClass',
            inlineStyles: Styles(
              raw: {'height': measuredPxCss(viewport.clientHeight)},
            ),
          ),
    verticalThumb: vertical == null
        ? null
        : WebElementChrome(
            className: '$kScrollbarThumbClass $kScrollbarVerticalClass',
            inlineStyles: Styles(
              raw: {
                'top': measuredPxCss(hitStart(vertical)),
                'height': measuredPxCss(hitLength(vertical)),
              },
            ),
          ),
    verticalCapsule: vertical == null ? null : plain(kScrollbarCapsuleClass),
    horizontalTrack: horizontal == null
        ? null
        : WebElementChrome(
            className: '$kScrollbarTrackClass $kScrollbarHorizontalClass',
            inlineStyles: Styles(
              raw: {
                'width': measuredPxCss(viewport.clientWidth),
                'top': horizontalTop(),
              },
            ),
          ),
    horizontalThumb: horizontal == null
        ? null
        : WebElementChrome(
            className: '$kScrollbarThumbClass $kScrollbarHorizontalClass',
            inlineStyles: Styles(
              raw: {
                'inset-inline-start': measuredPxCss(hitStart(horizontal)),
                'width': measuredPxCss(hitLength(horizontal)),
                'top': horizontalTop(),
              },
            ),
          ),
    horizontalCapsule: horizontal == null
        ? null
        : plain(kScrollbarCapsuleClass),
  );
}

// ═══════════════════════════════════════════════════
// Scoped-CSS resolver (Category C)
// ═══════════════════════════════════════════════════

/// Resolves the scoped `<style>` block contents for `Scrollbar`, every rule
/// pinned to the supplied [scopeId].
///
/// Walks the same merge chain as [resolveScrollbar] (design-system default →
/// `CoreScrollbarTheme.style` → `widget.scrollbarStyle`). Kept as a separate
/// `resolve*` entry point rather than a field on [ResolvedScrollbar] because
/// the payload is a `<style>` block keyed by a CSS selector, which a
/// `WebElementChrome` className/inlineStyles slot cannot express.
///
/// **The native scrollbar is hidden** (`scrollbar-width: none` and
/// `::-webkit-scrollbar { display: none }`) and the thumb is a `<div>` drawn
/// over the content. That is what lets the bar take no width, as the Flutter
/// overlay takes none; a native scrollbar has no CSS spelling that floats
/// above the content on every engine.
///
/// **Forced colours are the exception.** In `forced-colors: active` the
/// browser repaints every `background-color` as the page background, so a
/// `<div>` thumb would be invisible — while its native scrollbar is
/// restyled in system colours and stays readable. There the native bar is
/// left alone and the overlay is not drawn: the one mode where the bar takes
/// width again, because a bar nobody can see is worse than one that moves
/// the content.
///
/// Every selector reaches its elements through child combinators from the
/// scope id. A descendant selector would also match the track and thumb of a
/// `Scrollbar` nested inside this one's content and restyle them.
///
/// The thumb is a capsule inside a hit area that is its thickness plus its
/// inset on both sides (`CoreScrollbarThumbGeometry.footprint`). Hovering
/// the thumb or its track — or holding the thumb — moves the capsule from
/// its resting look to the hovered one (colour, thickness, and the inset it
/// grows into, so it stays centred in the same footprint) over
/// `CoreScrollbarContract.hoverTransitionMs`. For `auto` / `thin` the whole
/// thumb also fades: it rests invisible, shows while the area was just
/// scrolled, hovered or held, and fades over
/// `CoreScrollbarContract.fadeDurationMs`. `always` keeps it shown.
///
/// Lengths the design states are `rem`, like the track they live in, so the
/// browser-level font-size scale stays consistent with the rest of the page
/// (matches `MediaQuery.textScaler` parity on Flutter). The insets are
/// pinned: they are the thumb's seat inside its own footprint, control
/// geometry the Flutter twin leaves out of the density.
String resolveScrollbarCss(
  BuildContext context, {
  required CoreScrollbarAxis axis,
  required CoreScrollbarVisibility visibility,
  required String scopeId,
  bool interactive = true,
  CoreScrollbarStyle? scrollbarStyle,
}) {
  final scope = '#$scopeId';

  // The native bar goes in every mode; `hidden` has nothing more to say.
  if (visibility == .hidden) {
    return (StringBuffer()
          ..write('$scope { scrollbar-width: none; }')
          ..write('$scope::-webkit-scrollbar { display: none; }'))
        .toString();
  }

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final resolved = _resolveGeometry(
    context,
    visibility: visibility,
    scrollbarStyle: scrollbarStyle,
  );
  final merged = resolved.merged;
  final geometry = resolved.geometry;
  final thumbColor = merged.thumbColor ?? CoreScrollbarStyle.defaultThumbColor;
  final hoverThumbColor =
      merged.hoverThumbColor ?? CoreScrollbarStyle.defaultHoverThumbColor;
  final trackColor = merged.trackColor ?? CoreScrollbarStyle.defaultTrackColor;
  final thumbRadius =
      merged.thumbRadius ?? CoreScrollbarStyle.defaultThumbRadius;

  // ─── Stage 2 — EMIT (theme-free) ──────────────────────
  final thumbColorCss = thumbColor.toValue();
  final hoverThumbColorCss = hoverThumbColor.toValue();
  final trackColorCss = trackColor.toValue();
  final radiusCss = thumbRadius.toValue();
  final footprintRem = '${geometry.footprint / kRemDivisor}rem';
  final thicknessRem = '${geometry.thickness / kRemDivisor}rem';
  final activeThicknessRem = '${geometry.activeThickness / kRemDivisor}rem';
  final insetRem = pinnedLengthCss(geometry.inset);
  final activeInsetRem = pinnedLengthCss(geometry.activeInset);

  final fades = visibility == .auto || visibility == .thin;
  final pointerEvents = interactive ? 'auto' : 'none';
  final fade = durationMsCss(CoreScrollbarContract.fadeDurationMs);
  final hover = durationMsCss(CoreScrollbarContract.hoverTransitionMs);
  final easing = CoreEasing.move.toVarCss();

  final layer = '$scope > .$kScrollbarLayerClass';
  final track = '$layer > .$kScrollbarTrackClass';
  final thumb = '$layer > .$kScrollbarThumbClass';
  final capsule = '$thumb > .$kScrollbarCapsuleClass';
  const vertical = '.$kScrollbarVerticalClass';
  const horizontal = '.$kScrollbarHorizontalClass';
  const trackTag = '.$kScrollbarTrackClass';
  const thumbTag = '.$kScrollbarThumbClass';
  const capsuleTag = '.$kScrollbarCapsuleClass';
  final draggingV =
      '$scope.$kScrollbarDraggingVerticalClass > .'
      '$kScrollbarLayerClass';
  final draggingH =
      '$scope.$kScrollbarDraggingHorizontalClass > .'
      '$kScrollbarLayerClass';

  final css = StringBuffer()
    // The native bar: hidden everywhere the overlay is drawn, left alone
    // where it is not.
    ..write('@media (forced-colors: none) { ')
    ..write('$scope { scrollbar-width: none; } ')
    ..write('$scope::-webkit-scrollbar { display: none; } }')
    ..write('@media (forced-colors: active) { $layer { display: none; } }')
    // The layer sticks to the corner of the visible area and has no height,
    // so it takes no space in the content's layout while the thumbs it holds
    // stay in view as the content scrolls under it. 1000 is the base content
    // layer: above content that picked its own z-index, below dropdowns.
    ..write('$layer { position: sticky; top: 0; inset-inline-start: 0; ')
    ..write('width: 100%; height: 0; z-index: ${CoreZIndex.z0}; ')
    ..write('pointer-events: none; }')
    // Tracks: the strip a tap on pages by. Transparent unless the style
    // gives the track a colour.
    ..write('$track { position: absolute; background: $trackColorCss; ')
    ..write('pointer-events: $pointerEvents; ')
    ..write('transition: opacity $fade $easing; }')
    ..write('$track$vertical { top: 0; inset-inline-end: 0; ')
    ..write('width: $footprintRem; }')
    ..write('$track$horizontal { inset-inline-start: 0; ')
    ..write('height: $footprintRem; }')
    // Touch can drag the thumb but has no pointer to page with, so the
    // strip steps aside for it.
    ..write('@media (pointer: coarse) { $track { pointer-events: none; } }')
    // Thumb hit areas: capsule plus the inset around it.
    ..write('$thumb { position: absolute; touch-action: none; ')
    ..write('pointer-events: $pointerEvents; }')
    ..write('$thumb$vertical { inset-inline-end: 0; ')
    ..write('width: $footprintRem; }')
    ..write('$thumb$horizontal { height: $footprintRem; }')
    // The capsule at rest. It keeps `insetRem` from the edge on every side,
    // so the hit area around it is the footprint.
    ..write('$capsule { position: absolute; background-color: $thumbColorCss; ')
    ..write('border-radius: $radiusCss; ')
    ..write('transition: opacity $fade $easing, ')
    ..write('background-color $hover $easing, ')
    ..write('width $hover $easing, height $hover $easing, ')
    ..write('inset-inline-end $hover $easing, bottom $hover $easing; }')
    ..write('$thumb$vertical > $capsuleTag { top: $insetRem; ')
    ..write('bottom: $insetRem; inset-inline-end: $insetRem; ')
    ..write('width: $thicknessRem; }')
    ..write('$thumb$horizontal > $capsuleTag { ')
    ..write('inset-inline-start: $insetRem; inset-inline-end: $insetRem; ')
    ..write('bottom: $insetRem; height: $thicknessRem; }');

  // `auto` / `thin` rest invisible and appear on activity.
  if (fades) {
    css
      ..write('$track, $capsule { opacity: 0; }')
      ..write('$scope.$kScrollbarShownClass > .$kScrollbarLayerClass > ')
      ..write('$trackTag, ')
      ..write('$scope.$kScrollbarShownClass > .$kScrollbarLayerClass > ')
      ..write('$thumbTag > $capsuleTag { opacity: 1; }');
    if (interactive) {
      css
        ..write('$track:hover, $thumb:hover > $capsuleTag, ')
        ..write('$track:hover + $thumbTag > $capsuleTag { opacity: 1; }')
        // Its own rule: a browser without `:has()` drops this one rule and
        // nothing else. It only matters when the style gives the track a
        // colour.
        ..write('$track:has(+ $thumbTag:hover) { opacity: 1; }')
        ..write('$draggingV > $trackTag$vertical, ')
        ..write('$draggingV > $thumbTag$vertical > $capsuleTag, ')
        ..write('$draggingH > $trackTag$horizontal, ')
        ..write('$draggingH > $thumbTag$horizontal > $capsuleTag ')
        ..write('{ opacity: 1; }');
    }
  }

  // The hovered look: darker, thicker, and the inset narrows by what the
  // thickness grew so the capsule stays centred in the same footprint.
  if (interactive) {
    css
      ..write('$thumb$vertical:hover > $capsuleTag, ')
      ..write('$track$vertical:hover + $thumbTag$vertical > $capsuleTag, ')
      ..write('$draggingV > $thumbTag$vertical > $capsuleTag { ')
      ..write('background-color: $hoverThumbColorCss; ')
      ..write('inset-inline-end: $activeInsetRem; ')
      ..write('width: $activeThicknessRem; }')
      ..write('$thumb$horizontal:hover > $capsuleTag, ')
      ..write('$track$horizontal:hover + $thumbTag$horizontal > $capsuleTag, ')
      ..write('$draggingH > $thumbTag$horizontal > $capsuleTag { ')
      ..write('background-color: $hoverThumbColorCss; ')
      ..write('bottom: $activeInsetRem; ')
      ..write('height: $activeThicknessRem; }');
  }

  return css.toString();
}

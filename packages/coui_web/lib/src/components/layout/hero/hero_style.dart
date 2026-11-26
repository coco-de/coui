/// Paint-ready chrome and resolver for Web `HeroSection`.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `HeroSection`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="region">)         // outer hero container (positioning + flex centre)
///   ├─ overlay (<div>)               // co_hero_section renders only when overlayColor != null
///   └─ content (<div>)               // centred content wrapper (inline z-index, lifted above overlay)
/// ```
///
/// All slot chromes are non-null except [overlay], which is design-
/// optional — `null` when no `overlayColor` override is supplied (same
/// null-policy as `Card.footer`).
///
/// `co_hero_section.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in
/// the widget body.
class ResolvedHero implements WebResolvedChrome {
  /// Creates a [ResolvedHero].
  const ResolvedHero({
    required this.root,
    required this.content,
    required this.splitGapStyle,
    required this.splitTrack,
    required this.splitSlot,
    this.overlay,
    this.appearHidden,
    this.appearShown,
  });

  /// Paint-ready chrome for the outer hero container `<div>` —
  /// `relative flex items-center justify-center w-full` plus optional
  /// `bg-${surfaceContainer}` (when no inline background override),
  /// and inline `min-height` / `padding` plus optional
  /// `background-color` / `background-image` (when an `imageUrl` is
  /// supplied to the widget).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the centred content wrapper `<div>` —
  /// `relative` plus an inline z-index. On a split hero this wrapper
  /// stretches to the row's width.
  final WebElementChrome content;

  /// Gutter between copy and media. Raw [CoreGapStyle] forwarded to
  /// `Gap`.
  final CoreGapStyle splitGapStyle;

  /// Paint-ready chrome for the split pair. `flex-row` at the tablet
  /// tier and above, `flex-col` below — the same threshold as
  /// `ResponsiveRowColumn`. The widget mounts this only when its own
  /// [CoreHeroLayout] is split; the enum stays off this chrome record,
  /// the same way `ResolvedFooter` folds layout into class names.
  final WebElementChrome splitTrack;

  /// Paint-ready chrome for each cell of the split pair (`flex-1` on a
  /// row, `w-full` when stacked).
  final WebElementChrome splitSlot;

  /// Paint-ready chrome for the absolute overlay layer `<div>` —
  /// `absolute inset-0 pointer-events-none` plus inline
  /// `background-color`. `null` when no overlay colour is supplied.
  final WebElementChrome? overlay;

  /// Paint-ready chrome for the content before it has met the viewport.
  ///
  /// `null` when the caller did not opt into `appear`, so the content
  /// slot stays the static chrome a default hero has always shipped.
  /// Opacity, travel, and the transition shorthand live on
  /// [WebElementChrome.inlineStyles] — the widget swaps this slot for
  /// [appearShown] and does not assemble the CSS itself. `className` is
  /// empty: the entrance is inline-only.
  final WebElementChrome? appearHidden;

  /// Paint-ready chrome for the content after the entrance has started.
  /// Same null policy as [appearHidden].
  final WebElementChrome? appearShown;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedHero] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreHeroStyle.defaultX)
///   → theme.coreComponentTheme.heroSection.style
///   → widget.heroSectionStyle
/// ```
///
/// The `imageUrl` is widget-only (semantic content, not chrome) so the
/// resolver takes it as a parameter and folds it into the root's inline
/// styles.
ResolvedHero resolveHero(
  BuildContext context, {
  String? imageUrl,
  CoreHeroLayout? layout,
  bool appear = CoreHeroContract.defaultAppear,
  CoreHeroStyle? heroSectionStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.heroSection;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreHeroStyle(), [
    coreTheme?.style,
    heroSectionStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finishes its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final padding = merged.padding ?? CoreHeroStyle.defaultPadding;
  final minHeight = merged.minHeight ?? CoreHeroStyle.defaultMinHeight;
  final effectiveLayout =
      layout ?? merged.layout ?? CoreHeroStyle.defaultLayout;
  final splitIsRow = heroSplitIsRow(resolveBreakpoint(context).tier);
  final splitGapStyle = CoreHeroStyle.defaultSplitGapStyle.merge(
    merged.splitGapStyle,
  );

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Background routes through the emit family — the token default
  // (`surfaceContainer`) emits a `bg-{token}` Tailwind class (dark-mode
  // reactive, mirrors the Flutter resolver's `surfaceContainer`
  // fallback); a raw caller override goes inline. No `scheme.resolve`
  // (a no-op on Web) and no direct `cs.<token>` access.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CoreHeroStyle.defaultBackgroundColor,
    .background,
  );
  // Overlay colour — emitted only when supplied (no default; `null` ==
  // no overlay layer). The override is its own fallback so the emit
  // family routes a token override to a class and a raw one inline.
  final overlayColorValue = merged.overlayColor;
  final overlayEmit = overlayColorValue == null
      ? null
      : emitColor(overlayColorValue, overlayColorValue, .background);

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer hero container `<div>` Tailwind className —
  /// positioning + flex-centre layout + the background emit class (the
  /// `bg-{token}` class for a token default/override; empty for a raw
  /// inline override).
  String buildRootClassName() => [
    WebLayout.relative,
    WebLayout.flex,
    // Centre hugs the copy. Split stretches the pair across the row;
    // `flex-col` is the cross-axis so the track fills the width.
    if (effectiveLayout == CoreHeroLayout.center) ...[
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
    ] else
      WebLayout.flexCol,
    WebLayout.wFull,
    backgroundEmit.className,
    // Marks this panel as a component surface, so a material preset
    // reaches it. Its Flutter twin gets the same treatment by composing
    // `OutlinedContainer`. Gated on `imageUrl == null` — a picture hero
    // has nothing defined for a material to compose atop of (see the
    // Flutter resolver's `containerStyle` doc), so an image background
    // never carries the marker.
    if (imageUrl == null) ...webSurfaceMarkerFor(.content),
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the outer hero container `<div>` inline-CSS bundle —
  /// `min-height` / `padding`, any inline `background-color` fragment
  /// from the emit family (raw override only — token values stay on the
  /// class), plus the `background-image` cluster (when an [imageUrl] is
  /// supplied).
  Styles buildRootInlineStyles() {
    final raw = {
      'min-height': '${minHeight / kRemDivisor}rem',
      'padding': padding.toValue(),
      ...?backgroundEmit.inline,
    };
    if (imageUrl != null) {
      raw['background-image'] = 'url($imageUrl)';
      raw['background-size'] = 'cover';
      raw['background-position'] = 'center';
    } else {
      // The other half of the surface marker above — only published
      // when the marker is (`imageUrl == null`).
      raw.addAll(
        surfaceFillVar(
          merged.backgroundColor ?? CoreHeroStyle.defaultBackgroundColor,
        ),
      );
    }
    return Styles(raw: raw);
  }

  /// Composes the centred content wrapper `<div>` Tailwind className —
  /// `relative` only; the lift above the overlay layer is an inline
  /// `z-index` (see [buildContentInlineStyles]) because the value isn't
  /// a registered `zIndex` scale step and Tailwind has no CSS rule for
  /// an unregistered class suffix (arbitrary-value bracket syntax is
  /// blocked by the design-token guard — inline is the sanctioned exit).
  String buildContentClassName() => WebLayout.relative;

  /// Composes the centred content wrapper `<div>` inline-CSS bundle —
  /// `z-index: ${CoreZIndex.z0 + 1}` so the content sits above the
  /// overlay layer (local lift, not a page-level overlay — stays a
  /// magnitude below the first named `CoreZIndex` rung, `z10`=1010).
  Styles buildContentInlineStyles() =>
      const Styles(raw: {'z-index': '${CoreZIndex.z0 + 1}'});

  /// Composes the absolute overlay layer `<div>` Tailwind className —
  /// pointer-none passthrough overlay plus the overlay emit class (a
  /// `bg-{token}` class for a token override; empty for a raw inline
  /// override).
  String buildOverlayClassName() => [
    WebLayout.absolute,
    WebLayout.insetZero,
    WebLayout.pointerEventsNone,
    ?overlayEmit?.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the absolute overlay layer `<div>` inline-CSS bundle —
  /// any inline `background-color` fragment from the emit family (raw
  /// override only). Returns `null` when no inline fragment applies.
  Styles? buildOverlayInlineStyles() {
    final inline = overlayEmit?.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  // Entrance recipe. Built only when the caller opted in, so a static
  // hero's content styles are byte-for-byte the ones it had before.
  // The duration is a `--coui-duration-*` variable (via [durationMsCss])
  // rather than a millisecond literal: `prefers-reduced-motion` zeroes
  // that variable, which is the web half of `resolveMotionDuration`.
  // Resolving the preference in Dart would disagree with the server,
  // which cannot see the media query.
  // Emitted as chrome slots (RULE C) — paint-ready CSS lives on
  // `inlineStyles`, not as bare `Styles?` on ResolvedHero.
  WebElementChrome? appearHidden;
  WebElementChrome? appearShown;
  if (appear) {
    final duration =
        merged.appearDuration ?? CoreHeroStyle.defaultAppearDuration;
    final curve = merged.appearCurve ?? CoreHeroStyle.defaultAppearCurve;
    final offset = merged.appearOffset ?? CoreHeroStyle.defaultAppearOffset;
    final timing =
        '${durationMsCss(duration.inMilliseconds)} ${curve.toVarCss()}';
    final transition = 'opacity $timing, transform $timing';
    final travel = 'translateY(${offset / kRemDivisor}rem)';
    appearHidden = WebElementChrome(
      className: '',
      inlineStyles: Styles(
        raw: {
          'opacity': '0',
          'transform': travel,
          'transition': transition,
          'pointer-events': 'none',
        },
      ),
    );
    appearShown = WebElementChrome(
      className: '',
      inlineStyles: Styles(
        raw: {
          'opacity': '1',
          'transform': 'none',
          'transition': transition,
          'pointer-events': 'auto',
        },
      ),
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final splitTrackClass = splitIsRow
      ? '${WebLayout.flexRowItemsCenterFull} ${WebLayout.minWZero}'
      : WebLayout.flexColFull;
  final splitSlotClass = splitIsRow
      ? '${WebLayout.flex1} ${WebLayout.minWZero}'
      : WebLayout.wFull;

  return ResolvedHero(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    content: WebElementChrome(
      className: effectiveLayout == CoreHeroLayout.center
          ? buildContentClassName()
          : '${buildContentClassName()} ${WebLayout.wFull}',
      inlineStyles: buildContentInlineStyles(),
    ),
    splitGapStyle: splitGapStyle,
    splitTrack: WebElementChrome(className: splitTrackClass),
    splitSlot: WebElementChrome(className: splitSlotClass),
    overlay: overlayEmit == null
        ? null
        : WebElementChrome(
            className: buildOverlayClassName(),
            inlineStyles: buildOverlayInlineStyles(),
          ),
    appearHidden: appearHidden,
    appearShown: appearShown,
  );
}

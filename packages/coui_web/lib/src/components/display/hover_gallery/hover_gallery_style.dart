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

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `HoverGallery`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                            // outer container, relative + overflow-hidden
///   └─ layer (<div>)                      // per-image, absolute fill; co_hover_gallery picks layerActive vs layerIdle by `i == activeIndex`
///        └─ image (<img>)                 // co_hover_gallery renders only when imageUrls supplied; otherwise caller itemBuilder output
/// ```
///
/// `co_hover_gallery.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in
/// the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 4 — runtime state variants ([layerActive] / [layerIdle]) for
///   the same DOM slot, switched on by widget state (`i == activeIndex`).
///
/// No scalar metadata (height / borderRadius / duration) is exposed —
/// all derived values are folded into the slot chromes here.
class ResolvedHoverGallery implements WebResolvedChrome {
  /// Creates a [ResolvedHoverGallery].
  const ResolvedHoverGallery({
    required this.root,
    required this.image,
    required this.layerActive,
    required this.layerIdle,
  });

  /// Paint-ready chrome for the outer container `<div>` element.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the inner `<img>` element — reused across
  /// every image layer that renders via the `imageUrls` path (the `fit`
  /// value is captured once at resolve time).
  final WebElementChrome image;

  /// Paint-ready chrome for an active crossfade layer `<div>` —
  /// `opacity: 1` plus the opacity transition rule (duration baked in
  /// at resolve time).
  final WebElementChrome layerActive;

  /// Paint-ready chrome for an idle crossfade layer `<div>` — same
  /// shape as [layerActive] with `opacity: 0`.
  final WebElementChrome layerIdle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedHoverGallery] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.hoverGallery.style
///   → widget.hoverGalleryStyle
/// ```
ResolvedHoverGallery resolveHoverGallery(
  BuildContext context, {
  CoreHoverGalleryStyle? hoverGalleryStyle,
  String? fit,
}) {
  final hgTheme = context.theme.coreComponentTheme?.hoverGallery;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreHoverGalleryStyle(), [
    hgTheme?.style,
    hoverGalleryStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final heightPx = merged.height ?? CoreHoverGalleryStyle.defaultHeight;
  final borderRadius =
      merged.borderRadius ?? CoreHoverGalleryStyle.defaultBorderRadius;
  final animationDurationMs =
      (merged.animationDuration ??
              CoreHoverGalleryStyle.defaultAnimationDuration)
          .inMilliseconds;
  final effectiveFit = fit ?? 'cover';
  // Token-routed (`--coui-duration-*` / `--easing-ease`) rather than raw
  // `${ms}ms`/`ease` literals — see `durationMsCss` doc.
  final transitionRule =
      'opacity ${durationMsCss(animationDurationMs)} '
      'var(--easing-${CoreEasing.scale.ease})';

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the outer container `<div>` Tailwind className —
  /// structural rules (relative position, full width, overflow clip)
  /// that never vary by caller override.
  String buildRootClassName() =>
      '${WebLayout.relative} ${WebLayout.wFull} ${WebLayout.overflowHidden}';

  /// Composes the outer container `<div>` inline-CSS bundle — fixed
  /// height (logical px → rem) and border-radius (caller-overridable).
  Styles buildRootInlineStyles() => .new(
    raw: {
      'height': '${heightPx / kRemDivisor}rem',
      'border-radius': borderRadius.toValue(),
    },
  );

  /// Composes the inner `<img>` element Tailwind className — structural
  /// rules (fill layer, block display, no UA margin) that never vary by
  /// caller override.
  String buildImageClassName() =>
      '${WebLayout.block} ${WebLayout.wFull} ${WebLayout.hFull} m-0';

  /// Composes the inner `<img>` element inline-CSS bundle — only the
  /// caller-driven `object-fit` rule (others are className-driven).
  Styles buildImageInlineStyles() => .new(
    raw: {'object-fit': effectiveFit},
  );

  /// Composes a layer `<div>` Tailwind className — absolute fill (the
  /// only structural rules; opacity + transition live in inline CSS).
  String buildLayerClassName() => WebLayout.absoluteFull;

  /// Composes a layer `<div>` inline-CSS bundle — per-state `opacity`
  /// and the shared opacity transition (duration baked at resolve time).
  Styles buildLayerInlineStyles({required bool isActive}) => .new(
    raw: {
      'opacity': isActive ? '1' : '0',
      'transition': transitionRule,
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedHoverGallery(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    image: WebElementChrome(
      className: buildImageClassName(),
      inlineStyles: buildImageInlineStyles(),
    ),
    layerActive: WebElementChrome(
      className: buildLayerClassName(),
      inlineStyles: buildLayerInlineStyles(isActive: true),
    ),
    layerIdle: WebElementChrome(
      className: buildLayerClassName(),
      inlineStyles: buildLayerInlineStyles(isActive: false),
    ),
  );
}

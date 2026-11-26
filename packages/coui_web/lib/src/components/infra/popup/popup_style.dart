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

/// Paint-ready chrome for Web `Popup`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="menu" flex flex-{col|row}>)   // bordered floating panel
///   └─ caller children                            // entries / dividers / etc.
/// ```
///
/// `co_popup.dart` reads `resolved.root.className` + `resolved.root
/// .inlineStyles` straight off — no merge / fallback / conversion in
/// the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots forwarded to dependent
///   resolvers. [style] is the fully-merged [CorePopupStyle] (every
///   field non-null after default fallback) — `resolveDropdownMenu`
///   / `resolveMenubar` / `resolveNavigationMenu` consume it so
///   panel-derived chrome (divider width, etc.) stays in lock-step
///   with the popup's resolved values without re-running the merge
///   chain.
class ResolvedPopup implements WebResolvedChrome {
  /// Creates a [ResolvedPopup].
  const ResolvedPopup({required this.root, required this.style});

  /// Paint-ready chrome for the outer `<div role="menu">` panel
  /// container — axis-aware flex layout + the full inline panel chrome
  /// (background / border / radius / shadow / padding / min-width).
  @override
  final WebElementChrome root;

  /// Fully-merged [CorePopupStyle] — every field non-null after the
  /// design-system default fallback. Forwarded to dependent panel-style
  /// resolvers so they can derive matching chrome (e.g. divider border
  /// width = panel border width) without re-running the merge chain.
  final CorePopupStyle style;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedPopup] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CorePopupStyle.defaultX)
///   → theme.coreComponentTheme.popup.style
///   → widget.popupStyle
/// ```
ResolvedPopup resolvePopup(
  BuildContext context, {
  required CoreAxis direction,
  CorePopupStyle? popupStyle,
}) {
  final popupTheme = context.theme.coreComponentTheme?.popup;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CorePopupStyle(), [
    popupTheme?.style,
    popupStyle,
  ]);

  // ─── Stage 1 RESOLVE — settle each value to its Core type ──
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final padding = merged.padding ?? CorePopupStyle.defaultPadding;
  final borderRadius =
      merged.borderRadius ?? CorePopupStyle.defaultBorderRadius;
  final borderWidth = merged.borderWidth ?? CorePopupStyle.defaultBorderWidth;
  final backgroundColor =
      merged.backgroundColor ?? CorePopupStyle.defaultBackgroundColor;
  final borderColor = merged.borderColor ?? CorePopupStyle.defaultBorderColor;
  final boxShadow = merged.boxShadow ?? CorePopupStyle.defaultBoxShadow;
  final minWidth = merged.minWidth ?? CorePopupStyle.defaultMinWidth;
  final maxWidth = merged.maxWidth ?? CorePopupStyle.defaultMaxWidth;
  final spacing = merged.spacing ?? CorePopupStyle.defaultSpacing;
  final contentColor =
      merged.contentColor ?? CorePopupStyle.defaultContentColor;

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // Colours route through the emit family — token defaults emit a
  // Tailwind class (dark-mode reactive), raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web; CSS resolves tokens at runtime).
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CorePopupStyle.defaultBackgroundColor,
    .background,
  );
  final borderEmit = emitColor(
    merged.borderColor,
    CorePopupStyle.defaultBorderColor,
    .border,
  );
  // Ambient content text colour — `text-{token}` class on the panel root
  // so `Text` descendants inherit it (raw override goes inline `color`).
  final contentEmit = emitColor(
    merged.contentColor,
    CorePopupStyle.defaultContentColor,
    .text,
  );
  // Shadow base — `.toValue()` emits `rgb(var(--coui-on-surface))` for
  // the token default / `rgb(...)` for a raw override. No
  // `scheme.resolve` (Web no-op).
  final shadowBase =
      (merged.shadowBaseColor ?? CorePopupStyle.defaultShadowBaseColor)
          .toValue();
  // The rim rides beside the cast in one `box-shadow` list. Panels opt
  // in by naming the variable; controls do not, which is what keeps a
  // surface treatment off a toggle knob.
  final boxShadowValue =
      '${emitShadow(boxShadow, base: shadowBase)}, $kSurfaceRimVar';
  // Logical longhands for an inset stated by the reading direction (start /
  // end); the one-line shorthand for a symmetric one — every panel's default.
  //
  // The padding is measured from the panel's outer edge, the border included
  // (Flutter's `DecoratedBox` paints the border over it), so a drawn border
  // comes out of the padding rather than adding to the box.
  //
  // The border is the one the panel actually keeps: a material that draws its
  // own edge folds it away (`kWebSurfaceEdgeStyleVar`), and the padding —
  // measured from the outer edge — then comes out of nothing.
  final paddingDeclarations = borderWidth > 0
      ? padding.toDeclarationsWithinBorder(
          'padding',
          surfaceClipKeptBorder(strokeWidthCss(borderWidth)),
        )
      : padding.toLogicalDeclarations('padding');
  final borderRadiusValue = borderRadius.toValue();

  // Fully-filled style forwarded to dependent resolvers (Cat 2) — every
  // field non-null after the default fallback, including the enter / exit
  // animation durations the menu family reads for its portal motion.
  final resolvedStyle = CorePopupStyle(
    surfaceStyle: merged.surfaceStyle,
    padding: padding,
    borderRadius: borderRadius,
    borderWidth: borderWidth,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    boxShadow: boxShadow,
    minWidth: minWidth,
    maxWidth: maxWidth,
    spacing: spacing,
    contentColor: contentColor,
    openAnimationDuration:
        merged.openAnimationDuration ??
        CorePopupStyle.defaultOpenAnimationDuration,
    closeAnimationDuration:
        merged.closeAnimationDuration ??
        CorePopupStyle.defaultCloseAnimationDuration,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the panel `<div role="menu">` Tailwind className — flex
  /// container along [direction], clipping children to the panel
  /// radius, plus the colour token classes from the emit family
  /// (suppressed when the caller passed a raw override → inline).
  String buildRootClassName() {
    final dir = direction == .vertical ? WebLayout.flexCol : WebLayout.flexRow;
    return <String>[
      // Surface hook (#3464) — a floating anchored panel is a surface
      // by the same reasoning `Dialog`/`Tooltip` already carry the
      // marker for: it has its own background/border/shadow chrome, and
      // there is no principled reason a dialog gets a material preset
      // while the popover it can open on top of does not.
      ...webSurfaceMarkerFor(
        CoreSurfaceRole.functional,
        surfaceStyle: merged.surfaceStyle,
      ),
      WebLayout.flex,
      dir,
      WebLayout.overflowHidden,
      // The panel clips its content and keeps a border — a material that draws
      // its own edge reaches its band over that line (`kWebSurfaceClipMarker`).
      if (borderWidth > 0) kWebSurfaceClipMarker,
      // A panel that states a width band takes its content's width inside it,
      // as Flutter's `ConstrainedBox(min, max)` does: `flex` is block-level,
      // so without this a standalone panel fills whatever it sits in, up to
      // the band's top. One with no ceiling states no band to land in — it
      // fills, the way an anchored panel sized by its host needs.
      if (maxWidth.isFinite) 'w-fit',
      if (backgroundEmit.className.isNotEmpty) backgroundEmit.className,
      if (borderEmit.className.isNotEmpty) borderEmit.className,
      if (contentEmit.className.isNotEmpty) contentEmit.className,
    ].join(' ');
  }

  /// Composes the panel `<div role="menu">` inline-CSS bundle — chrome
  /// not expressible as a token class (border / radius / shadow /
  /// padding / min-width) plus any raw colour overrides from the emit
  /// family.
  Styles buildRootInlineStyles() {
    return Styles(
      raw: {
        'border-style': 'solid',
        'border-width': strokeWidthCss(borderWidth),
        // Stated after the plain style: the hook falls back to the same
        // `solid`.
        if (borderWidth > 0) ...surfaceClipFold(strokeWidthCss(borderWidth)),
        'border-radius': borderRadiusValue,
        'box-shadow': boxShadowValue,
        ...paddingDeclarations,
        'min-width': '${minWidth / kRemDivisor}rem',
        // Unbounded stays unset — `max-width: Infinityrem` is not CSS.
        if (maxWidth.isFinite) 'max-width': '${maxWidth / kRemDivisor}rem',
        'gap': spaceCss(spacing),
        ...?backgroundEmit.inline,
        ...?borderEmit.inline,
        ...?contentEmit.inline,
        // Publish the fill this surface chose (#3464) — pairs with
        // the surface marker above so a material preset can restate it
        // at a different alpha without knowing which token that was
        // (mirrors `outlined_container`/`card`; see
        // `check_surface_fill_contract.sh`, which enforces the pairing).
        ...surfaceFillVar(backgroundColor),
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedPopup(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    style: resolvedStyle,
  );
}

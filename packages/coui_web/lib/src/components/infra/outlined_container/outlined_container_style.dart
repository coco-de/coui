import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/dashed_overlay.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `OutlinedContainer`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)              // single chrome wrapper (border / radius / fill / shadow / blur)
///   └─ child                // caller-supplied content
/// ```
///
/// `root` carries the full Tailwind className (border style + elevation
/// + default surface / outline-variant colour token classes when no
/// per-instance colour override) plus the inline-CSS bundle for the
/// always-inline radius / padding / size and the per-instance colour /
/// border-width / blur / overflow / transition overrides. A stated
/// `backgroundGradient` is painted as an inline `background-image` in place
/// of the surface colour (class XOR inline: the `bg-*` class and the inline
/// `background-color` are dropped). All chrome is
/// pre-composed by [resolveOutlinedContainer] so `co_outlined_container`
/// reads `resolved.root.*` straight back into `Component.element(...)`.
class ResolvedOutlinedContainer implements WebResolvedChrome {
  /// Creates a [ResolvedOutlinedContainer].
  const ResolvedOutlinedContainer({
    required this.root,
    required this.dashOverlay,
    required this.dashRect,
  });

  /// Paint-ready chrome for the outer `<div>` — full Tailwind className
  /// plus the inline-CSS bundle rolled into a single [WebElementChrome]
  /// pair (composed by the closure-local builders inside
  /// [resolveOutlinedContainer]) so the widget's `build` can pass it
  /// straight to `Component.element(...)`.
  @override
  final WebElementChrome root;

  /// Dashed/dotted-border `<svg>` overlay — carries the border colour
  /// as a text-colour class or inline `color` (the `<rect>` strokes
  /// with `currentColor`); the container's arbitrary child keeps its
  /// own inherited colour. `null` when the border style isn't dashed
  /// or dotted — the widget mounts the overlay only when non-null
  /// (folds the old separate `dashPatterned` bool into this slot's own
  /// nullness).
  final WebElementChrome? dashOverlay;

  /// The overlay's `<rect>` — geometry / stroke pattern as CSS
  /// properties (shared `dashed_overlay.dart` chrome). `null` alongside
  /// [dashOverlay].
  final WebElementChrome? dashRect;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedOutlinedContainer] for the given [context].
///
/// Walks the nested-merge chain (Epic #1302):
///
/// ```text
/// design system default
///   → theme.outlinedContainer.style
///   → widget.containerStyle
/// ```
///
/// The closure-local `buildRootClassName` / `buildRootInlineStyles`
/// builders compose the root chrome once at the resolver entry point
/// and store the result on `resolved.root`. The widget reads
/// `resolved.root.*` straight back into `Component.element(...)`.
ResolvedOutlinedContainer resolveOutlinedContainer({
  required BuildContext context,
  CoreOutlinedContainerStyle? containerStyle,
  CoreSurfaceRole role = .defaultRole,
}) {
  final outlinedTheme = context.theme.coreComponentTheme?.outlinedContainer;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreOutlinedContainerStyle(), [
    outlinedTheme?.style,
    containerStyle,
  ]);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Background / border colours route through `CoreOutlinedContainerStyle
  // .defaultXxx` (single source — no `cs.surface` / `cs.outlineVariant`)
  // and through the emit family — a single class-XOR-inline decision per
  // colour. Token-bound values (the surface / outline-variant defaults
  // AND token overrides) emit Tailwind classes so they stay dark-mode
  // reactive; raw overrides go inline. No `scheme.resolve` (a no-op on
  // Web — CSS resolves tokens at runtime).
  //
  // `surfaceOpacity` multiplies into the background alpha — applied on
  // the CoreColor (preserving the token) before emit, so a token
  // background still emits a `bg-surface/60` class and a raw background
  // emits inline `rgb(... / a)`.
  //
  // The flat material the theme states (`ThemeData.surfaceBlur` /
  // `surfaceOpacity`) is the *surrounding* material's. A surface that names
  // its own `surfaceStyle` draws that preset's material instead — the Flutter
  // twin replaces the flat fields with the named preset's own values for the
  // same reason — so it has no flat material to fall back to. Reading the
  // theme's here would let an app-wide translucency leak into a card that
  // asked to be opaque.
  final material = merged.surfaceStyle == null ? context.theme : null;
  final surfaceOpacity = merged.surfaceOpacity ?? material?.surfaceOpacity;
  final backgroundToken =
      merged.backgroundColor ??
      CoreOutlinedContainerStyle.defaultBackgroundColor;
  final backgroundColor = surfaceOpacity == null
      ? backgroundToken
      : backgroundToken.scaleAlpha(surfaceOpacity);
  final backgroundEmit = emitColor(
    backgroundColor,
    backgroundColor,
    .background,
  );
  // A gradient fill is painted INSTEAD of the colour — one property carries
  // the surface, so the colour's class and inline fragment are dropped
  // rather than left under the image where a translucent stop would show
  // them. Same opacity rule as the colour: every stop's alpha is scaled, so
  // a surface that is translucent is translucent along its whole gradient.
  // `null` (the contract default) leaves the solid path untouched for every
  // component that does not state one.
  final backgroundGradient = merged.backgroundGradient == null
      ? null
      : _scaleGradientAlpha(merged.backgroundGradient!, surfaceOpacity);

  final borderStyle =
      merged.borderStyle ?? CoreOutlinedContainerStyle.defaultBorderStyle;
  // Dashed/dotted borders render through the SVG overlay — the CSS
  // `border-style` pattern is engine-defined (differs per browser) and
  // untunable, while the overlay carries the Core dash tokens.
  final dashPatterned = borderStyle == .dashed || borderStyle == .dotted;
  final dashLength =
      merged.dashLength ?? CoreOutlinedContainerStyle.defaultDashLength;
  final dashSpacing =
      merged.dashSpacing ?? CoreOutlinedContainerStyle.defaultDashSpacing;
  // Border colour — routed through the default `outline-variant` token
  // unless overridden. Skipped entirely when the border is suppressed
  // (`borderStyle == none`).
  final borderColor =
      merged.borderColor ?? CoreOutlinedContainerStyle.defaultBorderColor;
  final borderEmit = borderStyle == .none
      ? null
      : emitColor(borderColor, borderColor, .border);

  // Border radius is **always** emitted inline (`(merged ?? default)
  // .toValue()`) — no Tailwind radius utility class. Default and override
  // share this one CSS surface so the resolved chrome reflects
  // `merged.borderRadius` directly (Epic #1603 signature / chaining gate
  // — radius is always-inline, never a class-drop).
  final borderRadius =
      (merged.borderRadius ?? CoreOutlinedContainerStyle.defaultBorderRadius)
          .toValue();
  // Preserve all four sides and the authored physical/logical direction.
  // A null padding is omitted; the default is zero.
  final padding = merged.padding;
  final elevation =
      merged.elevation ?? CoreOutlinedContainerStyle.defaultElevation;
  // An explicit stack replaces the elevation preset rather than layering
  // over it — a hard offset shadow arriving with the preset's soft blur
  // still underneath would only ever approximate what the caller asked
  // for. Class and inline are mutually exclusive for the same reason any
  // emit is: an inline `box-shadow` would win on specificity and leave a
  // `shadow-*` class claiming something untrue.
  final explicitShadow = merged.boxShadow;
  // Theme-free, like every Web emit: a token name goes out and the browser
  // resolves it at runtime (`--coui-shadow` by default), so dark mode follows
  // without this resolver knowing a scheme exists. A raw base goes out as the
  // literal colour it is, and the stack with it — no `--shadow-*` variable
  // carries a pinned tint, so a surface style's shadow geometry does not reach
  // it on this platform.
  final shadowBase =
      (merged.shadowBaseColor ??
              CoreOutlinedContainerStyle.defaultShadowBaseColor)
          .toValue();
  final clipBehavior =
      merged.clipBehavior ?? CoreOutlinedContainerStyle.defaultClipBehavior;
  final durationMs =
      (merged.duration ?? CoreOutlinedContainerStyle.defaultDuration)
          .inMilliseconds;
  // When the resolved border colour is fully transparent the border is
  // invisible — collapse its width to 0 so it doesn't eat the child's
  // layout. Mirrors the Flutter resolver (`Border.all` insets the box by
  // `width` even when alpha == 0).
  //
  // Judged on the emitted colour alone. `CoreColor.isTransparent` on this
  // platform means "carries no token" (no Tailwind class exists for it), so
  // it is true of every raw colour and would collapse a raw hardware rim that
  // is perfectly opaque.
  final preserveBorder =
      merged.preserveTransparentBorder ??
      CoreOutlinedContainerStyle.defaultPreserveTransparentBorder;
  final transparentBorder =
      !preserveBorder && _isCssColorTransparent(borderColor.toValue());
  // `none` must also defeat the inline width; otherwise it overrides the
  // `border-0` class, drawing a default-color line and insetting the child.
  final borderWidth = transparentBorder || borderStyle == .none
      ? 0.0
      : (merged.borderWidth ?? CoreOutlinedContainerStyle.defaultBorderWidth);
  // A surface that clips its own content and keeps a border says so, so a
  // material that draws its own edge can fold that border into the padding and
  // reach its band over the line (see `kWebSurfaceClipMarker`). A
  // dash-patterned border is the SVG overlay's, not a CSS one: it is drawn at
  // the padding box, so folding the spacer it may reserve would move the dashes
  // outward with it. It says nothing, and its band stays where it was.
  final clipsOverBorder =
      clipBehavior != .none && borderWidth > 0 && !dashPatterned;
  final surfaceBlur = merged.surfaceBlur ?? material?.surfaceBlur;
  final width = merged.width;
  final height = merged.height;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<div>` Tailwind className — border style +
  /// elevation + the emit-family colour classes (token-bound surface /
  /// border colours emit `bg-*` / `border-*` classes; raw overrides
  /// contribute nothing here and emit inline instead).
  String buildRootClassName() {
    final classList = [
      // Marks this element as a component surface. Carries no styling of
      // its own; it exists so a style whose boundary is shadow alone can
      // be given a real stroke under forced colours, where shadow is not
      // painted and the boundary would otherwise be gone. Without a stable
      // hook that correction would have to be authored per component.
      //
      // A `surfaceStyle` swaps the document-scoped marker for the local one,
      // which the stylesheet reads as that preset's material and nothing
      // else's — the surrounding preset's rules stop matching this element.
      ...webSurfaceMarkerFor(role, surfaceStyle: merged.surfaceStyle),
      if (clipsOverBorder) kWebSurfaceClipMarker,
      // Border style — Tailwind class for solid/dashed/dotted; `none`
      // is expressed via `border-0` to drop the stroke entirely.
      switch (borderStyle) {
        .solid => 'border',
        // Dash-patterned borders render through the SVG overlay — the
        // root only anchors it.
        .dashed || .dotted => WebLayout.relative,
        .none => 'border-0',
      },
      // Elevation is no longer a class (#3463) — `box-shadow` is always
      // inline now, so a style's rim has a layer to ride beside. See
      // `buildRootInlineStyles`.
      // Surface fill — emit-family class (token → `bg-{token}`; raw →
      // empty here, inline below). A gradient fill replaces it.
      if (backgroundGradient == null) backgroundEmit.className,
      // Border colour — emit-family class (token → `border-{token}`; raw →
      // empty here, inline below). `null` when `borderStyle == none`.
      if (!dashPatterned) ?borderEmit?.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the outer `<div>` inline CSS — always-inline radius /
  /// padding / size plus the per-instance colour / border-width / blur /
  /// overflow / transition overrides.
  Styles buildRootInlineStyles() {
    // An inline minimum is intentional: a generated utility may be absent
    // from the consuming app's Tailwind build. Keep overflow independent.
    final raw = <String, String>{'min-width': '0'};

    // Border width — `(merged ?? default)` always-inline (rem),
    // collapsed to 0 for a transparent border above.
    if (!dashPatterned || preserveBorder) {
      raw['border-width'] = strokeWidthCss(borderWidth);
    }
    // A surface that clips its content states its border style through the
    // variable a material that draws its own edge folds the border away with.
    if (clipsOverBorder) {
      raw.addAll(surfaceClipFold(strokeWidthCss(borderWidth)));
    }
    // Patterned strokes are painted by the SVG overlay. Reserve their inset
    // only for opt-in callers, without drawing a second CSS border.
    if (dashPatterned && preserveBorder) {
      raw['border-style'] = 'solid';
      raw['border-color'] = 'transparent';
    }
    // Border / background colours — emit-family inline fragments (raw
    // overrides only; token values stay on the classes built above, so a
    // token surface / outline-variant default contributes nothing here).
    final backgroundInline = backgroundEmit.inline;
    if (backgroundGradient != null) {
      raw['background-image'] = backgroundGradient.toValue();
      // The gradient spans the whole border box, the way the fill of the
      // Flutter twin does, instead of the padding box CSS sizes a
      // background image to by default (which would repeat it under the
      // border).
      raw['background-origin'] = 'border-box';
    } else if (backgroundInline != null) {
      raw.addAll(backgroundInline);
    }
    final borderInline = borderEmit?.inline;
    if (borderInline != null && !dashPatterned) {
      raw.addAll(borderInline);
    }
    // Border radius is always inline — `(merged ?? default).toValue()`
    // composed above. The CSS shorthand preserves all four corners.
    raw['border-radius'] = borderRadius;
    // Padding — always inline when set (`null` = no padding).
    if (padding != null && clipsOverBorder) {
      // Adds what a folded border gives up, so the content stays put.
      raw.addAll(padding.toDeclarationsWithClipPad('padding'));
    } else if (padding != null) {
      if (!padding.isDirectional &&
          padding.top == padding.right &&
          padding.top == padding.bottom &&
          padding.top == padding.left) {
        // Keep the existing uniform representation for unchanged callers.
        raw['padding'] = spaceCss(padding.top);
      } else {
        raw.addAll(padding.toLogicalDeclarations('padding'));
      }
    }
    // Explicit size — always-inline rem when set.
    if (width != null) {
      raw['width'] = '${width / kRemDivisor}rem';
    }
    if (height != null) {
      raw['height'] = '${height / kRemDivisor}rem';
    }
    // Surface blur — Tailwind has `backdrop-blur-{sm/md/...}` but the
    // contract uses an arbitrary sigma double, so emit inline CSS for
    // exact parity with Flutter `BackdropFilter`.
    if (surfaceBlur != null && surfaceBlur > 0) {
      raw['backdrop-filter'] = 'blur(${surfaceBlur}px)';
    }
    // Publish the fill this surface chose, so a style preset can restate
    // it at a different alpha without knowing which token that was — a
    // card fills with `surface`, a popover with `popover`. Setting a
    // custom property draws nothing on its own. A gradient is not one fill a
    // preset could restate, so a surface that states one publishes none.
    if (backgroundGradient == null) raw.addAll(surfaceFillVar(backgroundColor));
    // Box shadow — always inline now (#3463), never the `shadow-*`
    // elevation class it used to be, so a claymorphism rim has a layer to
    // ride beside whichever path set the shadow.
    //
    // The authored layer is either the caller's explicit stack (arbitrary
    // offsets/blur, no Tailwind class exists for that) or the elevation
    // preset restated as the same `var(--shadow-*)` reference the class
    // used to carry — `theme_config.dart`'s `_boxShadowConfig` points
    // `shadow-sm`/`md`/`lg` straight at those variables, so this is the
    // same value through a different door, not a new one.
    //
    // The rim rides only that authored layer. A rim decorates a surface
    // that casts its own shadow; it does not raise a flat one — the gate
    // the Flutter twin keys `resolveSurfaceRim` on (the authored stack) and
    // the one `Card` already keeps here (the rim only beside a lift). A flat
    // container used to name it anyway and was lit under claymorphism on
    // this platform alone.
    //
    // A style that pins its stack's alpha (`shadowStrengthens: false`)
    // leaves `--coui-shadow-strength` out of each layer's colour, so the dark
    // scope draws it as the light one does — the Flutter twin bends the same
    // stack with the brightness put back to light. The `--shadow-*` variables
    // carry the strength inside them, so a pinned stack is written as its
    // literal layers.
    final strengthens =
        merged.shadowStrengthens ??
        CoreOutlinedContainerStyle.defaultShadowStrengthens;
    final authoredShadow = explicitShadow != null
        ? (explicitShadow.isEmpty
              ? null
              : emitShadow(
                  explicitShadow,
                  base: shadowBase,
                  strengthens: strengthens,
                ))
        : switch (elevation) {
            .none => null,
            // The preset's stack through `emitShadow`: the `--shadow-*`
            // variable for the default base — the reference the class used
            // to carry — and the literal layers for a pinned one.
            .soft || .medium || .strong => emitShadow(
              elevation.layers,
              base: shadowBase,
              strengthens: strengthens,
            ),
          };
    raw['box-shadow'] = switch ((authoredShadow, explicitShadow)) {
      (final String cast, _) => '$cast, $kSurfaceRimVar',
      // Rest elevation takes the style's injected cast, the same way Button
      // does. `kControlShadowVar` resolves to nothing under every style
      // except neo-brutalism, whose `controlShadow` boxes surfaces as well
      // as controls — so this costs other styles nothing and stops the
      // Flutter twin from being the only platform that draws it.
      (null, null) => kControlShadowVar,
      // An explicitly empty stack is left empty, as the Flutter twin leaves
      // it — "no shadow" is a thing a caller can ask for.
      (null, _) => 'none',
    };
    // Clip behavior — CSS `overflow`.
    raw['overflow'] = switch (clipBehavior) {
      .none => 'visible',
      // Web has no native antialiased clip — both fall back to hidden.
      .hardEdge || .antiAlias || .antiAliasWithSaveLayer => WebLayout.hidden,
    };
    // Transitions — only meaningful when caller asked for one. Token-routed
    // duration + easing (`durationMsCss` / `toVarCss` docs).
    if (durationMs > 0) {
      final d = durationMsCss(durationMs);
      final e = CoreEasing.move.toVarCss();
      raw['transition'] = <String>[
        'background-color $d $e',
        'border-color $d $e',
        'border-width $d $e',
        'border-radius $d $e',
        'box-shadow $d $e',
        'width $d $e',
        'height $d $e',
      ].join(', ');
    }

    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  // Dash overlay colour — the same resolved border colour re-emitted
  // through the `.text` target (token → `text-*` class, raw → inline
  // `color`), riding the `<svg>` so the `<rect>`'s `currentColor`
  // stroke picks it up without touching the host's own colour.
  final dashTextEmit = dashPatterned
      ? emitColor(borderColor, borderColor, .text)
      : null;
  final dashOverlayClassName = [
    dashedOverlaySvgClassName(),
    ?dashTextEmit?.className,
  ].where((cls) => cls.isNotEmpty).join(' ');
  final dashTextInline = dashTextEmit?.inline;
  final dashOverlayStyles = dashTextInline == null
      ? dashedOverlaySvgStyles()
      : Styles.combine([dashedOverlaySvgStyles(), Styles(raw: dashTextInline)]);

  return ResolvedOutlinedContainer(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    dashOverlay: dashPatterned
        ? WebElementChrome(
            className: dashOverlayClassName,
            inlineStyles: dashOverlayStyles,
          )
        : null,
    dashRect: dashPatterned
        ? WebElementChrome(
            className: '',
            inlineStyles: dashedOverlayRectStyles(
              // Same value as the solid-border path above
              // (`strokeWidthCss(borderWidth)` at the `border-width`
              // emit) — a dashed border is still stroke-axis-bound, so
              // it must ride the same `--coui-stroke-width-N` variable
              // rather than a literal the neo-brutalism `strokeFloor`
              // preset can't reach.
              strokeWidth: strokeWidthCss(borderWidth),
              dashLength: dashLength,
              dashGap: dashSpacing,
              radius:
                  (merged.borderRadius ??
                          CoreOutlinedContainerStyle.defaultBorderRadius)
                      .topLeft,
              dotted: borderStyle == .dotted,
            ),
          )
        : null,
  );
}

/// [gradient] with every stop's alpha multiplied by [opacity] — the gradient
/// counterpart of `CoreColor.scaleAlpha` on a solid fill. `null` opacity
/// returns the gradient unchanged.
CoreGradient _scaleGradientAlpha(CoreGradient gradient, double? opacity) {
  if (opacity == null) return gradient;

  return CoreGradient(
    type: gradient.type,
    colors: [for (final stop in gradient.colors) stop.scaleAlpha(opacity)],
    stops: gradient.stops,
    begin: gradient.begin,
    end: gradient.end,
  );
}

/// Returns `true` when [css] is a fully-transparent CSS colour. Covers
/// the explicit `transparent` keyword and rgb()/rgba()/hsl() forms with
/// alpha == 0 so callers don't have to round-trip through a Color
/// abstraction.
bool _isCssColorTransparent(String css) {
  final trimmed = css.trim().toLowerCase();
  if (trimmed == 'transparent') return true;
  // Match `rgba(... / 0)` or `rgba(..., 0)` and `hsla(... / 0)`.
  final alphaSlash = RegExp(r'/\s*0(?:\.0+)?%?\s*\)');
  if (alphaSlash.hasMatch(trimmed)) return true;
  // A comma-form alpha is the FOURTH channel. Matching only the last
  // comma also mistook an opaque rgb(r, g, 0) blue channel for alpha.
  final alphaComma = RegExp(
    r'^(?:rgba?|hsla?)\([^,]+,[^,]+,[^,]+,\s*0(?:\.0+)?%?\s*\)$',
  );
  if (alphaComma.hasMatch(trimmed)) return true;
  // 8-digit hex with `00` alpha (`#rrggbb00` or `#rgba` with `0`).
  final hex8 = RegExp(r'^#[0-9a-f]{6}00$');
  if (hex8.hasMatch(trimmed)) return true;
  final hex4 = RegExp(r'^#[0-9a-f]{3}0$');
  if (hex4.hasMatch(trimmed)) return true;
  return false;
}

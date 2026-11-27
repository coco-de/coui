import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Card`.
///
/// DOM shape (slot-based path, `co_card` decides which optional
/// branches render):
///
/// ```text
/// root (<div>)
///   ├─ mediaWrapper (<div>)                       // co_card renders only when media != null
///   │    ├─ media (caller-supplied Component)
///   │    └─ overlayWrapper (<div>)                // co_card renders only when overlay != null
///   │         └─ overlay (caller-supplied Component)
///   └─ contentWrapper (<div>)                     // co_card renders only when header / body / footer is set
///        ├─ header (<div>)                        // co_card renders only when header != null
///        ├─ Gap(headerBodyGapStyle)             // co_card renders only when header != null && body != null
///        ├─ body (caller-supplied Component)
///        ├─ Gap(bodyFooterGapStyle)             // co_card renders only when (header || body) && footer
///        └─ footer (caller-supplied Component)
/// ```
///
/// Custom path (`child` / `children` instead of slots):
///
/// ```text
/// root (<div>)
///   └─ customWrapper (<div>)                      // co_card emits this when child/children supplied
///        └─ child | …children
/// ```
///
/// All slot chromes are non-null — `co_card` decides which optional
/// elements actually render based on slot presence.
///
/// Per Epic #1603 (옵션 B 최종) the inter-slot spacers are rendered
/// through the unified `Gap` widget, so the resolver carries the
/// nested [CoreGapStyle] slots ([headerBodyGapStyle] /
/// [bodyFooterGapStyle]) and `co_card` forwards them straight to
/// `Gap(gapStyle: …)`.
class ResolvedCard implements WebResolvedChrome {
  /// Creates a [ResolvedCard].
  const ResolvedCard({
    required this.root,
    required this.mediaWrapper,
    required this.overlayWrapper,
    required this.contentWrapper,
    required this.header,
    required this.headerBodyGapStyle,
    required this.bodyFooterGapStyle,
    required this.customWrapper,
    required this.clickableStyle,
  });

  /// Outermost `<div>` element chrome — variant Tailwind classes,
  /// elevation shadow, sizing, interaction (cursor + hover shadow)
  /// composed into one className, plus inline-CSS overrides for theme
  /// chrome.
  @override
  final WebElementChrome root;

  /// Media wrapper `<div>` chrome (`position: relative; overflow:
  /// hidden`). Always non-null — `co_card` renders only when
  /// `media != null`.
  final WebElementChrome mediaWrapper;

  /// Overlay wrapper `<div>` chrome (absolute, inset 0). Always
  /// non-null — `co_card` renders only when `overlay != null`.
  final WebElementChrome overlayWrapper;

  /// Content wrapper `<div>` chrome — `flex flex-col items-start` +
  /// padding inline-CSS. Always non-null — `co_card` renders only
  /// when there are slot children to wrap.
  final WebElementChrome contentWrapper;

  /// Header `<div>` chrome — typography class + font weight.
  final WebElementChrome header;

  /// Nested [CoreGapStyle] for the header → body spacer — forwarded
  /// to `Gap(gapStyle: …)`. `co_card` renders the gap only when both
  /// header and body are set.
  final CoreGapStyle headerBodyGapStyle;

  /// Nested [CoreGapStyle] for the body → footer spacer — forwarded
  /// to `Gap(gapStyle: …)`. `co_card` renders the gap only when
  /// footer follows header or body.
  final CoreGapStyle bodyFooterGapStyle;

  /// Custom-children wrapper `<div>` chrome — padding inline-CSS.
  /// Always non-null — `co_card` renders this only when caller passes
  /// `child` / `children` instead of named slots.
  final WebElementChrome customWrapper;

  /// Nested [CoreClickableStyle] slot for the composed per-card
  /// `Clickable` (tappable cards only) — `CoreCardStyle.defaultClickableStyle`
  /// (press-shrink OFF) merged with the per-instance override, raw-forwarded
  /// to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCard] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per variant)
///   → theme.coreComponentTheme.card.style
///   → theme.coreComponentTheme.card.variantStyles[variant]
///   → widget.cardStyle
/// ```
ResolvedCard resolveCard(
  BuildContext context, {
  required CoreCardVariant variant,
  required bool hasMedia,
  required bool interactive,
  bool singleCustomChild = false,
  CoreCardStyle? cardStyle,
  CoreSurfaceRole role = .defaultRole,
}) {
  final cardTheme = context.theme.coreComponentTheme?.card;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCardStyle(), [
    cardTheme?.style,
    cardTheme?.variantStyles?[variant],
    cardStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreCardStyle.defaultsByVariant[variant]!;

  // ─── Resolved chrome values ───────────────────────────
  final padding = merged.padding ?? CoreCardStyle.defaultPadding;
  // Border radius is **always** emitted inline (`(merged ?? default)
  // .toValue()`) — no `rounded-*` Tailwind class. This keeps the
  // override path and the default path on the same CSS surface so the
  // resolved chrome reflects `merged.borderRadius` directly (Epic #1603
  // chaining gate — radius / padding are always-inline).
  final borderRadius =
      (merged.borderRadius ?? CoreCardStyle.defaultBorderRadius).toValue();
  // Merge the design-system default `CoreGapStyle` with the
  // per-instance override — the resolved slot is forwarded straight
  // to `Gap(gapStyle: …)` by `co_card`.
  final headerBodyGapStyle = CoreCardStyle.defaultHeaderBodyGapStyle.merge(
    merged.headerBodyGapStyle,
  );
  final bodyFooterGapStyle = CoreCardStyle.defaultBodyFooterGapStyle.merge(
    merged.bodyFooterGapStyle,
  );
  final elevation = merged.elevation ?? CoreCardStyle.defaultElevation;
  final hoverElevation =
      merged.hoverElevation ?? CoreCardStyle.defaultHoverElevation;
  final sizing = merged.sizing ?? CoreCardStyle.defaultSizing;
  // Overlay inset — design-system default unless the caller overrode
  // `overlayInset` (Epic #1603 coverage gate). The token class is
  // dropped and an inline `inset` rem rule takes over when overridden.
  final overlayInset = merged.overlayInset ?? CoreCardStyle.defaultOverlayInset;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Every colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound values
  // (variant defaults AND token overrides) emit Tailwind classes so they
  // stay dark-mode reactive; raw overrides go inline. No `scheme.resolve`
  // (a no-op on Web) and no hand-rolled `text-${...token!.name}` role-class
  // construction.
  //
  // Background — `emitColor` resolves `merged.backgroundColor ?? variant
  // default`; the filled variant background is token-bound (class), a raw
  // override goes inline. The `border` Tailwind class / border colour are
  // only emitted when the card draws a border (a width above 0 and a colour
  // that is not clear), so `backgroundEmit` is unconditional but the border
  // emit is skipped for borderless cards.
  // Glassmorphism — `surfaceOpacity` scales the background token's alpha
  // (mirrors Flutter `OutlinedContainer`'s
  // `backgroundToken.scaleAlpha(surfaceOpacity)`); `null` = opaque
  // (design-system default), matching the paired `surfaceBlur` handling
  // below. Only the present side is scaled — an absent override stays
  // `null` so `emitColor` still treats it as "no override" (default
  // stays on the token class) rather than manufacturing a fake inline
  // override.
  final surfaceOpacity = merged.surfaceOpacity;
  final backgroundEmit = emitColor(
    surfaceOpacity == null || merged.backgroundColor == null
        ? merged.backgroundColor
        : merged.backgroundColor!.scaleAlpha(surfaceOpacity),
    surfaceOpacity == null
        ? variantStyle.backgroundColor
        : variantStyle.backgroundColor.scaleAlpha(surfaceOpacity),
    .background,
  );
  // The edge is read the way Flutter's `OutlinedContainer` reads it: the
  // instance's width and colour over the variant row's, and an edge whose
  // colour is clear draws nothing (the width folds to 0). A borderless
  // variant given only a width — or only a colour — therefore stays
  // borderless on both platforms, and one given both draws its edge.
  final borderWidthEffective = merged.borderWidth ?? variantStyle.borderWidth;
  final borderColorBase = variantStyle.borderColor ?? CoreColor.transparent;
  final borderColorEffective = merged.borderColor ?? borderColorBase;
  final drawsBorder =
      borderWidthEffective > 0 &&
      (borderColorEffective.token != null || borderColorEffective.alpha > 0);
  final borderEmit = drawsBorder
      ? emitColor(merged.borderColor, borderColorBase, .border)
      : null;
  // Body / header typography — `emitTypography` merges the design-system
  // default role (`defaultBodyTextStyle` / `defaultHeaderTextStyle`,
  // token-backed with the `onSurface` colour) with the
  // per-instance override. A pure role emits a `text-{role}` class
  // (dark-mode reactive); explicit scalar / raw-colour overlays emit
  // inline alongside the class.
  final bodyEmit = emitTypography(
    merged.bodyTextStyle,
    CoreCardStyle.defaultBodyTextStyle,
  );
  final headerEmit = emitTypography(
    merged.headerTextStyle,
    CoreCardStyle.defaultHeaderTextStyle,
  );
  // Shadow base colour — design-system default unless overridden.
  // `.toValue()` (theme-free) emits `var(--coui-<token>)` for token
  // colours and `rgb(...)` for raw ARGB overrides, so the hand-composed
  // `box-shadow` string layers correctly for both. No `scheme.resolve`
  // (no-op on Web — the browser resolves the CSS variable at runtime).
  final shadowBase =
      (merged.shadowBaseColor ?? CoreCardStyle.defaultShadowBaseColor)
          .toValue();
  // Chrome state-transition duration — animates background / border /
  // border-radius under a theme swap or per-instance style change
  // (mirrors the Flutter `OutlinedContainer` AnimatedContainer).
  // Epic #1603 coverage gate — `chromeAnimationDuration` is reflected.
  final chromeAnimationDurationMs =
      (merged.chromeAnimationDuration ??
              CoreCardStyle.defaultChromeAnimationDuration)
          .inMilliseconds;
  // Hover-shadow fade duration — animates the `box-shadow` swap on
  // hover, so it is driven by `hoverShadowAnimationDuration` (matches
  // the Flutter interactive wrapper). Epic #1603 coverage gate —
  // distinct from the chrome transition duration above.
  final hoverShadowAnimationDurationMs =
      (merged.hoverShadowAnimationDuration ??
              CoreCardStyle.defaultHoverShadowAnimationDuration)
          .inMilliseconds;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs),
  // shared by both the chrome and hover-shadow transitions below.
  final chromeAnimationDurationCss = durationMsCss(chromeAnimationDurationMs);
  final hoverShadowAnimationDurationCss = durationMsCss(
    hoverShadowAnimationDurationMs,
  );
  final chromeEasingCss = CoreEasing.move.toVarCss();
  final clipModeOverride = merged.clipBehavior;
  final shouldClip = clipModeOverride == null
      ? hasMedia
      : clipModeOverride != .none;

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` Tailwind className.
  String buildRootClassName() {
    // Marks this element as a component surface. Carries no styling of
    // its own — it is the hook a style preset targets to give the surface
    // a material, and the one forced colours targets to restore a
    // boundary that was drawn as a shadow.
    //
    // A `surfaceStyle` swaps the document-scoped marker for the local one,
    // which the stylesheet reads as that preset's material and nothing
    // else's — the surrounding preset's rules stop matching this element.
    final classList = [
      ...webSurfaceMarkerFor(role, surfaceStyle: merged.surfaceStyle),
    ];

    // Body typography — `emitTypography` emits the `text-{role}` (+ token
    // colour) class for the default / token-override path; a raw / scalar
    // overlay contributes an empty fragment here and goes inline instead.
    if (bodyEmit.className.isNotEmpty) classList.add(bodyEmit.className);

    // Variant chrome — `emitColor` emits the `bg-{token}` class for the
    // token-bound variant default (and token overrides); a raw override
    // contributes an empty fragment and goes inline. The `border` Tailwind
    // class + border colour are added only when this variant draws a
    // border.
    if (backgroundEmit.className.isNotEmpty) {
      classList.add(backgroundEmit.className);
    }
    if (drawsBorder) {
      classList.add('border');
      if (borderEmit!.className.isNotEmpty) {
        classList.add(borderEmit.className);
      }
    }

    final elevClass = elevation
        .toOutlinedContainerElevation()
        .tailwindShadowClass;
    if (elevClass.isNotEmpty) {
      classList.add(elevClass);
      // The style's surface rim decorates this lift. It cannot ride the
      // inline map: an inline `box-shadow` out-ranks `hover:shadow-*` and
      // would freeze the hover elevation. The marker's rule restates the
      // elevation classes' own composition with the rim as one more
      // layer, so hovering still swaps the lift underneath it. An
      // authored `boxShadow` goes inline and carries its own rim.
      if (merged.boxShadow == null) classList.add(kSurfaceRimLiftMarker);
    } else if (merged.boxShadow == null) {
      // States no rest shadow of its own — so it takes the style's, the
      // way its Flutter twin does by composing `OutlinedContainer`. The
      // Web card draws its own box instead, so the opt-in has to be
      // restated here or the two platforms diverge under any style whose
      // signature IS the cast.
      classList.add(kControlShadowRestMarker);
    }

    if (shouldClip) classList.add(WebLayout.overflowHidden);

    if (interactive) {
      // Cursor / focus ring / press are owned by the composing
      // `Clickable`; the hover-shadow class stays on the styled card
      // root because the shadow feedback is the card Style's own chrome
      // (the CSS `:hover` fires on this element regardless of the
      // wrapping Clickable).
      final hoverShadowClass = hoverElevation
          .toOutlinedContainerElevation()
          .tailwindShadowClass;
      classList.add('hover:$hoverShadowClass');
      // The hover-shadow fade itself is emitted as an inline
      // `transition` rule (see `buildRootInlineStyles`) driven by
      // `hoverShadowAnimationDuration`, alongside the always-on chrome
      // transition driven by `chromeAnimationDuration` — the two need
      // distinct durations, which a single Tailwind `transition-*
      // duration-N` pair cannot express.
    }

    switch (sizing) {
      case .expand:
        classList.add(WebLayout.wFull);
      case .intrinsic:
        classList.add(WebLayout.wFit);
      case .fixed:
        break;
    }
    // Sizing-mode-independent clamp — the CSS mirror of Flutter's
    // "a RenderBox can never exceed its parent's max-width constraint":
    // `w-fit` (and an inline fixed width) otherwise grow to intrinsic
    // width and punch through narrow parents, where the Flutter twin
    // clamps and wraps its text (clamp-vs-grow divergence).
    classList.add(WebLayout.maxWFull);

    return classList.join(' ');
  }

  /// Composes the root `<div>` inline-CSS bundle — theme-overridden
  /// chrome plus fixed sizing.
  Styles? buildRootInlineStyles() {
    final raw = <String, String>{};
    // Variant chrome: emit-family inline fragments for raw overrides only.
    // Token values stay on classes in the root className builder.
    final backgroundInline = backgroundEmit.inline;
    if (backgroundInline != null) raw.addAll(backgroundInline);
    if (borderEmit?.inline case final borderInline?) {
      raw.addAll(borderInline);
    }
    if (drawsBorder && merged.borderWidth != null) {
      raw['border-width'] = strokeWidthCss(merged.borderWidth!);
    }
    // Border radius is always inline — `(merged ?? default).toValue()`
    // composed above. Default and override share this one surface so
    // the resolved chrome reflects `merged.borderRadius` directly.
    raw['border-radius'] = borderRadius;
    if (merged.boxShadow != null) {
      // Rim appended — mirrors `popup`/`draggable_panel`/`drawer`, the
      // other unconditional-inline shadow sites. The rim variable renders
      // nothing under every style but the one that states a rim.
      //
      // The elevation-class path takes its rim through
      // `kSurfaceRimLiftMarker` in the className builder instead — an
      // inline `box-shadow` there would out-rank the `hover:shadow-*`
      // class and freeze the hover elevation.
      raw['box-shadow'] =
          '${emitShadow(merged.boxShadow!, base: shadowBase)}, $kSurfaceRimVar';
    }
    // The cast a card takes when it states no rest shadow of its own
    // rides `kControlShadowRestMarker` in the className builder, not this
    // map — see that constant for why. Inlining it here would out-rank a
    // hoverable card's `hover:shadow-*` and trade the elevation feedback
    // away, which is the one thing this surface cannot afford to lose.
    // Glassmorphism backdrop blur — arbitrary sigma → inline CSS for exact
    // parity with Flutter `SurfaceBlur` (mirrors `OutlinedContainer`). Falls
    // back to the theme surface blur; `null`/`0` = opaque (default).
    //
    // The theme's flat blur is the surrounding material's, so a card that
    // names its own `surfaceStyle` has none to fall back to (see
    // `resolveOutlinedContainer`, the same rule on the primitive).
    final material = merged.surfaceStyle == null ? context.theme : null;
    final surfaceBlur = merged.surfaceBlur ?? material?.surfaceBlur;
    if (surfaceBlur != null && surfaceBlur > 0) {
      raw['backdrop-filter'] = 'blur(${surfaceBlur}px)';
    }
    // Publish the fill so a style preset can restate it translucently
    // without knowing which token this variant chose.
    raw.addAll(
      surfaceFillVar(merged.backgroundColor ?? variantStyle.backgroundColor),
    );
    // Body typography: emit-family inline overlay carrying the size, weight,
    // line-height, letter-spacing and raw colour from the merged override.
    // The role and token colour stay on the class in the root className
    // builder.
    final bodyInline = bodyEmit.inline;
    if (bodyInline != null) raw.addAll(bodyInline);
    if (sizing == .fixed) {
      if (merged.width != null) {
        raw['width'] = '${merged.width! / kRemDivisor}rem';
      }
      if (merged.height != null) {
        raw['height'] = '${merged.height! / kRemDivisor}rem';
      }
    }
    // Chrome state transition — `background-color` / `border-color` /
    // `border-width` / `border-radius` fade with `chromeAnimationDuration`
    // (mirrors the Flutter `OutlinedContainer` AnimatedContainer). The
    // hover `box-shadow` fade is layered on with the dedicated
    // `hoverShadowAnimationDuration` only when the card is interactive
    // (mirrors the Flutter interactive wrapper). Emitted inline (frame
    // resolver pattern) because the two transitions need distinct
    // durations.
    raw['transition'] = <String>[
      'background-color $chromeAnimationDurationCss $chromeEasingCss',
      'border-color $chromeAnimationDurationCss $chromeEasingCss',
      'border-width $chromeAnimationDurationCss $chromeEasingCss',
      'border-radius $chromeAnimationDurationCss $chromeEasingCss',
      if (interactive)
        'box-shadow $hoverShadowAnimationDurationCss $chromeEasingCss',
    ].join(', ');
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the content-wrapper inline-CSS — applies the resolved
  /// physical shorthand or logical sides, preserving reading direction.
  Styles buildContentInlineStyles() =>
      .new(raw: padding.toLogicalDeclarations('padding'));

  /// Composes the header `<div>` Tailwind className — the `text-{role}`
  /// (+ token colour) class from [headerEmit] for the default / token-
  /// override path. The header's weight is the role's own, carried by
  /// that class; a raw / scalar override contributes an empty fragment
  /// here and emits inline instead.
  String buildHeaderClassName() => headerEmit.className;

  /// Composes the header `<div>` inline-CSS — the emit-family inline
  /// overlay from [headerEmit] (explicit scalar / raw-colour overrides
  /// only; the role + token colour stay on the class in
  /// [buildHeaderClassName]). Returns `null` for a pure role.
  Styles? buildHeaderInlineStyles() {
    final inline = headerEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the overlay-wrapper `<div>` Tailwind className. The
  /// `inset-*` token class is suppressed when `overlayInset` is
  /// overridden so the inline rem rule wins (Epic #1603 gate —
  /// size token class drop + inline rem on override).
  String buildOverlayClassName() {
    final hasOverlayInsetOverride = merged.overlayInset != null;
    return <String>[
      WebLayout.absolute,
      if (!hasOverlayInsetOverride)
        'inset-${CoreCardStyle.defaultOverlayInset.tailwindSpace}',
    ].join(' ');
  }

  /// Composes the overlay-wrapper inline-CSS — emits the `inset` rule
  /// only when `overlayInset` is overridden.
  ///
  /// Pinned: the inset positions the overlay against the card's edges,
  /// which the Flutter twin leaves out of the density. (The default is
  /// `0`, which no density moves, so its class above is safe.)
  Styles? buildOverlayInlineStyles() => merged.overlayInset == null
      ? null
      : .new(raw: {'inset': pinnedLengthCss(overlayInset)});

  // Nested Clickable slot — partial default (press-shrink off for the
  // large card surface) merged with the override, raw-forwarded (the
  // Clickable's own resolver fills the rest).
  final clickableStyle = CoreCardStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedCard(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    mediaWrapper: const WebElementChrome(
      className: WebLayout.relativeOverflowHidden,
    ),
    overlayWrapper: WebElementChrome(
      className: buildOverlayClassName(),
      inlineStyles: buildOverlayInlineStyles(),
    ),
    contentWrapper: WebElementChrome(
      // `h-full`: fills the card root when a parent gives the card an
      // explicit height (e.g. `AspectRatioBox`'s tight box) — a no-op
      // under the usual auto-height root (percentage heights resolve
      // to auto there), mirroring how Flutter's card content expands
      // under tight constraints only.
      className: '${WebLayout.flexColItemsStart} ${WebLayout.hFull}',
      inlineStyles: buildContentInlineStyles(),
    ),
    header: WebElementChrome(
      className: buildHeaderClassName(),
      inlineStyles: buildHeaderInlineStyles(),
    ),
    headerBodyGapStyle: headerBodyGapStyle,
    bodyFooterGapStyle: bodyFooterGapStyle,
    customWrapper: WebElementChrome(
      // Same tight-height fill as `contentWrapper` above.
      //
      // A single child is the Web mirror of Flutter's `Card(child: …)`,
      // where the child sits straight inside the container. A plain block
      // would give an inline-level child (the `Text` chain is an inline
      // `span`) a line box whose strut is the *inherited* body line height,
      // so a 13px / 19.5px caption came out 21px tall. A flex column
      // blockifies the child so it keeps its own line height, and its
      // default stretch keeps a block child filling the width the way it
      // did in the block. Several children (a Web-only API) keep the plain
      // block, so inline siblings still flow on one line.
      className: singleCustomChild
          ? '${WebLayout.flexColItemsStretch} ${WebLayout.hFull}'
          : WebLayout.hFull,
      inlineStyles: buildContentInlineStyles(),
    ),
    clickableStyle: clickableStyle,
  );
}

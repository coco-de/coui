/// Style-slot single entry point for the Web `Pagination`.
///
/// `resolvePagination` walks the nested merge chain
/// (`CorePaginationStyle.defaultX` → `theme.pagination.style` →
/// `widget.paginationStyle`) and ships back a [ResolvedPagination]
/// paint-ready chrome bundle. Every per-state button / ellipsis chrome
/// is pre-composed as a `WebElementChrome` slot so the
/// `co_pagination.dart` build only reads
/// `chrome.X.className / inlineStyles`, never doing composition
/// itself.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedPagination — fully pre-composed chrome
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Pagination`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="navigation" flex flex-row>)         // outer wrapper
///   └─ Clickable (<div role="button">) × n             // per-button wrapper
///        └─ <div>                                       // buttonActive
///                                                       // buttonInactiveEnabled
///                                                       // buttonInactiveDisabled
///                                                       // ellipsis
///   (a disabled pagination drops the Clickable wrapper and draws the
///    buttonActiveDisabled / buttonDisabled / ellipsisDisabled <div> alone)
///   └─ fitProbe (<div inert aria-hidden>)              // only when the
///        └─ fitProbeRow (<div>) × ladder step          // row can compact
/// ```
///
/// [fitProbe] holds an invisible, zero-size copy of the row at every
/// compaction step (`CorePaginationLayout.ladder`), each laid out at its
/// natural width in a [fitProbeRow] box; the client measurer picks the
/// first one that fits the width the row is given.
///
/// Every state-dependent slot is pre-composed here as a
/// `WebElementChrome`. The number of unique chrome combinations is
/// bounded (active / inactive-enabled / inactive-disabled for buttons,
/// plus the ellipsis) so we compute them once and the widget picks the
/// right slot per child. Interaction chrome (cursor / focus ring /
/// press feedback / keyboard activation) is owned by the composing
/// `Clickable`, fed the nested [clickableStyle] slot.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only Cat 1
/// `WebElementChrome` slots plus the Cat 2 nested [CoreClickableStyle]
/// slot — no scalar metadata, no `Component`, no nested logic.
/// `co_pagination` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>`.
class ResolvedPagination implements WebResolvedChrome {
  /// Creates a [ResolvedPagination].
  const ResolvedPagination({
    required this.root,
    required this.buttonActive,
    required this.buttonInactiveEnabled,
    required this.buttonInactiveDisabled,
    required this.labelButtonInactiveEnabled,
    required this.labelButtonInactiveDisabled,
    required this.buttonActiveDisabled,
    required this.buttonDisabled,
    required this.labelButtonDisabled,
    required this.ellipsis,
    required this.ellipsisDisabled,
    required this.iconStyle,
    required this.fitProbe,
    required this.fitProbeRow,
    required this.clickableStyle,
  });

  /// Paint-ready chrome for the outermost wrapper `<div
  /// role="navigation" flex flex-row>` — hosts every page-number /
  /// nav / ellipsis child button at the resolved item spacing.
  @override
  final WebElementChrome root;

  /// Chrome for the currently-active (selected) page button.
  final WebElementChrome buttonActive;

  /// Chrome for an inactive but interactive page button (clickable).
  final WebElementChrome buttonInactiveEnabled;

  /// Chrome for an inactive non-interactive page button (handler
  /// missing or page disabled).
  final WebElementChrome buttonInactiveDisabled;

  /// [buttonInactiveEnabled] for a previous / next button that shows its
  /// label: same height, colours and radius, but no width — the box takes
  /// its width from the icon, gap and label plus the label padding, so a
  /// word is never squeezed into the square page-button box.
  final WebElementChrome labelButtonInactiveEnabled;

  /// [buttonInactiveDisabled] for a previous / next button that shows its
  /// label — sized like [labelButtonInactiveEnabled].
  final WebElementChrome labelButtonInactiveDisabled;

  /// Chrome for the currently-active page button while the whole pagination
  /// is disabled (`enabled: false`) — the disabled container fill and the
  /// disabled content colour.
  final WebElementChrome buttonActiveDisabled;

  /// Chrome for an inactive page button while the whole pagination is
  /// disabled — the disabled content colour, no hover.
  final WebElementChrome buttonDisabled;

  /// [buttonDisabled] for a previous / next button that shows its label.
  final WebElementChrome labelButtonDisabled;

  /// Chrome for the ellipsis button (jump-to-edge target when an
  /// `onPageChanged` handler is present, purely visual `…` otherwise —
  /// the interactive affordance is owned by the composing `Clickable`).
  final WebElementChrome ellipsis;

  /// [ellipsis] while the whole pagination is disabled.
  final WebElementChrome ellipsisDisabled;

  /// Nested [CoreIconStyle] slot for the previous / next chevron — raw
  /// (pre-scaling), forwarded to `Icon(iconStyle: …)`.
  final CoreIconStyle iconStyle;

  /// The invisible host of the measuring copies — taken out of the flex
  /// flow (absolute), zero-size and clipped so it never widens the page,
  /// `visibility: hidden` so it never paints.
  final WebElementChrome fitProbe;

  /// One measuring copy of the row: the [root] row chrome at its
  /// max-content width, so its box is the width the step needs.
  final WebElementChrome fitProbeRow;

  /// Nested [CoreClickableStyle] slot for the composed per-button
  /// `Clickable` — `CorePaginationStyle.defaultClickableStyle` merged
  /// with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for `<style>` block in `Pagination`.
///
/// Non-empty only when a per-instance / theme override moves a `:hover`
/// colour off the Tailwind scale — a raw (token-less) `hoverBackgroundColor`
/// or a raw `hoverTextStyle.color`. Every page button shares one hover
/// colour, so the buttons carry a shared scope class (`co-pagination-h-<id>`)
/// and `resolvePagination` drops the matching `hover:bg-*` / `hover:text-*`
/// utility class (class XOR rule):
/// * `.co-pagination-h-<id>:hover{background-color: …}` and / or
/// * `.co-pagination-h-<id>:hover{color: …}`.
class ResolvedPaginationRules {
  /// Creates a [ResolvedPaginationRules].
  const ResolvedPaginationRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

// ════════════════════════════════════════════════════════════════
// resolvePagination — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedPagination] for the given [context].
///
/// Walks the 2-stage merge chain and applies the
/// `CorePaginationStyle.defaultX` static const fallback so each
/// resolved chrome value reads from a single source of truth:
///
/// ```text
/// CorePaginationStyle.defaultX        // design system default
///   → theme.coreComponentTheme.pagination.style
///   → widget.paginationStyle
/// ```
///
/// Dimensional values (`itemSpacing` / square box metrics / corner radius)
/// are always emitted inline through `(merged ?? default)` so the resolved
/// chrome reflects the merged value directly (Epic #1603 single
/// signature — no dimensional Tailwind class branch). Colour defaults
/// flow through Tailwind classes (`bg-*` / `text-*` / `hover:*`) from
/// the resolved `CoreColor` tokens.
ResolvedPagination resolvePagination(
  BuildContext context, {
  required CorePaginationVariant variant,
  required String scopeId,
  CoreSurfaceRole role = .defaultRole,
  CorePaginationStyle? paginationStyle,
}) {
  final paginationTheme = context.theme.coreComponentTheme?.pagination;

  // 3-stage merge chain — theme.style → theme.variantStyles[variant] →
  // component.paginationStyle. Semantic identifier `variant` comes
  // straight from the widget; the theme cannot override it.
  final merged = resolveStyleChain(const CorePaginationStyle(), [
    paginationTheme?.style,
    paginationTheme?.variantStyles?[variant],
    paginationStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + design-system fallback so the
  // local builders below read from a single source of truth.
  final itemSpacing =
      merged.itemSpacing ?? CorePaginationStyle.defaultItemSpacing;
  final buttonSize = merged.buttonSize ?? CorePaginationStyle.defaultButtonSize;
  final buttonRadius =
      merged.buttonRadius ?? CorePaginationStyle.defaultButtonRadius;
  final labelButtonPadding =
      merged.labelButtonPadding ??
      CorePaginationStyle.defaultLabelButtonPadding;

  // ─── EMIT (theme-free) — per-state colours via emit family ─────
  // Non-pseudo colours flow through `emitColor` (token → class, raw
  // override → inline). Hover colours are `:hover` pseudo-variants,
  // which inline CSS cannot express, so they stay as token classes
  // built from the resolved `CoreColor` (parity with the Flutter
  // resolver which resolves the same `CorePaginationStyle.defaultX`).
  final activeBackgroundColor =
      merged.activeBackgroundColor ??
      CorePaginationStyle.defaultActiveBackgroundColor;
  final activeBackgroundEmit = emitColor(
    activeBackgroundColor,
    activeBackgroundColor,
    .background,
  );
  // sb8 — per-state text colour now lives inside the nested
  // `CoreTextStyle` slots; pull colour from each merged slot.
  final activeForeground = CorePaginationStyle.defaultActiveTextStyle
      .merge(merged.activeTextStyle)
      .color!;
  final activeForegroundEmit = emitColor(
    activeForeground,
    activeForeground,
    .text,
  );
  final foreground = CorePaginationStyle.defaultTextStyle
      .merge(merged.textStyle)
      .color!;
  final foregroundEmit = emitColor(foreground, foreground, .text);
  // The ellipsis rests on its own (decorative) colour; the disabled state
  // states one colour for everything and the disabled container for the
  // current page.
  final ellipsisForeground = CorePaginationStyle.defaultEllipsisStyle
      .merge(merged.ellipsisStyle)
      .color!;
  final ellipsisForegroundEmit = emitColor(
    ellipsisForeground,
    ellipsisForeground,
    .text,
  );
  final disabledForeground =
      merged.disabledColor ?? CorePaginationStyle.defaultDisabledColor;
  final disabledForegroundEmit = emitColor(
    disabledForeground,
    disabledForeground,
    .text,
  );
  final disabledBackground =
      merged.disabledBackgroundColor ??
      CorePaginationStyle.defaultDisabledBackgroundColor;
  final disabledBackgroundEmit = emitColor(
    disabledBackground,
    disabledBackground,
    .background,
  );
  // Hover colours — `:hover` pseudo-state, which inline CSS cannot
  // express (an inline `background-color` / `color` would win the
  // specificity war against a `hover:` variant). The page buttons all
  // share one hover colour, so a raw (token-less) override routes to a
  // single CLASS-scoped `<style>` rule (`.co-pagination-h-<id>:hover`)
  // that covers every button, while a design-system token stays on the
  // `hover:bg-*` / `hover:text-*` Tailwind class (byte-identical to the
  // pre-change emission). `resolvePaginationRules` accumulates the raw
  // rules; here we only decide class vs scope-class.
  final hoverScopeSelector = '.co-pagination-h-$scopeId';
  final hoverBackgroundEmit = emitPseudoColor(
    merged.hoverBackgroundColor,
    CorePaginationStyle.defaultHoverBackgroundColor,
    .background,
    pseudo: .hover,
    scopeSelector: hoverScopeSelector,
  );
  final hoverForeground = CorePaginationStyle.defaultHoverTextStyle
      .merge(merged.hoverTextStyle)
      .color!;
  final hoverForegroundEmit = emitPseudoColor(
    hoverForeground,
    hoverForeground,
    .text,
    pseudo: .hover,
    scopeSelector: hoverScopeSelector,
  );
  // A raw hover background OR a raw hover foreground moves off the
  // Tailwind scale — the button drops that colour's `hover:` class and
  // instead carries the shared scope class the `<style>` rule targets.
  final hoverScoped =
      hoverBackgroundEmit.rule.isNotEmpty ||
      hoverForegroundEmit.rule.isNotEmpty;
  // Hover colour-transition duration — merged override wins, else the
  // design-system default; shares the Core motion-aware CSS duration path.
  final hoverDurationMs =
      (merged.hoverDuration ?? CorePaginationStyle.defaultHoverDuration)
          .inMilliseconds;
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CorePaginationStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── EMIT (theme-free) — base button typography ────────────────
  // `emitTypography` merges the `bodyMedium` role default
  // (`defaultButtonTextStyle`) with the per-instance `buttonTextStyle`
  // overlay, emitting a `text-{role}` class plus any explicit scalar
  // overlay inline (parity with Flutter). The slot carries no colour
  // (per-state foreground drives the text classes), so the typography
  // overlay is stripped of colour before emit.
  final buttonTypographyEmit = emitTypography(
    _stripColor(merged.buttonTextStyle),
    CorePaginationStyle.defaultButtonTextStyle,
  );
  // The active button's role (`labelLarge` at `semiBold`) is a DEFAULT, so it
  // is layered under the caller's overlays — the same order the Flutter
  // resolver applies (`default base ⊕ default active ⊕ buttonTextStyle ⊕
  // activeButtonTextStyle`): a size or line box stated on `buttonTextStyle`
  // reaches the active button like every other one.
  final activeTypographyEmit = emitTypography(
    _stripColor(
      merged.buttonTextStyle == null
          ? merged.activeButtonTextStyle
          : merged.buttonTextStyle!.merge(merged.activeButtonTextStyle),
    ),
    CorePaginationStyle.defaultButtonTextStyle.merge(
      CorePaginationStyle.defaultActiveButtonTextStyle,
    ),
  );
  // Nested icon slot — raw-forwarded (the `Icon` scales itself).
  final iconStyle = CorePaginationStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );

  // ─── EMIT (theme-free) — ellipsis typography override ──────────
  // The per-instance ellipsis slot is a partial override emitted inline
  // (font-size / weight / line-height / letter-spacing); its colour (the
  // default decorative step or the override) is `ellipsisForegroundEmit`
  // above — token → class, raw → inline, theme-free.
  final ellipsisStyle = merged.ellipsisStyle;

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — local to the resolver,
  // inaccessible from outside.

  /// Composes the outer `<div role="navigation">` Tailwind className —
  /// flex row only. The `itemSpacing` is always emitted inline by
  /// [buildRootInlineStyles] (single-signature gate — dimensional values
  /// flow through `(merged ?? default)` inline, never a Tailwind class).
  String buildRootClassName() => WebLayout.flexRowItemsCenter;

  /// Composes the outer `<div role="navigation">` inline-CSS bundle —
  /// the resolved `itemSpacing` emitted as CSS `gap` through `spaceCss`
  /// (default or override share this one surface so the resolved chrome
  /// reflects `merged.itemSpacing` directly).
  Styles buildRootInlineStyles() => .new(raw: {'gap': spaceCss(itemSpacing)});

  /// Composes a button `<div>` Tailwind className for the given state
  /// flags.
  ///
  /// Square box metrics (`width` / `height`) and corner radius are
  /// always emitted inline by [buildButtonInlineStyles] (single-signature
  /// gate — dimensional values flow through `(merged ?? default)`,
  /// never a Tailwind class). Colour / typography classes derive from
  /// the emit-family results above ([emitColor] / [emitTypography]);
  /// hover colours stay as `:hover` pseudo token classes. Interaction
  /// chrome (cursor / focus ring / press) is owned by the composing
  /// `Clickable`.
  String buildButtonClassName({
    required bool active,
    required bool enabled,
    bool disabled = false,
  }) {
    final typographyEmit = active ? activeTypographyEmit : buttonTypographyEmit;
    final classes = [
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      WebLayout.whitespaceNowrap,
      'box-border',
      // Base button typography — `text-{role}` class (+ any explicit
      // overlay inline via [buildButtonInlineStyles]). The active button
      // carries its own role and weight.
      if (typographyEmit.className.isNotEmpty) typographyEmit.className,
      'transition-colors',
    ];

    if (disabled) {
      // The whole pagination is disabled: one foreground for everything, the
      // disabled container for the current page, and no hover.
      if (active) {
        classes.addAll(webSurfaceMarkerFor(role));
        if (disabledBackgroundEmit.className.isNotEmpty) {
          classes.add(disabledBackgroundEmit.className);
        }
      }
      if (disabledForegroundEmit.className.isNotEmpty) {
        classes.add(disabledForegroundEmit.className);
      }
    } else if (active) {
      // Marks the active-page pill as a component surface so a material
      // preset reaches it, the way `webSurfaceMarkerFor` reaches `Alert`'s
      // own root — restated here rather than composing `OutlinedContainer`
      // (a DOM restructure) because the box is a single `<div>` with no
      // nested chrome to delegate. Only the active bundle carries it: the
      // inactive-enabled bundle's fill is a CSS `:hover` pseudo-class, and
      // this marker class has no pseudo-gated form — adding it there would
      // blur the page behind every unhighlighted number at rest, not just
      // on hover (mirrors the Flutter resolver's `surfaceBlur: 0` on
      // `hoverContainerStyle` / `idleContainerStyle`).
      classes.addAll(webSurfaceMarkerFor(role));
      if (activeBackgroundEmit.className.isNotEmpty) {
        classes.add(activeBackgroundEmit.className);
      }
      if (activeForegroundEmit.className.isNotEmpty) {
        classes.add(activeForegroundEmit.className);
      }
    } else {
      if (foregroundEmit.className.isNotEmpty) {
        classes.add(foregroundEmit.className);
      }
      if (enabled) {
        // Token hover colours ride the `hover:bg-*` / `hover:text-*`
        // classes; a raw override contributes no class (routed to the
        // scoped rule) and the shared scope class is added once.
        if (hoverBackgroundEmit.className.isNotEmpty) {
          classes.add(hoverBackgroundEmit.className);
        }
        if (hoverForegroundEmit.className.isNotEmpty) {
          classes.add(hoverForegroundEmit.className);
        }
        if (hoverScoped) classes.add('co-pagination-h-$scopeId');
      }
    }

    return classes.join(' ');
  }

  /// Composes a button `<div>` inline-CSS bundle — the resolved square
  /// box metrics (`width` / `height`) and corner radius plus any
  /// explicit typography / raw colour overlay that the emit family
  /// pushed inline (a raw colour override that has no preset class).
  /// Default and override share this one surface so the resolved chrome
  /// reflects `merged.buttonSize` / `merged.buttonRadius` directly.
  ///
  /// A [labelled] button (previous / next with `showLabel`) keeps the
  /// height but drops the width for the label padding: its content sets
  /// the width.
  Styles buildButtonInlineStyles({
    required bool active,
    bool labelled = false,
    bool disabled = false,
  }) {
    final raw = {
      'transition-duration': durationMsCss(hoverDurationMs),
      if (labelled)
        'padding': labelButtonPadding.toValue()
      else
        'width': '${buttonSize / kRemDivisor}rem',
      'height': '${buttonSize / kRemDivisor}rem',
      'border-radius': buttonRadius.toValue(),
      // Base button typography overlay (explicit `font-size` /
      // `font-weight` / `line-height` / `letter-spacing` props the user
      // set on the slot) — emitted inline alongside the role class.
      ...?(active ? activeTypographyEmit.inline : buttonTypographyEmit.inline),
      // Per-state colour — when the resolved colour is a raw override
      // (no preset class) the emit family carries it inline; token
      // colours stay on the class so nothing is emitted here.
      if (disabled) ...?disabledForegroundEmit.inline,
      if (disabled && active) ...?disabledBackgroundEmit.inline,
      if (!disabled && active) ...?activeBackgroundEmit.inline,
      if (!disabled && active) ...?activeForegroundEmit.inline,
      if (!disabled && !active) ...?foregroundEmit.inline,
      // The other half of the surface marker above — publishes the fill
      // this button chose so a material preset can restate it at its own
      // alpha without knowing which token that was.
      if (active)
        ...surfaceFillVar(
          disabled ? disabledBackground : activeBackgroundColor,
        ),
    };
    return Styles(raw: raw);
  }

  /// Composes the ellipsis `<div>` Tailwind className — shares the
  /// button box metrics (always emitted inline), the base button
  /// typography (the `…` differs from a number by its colour alone) and the
  /// ellipsis text colour class (token override). The interactive affordance
  /// (cursor / focus ring / press) is owned by the composing `Clickable`.
  String buildEllipsisClassName({bool disabled = false}) {
    final colorEmit = disabled
        ? disabledForegroundEmit
        : ellipsisForegroundEmit;
    final classes = [
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      'box-border',
      if (buttonTypographyEmit.className.isNotEmpty)
        buttonTypographyEmit.className,
      if (colorEmit.className.isNotEmpty) colorEmit.className,
    ];
    return classes.join(' ');
  }

  /// Composes the ellipsis `<div>` inline-CSS bundle — the resolved
  /// square box metrics (`width` / `height`, always inline) plus the
  /// nested ellipsis text style override (font-size / weight) and its
  /// raw colour override (token colours land on the class instead).
  Styles buildEllipsisInlineStyles({bool disabled = false}) {
    final colorEmit = disabled
        ? disabledForegroundEmit
        : ellipsisForegroundEmit;
    final raw = {
      'width': '${buttonSize / kRemDivisor}rem',
      'height': '${buttonSize / kRemDivisor}rem',
      ...?buttonTypographyEmit.inline,
      // Typography overrides (`font-size` / `font-weight` / `line-height`
      // / `letter-spacing`) flow through `toInlineCss`; colour is dropped
      // here and re-emitted by the colour emit (token → class,
      // raw → inline) so dark-mode tracks via the CSS variable.
      ...?ellipsisStyle?.toInlineCss(includeColor: false),
      ...?colorEmit.inline,
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedPagination(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    buttonActive: WebElementChrome(
      className: buildButtonClassName(active: true, enabled: false),
      inlineStyles: buildButtonInlineStyles(active: true),
    ),
    buttonInactiveEnabled: WebElementChrome(
      className: buildButtonClassName(active: false, enabled: true),
      inlineStyles: buildButtonInlineStyles(active: false),
    ),
    buttonInactiveDisabled: WebElementChrome(
      className: buildButtonClassName(active: false, enabled: false),
      inlineStyles: buildButtonInlineStyles(active: false),
    ),
    labelButtonInactiveEnabled: WebElementChrome(
      className: buildButtonClassName(active: false, enabled: true),
      inlineStyles: buildButtonInlineStyles(active: false, labelled: true),
    ),
    labelButtonInactiveDisabled: WebElementChrome(
      className: buildButtonClassName(active: false, enabled: false),
      inlineStyles: buildButtonInlineStyles(active: false, labelled: true),
    ),
    buttonActiveDisabled: WebElementChrome(
      className: buildButtonClassName(
        active: true,
        enabled: false,
        disabled: true,
      ),
      inlineStyles: buildButtonInlineStyles(active: true, disabled: true),
    ),
    buttonDisabled: WebElementChrome(
      className: buildButtonClassName(
        active: false,
        enabled: false,
        disabled: true,
      ),
      inlineStyles: buildButtonInlineStyles(active: false, disabled: true),
    ),
    labelButtonDisabled: WebElementChrome(
      className: buildButtonClassName(
        active: false,
        enabled: false,
        disabled: true,
      ),
      inlineStyles: buildButtonInlineStyles(
        active: false,
        labelled: true,
        disabled: true,
      ),
    ),
    ellipsis: WebElementChrome(
      className: buildEllipsisClassName(),
      inlineStyles: buildEllipsisInlineStyles(),
    ),
    ellipsisDisabled: WebElementChrome(
      className: buildEllipsisClassName(disabled: true),
      inlineStyles: buildEllipsisInlineStyles(disabled: true),
    ),
    iconStyle: iconStyle,
    fitProbe: const WebElementChrome(
      className:
          '${WebLayout.absolute} ${WebLayout.invisible} '
          '${WebLayout.overflowHidden} ${WebLayout.pointerEventsNone}',
      inlineStyles: Styles(raw: {'width': '0', 'height': '0'}),
    ),
    fitProbeRow: WebElementChrome(
      className: '${buildRootClassName()} ${WebLayout.wMax}',
      inlineStyles: buildRootInlineStyles(),
    ),
    clickableStyle: clickableStyle,
  );
}

/// Returns a copy of [style] with its `color` field cleared (token slot
/// and every scalar overlay preserved). Pagination per-state foreground
/// colour is resolved through the dedicated text-colour classes, so the
/// base button typography overlay must not carry a colour — otherwise
/// [emitTypography] would emit a competing colour.
CoreTextStyle? _stripColor(CoreTextStyle? style) {
  if (style == null || style.color == null) return style;
  final base = style.token == null
      ? const CoreTextStyle()
      : CoreTextStyle.token(style.token!);
  return base.copyWith(
    fontSize: style.fontSize,
    lineHeight: style.lineHeight,
    lineHeightPx: style.lineHeightPx,
    fontWeight: style.fontWeight,
    letterSpacing: style.letterSpacing,
    fontFamily: style.fontFamily,
  );
}

/// Resolves the scoped `<style>` rules for a `Pagination` whose `:hover`
/// colour moves off the Tailwind scale — see [ResolvedPaginationRules].
/// Returns empty CSS on the default path (`resolvePagination` keeps the
/// `hover:bg-*` / `hover:text-*` utility classes: class XOR rule).
///
/// The merge chain mirrors [resolvePagination], so the class-drop
/// conditions and the scoped rules always see the same resolved values.
ResolvedPaginationRules resolvePaginationRules(
  BuildContext context, {
  required CorePaginationVariant variant,
  required String scopeId,
  CorePaginationStyle? paginationStyle,
}) {
  final paginationTheme = context.theme.coreComponentTheme?.pagination;
  final merged = resolveStyleChain(const CorePaginationStyle(), [
    paginationTheme?.style,
    paginationTheme?.variantStyles?[variant],
    paginationStyle,
  ]);

  final buffer = StringBuffer();
  final scopeSelector = '.co-pagination-h-$scopeId';

  // Hover background — a raw (token-less) override paints via the scoped
  // `.co-pagination-h-<id>:hover` rule (all page buttons share it).
  buffer.write(
    emitPseudoColor(
      merged.hoverBackgroundColor,
      CorePaginationStyle.defaultHoverBackgroundColor,
      .background,
      pseudo: .hover,
      scopeSelector: scopeSelector,
    ).rule,
  );

  // Hover foreground — same, for the shared text colour.
  final hoverForeground = CorePaginationStyle.defaultHoverTextStyle
      .merge(merged.hoverTextStyle)
      .color!;
  buffer.write(
    emitPseudoColor(
      hoverForeground,
      hoverForeground,
      .text,
      pseudo: .hover,
      scopeSelector: scopeSelector,
    ).rule,
  );

  return ResolvedPaginationRules(css: buffer.toString());
}

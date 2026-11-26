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
// ResolvedItemPicker
// ═══════════════════════════════════════════════════

/// Resolver output for Web `ItemPicker`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                           // picker container
///   ├─ search input (TextField)          // optional search field
///   ├─ Divider                           // closes the search row
///   ├─ empty (<div>)                     // empty-state placeholder
///   └─ items (<div role="listbox">)      // grid or list scroll area
///        ├─ title (<div>)                // optional label, first in the list
///        └─ option (<div role="option">) // built by resolveItemPickerOption
/// ```
///
/// Output of [resolveItemPicker] — every chrome / dimensional override
/// has had the nested-merge chain applied:
///
/// ```text
/// design system default (CoreItemPickerStyle.default*)
///   → theme.coreComponentTheme.itemPicker.style
///   → widget.itemPickerStyle
/// ```
///
/// Per-option chrome (selected state, hover) ships through the dedicated
/// per-item resolver [resolveItemPickerOption], which re-walks the same
/// merge chain for the selected / hover colour and padding / gap / radius
/// values — so no behavioural / dimensional scalar is carried here (Epic
/// #1603 옵션 B 최종 — main `ResolvedCo*` is pure chrome).
class ResolvedItemPicker implements WebResolvedChrome {
  /// Creates a [ResolvedItemPicker].
  const ResolvedItemPicker({
    required this.root,
    required this.title,
    required this.empty,
    required this.items,
    required this.searchFieldStyle,
    required this.searchIconStyle,
    required this.searchDividerStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="listbox">` picker
  /// container — composed `flex flex-col border` className (plus the
  /// default surface-tone background class when no per-instance
  /// override is supplied) and inline-CSS bundle carrying the resolved
  /// border-radius / border-width / border-colour values and the
  /// optional background-colour override. State-independent.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the optional title `<div>` — composed
  /// font-weight className plus the resolved title padding + `onSurface`
  /// colour inline CSS.
  final WebElementChrome title;

  /// Paint-ready chrome for the empty-state `<div>` — composed
  /// `text-center` className plus the resolved empty-state padding +
  /// `onSurfaceVariant` colour inline CSS.
  final WebElementChrome empty;

  /// Paint-ready chrome for the items scroll-area `<div>`. The
  /// className is left empty here because the items-area layout
  /// (`flex flex-col` for list / `grid grid-cols-N` for grid) depends
  /// on runtime `layout` / `gridColumns` and is resolved per-build via
  /// [resolveItemPickerItems]. Inline CSS is `null` for the same
  /// reason — the resolved padding / gap / `max-height` live on
  /// [resolveItemPickerItems]'s output. The slot remains present so
  /// the call site reaches "items chrome" through the same uniform
  /// slot pattern as every other element; future overrides land here.
  final WebElementChrome items;

  /// Nested [CoreTextFieldStyle] slot for the composed search
  /// `TextField` — [CoreItemPickerStyle.defaultSearchFieldStyle] (the
  /// frame's corner), the per-instance `searchFieldStyle` override, then
  /// the row: a stated `searchHeight` as the field's height, else nothing —
  /// the field's own `md` row is [CoreItemPickerStyle.defaultSearchHeight],
  /// emitted as the row variable a density moves (the Flutter twin sizes
  /// the same rung, moved, with its `SizedBox`).
  final CoreTextFieldStyle searchFieldStyle;

  /// Nested [CoreIconStyle] slot for the search glyph in front of the
  /// search field — the design default merged with the per-instance
  /// override, the colour swapped to the disabled tone while disabled.
  /// Raw-forwarded to the composed `Icon`.
  final CoreIconStyle searchIconStyle;

  /// Nested [CoreDividerStyle] slot for the `Divider` that closes the
  /// search row, raw-forwarded to `Divider(dividerStyle:)`.
  final CoreDividerStyle searchDividerStyle;
}

// ═══════════════════════════════════════════════════
// ResolvedItemPickerItems — items scroll-area chrome
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for the items scroll-area `<div>` inside a
/// `ItemPicker`.
///
/// DOM shape:
///
/// ```text
/// items (<div>)            // resolved.root — layout / gridColumns class
/// ```
class ResolvedItemPickerItems implements WebResolvedChrome {
  /// Creates a [ResolvedItemPickerItems].
  const ResolvedItemPickerItems({required this.root});

  /// Paint-ready chrome for the items scroll-area `<div>` — composed
  /// Tailwind layout className (`flex flex-col` for list / `grid
  /// grid-cols-N` for grid) plus the resolved padding / gap / `max-height`
  /// inline CSS.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// ResolvedItemPickerOption — per-option chrome
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for a single option `<div role="option">` inside
/// a `ItemPicker`.
///
/// DOM shape:
///
/// ```text
/// option (<div role="option">)   // resolved.root — selected/hover/cursor class
/// ```
class ResolvedItemPickerOption implements WebResolvedChrome {
  /// Creates a [ResolvedItemPickerOption].
  const ResolvedItemPickerOption({
    required this.root,
    required this.clickableStyle,
    required this.checkIconStyle,
  });

  /// Paint-ready chrome for the option chrome `<div>` — composed Tailwind
  /// className (base layout + per-state selected / hover classes) plus the
  /// resolved padding / gap / border-radius inline CSS and the optional
  /// override / default text colour. Cursor / focus ring are owned by the
  /// composing `Clickable` (via [clickableStyle]), not this slot.
  @override
  final WebElementChrome root;

  /// Nested [CoreClickableStyle] slot for the composed per-option
  /// `Clickable` — `CoreItemPickerStyle.defaultClickableStyle` merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreIconStyle] slot for the selected-option check glyph —
  /// carries the resolved icon size (override else the single-source
  /// named default), raw-forwarded to `Icon(iconStyle:)`. The colour is
  /// left to CSS `currentColor` inheritance from the selected row's text
  /// colour (the Flutter twin's `checkIconStyle` bakes the colour in
  /// because Flutter icons do not inherit `DefaultTextStyle`).
  final CoreIconStyle checkIconStyle;
}

// ═══════════════════════════════════════════════════
// ResolvedItemPickerRules — scoped <style> text
// ═══════════════════════════════════════════════════

/// Scoped CSS text for `<style>` block in `ItemPicker`.
///
/// Non-empty only when a per-instance / theme override moves a `:hover`
/// colour off the Tailwind scale:
/// * an option's background or text — a raw (token-less)
///   `optionHoverColor` or `optionHoverTextStyle.color`. `:hover` is a
///   pseudo-state, which inline CSS cannot express, so the options carry a
///   shared scope class in that condition and `resolveItemPickerOption`
///   drops the matching `hover:bg-*` / `hover:text-*` utility (class XOR
///   rule). Every option shares one hover colour, so one class-scoped rule
///   covers them all: `.co-item-picker-h-<id>:hover{background-color: …}`
///   and `.co-item-picker-h-<id>:hover{color: …}`.
/// * the picker frame's border — a raw `hoverBorderColor`, or a raw
///   resting `borderColor` (inline, so no class can step it). The frame
///   carries its own scope class and `resolveItemPicker` drops the
///   `hover:border-*` utility:
///   `.co-item-picker-frame-<id>:hover{border-color: …}`.
class ResolvedItemPickerRules {
  /// Creates a [ResolvedItemPickerRules].
  const ResolvedItemPickerRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

/// The class a picker frame carries when its hover border rides a scoped
/// rule — [resolveItemPicker] stamps it and [resolveItemPickerRules]
/// selects it, both from the same [scopeId].
String _frameScopeClass(String scopeId) => 'co-item-picker-frame-$scopeId';

/// Where the picker frame's hover border rides: a pseudo class when every
/// colour involved is a token, a scoped rule when one is not.
///
/// Precedence is `disabled > hover > rest` — the picker frame itself has
/// no focus or error state (its search field is a composed `TextField` that
/// owns its own), so there is no `focus-within:` utility whose cascade
/// order against `hover:` needs guarding.
/// * **disabled** — no hover step (`enabled == false` → empty).
/// * **hover** — `hoverBorderColor` (token → class, raw → scoped rule).
///
/// A raw resting border is emitted inline, which outranks every class and
/// every selector; the hover step then needs `!important` or it would
/// never show. A token rest border is a class and loses to both paths.
PseudoEmit _resolveHoverBorder(
  CoreItemPickerStyle merged, {
  required bool enabled,
  required String scopeSelector,
}) {
  if (!enabled) return (className: '', rule: '');
  final hover =
      merged.hoverBorderColor ?? CoreItemPickerStyle.defaultHoverBorderColor;
  final rest = merged.borderColor ?? CoreItemPickerStyle.defaultBorderColor;
  if (rest.token == null) {
    return (
      className: '',
      rule:
          '${WebPseudo.hover.selector(scopeSelector)}'
          '{border-color: ${hover.toValue()} !important;}',
    );
  }
  return emitPseudoColor(
    hover,
    hover,
    .border,
    pseudo: .hover,
    scopeSelector: scopeSelector,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedItemPicker] for the given [context].
///
/// Walks the nested-merge chain (Epic #1302):
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.itemPicker.style
///   → widget.itemPickerStyle
/// ```
///
/// [enabled] gates the frame's hover border (a disabled picker has no hover
/// step) and the title / empty-state colour (`disabledForegroundColor`), and [scopeId] names the frame's scope class when that border rides
/// a scoped rule (a raw colour); the widget passes both, and a caller that
/// reads only other slots may leave them at their defaults.
ResolvedItemPicker resolveItemPicker(
  BuildContext context, {
  bool enabled = true,
  String scopeId = '',
  CoreItemPickerStyle? itemPickerStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.itemPicker;

  final merged = resolveStyleChain(const CoreItemPickerStyle(), [
    csTheme?.style,
    itemPickerStyle,
  ]);

  // Nested search-field slot — the partial default (the frame's corner,
  // so the field is no rounder than the box it sits in), then the
  // per-instance `searchFieldStyle` override, then the row height last.
  // The height goes last because the Flutter twin sizes the row with a
  // `SizedBox(searchHeight)` that no `textFieldStyle.height` can beat — the
  // row height stays `searchHeight` on both platforms.
  //
  // Unstated, the row is the control ladder's md rung
  // (`defaultSearchHeight`) — the composed field's own row, which the field
  // already emits as the row variable a density moves. So no height is
  // forwarded for it: a forwarded height goes out as a literal and would
  // hold 40 under every density while the Flutter twin's row moves. The one
  // exception is a `searchFieldStyle` that states a height of its own, which
  // the row still has to beat — then the rung goes out as a literal, the one
  // length a forwarded height can carry, which no density reaches (the
  // Flutter twin holds the same authored rung in that case).
  // Forwarded to the composed `TextField(textFieldStyle:)`.
  final fieldStatesHeight =
      merged.searchFieldStyle?.height != null ||
      merged.searchFieldStyle?.minHeight != null;
  final searchHeight =
      merged.searchHeight ??
      (fieldStatesHeight ? CoreItemPickerStyle.defaultSearchHeight : null);
  final searchFieldStyle = CoreItemPickerStyle.defaultSearchFieldStyle
      .merge(merged.searchFieldStyle)
      .merge(CoreTextFieldStyle(height: searchHeight));

  // Nested search glyph / divider slots — design defaults merged with the
  // overrides and raw-forwarded (`Icon` / `Divider` resolve their own
  // chrome). A disabled picker takes the disabled tone unless the override
  // states a colour.
  final searchIconBase = CoreItemPickerStyle.defaultSearchIconStyle.merge(
    merged.searchIconStyle,
  );
  final searchIconStyle = enabled || merged.searchIconStyle?.color != null
      ? searchIconBase
      : searchIconBase.merge(
          const CoreIconStyle(
            color: CoreItemPickerStyle.defaultDisabledSearchIconColor,
          ),
        );
  final searchDividerStyle = CoreItemPickerStyle.defaultSearchDividerStyle
      .merge(merged.searchDividerStyle);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Colour / typography values route through the emit family — a single
  // class-XOR-inline decision per design value. Token-bound values emit
  // Tailwind classes (dark-mode reactive); raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web).
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CoreItemPickerStyle.defaultBackgroundColor,
    .background,
  );
  final borderEmit = emitColor(
    merged.borderColor,
    CoreItemPickerStyle.defaultBorderColor,
    .border,
  );
  // Hover border — a token rides `hover:border-*`; a raw colour has no
  // class, so the frame carries its scope class and
  // `resolveItemPickerRules` paints it (class XOR rule).
  final frameScopeClass = _frameScopeClass(scopeId);
  final hoverBorderEmit = _resolveHoverBorder(
    merged,
    enabled: enabled,
    scopeSelector: '.$frameScopeClass',
  );
  // Title / empty typography — `emitTypography` merges the token-backed
  // default role with any per-instance overlay, emitting the `text-{role}`
  // / `text-{colorToken}` / `font-{weight}` class for token values and any
  // explicit scalar / raw colour overlay inline alongside.
  // A disabled picker states its title and empty-state line in
  // `disabledForegroundColor`, layered last (the option rows take the same
  // colour in `resolveItemPickerOption`).
  final disabledTextStyle = enabled
      ? null
      : CoreTextStyle(
          color:
              merged.disabledForegroundColor ??
              CoreItemPickerStyle.defaultDisabledForegroundColor,
        );
  final titleEmit = emitTypography(
    merged.titleTextStyle?.merge(disabledTextStyle) ?? disabledTextStyle,
    CoreItemPickerStyle.defaultTitleTextStyle,
  );
  final emptyEmit = emitTypography(
    merged.emptyTextStyle?.merge(disabledTextStyle) ?? disabledTextStyle,
    CoreItemPickerStyle.defaultEmptyTextStyle,
  );
  // Border radius / width are **always** emitted inline (`(merged ??
  // default).toValue()` / rem) — no `rounded-*` / `border-N` class —
  // so the override path and the default path share one CSS surface
  // (Epic #1603 signature gate — radius / padding always-inline).
  final borderRadius =
      (merged.borderRadius ?? CoreItemPickerStyle.defaultBorderRadius)
          .toValue();
  final borderWidth =
      merged.borderWidth ?? CoreItemPickerStyle.defaultBorderWidth;
  // Shadow rung — the panel states its own (a floating face), so it rides
  // the elevation's `shadow-*` class and takes no style-contributed cast.
  final elevation = merged.elevation ?? CoreItemPickerStyle.defaultElevation;
  // Promoted dimensional overrides — resolved here so the title / empty
  // padding reflect `merged.X` (Epic #1603 coverage gate — all emitted
  // inline, no `p-*` class).
  final titlePadding =
      merged.titlePadding ?? CoreItemPickerStyle.defaultTitlePadding;
  final emptyPadding =
      merged.emptyPadding ?? CoreItemPickerStyle.defaultEmptyPadding;

  // ─── Local builders ───────────────────────────────────

  /// Composes the picker container Tailwind className — `flex flex-col
  /// w-full` stack with the border colour class ([borderEmit], token
  /// values only) and the default surface-tone background class when no
  /// per-instance override is supplied (card colour model). `w-full`
  /// fills the parent so the picker matches its Flutter twin instead of
  /// collapsing to content width.
  String buildContainerClassName() => [
    // This picker draws its own box rather than composing one, so what
    // shows through it is the page it is laid on — the same reasoning
    // that marks `card` and `alert` here while their Flutter twins
    // inherit it through `OutlinedContainer`. Paired with the fill
    // published below; the marker alone would resolve a preset's
    // restated colour to nothing and drop the background entirely.
    ...webSurfaceMarkerFor(CoreSurfaceRole.content),
    // A panel that states no shadow (`elevation: none`) takes the cast a
    // style contributes — its Flutter twin gets that from the
    // `OutlinedContainer` it composes, which hands any surface at rest the
    // style's cast. No-op under every style that contributes none.
    if (elevation == CoreOutlinedContainerElevation.none)
      kControlShadowRestMarker
    else
      elevation.tailwindShadowClass,
    '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.wFull} border',
    backgroundEmit.className,
    borderEmit.className,
    hoverBorderEmit.className,
    if (hoverBorderEmit.rule.isNotEmpty) frameScopeClass,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the picker container inline CSS — resolved border-radius /
  /// border-width plus any raw colour overrides ([backgroundEmit] /
  /// [borderEmit] inline fragments; token values stay on classes).
  Styles buildContainerInlineStyles() => .new(
    raw: {
      'border-radius': borderRadius,
      'border-width': strokeWidthCss(borderWidth),
      ...surfaceBleedVar(strokeWidthCss(borderWidth)),
      ...?backgroundEmit.inline,
      ...?borderEmit.inline,
      // The marker's other half — a preset restates this fill at a
      // lower alpha and cannot know which token the picker chose.
      ...surfaceFillVar(
        merged.backgroundColor ?? CoreItemPickerStyle.defaultBackgroundColor,
      ),
    },
  );

  /// Composes the picker title `<div>` Tailwind className — the typography
  /// role / colour / weight token classes from [titleEmit].
  String buildTitleClassName() => titleEmit.className;

  /// Composes the picker title `<div>` inline CSS — resolved padding plus
  /// the [titleEmit] inline fragments (explicit scalar / raw colour
  /// overlays only; token role / colour stay on classes).
  // The label spans every column of a grid list, so it reads as a heading
  // of the list rather than as a cell.
  Styles buildTitleInlineStyles() => .new(
    raw: {
      'padding': titlePadding.toValue(),
      'grid-column': '1 / -1',
      ...?titleEmit.inline,
    },
  );

  /// Composes the empty-state `<div>` Tailwind className — `text-center`
  /// plus the typography role / colour token classes from [emptyEmit].
  String buildEmptyClassName() =>
      ['text-center', emptyEmit.className].where((c) => c.isNotEmpty).join(' ');

  /// Composes the empty-state `<div>` inline CSS — resolved padding plus
  /// the [emptyEmit] inline fragments (explicit scalar / raw colour
  /// overlays only; token role / colour stay on classes).
  Styles buildEmptyInlineStyles() => .new(
    raw: {'padding': emptyPadding.toValue(), ...?emptyEmit.inline},
  );

  return ResolvedItemPicker(
    root: WebElementChrome(
      className: buildContainerClassName(),
      inlineStyles: buildContainerInlineStyles(),
    ),
    title: WebElementChrome(
      className: buildTitleClassName(),
      inlineStyles: buildTitleInlineStyles(),
    ),
    empty: WebElementChrome(
      className: buildEmptyClassName(),
      inlineStyles: buildEmptyInlineStyles(),
    ),
    items: const WebElementChrome(className: ''),
    searchFieldStyle: searchFieldStyle,
    searchIconStyle: searchIconStyle,
    searchDividerStyle: searchDividerStyle,
  );
}

// ═══════════════════════════════════════════════════
// resolveItemPickerItems — items scroll-area entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedItemPickerItems] for the items scroll-area. Closes
/// over the per-instance runtime `layout` / `gridColumns` so the layout
/// Tailwind className is pre-composed, plus the resolved
/// [CoreItemPickerStyle] for the padding / gap / `max-height` inline CSS.
ResolvedItemPickerItems resolveItemPickerItems(
  BuildContext context, {
  required CoreItemPickerLayout layout,
  required int gridColumns,
  CoreItemPickerStyle? itemPickerStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.itemPicker;
  final merged = resolveStyleChain(const CoreItemPickerStyle(), [
    csTheme?.style,
    itemPickerStyle,
  ]);
  final maxHeight = merged.maxHeight ?? CoreItemPickerStyle.defaultMaxHeight;
  final itemsPadding =
      merged.itemsPadding ?? CoreItemPickerStyle.defaultItemsPadding;
  // Inter-option spacing scalar — per-instance override wins, else the
  // design-system default. Flows straight into the grid `gap` CSS.
  final optionGap =
      merged.optionSpacing ?? CoreItemPickerStyle.defaultOptionSpacing;

  /// Composes the items scroll-area `<div>` Tailwind className based on
  /// the resolved [layout] / [gridColumns]. Layout only — padding / gap
  /// are emitted inline.
  String buildItemsClassName() => switch (layout) {
    .list => '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.overflowAuto}',
    .grid =>
      '${WebLayout.grid} grid-cols-$gridColumns ${WebLayout.overflowAuto}',
  };

  /// Composes the items scroll-area `<div>` inline CSS — resolved
  /// padding, `max-height`, and (grid only) the inter-item `gap`.
  Styles buildItemsInlineStyles() => .new(
    raw: {
      'padding': itemsPadding.toValue(),
      'max-height': '${maxHeight / kRemDivisor}rem',
      if (layout == .grid) 'gap': spaceCss(optionGap),
    },
  );

  return ResolvedItemPickerItems(
    root: WebElementChrome(
      className: buildItemsClassName(),
      inlineStyles: buildItemsInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// resolveItemPickerOption — per-option entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedItemPickerOption] for a single option.
///
/// Re-walks the same nested-merge chain as [resolveItemPicker]
/// (design-system default → `theme.coreComponentTheme.itemPicker.style` →
/// `widget.itemPickerStyle`) for the per-option selected / hover colour
/// and padding / gap / radius values — so the per-option chrome bundle
/// (className + inline CSS) is pre-composed without `ResolvedItemPicker`
/// carrying any behavioural / dimensional scalar (Epic #1603 옵션 B 최종).
/// Closes over the per-option runtime [selected] / [enabled].
ResolvedItemPickerOption resolveItemPickerOption(
  BuildContext context, {
  required bool selected,
  required bool enabled,
  required String scopeId,
  CoreItemPickerStyle? itemPickerStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.itemPicker;

  final merged = resolveStyleChain(const CoreItemPickerStyle(), [
    csTheme?.style,
    itemPickerStyle,
  ]);

  // ─── EMIT Stage 2 (Web, theme-free) — selected colours ─
  // The selected background / text colour routes through `emitColor` —
  // token default → Tailwind class (dark-mode reactive), raw override →
  // inline. No `scheme.resolve` (a no-op on Web).
  final selectedBgEmit = emitColor(
    merged.selectedColor,
    CoreItemPickerStyle.defaultSelectedColor,
    .background,
  );
  // Selected typography — the same bodyMedium role base with the selected
  // colour default layered before the per-instance override (mirrors the
  // Flutter chain `defaultOption.merge(defaultSelected).merge(override)`).
  // A disabled picker says so in its own token — the option text and the
  // check take `disabledForegroundColor`, in every state (a disabled row has
  // no hover step and its selected mark is as inert as the rest).
  final disabledForegroundColor =
      merged.disabledForegroundColor ??
      CoreItemPickerStyle.defaultDisabledForegroundColor;
  final disabledTextStyle = enabled
      ? null
      : CoreTextStyle(color: disabledForegroundColor);
  final selectedTypographyEmit = emitTypography(
    CoreItemPickerStyle.defaultSelectedTextStyle
        .merge(merged.selectedTextStyle)
        .merge(disabledTextStyle),
    CoreItemPickerStyle.defaultOptionTextStyle,
  );
  // Resting option typography — role + colour through the emit family
  // (`text-body-medium` + `text-on-surface` classes for token values, so
  // the `hover:text-*` pseudo below cascades over the colour — #2126
  // class; explicit overlays go inline). Colour-only extraction dropped
  // the role and the options rendered at the inherited one.
  final optionTypographyEmit = emitTypography(
    merged.optionTextStyle?.merge(disabledTextStyle) ?? disabledTextStyle,
    CoreItemPickerStyle.defaultOptionTextStyle,
  );
  // Hover colours flow through the `hover:` pseudo class on the option,
  // so the merged value (override ?? default) is read via `.tailwindColor`
  // (Epic #1603 coverage gate — `optionHoverColor` /
  // `optionHoverTextStyle.color` reflected). Pseudo-state cannot be
  // expressed inline, so these stay as token classes regardless of source.
  final optionHoverColor =
      merged.optionHoverColor ?? CoreItemPickerStyle.defaultOptionHoverColor;
  final optionHoverTextColor =
      merged.optionHoverTextStyle?.color ??
      CoreItemPickerStyle.defaultOptionHoverTextStyle.color!;
  // Class-vs-scoped-rule pivots. A `hover:` pseudo colour can only ride a
  // Tailwind class when it is a design-system token; a raw (token-less)
  // hover background / text colour has no class, so the option drops the
  // `hover:bg-*` / `hover:text-*` utility and carries the shared scope
  // class the `resolveItemPickerRules` `<style>` targets instead (class
  // XOR rule). Every option shares one hover colour, so one class-scoped
  // rule covers them all. Disabled options drop the hover affordance, so
  // never route to a rule.
  final optionHoverBgRaw = enabled && optionHoverColor.token == null;
  final optionHoverTextRaw = enabled && optionHoverTextColor.token == null;
  final optionPadding =
      merged.optionPadding ?? CoreItemPickerStyle.defaultOptionPadding;
  // Inter-option spacing scalar — per-instance override wins, else the
  // design-system default. Web is scaling-agnostic, so the value flows
  // straight into the inline `gap` CSS through `spaceCss`.
  final optionSpacing =
      merged.optionSpacing ?? CoreItemPickerStyle.defaultOptionSpacing;
  final optionBorderRadius =
      merged.optionBorderRadius ??
      CoreItemPickerStyle.defaultOptionBorderRadius;
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreItemPickerStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  /// Composes the per-option Tailwind className — base layout + per-state
  /// selected / hover classes. `w-full` fills the composing `Clickable`
  /// root so the row spans its cell (list) / column (grid). Padding / gap
  /// / border-radius are emitted inline (signature gate); selected / hover
  /// colours follow the card colour model (default token class, raw
  /// override → inline). Cursor / focus ring live on the `Clickable`.
  String buildOptionClassName() {
    const base =
        '${WebLayout.relative} ${WebLayout.flex} ${WebLayout.itemsCenter} '
        '${WebLayout.wFull} select-none';

    if (selected) {
      return [
        base,
        selectedBgEmit.className,
        selectedTypographyEmit.className,
      ].where((cls) => cls.isNotEmpty).join(' ');
    }

    return [
      base,
      // Role + base text colour as classes so the `hover:text-*` pseudo
      // below can cascade over the colour — an inline `color` would win
      // and the hover tint would never apply (#2126 class).
      optionTypographyEmit.className,
      // Hover colours read the merged value (`optionHoverColor` /
      // `optionHoverTextColor`) through the `hover:` pseudo class so the
      // CSS `:hover` state reflects the override (Epic #1603 coverage
      // gate). A token colour rides its `hover:bg-*` / `hover:text-*`
      // class; a raw override drops the class and carries the shared
      // scope class the scoped `.co-item-picker-h:hover` rule targets
      // (class XOR rule). Disabled options drop the hover affordance
      // entirely.
      if (enabled) ...[
        if (!optionHoverBgRaw) 'hover:bg-${optionHoverColor.tailwindColor}',
        if (!optionHoverTextRaw)
          'hover:text-${optionHoverTextColor.tailwindColor}',
        if (optionHoverBgRaw || optionHoverTextRaw) 'co-item-picker-h-$scopeId',
      ],
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the per-option inline CSS — resolved padding / gap /
  /// border-radius plus any raw selected colour overrides
  /// ([selectedBgEmit] / [selectedTextEmit] inline fragments; token
  /// values stay on classes). Resting text colour is a class so
  /// `hover:text-*` cascades over it (no inline `color`).
  Styles buildOptionInlineStyles() {
    final raw = {
      'border-radius': optionBorderRadius.toValue(),
      'padding': optionPadding.toValue(),
      'gap': spaceCss(optionSpacing),
      if (selected) ...?selectedBgEmit.inline,
      if (selected)
        ...?selectedTypographyEmit.inline
      else
        ...?optionTypographyEmit.inline,
    };
    return Styles(raw: raw);
  }

  // Nested Icon slot — the resolved check-glyph size and colour (override
  // else the single-source named defaults) bundled into a `CoreIconStyle`,
  // raw-forwarded to the composed `Icon` (mirrors the Flutter twin's
  // `checkIconStyle`).
  final checkIconStyle = CoreIconStyle(
    size: merged.checkIconSize ?? CoreItemPickerStyle.defaultCheckIconSize,
    color: enabled
        ? merged.checkColor ?? CoreItemPickerStyle.defaultCheckColor
        : disabledForegroundColor,
  );

  return ResolvedItemPickerOption(
    root: WebElementChrome(
      className: buildOptionClassName(),
      inlineStyles: buildOptionInlineStyles(),
    ),
    clickableStyle: clickableStyle,
    checkIconStyle: checkIconStyle,
  );
}

// ═══════════════════════════════════════════════════
// resolveItemPickerRules — scoped <style> entry point
// ═══════════════════════════════════════════════════

/// Resolves the scoped `<style>` rules for an `ItemPicker` whose option
/// `:hover` background / text colour moves off the Tailwind scale — see
/// [ResolvedItemPickerRules]. Returns empty CSS on the default path
/// (`resolveItemPickerOption` keeps the utility classes: class XOR rule).
///
/// The merge chain mirrors [resolveItemPickerOption], so the class-drop
/// conditions and the scoped rules always see the same resolved values.
/// Disabled pickers drop the hover affordance, so emit no rules.
ResolvedItemPickerRules resolveItemPickerRules(
  BuildContext context, {
  required String scopeId,
  required bool enabled,
  CoreItemPickerStyle? itemPickerStyle,
}) {
  if (!enabled) return const ResolvedItemPickerRules(css: '');

  final csTheme = context.theme.coreComponentTheme?.itemPicker;
  final merged = resolveStyleChain(const CoreItemPickerStyle(), [
    csTheme?.style,
    itemPickerStyle,
  ]);

  final buffer = StringBuffer();
  final scopeSelector = '.co-item-picker-h-$scopeId';

  // Frame hover border — the rule half of the class XOR rule
  // `resolveItemPicker` decides with the same helper.
  buffer.write(
    _resolveHoverBorder(
      merged,
      enabled: enabled,
      scopeSelector: '.${_frameScopeClass(scopeId)}',
    ).rule,
  );

  // Hover background — a raw (token-less) override paints via the scoped
  // `.co-item-picker-h-<id>:hover` rule (all options share the one colour).
  final optionHoverColor =
      merged.optionHoverColor ?? CoreItemPickerStyle.defaultOptionHoverColor;
  if (optionHoverColor.token == null) {
    buffer.write(
      emitPseudoColor(
        optionHoverColor,
        optionHoverColor,
        .background,
        pseudo: .hover,
        scopeSelector: scopeSelector,
      ).rule,
    );
  }

  // Hover text — same class-XOR-rule pivot on the text colour.
  final optionHoverTextColor =
      merged.optionHoverTextStyle?.color ??
      CoreItemPickerStyle.defaultOptionHoverTextStyle.color!;
  if (optionHoverTextColor.token == null) {
    buffer.write(
      emitPseudoColor(
        optionHoverTextColor,
        optionHoverTextColor,
        .text,
        pseudo: .hover,
        scopeSelector: scopeSelector,
      ).rule,
    );
  }

  return ResolvedItemPickerRules(css: buffer.toString());
}

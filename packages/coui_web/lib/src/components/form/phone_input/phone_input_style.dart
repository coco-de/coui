import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// flag-icons flags are authored at a 4:3 aspect (viewBox 640×480); the Flutter
// `PhoneInput` renders the same flag-icons SVGs via `CountryFlag`, so both
// platforms show identical flags. Not a design token — the intrinsic aspect
// ratio of the flag artwork.
const double _kFlagAspectRatio = 4 / 3;

// The chevron `<svg>` is drawn inline on Lucide's 24-unit grid — the
// `viewBox` `phone_input.dart` writes on it and the grid its `polyline`
// points are authored on. Not a design token; the stroke rule needs it to
// turn a rendered weight into the glyph's own units.
const _kChevronViewBox = 24;

/// Inline CSS carrying the per-country flag `background-image` for the flag
/// box `<div>`. The box is a single element (no child `<img>`) so the SVG's
/// intrinsic size never leaks into the surrounding flex row. Only the image
/// URL is per-instance content; the box size / `background-size` chrome is
/// emitted by the resolver (`buildFlagInlineStyles` etc.). Lives in the style
/// layer so the widget stays render-only.
Styles buildPhoneFlagBackground(String url) =>
    .new(raw: {'background-image': 'url($url)'});

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `PhoneInput`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                       // outer container row
///   ├─ countrySelector (<button>)                    // flag + dial code + chevron trigger
///   │    ├─ flag (<span>)                            // flag emoji
///   │    ├─ dialCode (<span>)                        // dial code text
///   │    └─ chevron (<svg>)                          // dropdown chevron icon
///   ├─ phoneInput (<input type="tel">)               // phone number field
///   └─ dropdown (<div role="listbox">)               // co_phone_input renders only when open
///        ├─ searchInput (<input>)                    // country search field
///        └─ dropdownItem (<button role="option">)    // co_phone_input renders one per filtered country
///             ├─ dropdownItemFlag (<span>)           // flag emoji
///             ├─ dropdownItemName (<span>)           // country name
///             └─ dropdownItemDialCode (<span>)       // dial code text
/// ```
///
/// All slot chromes are non-null — `co_phone_input` decides whether to
/// render each optional slot (dropdown, dropdown items) based on
/// instance state.
///
/// Per Epic #1603 (옵션 B 최종, 단일 inline 시그니처) every dimensional
/// chrome value (border radius / padding / sizes / offsets / font sizes
/// / border width) is emitted **inline** as a `rem` value or
/// `(merged.X ?? default).toValue()` — never a radius / padding utility
/// class, and no class-drop branching. Inter-child spacers (flag↔dial
/// code, country selector↔input, dropdown flag↔name) are nested `Gap`
/// children that self-resolve from the [CoreGapStyle] slots
/// ([flagGapStyle] / [countryGapStyle] / [dropdownItemGapStyle]). Only
/// colour and typography tokens stay as Tailwind classes (card 모범 —
/// default token class, override suppresses the class so the inline
/// rule wins).
class ResolvedPhoneInput implements WebResolvedChrome {
  /// Creates a [ResolvedPhoneInput].
  const ResolvedPhoneInput({
    required this.root,
    required this.countrySelector,
    required this.flag,
    required this.dialCode,
    required this.chevron,
    required this.phoneInput,
    required this.dropdown,
    required this.searchInput,
    required this.dropdownItem,
    required this.dropdownItemFlag,
    required this.dropdownItemName,
    required this.dropdownItemDialCode,
    required this.flagGapStyle,
    required this.countryGapStyle,
    required this.dropdownItemGapStyle,
    required this.numberFieldStyle,
    required this.searchFieldStyle,
    required this.popoverStyle,
    required this.separator,
    required this.separatorLine,
    required this.separatorDividerStyle,
    required this.dividerStyle,
    required this.searchIconStyle,
    required this.dropdownCheckIconStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` row container —
  /// composed `relative flex items-stretch border` className plus the
  /// colour token classes (`border-{outline}` / `bg-{surface}`
  /// suppressed when overridden) and the focus-within / hover border steps
  /// (the hover step only while enabled and not focus-within), and an
  /// inline-CSS bundle carrying the
  /// resolved height / border-width / border-radius / max-width /
  /// country gap / padding / disabled opacity. State-driven (`enabled`)
  /// so the disabled opacity travels with the pre-computed root chrome.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the country selector `<button>` — composed
  /// Tailwind className (flex layout + typography + hover background +
  /// colour-token border-right) plus an inline-CSS bundle carrying the
  /// resolved flag gap / selector padding / border-width.
  final WebElementChrome countrySelector;

  /// Paint-ready chrome for the selector flag `<span>` — composed
  /// typography className plus the resolved `font-size` inline CSS
  /// (drives the emoji visual size).
  final WebElementChrome flag;

  /// Paint-ready chrome for the selector dial code `<span>` — composed
  /// typography + font-weight className; inline CSS is `null`.
  final WebElementChrome dialCode;

  /// Paint-ready chrome for the dropdown chevron `<svg>` — inline CSS
  /// carries the resolved `width` / `height` (logical px → rem) so the
  /// HTML `width` / `height` attributes do not have to expose a scalar
  /// on the resolved layer (Epic #1603 옵션 B 최종). `co_phone_input`
  /// applies `chevron.inlineStyles` as the SVG element style.
  final WebElementChrome chevron;

  /// Paint-ready chrome for the `<div>` that hosts the composed number
  /// `TextField` — composed Tailwind className (flex layout + typography +
  /// focus) plus the resolved horizontal padding inline CSS. The
  /// placeholder colour is not here: `::placeholder` only matches the
  /// `<input>` inside the field, so it rides [numberFieldStyle]. Disabled
  /// opacity is applied at the container level (the outer chrome fades
  /// together).
  final WebElementChrome phoneInput;

  /// Paint-ready chrome for the country dropdown `<div role="listbox">`
  /// — composed Tailwind className (absolute positioning + z-index +
  /// colour-token border + shadow + overflow) plus an inline-CSS bundle
  /// carrying the resolved popover top offset / popup border radius /
  /// max-height / width. `co_phone_input` renders this only when the
  /// dropdown is open.
  final WebElementChrome dropdown;

  /// Paint-ready chrome for the `<div>` that hosts the composed search
  /// `TextField` — composed Tailwind className (full width + typography +
  /// colour-token border-bottom + background + focus) plus the resolved
  /// dropdown-item padding inline CSS. The placeholder colour rides
  /// [searchFieldStyle], for the same reason as [phoneInput].
  final WebElementChrome searchInput;

  /// Paint-ready chrome for a single dropdown `<button role="option">`
  /// row — composed Tailwind className (flex layout + typography +
  /// hover) plus an inline-CSS bundle carrying the resolved
  /// dropdown-item padding (the inner spans carry the row's gaps).
  /// Chrome is identical across all rows (no per-country variation).
  final WebElementChrome dropdownItem;

  /// Paint-ready chrome for the dropdown item flag `<span>` — composed
  /// typography className plus the resolved `font-size` inline CSS
  /// (drives the emoji visual size).
  final WebElementChrome dropdownItemFlag;

  /// Paint-ready chrome for the dropdown item name `<span>` — composed
  /// `flex-1 text-left` className plus the resolved flag→name gap inline
  /// CSS (`margin-left` = dropdown item gap).
  final WebElementChrome dropdownItemName;

  /// Paint-ready chrome for the dropdown item dial code `<span>` —
  /// composed colour-token className (`text-{onSurfaceVariant}`) only.
  /// The name→dial-code spacer is a nested `Gap` child (see
  /// [countryGapStyle]).
  final WebElementChrome dropdownItemDialCode;

  /// Nested [CoreGapStyle] for the selector flag↔dial-code spacer —
  /// forwarded to `Gap(gapStyle: …)`.
  final CoreGapStyle flagGapStyle;

  /// Nested [CoreGapStyle] for the dropdown-item name↔dial-code spacer
  /// (also reused as the country-selector↔input gap when needed) —
  /// forwarded to `Gap(gapStyle: …)`.
  final CoreGapStyle countryGapStyle;

  /// Nested [CoreGapStyle] for the dropdown-item flag↔name spacer —
  /// forwarded to `Gap(gapStyle: …)`.
  final CoreGapStyle dropdownItemGapStyle;

  /// Resolved phone-number field style — the chromeless default with the
  /// resolved `placeholderColor` laid over its placeholder slot, so the
  /// colour reaches the `<input>` the composed `TextField` owns. The nested
  /// `numberFieldStyle` override is merged last, preserving caller precedence.
  /// Raw-forwarded to that `TextField`.
  final CoreTextFieldStyle numberFieldStyle;

  /// Resolved dropdown search-field style — the chromeless default, the
  /// resolved `placeholderColor` over its placeholder slot, then the
  /// caller's `searchFieldStyle` (so a nested placeholder override still
  /// wins for the search field). Raw-forwarded to the search `TextField`.
  final CoreTextFieldStyle searchFieldStyle;

  /// Resolved country-dropdown popover style (`triggerSizing: expand` default
  /// merged with the caller override) — raw-forwarded to the `Popover`.
  final CorePopoverStyle popoverStyle;

  /// Paint-ready chrome for the wrapper that centres the hairline between
  /// the selector and the number in the row.
  final WebElementChrome separator;

  /// Paint-ready chrome for the box that gives the hairline its height —
  /// shorter than the row.
  final WebElementChrome separatorLine;

  /// Nested [CoreDividerStyle] slot of the vertical `Divider` inside
  /// [separatorLine] — the separator colour at the box's stroke width.
  final CoreDividerStyle separatorDividerStyle;

  /// Nested [CoreDividerStyle] slot of the horizontal `Divider` that closes
  /// the country search row.
  final CoreDividerStyle dividerStyle;

  /// Search glyph in front of the country search field — raw-forwarded to
  /// `Icon`.
  final CoreIconStyle searchIconStyle;

  /// Selected-country check glyph — raw-forwarded to `Icon`.
  final CoreIconStyle dropdownCheckIconStyle;
}

/// Scoped CSS text for `<style>` block in `PhoneInput`.
///
/// Non-empty only when a per-instance / theme override moves a pseudo-state
/// colour off the Tailwind scale — a raw (token-less) `focusBorderColor`,
/// `hoverBorderColor` or `hoverColor`. Those pseudo-states (`:focus-within` /
/// `:hover`) cannot be expressed inline, so the affected elements carry a scope
/// class and `resolvePhoneInput` drops the matching pseudo utility class
/// (class XOR rule):
/// * `.co-phone-input-fw-<id>:focus-within{border-color: …}` (field row),
/// * `.co-phone-input-hb-<id>:hover:not(:focus-within){border-color: …}`
///   (field row — the hover step excludes focus-within in the selector
///   itself, so the focused border wins whatever the cascade order),
/// * `.co-phone-input-h-<id>:hover{background-color: …}` (selector + items).
///
/// `placeholderColor` is not among them: `::placeholder` only matches an
/// `<input>`, and both inputs belong to composed `TextField`s — so the
/// colour rides their style slots and each `TextField` emits it.
class ResolvedPhoneInputRules {
  /// Creates a [ResolvedPhoneInputRules].
  const ResolvedPhoneInputRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedPhoneInput] for the given [context].
///
/// Walks the nested-merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.phoneInput.style
///   → widget.phoneInputStyle
/// ```
ResolvedPhoneInput resolvePhoneInput(
  BuildContext context, {
  required bool enabled,
  required String scopeId,
  CorePhoneInputStyle? phoneInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.phoneInput;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CorePhoneInputStyle(), [
    csTheme?.style,
    phoneInputStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Every dimensional value finished its merge + fallback so the local
  // builders below run from a single source of truth and emit it inline
  // (단일 시그니처 — `(merged.X ?? default)` 으로 분기 없이).
  final borderRadius =
      (merged.borderRadius ?? CorePhoneInputStyle.defaultBorderRadius)
          .toValue();
  // The box is a row of the control ladder (the md rung, the row of the
  // text field beside it): unstated, it goes out as the row variable so a
  // density moves it, as on Flutter. A caller's own height is a statement
  // and stays as stated.
  final height = merged.height == null
      ? controlHeightCss(CorePhoneInputStyle.defaultHeight)
      : '${merged.height! / kRemDivisor}rem';
  final borderWidth =
      merged.borderWidth ?? CorePhoneInputStyle.defaultBorderWidth;
  final maxWidth = merged.maxWidth ?? CorePhoneInputStyle.defaultMaxWidth;
  final padding = merged.padding;
  final disabledOpacity =
      merged.disabledOpacity ?? CorePhoneInputStyle.defaultDisabledOpacity;
  // Logical sides: the selector's inset is a statement about reading order
  // (start 14, end 10), emitted as `padding-inline-*`.
  final selectorPadding =
      merged.selectorPadding ?? CorePhoneInputStyle.defaultSelectorPadding;
  final inputFieldPadding =
      merged.inputFieldPadding ?? CorePhoneInputStyle.defaultInputFieldPadding;
  final dropdownItemPadding =
      (merged.dropdownItemPadding ??
              CorePhoneInputStyle.defaultDropdownItemPadding)
          .toValue();
  final dropdownListPadding =
      (merged.dropdownListPadding ??
              CorePhoneInputStyle.defaultDropdownListPadding)
          .toValue();
  final dropdownItemBorderRadius =
      (merged.dropdownItemBorderRadius ??
              CorePhoneInputStyle.defaultDropdownItemBorderRadius)
          .toValue();
  final flagBorderRadius =
      (merged.flagBorderRadius ?? CorePhoneInputStyle.defaultFlagBorderRadius)
          .toValue();
  final separatorHeight =
      merged.separatorHeight ?? CorePhoneInputStyle.defaultSeparatorHeight;

  // Nested gap-style slots — forwarded straight to `Gap(gapStyle: …)`
  // for the selector flag↔dial-code spacer, the dropdown-item flag↔name
  // spacer, and the dropdown-item name↔dial-code spacer (reused as the
  // country-selector↔input gap).
  final flagGapStyle = CorePhoneInputStyle.defaultFlagGapStyle.merge(
    merged.flagGapStyle,
  );
  final countryGapStyle = CorePhoneInputStyle.defaultCountryGapStyle.merge(
    merged.countryGapStyle,
  );
  final dropdownItemGapStyle = CorePhoneInputStyle.defaultDropdownItemGapStyle
      .merge(
        merged.dropdownItemGapStyle,
      );
  // ─── Colour / typography emits (theme-free, Core single source) ───
  // Non-pseudo colour tokens flow through `emitColor` (default → class,
  // override → inline). Pseudo-state colours (hover / placeholder) cannot
  // be expressed inline, so they resolve to a `CoreColor` and emit a
  // `.tailwindColor` class straight from the Core default.
  // Disabled swaps the box onto its own fill / edge tokens rather than
  // dimming the whole component.
  final background = enabled
      ? emitColor(
          merged.backgroundColor,
          CorePhoneInputStyle.defaultBackgroundColor,
          .background,
        )
      : emitColor(
          merged.disabledBackgroundColor,
          CorePhoneInputStyle.defaultDisabledBackgroundColor,
          .background,
        );
  // surface:content — the field draws its own box on the root `<div>`
  // rather than composing `OutlinedContainer` (the inner number field is
  // deliberately chromeless — `chromelessFieldStyle` — so the root owns
  // the single visible boundary). The design default always states a
  // solid `surface` token, so the pair applies unconditionally unless the
  // caller explicitly opted out with a raw transparent override (e.g. the
  // `.transparent` chrome preset) — same gate every other content-role
  // surface on this axis uses.
  final containerFillCore = enabled
      ? merged.backgroundColor ?? CorePhoneInputStyle.defaultBackgroundColor
      : merged.disabledBackgroundColor ??
            CorePhoneInputStyle.defaultDisabledBackgroundColor;
  final border = enabled
      ? emitColor(
          merged.borderColor,
          CorePhoneInputStyle.defaultBorderColor,
          .border,
        )
      : emitColor(
          merged.disabledBorderColor,
          CorePhoneInputStyle.defaultDisabledBorderColor,
          .border,
        );
  // Pseudo-state colours (focus-within border / hover background /
  // placeholder text) cannot be expressed inline — a design-system TOKEN
  // rides a Tailwind pseudo class (`focus-within:border-*`), while a RAW
  // (token-less) caller / theme override has no class and falls back to a
  // scoped `<style>` rule keyed on the element's scope class (see
  // [resolvePhoneInputRules]). `emitPseudoColor` picks the branch: the class
  // path is byte-identical to the pre-fallback `.tailwindColor` emission, so
  // token defaults / overrides render unchanged (no `<style>`). When the
  // className is empty the value went raw — the element drops the pseudo class
  // and carries the shared scope class instead (class XOR rule).
  final focusBorderPseudo = emitPseudoColor(
    merged.focusBorderColor,
    CorePhoneInputStyle.defaultFocusBorderColor,
    .border,
    pseudo: .focusWithin,
    scopeSelector: '.co-phone-input-fw-$scopeId',
  );
  // Hover border — the outer box takes one step toward the text colour while
  // the pointer is over it. `disabled > focus-within > hover > rest`:
  //  * a disabled field takes no hover step, so nothing is emitted (class and
  //    scope class alike);
  //  * focus-within outranks hover by *construction*, not by cascade order —
  //    Tailwind v3 emits `hover:` AFTER `focus-within:` at the same
  //    specificity, so a plain `hover:border-*` would beat the focused border
  //    while the pointer sits over a focused field. The
  //    `hoverUnlessFocusWithin` pseudo excludes `:focus-within` from the
  //    hover selector itself.
  //  * a raw resting border is emitted INLINE (`border.inline`), and inline
  //    outranks every selector — so the hover step is `!important` exactly
  //    then, or a caller who restyles the resting border would silently lose
  //    the hover step the Flutter twin still takes.
  final hoverBorderPseudo = enabled
      ? emitPseudoColor(
          merged.hoverBorderColor,
          CorePhoneInputStyle.defaultHoverBorderColor,
          .border,
          pseudo: .hoverUnlessFocusWithin,
          scopeSelector: '.co-phone-input-hb-$scopeId',
          important: border.inline != null,
        )
      : (className: '', rule: '');
  final hoverBorderRaw = enabled && hoverBorderPseudo.className.isEmpty;
  // Selector trigger + every dropdown row share the one `hoverColor`, so a raw
  // override paints via a single shared `.co-phone-input-h-<id>:hover` rule.
  final hoverPseudo = emitPseudoColor(
    merged.hoverColor,
    CorePhoneInputStyle.defaultHoverColor,
    .background,
    pseudo: .hover,
    scopeSelector: '.co-phone-input-h-$scopeId',
  );
  // The keyboard highlight (`aria-selected` on the option the search field's
  // `aria-activedescendant` points at) paints with the same `hoverColor` a
  // pointer hover does — one "this row is the one" colour whichever device
  // got there. A raw override shares the row's `.co-phone-input-h-<id>`
  // scope class.
  final highlightPseudo = emitPseudoColor(
    merged.hoverColor,
    CorePhoneInputStyle.defaultHoverColor,
    .background,
    pseudo: .ariaSelected,
    scopeSelector: '.co-phone-input-h-$scopeId',
  );
  final focusBorderRaw = focusBorderPseudo.className.isEmpty;
  final hoverRaw = hoverPseudo.className.isEmpty;
  // Typography slots → `emitTypography` (role class + explicit overlay
  // inline). Flag uses the `labelLarge` baseline role; the visual emoji
  // size is overlaid as `font-size` inline by the flag builders.
  final bodyText = emitTypography(
    merged.bodyTextStyle,
    CorePhoneInputStyle.defaultBodyTextStyle,
  );
  // Per-state dial-code colour — enabled uses the slot's own `onSurface`
  // (or the per-instance override); disabled swaps to the muted tone (or
  // its own override). Mirrors the Flutter resolver's
  // `dialCodeTextStyleEnabled` / `dialCodeTextStyleDisabled` pair.
  final disabledDialCodeColorCore =
      merged.disabledDialCodeColor ??
      CorePhoneInputStyle.defaultDisabledDialCodeColor;
  final dialCodeDefaultTextStyle = enabled
      ? CorePhoneInputStyle.defaultDialCodeTextStyle
      : CorePhoneInputStyle.defaultDialCodeTextStyle.copyWith(
          color: disabledDialCodeColorCore,
        );
  final dialCodeText = emitTypography(
    merged.dialCodeTextStyle,
    dialCodeDefaultTextStyle,
  );
  // Muted dropdown dial-code text — the `bodySmall` role + the
  // `onSurfaceVariant` colour live in
  // `CorePhoneInputStyle.defaultDropdownDialCodeTextStyle`; layer the
  // per-instance `dropdownDialCodeTextStyle` slot over it so the dial-code
  // span emits its typography + colour token classes from the single slot
  // (no state branch — mirrors the Flutter muted hint).
  final dropdownDialCodeText = emitTypography(
    merged.dropdownDialCodeTextStyle,
    CorePhoneInputStyle.defaultDropdownDialCodeTextStyle,
  );
  // The unified `Popover` owns the panel placement + border-radius (reflected
  // through the forwarded `popoverStyle` below). On the inner scrollable
  // listbox the scroll `max-height` is always applied; the `max-width` cap is
  // override-only.
  final popupMaxHeight =
      merged.popupMaxHeight ?? CorePhoneInputStyle.defaultPopupMaxHeight;
  // Override-only: `null` on the default path so the listbox is not
  // width-capped (the panel matches the anchor via the Popover's
  // `anchorFixedSize`), keeping the default output byte-identical and matching
  // the Flutter listbox (no width cap). A caller override caps the scrollable
  // list width.
  final popupMaxWidth = merged.popupMaxWidth;
  // Reflect the phone-input-level popover panel overrides into the forwarded
  // `popoverStyle` slot so a caller who overrides `popupBorderRadius` /
  // `popoverTopOffset` on `CorePhoneInputStyle` reaches the unified `Popover`'s
  // panel (mirrors the Flutter resolver, which resolves the same fields). They
  // sit as a BASE layer so a raw `popoverStyle` override still wins:
  //   * `popupBorderRadius` → the composed `Popup` panel corner radius. Its
  //     default is `CorePopupStyle`'s own default radius, so
  //     `?? default` is a no-op on the default path (byte-identical panel).
  //   * `popoverTopOffset` → the trigger↔panel placement gap. Its field default
  //     (`space4`) differs from the `Popover`'s own placement default
  //     (`space8`), so it is reflected override-only (`null` keeps
  //     its default gap), preserving the current default output.
  // Nested child-component field styles — the one `placeholderColor` laid
  // over both composed `TextField`s' placeholder slots (the colour can only
  // reach the `<input>`s through them), then raw-forwarded. The search
  // field applies it before the caller's `searchFieldStyle`, so a nested
  // placeholder override still wins there (Flutter resolver parity).
  final placeholderOverlay = CorePhoneInputStyle.placeholderFieldStyle(
    enabled
        ? merged.placeholderColor ?? CorePhoneInputStyle.defaultPlaceholderColor
        : merged.disabledPlaceholderColor ??
              CorePhoneInputStyle.defaultDisabledPlaceholderColor,
  );
  final numberFieldStyle = CorePhoneInputStyle.defaultNumberFieldStyle
      .merge(placeholderOverlay)
      .merge(merged.numberFieldStyle);
  final searchFieldStyle = CorePhoneInputStyle.defaultSearchFieldStyle
      .merge(placeholderOverlay)
      .merge(merged.searchFieldStyle);
  final popoverStyle = CorePopoverStyle(
    panelStyle: CorePopupStyle(
      borderRadius:
          merged.popupBorderRadius ??
          CorePhoneInputStyle.defaultPopupBorderRadius,
    ),
    placementOffset: merged.popoverTopOffset,
  ).merge(CorePhoneInputStyle.defaultPopoverStyle).merge(merged.popoverStyle);
  final searchIconStyle = CorePhoneInputStyle.defaultSearchIconStyle.merge(
    merged.searchIconStyle,
  );
  final dropdownCheckIconStyle = CorePhoneInputStyle
      .defaultDropdownCheckIconStyle
      .merge(merged.dropdownCheckIconStyle);
  final separatorColorCore =
      merged.separatorColor ?? CorePhoneInputStyle.defaultSeparatorColor;
  final flagSize = merged.flagSize ?? CorePhoneInputStyle.defaultFlagSize;
  final dropdownFlagSize =
      merged.dropdownFlagSize ?? CorePhoneInputStyle.defaultDropdownFlagSize;
  final chevronIconSize =
      merged.chevronIconStyle?.size ??
      CorePhoneInputStyle.defaultChevronIconStyle.size!;
  final disabled = !enabled;
  // Per-state chevron colour — mirrors the Flutter resolver's
  // `chevronIconStyleEnabled` / `chevronIconStyleDisabled` pair.
  final chevronColorCore = enabled
      ? (merged.chevronColor ?? CorePhoneInputStyle.defaultChevronColor)
      : (merged.disabledChevronColor ??
            CorePhoneInputStyle.defaultDisabledChevronColor);
  final chevronColorEmit = emitColor(null, chevronColorCore, .text);

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the root `<div>` Tailwind className. Only layout +
  /// colour-token classes — every dimensional value (height /
  /// border-width / radius / max-width / country gap / padding) is
  /// emitted inline by [buildRootInlineStyles].
  ///
  /// `overflow-hidden` clips the selector trigger's hover background to the
  /// container's rounded border (matching the Flutter outer container's
  /// `clipBehavior: antiAlias`). It is safe now that the country dropdown is
  /// portal-mounted through the `Popover` (a separate DOM subtree) rather than
  /// an in-flow sibling — so clipping the row no longer clips the panel.
  String buildRootClassName() => <String>[
    // States no shadow of its own, so it takes the style's — the
    // Flutter twin reads the same cast.
    kControlShadowRestMarker,
    // `w-full`: the field is a full-width input (like `TextField`'s
    // `grid w-full` root). Inside the Popover's flex trigger wrapper the
    // row is a flex item, which would otherwise shrink to content width.
    '${WebLayout.relative} ${WebLayout.flex} ${WebLayout.itemsStretch}',
    '${WebLayout.wFull} ${WebLayout.overflowHidden} border',
    border.className,
    focusBorderPseudo.className,
    if (focusBorderRaw) 'co-phone-input-fw-$scopeId',
    hoverBorderPseudo.className,
    if (hoverBorderRaw) 'co-phone-input-hb-$scopeId',
    background.className,
    if (!containerFillCore.isTransparent) ...webSurfaceMarkerFor(.content),
    // The frame clips the selector's hover fill to its corners and keeps a
    // border — a material that draws its own edge reaches its band over that
    // line (`kWebSurfaceClipMarker`).
    if (!containerFillCore.isTransparent && borderWidth > 0)
      kWebSurfaceClipMarker,
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the root `<div>` inline-CSS bundle — every dimensional
  /// chrome value plus the disabled opacity (단일 inline 시그니처). No
  /// flex `gap` here: the country selector and phone field sit flush,
  /// separated by the selector's `border-right` divider (matching the
  /// Flutter `Row` with no inter-child spacer).
  Styles buildRootInlineStyles() {
    final foldable = !containerFillCore.isTransparent && borderWidth > 0;
    final raw = {
      'height': height,
      'border-width': strokeWidthCss(borderWidth),
      if (foldable) ...surfaceClipFold(strokeWidthCss(borderWidth)),
      'border-radius': borderRadius,
      ...?border.inline,
      ...?background.inline,
      // The marker's other half — a preset restates this fill at a lower
      // alpha and cannot know which token the field chose.
      if (!containerFillCore.isTransparent)
        ...surfaceFillVar(containerFillCore),
    };
    if (padding != null) {
      if (foldable) {
        raw.addAll(padding.toDeclarationsWithClipPad('padding'));
      } else {
        raw['padding'] = padding.toValue();
      }
    }
    if (disabled) {
      raw['opacity'] = '$disabledOpacity';
    }
    return Styles(raw: raw);
  }

  /// Composes the country selector `<button>` Tailwind className —
  /// layout + typography. No hover fill: the box's own border carries the
  /// pointer, and the hairline after the selector is its own element
  /// ([buildSeparatorClassName]).
  String buildCountrySelectorClassName() => <String>[
    WebLayout.flexItemsCenter,
    'bg-transparent',
    bodyText.className,
    'cursor-pointer',
  ].where((c) => c.isNotEmpty).join(' ');

  /// Wrapper that centres the hairline in the row.
  String buildSeparatorClassName() => WebLayout.flexItemsCenter;

  /// Box that gives the hairline its height — shorter than the row.
  String buildSeparatorLineClassName() => WebLayout.flex;

  Styles buildSeparatorLineInlineStyles() => .new(
    raw: {'height': '${separatorHeight / kRemDivisor}rem'},
  );

  /// Composes the country selector `<button>` inline-CSS bundle —
  /// logical padding plus any body-text overlay (단일 inline
  /// 시그니처). The flag↔dial-code spacer is a nested `Gap` child (see
  /// [flagGapStyle]).
  Styles buildCountrySelectorInlineStyles() => .new(
    raw: {
      ...selectorPadding.toLogicalDeclarations('padding'),
      ...?bodyText.inline,
    },
  );

  /// Composes the selector flag box `<div>` Tailwind className — `block` so the
  /// background-image box lays out as a fixed-size flex item.
  String buildFlagClassName() => WebLayout.block;

  /// Composes the selector flag box `<div>` inline-CSS bundle — a fixed
  /// [flagSize]-height box (width follows the 4:3 artwork aspect, matching the
  /// Flutter `CountryFlag`) whose `background-size: contain` renders the flag
  /// SVG. Using a background image (not a child `<img>`) keeps the SVG's
  /// intrinsic size from inflating the surrounding flex row. `flex-shrink: 0`
  /// stops it collapsing.
  Styles buildFlagInlineStyles() => .new(
    raw: {
      'width': '${flagSize * _kFlagAspectRatio / kRemDivisor}rem',
      'height': '${flagSize / kRemDivisor}rem',
      'border-radius': flagBorderRadius,
      'background-size': 'contain',
      'background-position': 'center',
      'background-repeat': 'no-repeat',
      'flex-shrink': '0',
    },
  );

  /// Composes the selector dial code `<span>` Tailwind className — the
  /// `labelLarge` role + `onSurface` colour token classes from the
  /// [dialCodeText] slot. The `medium` weight overlay emits inline (see
  /// [buildDialCodeInlineStyles]).
  String buildDialCodeClassName() => dialCodeText.className;

  /// Composes the selector dial code `<span>` inline-CSS bundle — the
  /// explicit `font-weight` overlay carried by the [dialCodeText] slot.
  Styles? buildDialCodeInlineStyles() {
    final inline = dialCodeText.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the chevron `<svg>` Tailwind className — the per-state
  /// colour token class from [chevronColorEmit] (the `stroke:
  /// currentColor` attribute inherits it via CSS `color`).
  String buildChevronClassName() => chevronColorEmit.className;

  /// Composes the chevron `<svg>` inline-CSS bundle — `width` / `height`
  /// in rem so the SVG inherits the resolved chevron icon size without
  /// re-introducing a scalar field on the resolved layer (Epic #1603
  /// 옵션 B 최종), the stroke, plus any raw colour override from
  /// [chevronColorEmit].
  ///
  /// The chevron is the Lucide `chevron-down` glyph drawn inline, so its
  /// stroke is the icon stroke rule (`CoreIconStroke`) at the chevron's token
  /// size, written in the glyph's own viewBox units as the `Icon` does for a
  /// bundled glyph — the Flutter twin draws the same glyph through `Icon`. It
  /// rides inline CSS: the property sits on the `<svg>` root and its
  /// `polyline` inherits it.
  Styles buildChevronInlineStyles() => .new(
    raw: {
      'width': '${chevronIconSize / kRemDivisor}rem',
      'height': '${chevronIconSize / kRemDivisor}rem',
      'stroke-width': CoreIconStroke.formatNumber(
        CoreIconStroke.svgStrokeWidth(
          chevronIconSize,
          viewBox: _kChevronViewBox,
        ),
      ),
      ...?chevronColorEmit.inline,
    },
  );

  /// Composes the phone number `<input>` Tailwind className. Disabled
  /// opacity is applied at the container level (the entire chrome —
  /// border, selector, input — fades together via the root inline-CSS),
  /// matching Flutter's `Opacity` wrapper.
  String buildPhoneInputClassName() => <String>[
    // `items-center` vertically centres the composed chromeless field within
    // the fixed-height row — the field no longer stretches (`h-full`) like the
    // old raw `<input>`, so without this it sat at the top.
    '${WebLayout.flex} ${WebLayout.itemsCenter}',
    '${WebLayout.hFull} ${WebLayout.wFull} bg-transparent',
    bodyText.className,
    'focus-visible:outline-none disabled:cursor-not-allowed',
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the phone number `<input>` inline-CSS bundle — horizontal
  /// padding plus the resolved `max-width` cap (mirrors the Flutter
  /// field-level `ConstrainedBox(maxWidth:)`) plus any body-text overlay
  /// (단일 inline 시그니처). Vertical padding is unset so the field stays
  /// vertically centred within the fixed-height row.
  Styles buildPhoneInputInlineStyles() => .new(
    raw: {
      ...inputFieldPadding.toLogicalDeclarations('padding'),
      'max-width': '${maxWidth / kRemDivisor}rem',
      ...?bodyText.inline,
    },
  );

  /// Composes the scrollable option-list `<div role="listbox">` Tailwind
  /// className. Positioning / border / surface / shadow / radius now come
  /// from the unified `Popover` panel — only the scroll overflow lives here.
  String buildDropdownClassName() => WebLayout.overflowYAuto;

  /// Composes the option-list inline-CSS bundle — the scroll `max-height`
  /// (always) plus the resolved `max-width` cap when a caller overrides
  /// [CorePhoneInputStyle.popupMaxWidth] (the panel placement / chrome are the
  /// Popover's responsibility). Omitting `max-width` on the default path keeps
  /// the default output byte-identical (only `max-height`).
  Styles buildDropdownInlineStyles() {
    final raw = {
      'padding': dropdownListPadding,
      'max-height': '${popupMaxHeight / kRemDivisor}rem',
    };
    if (popupMaxWidth != null) {
      raw['max-width'] = '${popupMaxWidth / kRemDivisor}rem';
    }
    return Styles(raw: raw);
  }

  /// Composes the dropdown search field host className — full width only:
  /// the panel is the only boundary and the `Divider` after the row closes
  /// it, so the wrapper carries no edge, fill or inset of its own.
  String buildSearchInputClassName() => WebLayout.wFull;

  /// Composes the per-country dropdown item `<button>` Tailwind
  /// className — layout + typography + hover. Identical chrome across
  /// every row; the variable bit (flag / name / dial code) lives in the
  /// row's inner spans.
  String buildDropdownItemClassName() => <String>[
    // `w-full` so the row fills the panel — otherwise the `flex-1` name has
    // no space to grow and the dial code sits right after the name instead of
    // right-aligned to the panel edge (Flutter `Expanded(name)` parity).
    '${WebLayout.flexItemsCenter} ${WebLayout.wFull}',
    bodyText.className,
    hoverPseudo.className,
    highlightPseudo.className,
    if (hoverRaw) 'co-phone-input-h-$scopeId',
    'cursor-pointer',
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the per-country dropdown item `<button>` inline-CSS bundle
  /// — dropdown-item padding plus any body-text overlay (단일 inline
  /// 시그니처). Row gaps live on the inner spans (`dropdownItemName` /
  /// `dropdownItemDialCode`).
  Styles buildDropdownItemInlineStyles() => .new(
    raw: {
      'padding': dropdownItemPadding,
      'border-radius': dropdownItemBorderRadius,
      ...?bodyText.inline,
    },
  );

  /// Composes the dropdown item flag box `<div>` Tailwind className — `block`
  /// fixed-size background-image box (see [buildFlagClassName]).
  String buildDropdownItemFlagClassName() => WebLayout.block;

  /// Composes the dropdown item flag box `<div>` inline-CSS bundle — the
  /// flag-icons box at [dropdownFlagSize] height (4:3 artwork aspect),
  /// rendered via `background-size: contain`.
  Styles buildDropdownItemFlagInlineStyles() => .new(
    raw: {
      'width': '${dropdownFlagSize * _kFlagAspectRatio / kRemDivisor}rem',
      'height': '${dropdownFlagSize / kRemDivisor}rem',
      'border-radius': flagBorderRadius,
      'background-size': 'contain',
      'background-position': 'center',
      'background-repeat': 'no-repeat',
      'flex-shrink': '0',
    },
  );

  /// Composes the dropdown item name `<span>` Tailwind className.
  /// Spacer to the preceding flag and the following dial code are
  /// nested `Gap` children (see [dropdownItemGapStyle] /
  /// [countryGapStyle]); no inline margin here.
  String buildDropdownItemNameClassName() => '${WebLayout.flex1} text-left';

  /// Composes the dropdown item dial code `<span>` Tailwind className —
  /// the muted `bodySmall` typography role + the `onSurfaceVariant` colour
  /// token classes, emitted from the merged [dropdownDialCodeText] slot via
  /// `emitTypography` (single canonical path — role class + colour token
  /// class together, any scalar overlay inline). Spacer to the preceding
  /// name is a nested `Gap` child (see [countryGapStyle]); no inline
  /// margin here.
  String buildDropdownItemDialCodeClassName() => dropdownDialCodeText.className;

  /// Composes the dropdown item dial code `<span>` inline-CSS bundle — any
  /// explicit scalar overlay carried by the [dropdownDialCodeText] slot.
  Styles? buildDropdownItemDialCodeInlineStyles() {
    final inline = dropdownDialCodeText.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedPhoneInput(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    countrySelector: WebElementChrome(
      className: buildCountrySelectorClassName(),
      inlineStyles: buildCountrySelectorInlineStyles(),
    ),
    flag: WebElementChrome(
      className: buildFlagClassName(),
      inlineStyles: buildFlagInlineStyles(),
    ),
    dialCode: WebElementChrome(
      className: buildDialCodeClassName(),
      inlineStyles: buildDialCodeInlineStyles(),
    ),
    chevron: WebElementChrome(
      className: buildChevronClassName(),
      inlineStyles: buildChevronInlineStyles(),
    ),
    phoneInput: WebElementChrome(
      className: buildPhoneInputClassName(),
      inlineStyles: buildPhoneInputInlineStyles(),
    ),
    dropdown: WebElementChrome(
      className: buildDropdownClassName(),
      inlineStyles: buildDropdownInlineStyles(),
    ),
    searchInput: WebElementChrome(className: buildSearchInputClassName()),
    dropdownItem: WebElementChrome(
      className: buildDropdownItemClassName(),
      inlineStyles: buildDropdownItemInlineStyles(),
    ),
    dropdownItemFlag: WebElementChrome(
      className: buildDropdownItemFlagClassName(),
      inlineStyles: buildDropdownItemFlagInlineStyles(),
    ),
    dropdownItemName: WebElementChrome(
      className: buildDropdownItemNameClassName(),
    ),
    dropdownItemDialCode: WebElementChrome(
      className: buildDropdownItemDialCodeClassName(),
      inlineStyles: buildDropdownItemDialCodeInlineStyles(),
    ),
    separator: WebElementChrome(className: buildSeparatorClassName()),
    separatorLine: WebElementChrome(
      className: buildSeparatorLineClassName(),
      inlineStyles: buildSeparatorLineInlineStyles(),
    ),
    separatorDividerStyle: CoreDividerStyle(
      color: separatorColorCore,
      thickness: borderWidth,
    ),
    dividerStyle: CoreDividerStyle(
      color: separatorColorCore,
      thickness: borderWidth,
    ),
    searchIconStyle: searchIconStyle,
    dropdownCheckIconStyle: dropdownCheckIconStyle,
    flagGapStyle: flagGapStyle,
    countryGapStyle: countryGapStyle,
    dropdownItemGapStyle: dropdownItemGapStyle,
    // Nested child-component Style slots — merged with their Core defaults and
    // raw-forwarded (the child TextField / Popover resolve them). `popoverStyle`
    // additionally carries the reflected `popupBorderRadius` / `popoverTopOffset`
    // panel overrides (see its local above).
    numberFieldStyle: numberFieldStyle,
    searchFieldStyle: searchFieldStyle,
    popoverStyle: popoverStyle,
  );
}

/// Resolves the scoped `<style>` rules for a `PhoneInput` whose focus-within
/// border / hover border / hover background / placeholder colour override
/// moves off the Tailwind scale (a raw, token-less colour) — see
/// [ResolvedPhoneInputRules]. Returns empty CSS on the default path
/// (`resolvePhoneInput` keeps the pseudo utility classes: class XOR rule).
///
/// The merge chain mirrors [resolvePhoneInput] exactly, so the class-drop
/// conditions in the main resolver and these scoped rules always see the same
/// resolved colours. Each `emitPseudoColor(...).rule` is empty on the token
/// path, so the buffer accumulates nothing until a raw override appears.
/// [enabled] mirrors the main resolver's: a disabled field takes no hover
/// border step, so no hover-border rule is written for it.
ResolvedPhoneInputRules resolvePhoneInputRules(
  BuildContext context, {
  required String scopeId,
  bool enabled = true,
  CorePhoneInputStyle? phoneInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.phoneInput;
  final merged = resolveStyleChain(const CorePhoneInputStyle(), [
    csTheme?.style,
    phoneInputStyle,
  ]);

  final buffer = StringBuffer()
    // Focus-within border — a raw override paints via the scoped
    // `.co-phone-input-fw-<id>:focus-within` rule on the field row.
    ..write(
      emitPseudoColor(
        merged.focusBorderColor,
        CorePhoneInputStyle.defaultFocusBorderColor,
        .border,
        pseudo: .focusWithin,
        scopeSelector: '.co-phone-input-fw-$scopeId',
      ).rule,
    );
  // Hover border — a raw override paints via the scoped
  // `.co-phone-input-hb-<id>:hover:not(:focus-within)` rule on the field row.
  // The `:not(:focus-within)` lives in the selector, so the focus-within rule
  // above wins while the field is focused whatever the order of the two.
  if (enabled) {
    buffer.write(
      emitPseudoColor(
        merged.hoverBorderColor,
        CorePhoneInputStyle.defaultHoverBorderColor,
        .border,
        pseudo: .hoverUnlessFocusWithin,
        scopeSelector: '.co-phone-input-hb-$scopeId',
        // Mirrors the main resolver: a raw resting border is inline.
        important:
            (merged.borderColor ?? CorePhoneInputStyle.defaultBorderColor)
                .token ==
            null,
      ).rule,
    );
  }
  buffer
    // Hover background — a raw override paints via the single shared
    // `.co-phone-input-h-<id>:hover` rule (selector + all dropdown rows).
    ..write(
      emitPseudoColor(
        merged.hoverColor,
        CorePhoneInputStyle.defaultHoverColor,
        .background,
        pseudo: .hover,
        scopeSelector: '.co-phone-input-h-$scopeId',
      ).rule,
    )
    // Keyboard highlight — the same colour on the option the search field's
    // `aria-activedescendant` points at.
    ..write(
      emitPseudoColor(
        merged.hoverColor,
        CorePhoneInputStyle.defaultHoverColor,
        .background,
        pseudo: .ariaSelected,
        scopeSelector: '.co-phone-input-h-$scopeId',
      ).rule,
    );

  return ResolvedPhoneInputRules(css: buffer.toString());
}

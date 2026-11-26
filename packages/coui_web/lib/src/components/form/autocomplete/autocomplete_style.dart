library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/theme_context.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Autocomplete`.
///
/// DOM shape:
///
/// ```text
/// root (Popover — owns its own outermost DOM element)
///   ├─ trigger (Input)
///   └─ panel (<div role="listbox">)            // suggestion scroll area
///        └─ option (<button role="option">)    // repeated per filtered suggestion
///                                                (per-option chrome resolved by
///                                                 [resolveAutocompleteOption])
/// ```
///
/// The suggestion-panel box (background / border / radius / shadow /
/// padding) is owned by the composed `Popover` → `Popup`, so the
/// resolver declares no panel chrome of its own — it flows through
/// [popoverStyle]`.panelStyle` (a `CorePopupStyle`, the single source of
/// truth). [panel] carries only the listbox role + scroll region +
/// `max-height` constraint on the option list. Per-option `<button>`
/// chrome is produced by [resolveAutocompleteOption], a dedicated
/// per-item entry point that walks the same merge chain.
class ResolvedAutocomplete implements WebResolvedChrome {
  /// Creates a [ResolvedAutocomplete].
  const ResolvedAutocomplete({
    required this.root,
    required this.panel,
    required this.popoverStyle,
  });

  /// Paint-ready chrome for the outermost DOM element `Autocomplete`
  /// emits. `Autocomplete` itself adds no chrome to the outer element —
  /// it returns a [Popover] directly, and the popover owns its own root
  /// chrome. Empty className + `null` inline CSS satisfies the
  /// [WebResolvedChrome] contract without injecting an extra class.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the suggestion panel `<div role="listbox">`.
  /// Empty className (the panel only carries the listbox role and scroll
  /// region) plus an inline-CSS bundle for the resolved `max-height` +
  /// `overflow-y: auto` (the panel **box** surface is painted by the
  /// composed `Popover` → `Popup`).
  final WebElementChrome panel;

  /// Nested [CorePopoverStyle] slot — forwarded to the wrapping
  /// [Popover]. Merged with the design-system seed so the popover
  /// resolver sees a non-null base; the panel box chrome flows through
  /// `popoverStyle.panelStyle`.
  final CorePopoverStyle popoverStyle;
}

// ═══════════════════════════════════════════════════
// Per-option resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for a single option `<button>` inside an
/// autocomplete dropdown.
///
/// DOM shape:
///
/// ```text
/// option (<button>)                  // resolved.root
///   ├─ Component.text (label before the match)   // inherits root typography
///   ├─ match (<span>)                              // resolved.match
///   └─ Component.text (label after the match)
/// ```
class ResolvedAutocompleteOption implements WebResolvedChrome {
  /// Creates a [ResolvedAutocompleteOption].
  const ResolvedAutocompleteOption({required this.root, required this.match});

  /// Paint-ready chrome for the `<span>` wrapping the part of the label that
  /// matches the query — the match typography (SemiBold `onSurface` by
  /// default) over the root's base style.
  final WebElementChrome match;

  /// Paint-ready chrome for the option `<button>` — composed Tailwind
  /// className plus the per-option inline CSS that carries the option
  /// padding / radius and (when `hovered`) the hover background + text
  /// colours.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAutocomplete] for the given [context].
///
/// Per-option `<button>` chrome ships through the dedicated per-item
/// resolver [resolveAutocompleteOption].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.autocomplete.style
///   → widget.autocompleteStyle
/// ```
ResolvedAutocomplete resolveAutocomplete(
  BuildContext context, {
  CoreAutocompleteStyle? autocompleteStyle,
}) {
  final acTheme = context.theme.coreComponentTheme?.autocomplete;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreAutocompleteStyle(), [
    acTheme?.style,
    autocompleteStyle,
  ]);

  // Suggestion-list max height — caller override wins, else the design-
  // system default. Constrains the option list (the panel's scroll
  // region), not the panel box (owned by the composed `Popover`).
  final maxHeight =
      merged.dropdownMaxHeight ??
      CoreAutocompleteStyle.defaultDropdownMaxHeight;

  // Nested popover slot — the wrapping [Popover] (→ `Popup`) owns the
  // suggestion-panel box, so `Autocomplete` declares no panel chrome of
  // its own. The panel (background / border / radius / shadow / padding)
  // flows entirely through `popoverStyle.panelStyle` (a `CorePopupStyle`,
  // the single source of truth) and is filled by `Popup`'s defaults
  // unless the caller overrides it. Seeded with `const CorePopoverStyle()`
  // so the resolved slot is never null.
  final popoverStyle = CoreAutocompleteStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the suggestion panel `<div role="listbox">` inline CSS —
  /// `max-height` + `overflow-y: auto` over a `flex column`. The panel
  /// carries no Tailwind classes (the wrapping [Popover] already paints
  /// the surface chrome + padding).
  Styles buildPanelInlineStyles() => .new(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'max-height': '${maxHeight / kRemDivisor}rem',
      'overflow-y': 'auto',
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedAutocomplete(
    root: const WebElementChrome(className: ''),
    panel: WebElementChrome(
      className: '',
      inlineStyles: buildPanelInlineStyles(),
    ),
    popoverStyle: popoverStyle,
  );
}

// ═══════════════════════════════════════════════════
// Per-option resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAutocompleteOption] for a single dropdown option.
///
/// Walks the same merge chain as [resolveAutocomplete] (single source
/// of truth for the option chrome values — no scalar leak from the
/// parent resolver) and closes over the per-option runtime state
/// (`hovered`) so the `<button>` chrome can be pre-composed.
/// `co_autocomplete` reads `resolved.root.className` /
/// `resolved.root.inlineStyles` straight off for each option in its
/// render loop.
ResolvedAutocompleteOption resolveAutocompleteOption(
  BuildContext context, {
  required bool hovered,
  CoreAutocompleteStyle? autocompleteStyle,
}) {
  final acTheme = context.theme.coreComponentTheme?.autocomplete;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreAutocompleteStyle(), [
    acTheme?.style,
    autocompleteStyle,
  ]);

  // ─── Stage 1 RESOLVE (dimensional) ────────────────────
  // Radius / padding always emit inline through
  // `(merged.X ?? default).toValue()` — no branching, no radius or
  // padding Tailwind class (Epic #1603 chaining gate).
  final optionBorderRadius =
      merged.optionBorderRadius ??
      CoreAutocompleteStyle.defaultOptionBorderRadius;
  final optionPadding =
      merged.optionPadding ?? CoreAutocompleteStyle.defaultOptionPadding;

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // The option label typography shares the `dropdownTextStyle` slot for the
  // role + base colour; when `hovered` the option's text colour is overlaid
  // with the hover colour from the `optionHoverTextStyle` slot. A single
  // `emitTypography` per render emits the `text-{role}` class plus exactly
  // one `text-{colour}` class (base OR hover) — never two competing colour
  // classes (the hover state is a Dart re-render, not a CSS pseudo-class).
  final baseTextStyle = CoreAutocompleteStyle.defaultDropdownTextStyle.merge(
    merged.dropdownTextStyle,
  );
  final hoverTextStyle = CoreAutocompleteStyle.defaultOptionHoverTextStyle
      .merge(merged.optionHoverTextStyle);
  final textEmit = emitTypography(
    hovered ? hoverTextStyle : baseTextStyle,
    hovered ? hoverTextStyle : baseTextStyle,
  );
  // The matched part of the label: its own role + colour class, with the
  // weight as an inline overlay (`emitTypography` splits role class from
  // explicit overlay).
  final matchTextStyle = CoreAutocompleteStyle.defaultMatchTextStyle.merge(
    merged.matchTextStyle,
  );
  final matchEmit = emitTypography(matchTextStyle, matchTextStyle);
  // Hover background — token colours emit the `bg-{token}` class; raw
  // overrides emit inline. Only contributes when `hovered`.
  final hoverBackgroundEmit = emitColor(
    merged.optionHoverColor,
    CoreAutocompleteStyle.defaultOptionHoverColor,
    .background,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes a single suggestion option `<button>` Tailwind className —
  /// base layout plus the label typography class (`text-{role}` +
  /// `text-{colour}`) and, when hovered, the token-bound hover background
  /// class.
  String buildRootClassName() {
    final classList = [
      '${WebLayout.flexFull} cursor-pointer ${WebLayout.itemsCenter} bg-transparent border-0 '
          'text-left transition-colors',
      textEmit.className,
      if (hovered) hoverBackgroundEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes a single suggestion option `<button>` inline-CSS bundle —
  /// option dimensional chrome plus any raw typography overlay and, when
  /// `hovered`, the raw hover background fragment (token values stay on
  /// classes).
  Styles buildRootInlineStyles() => .new(
    raw: {
      'border-radius': optionBorderRadius.toValue(),
      'padding': optionPadding.toValue(),
      ...?textEmit.inline,
      if (hovered) ...?hoverBackgroundEmit.inline,
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedAutocompleteOption(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    match: WebElementChrome(
      className: matchEmit.className,
      inlineStyles: switch (matchEmit.inline) {
        final raw? => Styles(raw: raw),
        null => null,
      },
    ),
  );
}

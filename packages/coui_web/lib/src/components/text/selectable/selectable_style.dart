import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/internal/selection_paint.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `SelectableText`.
///
/// DOM shape:
///
/// ```text
/// root (<span>)
///   └─ text content | …children                  // co_selectable_text picks text or rich-text children
/// ```
///
/// `co_selectable_text.dart` reads `resolved.root.className` and
/// `resolved.root.inlineStyles` straight from this object — no merge /
/// fallback / conversion in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only Cat 1
/// `WebElementChrome` slots. The text-style slot
/// ([CoreSelectableTextStyle.textStyle]) is folded into the root
/// `inlineStyles` here; no raw typography scalars (fontSize / fontWeight
/// / lineHeight / letterSpacing / fontFamily / colorValue) leak out
/// because the merged values are emitted as CSS directly.
///
/// The caret slots ([CoreSelectableTextStyle.cursorColor] /
/// [CoreSelectableTextStyle.cursorWidth] /
/// [CoreSelectableTextStyle.cursorHeight] /
/// [CoreSelectableTextStyle.cursorRadius]) are likewise folded into the
/// root `inlineStyles` (Epic #1603 coverage gate — every contract
/// override field is reflected here, mirroring the Flutter resolver
/// 1:1). The browser caret on non-editable text exposes only
/// `caret-color`, so `merged.cursorColor` drives that property directly;
/// the un-stylable width / height / radius are surfaced as the
/// `--coui-caret-width` / `--coui-caret-height` / `--coui-caret-radius`
/// custom properties so Flutter parity is preserved and tooling can
/// read the intended geometry (matches the `text_area` / `text_field`
/// resolvers).
class ResolvedSelectableText implements WebResolvedChrome {
  /// Creates a [ResolvedSelectableText].
  const ResolvedSelectableText({required this.root});

  /// Paint-ready chrome for the outermost `<span>` element.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSelectableText] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreSelectableTextStyle.defaultX)
///   → theme.coreComponentTheme.selectableText.style
///   → widget.selectableTextStyle
/// ```
///
/// The cross-platform behavioural fields ([maxLines], [textAlign],
/// [enableInteractiveSelection]) are widget props — they flow into the
/// root chrome here so `co_selectable_text` reads a single paint-ready
/// `WebElementChrome` for the outer `<span>`.
ResolvedSelectableText resolveSelectableText(
  BuildContext context, {
  CoreSelectableTextStyle? selectableTextStyle,
  int? maxLines,
  CoreTextAlign? textAlign,
  bool enableInteractiveSelection = true,
}) {
  final selectableTheme = context.theme.coreComponentTheme?.selectableText;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreSelectableTextStyle(), [
    selectableTheme?.style,
    selectableTextStyle,
  ]);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Nested `CoreTextStyle` slot — selectable text has no design-system
  // default (it inherits the surrounding typography), so the fallback is
  // an empty `CoreTextStyle()`. `emitTypography` is the single canonical
  // path: a token-backed override (future caller) emits its role on a
  // `text-{role}` class plus token colour class (both inherited by the
  // `<span>`); a raw overlay (no role token) emits every populated field
  // — including `color` as `var(--coui-X)` — inline. No `scheme.resolve`
  // (a no-op on Web) and no hand-rolled colour branch. `font-family` is
  // not covered by `toInlineCss`, so it is appended manually below.
  final typographyEmit = emitTypography(
    merged.textStyle,
    CoreSelectableTextStyle.defaultTextStyle,
  );

  // Caret chrome (Epic #1603 coverage gate — mirrors the Flutter
  // resolver 1:1). The browser caret on non-editable text exposes only
  // `caret-color`; `cursorWidth` falls back to the design-system default
  // (the others default to the browser-native caret when unset). Width /
  // height / radius are surfaced as custom properties so the resolved
  // geometry is preserved for parity / tooling even though the native
  // caret cannot be re-styled (matches `text_area` / `text_field`). The
  // caret colour is emitted theme-free — `CoreColor.toValue()` already
  // resolves a token to `var(--coui-X)` (dark-mode reactive); no
  // `scheme.resolve` (a no-op on Web).
  final cursorColor =
      (merged.cursorColor ?? CoreSelectableTextStyle.defaultCursorColor)
          .toValue();
  final cursorWidth =
      merged.cursorWidth ?? CoreSelectableTextStyle.defaultCursorWidth;
  final cursorHeight = merged.cursorHeight;
  final cursorRadius = merged.cursorRadius?.toValue();

  // A raw tint uses a root-only pseudo-element rule rather than publishing
  // a descendant selection rule. Tokens keep their existing `selection:`
  // class; inline CSS carries only the raw rule's value.
  final selectionColor =
      merged.selectionColor ?? CoreSelectableTextStyle.defaultSelectionColor;

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<span>` Tailwind className.
  ///
  /// `select-text` overrides any inherited `user-select: none` so the
  /// content stays selectable — matching Flutter's `m.SelectableText`.
  /// When [enableInteractiveSelection] is `false`, `select-none` is used
  /// instead so selection is suppressed on both platforms. The
  /// [typographyEmit] role class (empty unless the caller passes a
  /// token-backed `textStyle`) is appended so a role + token colour stays
  /// on classes (dark-mode reactive).
  String buildRootClassName() {
    final selection = enableInteractiveSelection
        ? 'select-text'
        : 'select-none';
    return <String>[
      selection,
      typographyEmit.className,
      // Text-selection tint — pseudo-element class, inline CSS cannot
      // target `::selection`.
      if (selectionColor.token != null)
        'selection:bg-${selectionColor.tailwindColor}'
      else
        kSelectableSelectionMarker,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the root `<span>` inline-CSS bundle.
  ///
  /// Emits the nested [CoreTextStyle] slot overrides ([typographyEmit]
  /// inline — font-size / font-weight / line-height / letter-spacing / raw
  /// colour — plus the helper-uncovered `font-family`), the caret slot
  /// overrides (`caret-color` + `--coui-caret-*` custom properties), and
  /// the cross-platform [textAlign] / [maxLines] behaviour, and nothing
  /// else. Returns `null` when no rule applies so the element inherits the
  /// surrounding typography.
  Styles? buildRootInlineStyles() {
    final raw = <String, String>{
      ...?typographyEmit.inline,
      if (selectionColor.token == null)
        kSelectableSelectionColorVar: selectionColor.toValue(),
    };
    // Caret chrome. The browser caret exposes only `caret-color`; its
    // thickness / height / corner rounding are not stylable, so the
    // resolved geometry is surfaced as custom properties to preserve
    // Flutter parity and let tooling read the intended values (matches
    // `text_area` / `text_field`).
    raw['caret-color'] = cursorColor;
    raw['--coui-caret-width'] = '${cursorWidth / kRemDivisor}rem';
    // The room Flutter's selectable text keeps after its glyphs for the
    // caret — the cursor width plus the framework's gap, laid out whether a
    // caret shows or not. Reserved here too so the text is as wide on both
    // platforms. The caret's geometry, not spacing: it does not move with
    // density, as the Flutter twin's does not.
    raw['padding-inline-end'] = pinnedLengthCss(
      cursorWidth + kEditableCaretGap,
    );
    if (cursorHeight != null) {
      raw['--coui-caret-height'] = '${cursorHeight / kRemDivisor}rem';
    }
    if (cursorRadius != null) raw['--coui-caret-radius'] = cursorRadius;
    if (textAlign != null) {
      raw['text-align'] = _textAlignCss(textAlign);
    }
    if (maxLines != null) {
      // CSS line-clamp — equivalent to Flutter's `maxLines` clipping.
      raw['display'] = '-webkit-box';
      raw['-webkit-box-orient'] = 'vertical';
      raw['-webkit-line-clamp'] = '$maxLines';
      raw['overflow'] = WebLayout.hidden;
    }
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSelectableText(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (small pure functions, short signatures)
// ═══════════════════════════════════════════════════

/// Maps a [CoreTextAlign] to its CSS `text-align` value.
String _textAlignCss(CoreTextAlign align) => switch (align) {
  .start => 'start',
  .end => 'end',
  .center => 'center',
  .justify => 'justify',
  .left => 'left',
  .right => 'right',
};

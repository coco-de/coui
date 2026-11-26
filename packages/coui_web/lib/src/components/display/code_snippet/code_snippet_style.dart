/// Style-slot single entry point for the Web `CodeSnippet` — the resolver
/// and its paint-ready chrome.
library;

import 'dart:convert';
import 'dart:math';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `CodeSnippet`.
///
/// DOM shape:
///
/// ```text
/// root — OutlinedContainer(containerStyle) // outer bordered box —
///                                       //   composed, not hand-rolled.
///   └─ contentWrapper (<div>)          // `relative` positioning
///                                       //   context + default
///                                       //   typography role / fg
///                                       //   colour classes (suppressed
///                                       //   on override), inherited
///                                       //   by `pre`/`code`/`lineNumber`.
///     ├─ pre (<pre>)                      // horizontal-scroll wrapper —
///     │                                   //   `overflow-x-auto` +
///     │                                   //   transparent bg + typography
///     │                                   //   role class + inherit font.
///     │                                   //   Inline CSS: margin + padding
///     │                                   //   shorthand (always) + optional
///     │                                   //   min/max width / height caps
///     │                                   //   (+ `overflow-y: auto` with a
///     │                                   //   height cap).
///     │   └─ code (<code>)                // highlighted code area —
///     │                                   //   typography role class +
///     │                                   //   inherit font. Inline CSS:
///     │                                   //   optional codeTextStyle.
///     │       ├─ bandHost (<div>) (opt)     // only when a line carries a
///     │       │                           //   band — `relative`, at least
///     │       │                           //   as wide as the scroll area.
///     │       │   ├─ bandLayer (<div>)    // `absolute`, out to the
///     │       │   │                       //   padding edges, no pointer.
///     │       │   │   └─ bandRow / lineBands[tone] (<div>) ×N
///     │       │   │                       //   one `1lh` row per line up to
///     │       │   │                       //   the last band; a band row
///     │       │   │                       //   carries its colour and an
///     │       │   │                       //   sr-only line label.
///     │       │   └─ bandContent (<div>)  // `relative` — over the bands;
///     │       │                           //   holds what follows.
///     │       └─ lineRow (<div>) ×N (opt) // per-line row when
///     │                                   //   `showLineNumbers` true —
///     │                                   //   `flex` layout.
///     │             ├─ lineNumber (<span>)// gutter — inline-block +
///     │             │                     //   right-aligned + its own
///     │             │                     //   colour class (inline on a
///     │             │                     //   raw override) + select-none.
///     │             │                     //   Inline CSS: right margin +
///     │             │                     //   width + optional
///     │             │                     //   lineNumberTextStyle overlay.
///     │             └─ (bare <span>)      // raw code text — no slot
///     │                                   //   (no chrome).
///     └─ actionWrapper (<div>) (opt)      // top-right action row —
///                                         //   `absolute` + flex row,
///                                         //   positioned at the corner
///                                         //   offset (top / right inline)
///                                         //   relative to `contentWrapper`.
///                                         //   Skipped when no copy button
///                                         //   and no actions.
///           ├─ actions[]                  // user-supplied action widgets
///           │                             //   (no chrome — caller owns).
///           └─ Button (opt)             // copy affordance —
///                                         //   `Button(variant: .plain,
///                                         //   buttonStyle:
///                                         //   resolved.copyButtonStyle)`.
///                 └─ Icon(iconStyle: …) // copy glyph — states no colour
///                                         //   of its own, so it inherits
///                                         //   the Button's (`currentColor`).
/// ```
///
/// The outer box is composed from `OutlinedContainer` rather than a
/// hand-drawn `<div>` (`core/style-contract.md`'s child-component-
/// composition rule) — [containerStyle] carries the background /
/// border / radius chrome as `coui_core` domain types, raw-forwarded
/// to `OutlinedContainer(containerStyle: …)`; that component's own
/// resolver runs colour / radius resolution, the surface-material
/// wiring, and the "no shadow of its own → take the active style's
/// injected control-shadow" fallback exactly once. Foreground colour
/// and typography role — not chrome-box concerns — ride
/// [contentWrapper] instead, one level inside the composed root, so
/// `pre`/`code`/`lineNumber` still inherit them.
///
/// The resolver otherwise carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome). Radius /
///   padding / margin / size dimensional chrome is emitted inline
///   (`(merged.X ?? default).toValue()` / rem) — single inline
///   signature, no Tailwind dimensional class, no class-drop branch.
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [iconStyle] is forwarded to the copy-button icon via
///   `Icon(iconStyle: …)`.
///
/// No scalar metadata (`mode` / `showLineNumbers` / etc.) is exposed —
/// behaviour fields stay on the widget prop.
class ResolvedCodeSnippet {
  /// Creates a [ResolvedCodeSnippet].
  const ResolvedCodeSnippet({
    required this.containerStyle,
    required this.contentWrapper,
    required this.pre,
    required this.code,
    required this.lineRow,
    required this.lineNumber,
    required this.actionWrapper,
    required this.copyButtonStyle,
    required this.iconStyle,
    required this.actionGapStyle,
    required this.syntax,
    required this.bandHost,
    required this.bandLayer,
    required this.bandContent,
    required this.bandRow,
    required this.lineBands,
  });

  /// Nested [CoreOutlinedContainerStyle] for the composed outer box —
  /// raw-forwarded straight to `OutlinedContainer(containerStyle: …)`;
  /// that widget's own resolver owns border / radius / background /
  /// shadow emit (no className / inlineStyles assembly here).
  final CoreOutlinedContainerStyle containerStyle;

  /// Paint-ready chrome for the `relative`-positioned wrapper `<div>`
  /// nested inside the composed `OutlinedContainer`'s `child` slot —
  /// default typography role / foreground colour classes (suppressed
  /// on override) plus the `relative` positioning context that
  /// [actionWrapper]'s `absolute` corner offset resolves against.
  final WebElementChrome contentWrapper;

  /// Paint-ready chrome for the `<pre>` wrapper — `overflow-x-auto`,
  /// transparent background, default typography role class, inherit
  /// font. Inline CSS: margin + padding shorthand (always emitted) plus
  /// the code-area size caps (`min-width` / `max-width` / `min-height` /
  /// `max-height`, each only when set) and `overflow-y: auto` alongside a
  /// height cap.
  final WebElementChrome pre;

  /// Paint-ready chrome for the `<code>` element — typography role +
  /// inherit font. Inline CSS: optional `codeTextStyle` override
  /// (`null` when no override).
  final WebElementChrome code;

  /// Paint-ready chrome for a single line row `<div>` — `flex`
  /// layout (only used when `showLineNumbers` is true).
  final WebElementChrome lineRow;

  /// Paint-ready chrome for the top-right action wrapper `<div>` —
  /// `absolute` + flex row, positioned at the corner offset (top /
  /// right inline). Holds the caller action widgets + the copy
  /// `Button` (mirrors the Flutter `Position` + `Row`).
  /// `co_code_snippet` skips this wrapper when neither `showCopyButton`
  /// nor `actions` are present.
  final WebElementChrome actionWrapper;

  /// Paint-ready chrome for the line-number gutter `<span>` —
  /// inline-block + right-aligned + select-none, and the gutter's own colour
  /// (`onSurfaceVariant` by default) as a token class, or inline when a
  /// caller states a raw colour. Inline CSS: right margin and width, plus the
  /// optional `lineNumberTextStyle` overlay.
  final WebElementChrome lineNumber;

  /// Nested `CoreButtonStyle` slot for the optional copy affordance —
  /// `co_code_snippet` raw-forwards this to
  /// `Button(variant: .plain, buttonStyle: …)`. Chained
  /// `defaultCopyButtonStyle ⊕ override`; `Button` resolves its own
  /// internals (size / radius / padding / foreground / transition).
  /// `co_code_snippet` skips the button entirely when `showCopyButton`
  /// is false. On a solid role face it also carries the face's ink as the
  /// focus ring colour (`CoreCodeSnippetStyle.inkOnFace`).
  final CoreButtonStyle copyButtonStyle;

  /// Nested `CoreIconStyle` slot — `co_code_snippet` forwards this to
  /// `Icon(iconStyle: …)` for the copy-button glyph. Carries the resolved
  /// icon size and, unless a caller states one or the face is a solid role
  /// fill ([CoreCodeSnippetStyle.inkOnFace]), no colour: the glyph emits none
  /// and inherits the copy button's foreground through its states.
  final CoreIconStyle iconStyle;

  /// Nested `CoreGapStyle` slot between sibling action widgets in the
  /// top-right area — the resolver absorbs the design-system default
  /// ([CoreCodeSnippetStyle.defaultActionGapStyle]) so this is non-null
  /// and carries a concrete `size`. `co_code_snippet` reads
  /// `actionGapStyle.size` for the action-row gap inline CSS.
  final CoreGapStyle actionGapStyle;

  /// Paint-ready chrome for a highlighted `<span>` of each role, in
  /// [CoreSyntaxRole.values] order — read it by `role.index`, or let
  /// [syntaxChromeOf] pick it for a span. The entry of
  /// [CoreSyntaxRole.plain] is empty: plain text has no colour of its own and
  /// inherits the code colour.
  ///
  /// The colour is inline CSS holding a variable reference
  /// (`rgb(var(--coui-syntax-keyword))`), not a resolved colour: the browser
  /// resolves it at runtime, so a brightness, brand or high-contrast switch
  /// repaints the spans with no re-render, the same as every other token the
  /// component emits.
  ///
  /// Every entry is empty on a face the role colours are not certified on
  /// ([CoreSyntaxFaces.admits] is `false` for it): no span states a colour,
  /// and all of them inherit the code colour, the snippet's own ink.
  final List<WebElementChrome> syntax;

  /// Paint-ready chrome for the wrapper that holds the line bands under the
  /// code — `relative`, and at least as wide as the scroll area
  /// (`min-width: 100%; width: max-content`) so a band runs to its edge
  /// however long the line. Rendered only when a line carries a band.
  final WebElementChrome bandHost;

  /// Paint-ready chrome for the layer the bands sit in — `absolute`, from
  /// the top of the code out to the `<pre>` padding on both sides, so a band
  /// spans the gutter, the code and the padding the way the Flutter twin's
  /// does. Takes no pointer.
  final WebElementChrome bandLayer;

  /// Paint-ready chrome for the wrapper of the code (and gutter) inside
  /// [bandHost] — `relative`, so it paints over [bandLayer].
  final WebElementChrome bandContent;

  /// Paint-ready chrome for a row of [bandLayer] with no band — one line box
  /// (`height: 1lh`), keeping the rows under their lines.
  final WebElementChrome bandRow;

  /// Paint-ready chrome for a row of [bandLayer] that carries a band, in
  /// [CoreCodeLineTone.values] order — read it by `tone.index`. Each is one
  /// line box in the tone's colour (a token class, or inline for a raw
  /// colour); the entry is `null` for a tone that draws no band
  /// ([CoreCodeSnippetStyle.lineColorFor]).
  final List<WebElementChrome?> lineBands;

  /// The highlighter theme every `CodeSnippet` shares.
  ///
  /// It names *roles*, not colours: each scope prefix of
  /// [CoreSyntaxScopes.roles] takes a sentinel foreground that stands for its
  /// [CoreSyntaxRole], and [syntaxChromeOf] swaps the sentinel for the role's
  /// chrome (its CSS variable reference) when a span is emitted. Nothing in
  /// it depends on the palette — which is what lets one highlighter be shared
  /// by every snippet on the page, server-rendered or not — and a span the
  /// table does not name takes the [CoreSyntaxRole.plain] sentinel, never the
  /// highlighter's own black.
  static hl.HighlighterTheme get syntaxTheme => _sharedSyntaxTheme;

  /// The chrome [span] is emitted with, or `null` when it inherits the code
  /// colour (a plain span, one the highlighter left unstyled, or any span on
  /// a face that does not admit the role colours).
  ///
  /// A span the theme named carries its role's sentinel. The one span that
  /// does not is a bare bracket (`{ [ ( ) ] }` outside any scope), which the
  /// highlighter paints from a hard-coded rainbow of its own — recognised by
  /// having a style and no scope — and which reads as punctuation here.
  WebElementChrome? syntaxChromeOf(hl.TextSpan span) {
    final style = span.style;
    if (style == null || span.text == null) return null;
    final role =
        _roleOfSentinel(style.foreground.argb) ??
        (span.scopes.isEmpty ? CoreSyntaxRole.punctuation : null);
    if (role == null) return null;
    final chrome = syntax[role.index];
    return chrome.inlineStyles == null ? null : chrome;
  }
}

// ═══════════════════════════════════════════════════
// Syntax theme — roles, not colours
// ═══════════════════════════════════════════════════

// Top-level initialisers run on first read: built once, lazily.
final hl.HighlighterTheme _sharedSyntaxTheme = _buildSyntaxTheme();

/// The foreground the theme states for [role] — a colour no palette and no
/// highlighter default can produce (`0xFF00000N`), so a span carrying it is
/// unambiguously that role's.
int _sentinelOf(CoreSyntaxRole role) => 0xFF000000 | (role.index + 1);

CoreSyntaxRole? _roleOfSentinel(int argb) {
  final index = (argb & 0x00FFFFFF) - 1;
  if (argb >> 24 != 0xFF ||
      index < 0 ||
      index >= CoreSyntaxRole.values.length) {
    return null;
  }
  return CoreSyntaxRole.values[index];
}

String _hexOf(CoreSyntaxRole role) =>
    '#${(_sentinelOf(role) & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';

hl.HighlighterTheme _buildSyntaxTheme() {
  // A scope-less entry is the fallback every unnamed span takes; without it
  // the highlighter paints them black. Every entry states a foreground for
  // the same reason — a missing one also becomes black.
  final settings = <Map<String, Object>>[
    {
      'settings': {'foreground': _hexOf(CoreSyntaxRole.plain)},
    },
    for (final role in CoreSyntaxRole.values)
      if (CoreSyntaxScopes.scopesOf(role) case final scopes
          when scopes.isNotEmpty)
        {
          'scope': scopes,
          'settings': {'foreground': _hexOf(role)},
        },
  ];
  return hl.HighlighterTheme.fromConfiguration(
    jsonEncode({'settings': settings}),
    hl.TextStyle(foreground: hl.Color(_sentinelOf(CoreSyntaxRole.plain))),
  );
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCodeSnippet] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default (CoreCodeSnippetStyle.defaultX)
///   → theme.coreComponentTheme.codeSnippet.style
///   → widget.codeSnippetStyle
/// ```
/// [lineCount] is a build-time content prop — it sizes the line-number
/// gutter to the widest line number's digit count so the gutter hugs
/// the numbers (parity with the Flutter twin's intrinsic-width
/// `Column`).
ResolvedCodeSnippet resolveCodeSnippet(
  BuildContext context, {
  required int lineCount,
  CoreCodeSnippetStyle? codeSnippetStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.codeSnippet;

  // ─── Merge chain ──────────────────────────────────────
  final stated = resolveStyleChain(const CoreCodeSnippetStyle(), [
    csTheme?.style,
    codeSnippetStyle,
  ]);

  // The face the code sits on decides two things: whether the role colours
  // apply, and — on a solid role face — the ink of the line numbers, the copy
  // glyph and the copy button's focus ring. That ink goes under whatever a
  // caller states, so it is the same however the face was chosen and the
  // order of colour getters does not matter.
  final merged = resolveStyleChain(const CoreCodeSnippetStyle(), [
    CoreCodeSnippetStyle.inkOnFace(
      stated.backgroundColor ?? CoreCodeSnippetStyle.defaultBackgroundColor,
    ),
    stated,
  ]);
  final face =
      merged.backgroundColor ?? CoreCodeSnippetStyle.defaultBackgroundColor;

  // ─── Resolved chrome values ───────────────────────────
  // Colour / typography tokens render through Tailwind role classes
  // (default class, suppressed → inline when overridden — card 모범).
  // Foreground colour rides the nested `codeTextStyle.color` slot; the
  // design-system default lives on `defaultCodeTextStyle.color`.
  final foregroundColorOverride = merged.codeTextStyle?.color;
  final foregroundColor =
      foregroundColorOverride ??
      CoreCodeSnippetStyle.defaultCodeTextStyle.color!;
  // Code body typography — the role rides its `text-{role}` class (the
  // default is the token-backed `codeSm`, whose 21px line box and mono
  // family come from the role's CSS variables) and only what a caller states
  // on top of the role goes inline. The same emit result is applied to every
  // element that carries the role class (`contentWrapper`, `pre`, `code`) so
  // their struts agree. The foreground colour belongs to `codeTextStyle` and
  // rides `contentWrapper` below; a colour stated on the role slot itself is
  // not a supported input (Flutter forces the foreground over it).
  final codeTypography = emitTypography(
    merged.codeTypography,
    CoreCodeSnippetStyle.defaultCodeTypography,
  );

  // Outer chrome — composed via `OutlinedContainer` rather than a
  // hand-drawn box (core/style-contract.md — 합성 = 재구현 금지).
  // Background / border / radius stay `coui_core` domain types,
  // raw-forwarded to `OutlinedContainer(containerStyle: …)`; that
  // component's own resolver runs colour / radius resolution, the
  // surface-material wiring, and the "no shadow of its own" fallback
  // exactly once.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: face,
    borderColor: merged.borderColor ?? CoreCodeSnippetStyle.defaultBorderColor,
    borderRadius:
        merged.borderRadius ?? CoreCodeSnippetStyle.defaultBorderRadius,
    borderWidth: merged.borderWidth ?? CoreCodeSnippetStyle.defaultBorderWidth,
  );

  // Padding / margin / size — always emitted inline
  // (`(merged.X ?? default).toValue()` / rem). 단일 시그니처: no
  // Tailwind dimensional class, no class-drop branch.
  final padding = (merged.padding ?? CoreCodeSnippetStyle.defaultPadding)
      .toValue();
  final preMargin = merged.preMargin ?? CoreCodeSnippetStyle.defaultPreMargin;
  final lineNumberMargin =
      merged.lineNumberMargin ?? CoreCodeSnippetStyle.defaultLineNumberMargin;
  // Code-area size caps — no design-system default (unconstrained is the
  // design), so each edge emits only when the caller set it and the
  // default markup stays byte-identical.
  final minWidth = merged.minWidth;
  final maxWidth = merged.maxWidth;
  final minHeight = merged.minHeight;
  final maxHeight = merged.maxHeight;
  // Gutter width — widest line number's digit count in `ch` units
  // (the code font is monospace, so `1ch` is exactly one digit's
  // advance). Mirrors the Flutter twin's intrinsic-width gutter — a
  // fixed px width left a wide empty band before single-digit numbers.
  final lineNumberDigits = max(1, '$lineCount'.length);
  final copyButtonOffset =
      merged.copyButtonOffset ?? CoreCodeSnippetStyle.defaultCopyButtonOffset;
  // Nested `CoreButtonStyle` slot — chain (default ⊕ override) then
  // raw-forward to `Button(variant: .plain, buttonStyle: …)`. The button
  // owns its size / radius / padding / foreground / transition chrome —
  // not emitted here. Web EMIT is theme-free (no `scheme.resolve`).
  final copyButtonStyle = CoreCodeSnippetStyle.defaultCopyButtonStyle.merge(
    merged.copyButtonStyle,
  );
  // Nested `CoreIconStyle` slot — merge the design-system default (16 px, no
  // colour) with any per-instance override (a solid role face's ink among
  // them) and forward whole to `Icon`. With no colour stated the icon emits
  // none, so the glyph inherits the colour the `Button(variant: .plain)` sets
  // on itself — rest, hover, disabled.
  final iconStyle = CoreCodeSnippetStyle.defaultCopyIconStyle.merge(
    merged.copyIconStyle,
  );
  // Nested action-gap slot — absorb the design-system default so the
  // resolver forwards a non-null `CoreGapStyle` to the action-row gap.
  final actionGapStyle = CoreCodeSnippetStyle.defaultActionGapStyle.merge(
    merged.actionGapStyle,
  );

  // Gutter colour — its own slot (`onSurfaceVariant` by default, a solid role
  // face's ink on one), not the code colour dimmed: a token colour (the
  // default, or a token a caller states) rides a class, a raw one goes
  // inline. It does not follow a restated `codeTextStyle` colour.
  final lineNumberColor = emitColor(
    merged.lineNumberTextStyle?.color,
    CoreCodeSnippetStyle.defaultLineNumberTextStyle.color!,
    .text,
  );

  // Line bands — each slot chained onto its default; Core says which one a
  // tone reads (`lineColorFor` — none for the tones that draw no band). A
  // token colour rides a class, a raw one goes inline. The layer reaches out
  // over the `<pre>` padding on both sides, by the same spacing variables the
  // padding itself emits.
  final paddingInsets = merged.padding ?? CoreCodeSnippetStyle.defaultPadding;
  // The room the Flutter twin's framework `SelectableText` keeps after the
  // code for its caret (see `buildPreInlineStyles`).
  const caretRoom = kEditableDefaultCursorWidth + kEditableCaretGap;
  final successLineColor =
      merged.successLineColor ?? CoreCodeSnippetStyle.defaultSuccessLineColor;
  final warningLineColor =
      merged.warningLineColor ?? CoreCodeSnippetStyle.defaultWarningLineColor;
  final errorLineColor =
      merged.errorLineColor ?? CoreCodeSnippetStyle.defaultErrorLineColor;
  final lineBandColors = [
    for (final tone in CoreCodeLineTone.values)
      if (CoreCodeSnippetStyle.lineColorFor(
            tone,
            success: successLineColor,
            warning: warningLineColor,
            error: errorLineColor,
          )
          case final color?)
        emitColorOrInherit(color, .background)
      else
        null,
  ];

  // Syntax colours — one chrome per role, in `CoreSyntaxRole.values` order,
  // each a variable reference on a face the role colours are certified on
  // (`CoreSyntaxFaces`). `plain` has no token (it inherits the code colour),
  // so its chrome is empty; on a face that does not admit the role colours
  // every chrome is empty and the spans inherit the code colour.
  final syntax = [
    for (final role in CoreSyntaxRole.values)
      if (role.token case final token? when CoreSyntaxFaces.admits(face))
        WebElementChrome(
          className: '',
          inlineStyles: Styles(
            raw: {'color': CoreColor.token(token).toValue()},
          ),
        )
      else
        const WebElementChrome(className: ''),
  ];

  // ─── Local builders ───────────────────────────────────

  /// Composes the `relative`-positioned content-wrapper `<div>`
  /// Tailwind className — nested inside the composed
  /// `OutlinedContainer`'s `child` slot. Carries the `relative`
  /// positioning context [actionWrapper]'s `absolute` corner offset
  /// resolves against, plus the default typography role / foreground
  /// colour classes (suppressed when overridden so the inline rule
  /// wins — card 모범) so `pre`/`code`/`lineNumber` inherit them.
  /// Chrome (background / border / radius) rides [containerStyle] on
  /// the composed root instead — not this wrapper.
  String buildContentWrapperClassName() {
    final classList = [
      WebLayout.relative,
      codeTypography.className,
      if (foregroundColorOverride == null)
        'text-${foregroundColor.tailwindColor}',
    ];
    return classList.join(' ');
  }

  /// Composes the content-wrapper `<div>` inline CSS — any typography
  /// overlay a caller stated on [codeTypography] plus the foreground colour
  /// override (emitted when supplied; the token colour stays on the class
  /// built above). `null` when neither is present.
  Styles? buildContentWrapperInlineStyles() {
    final raw = {
      ...?codeTypography.inline,
      if (foregroundColorOverride != null)
        'color': foregroundColorOverride.toValue(),
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the `<pre>` wrapper Tailwind className — horizontal
  /// overflow + transparent background + typography role + inherit
  /// font.
  String buildPreClassName() =>
      '${WebLayout.overflowXAuto} '
      'bg-transparent '
      '${codeTypography.className} '
      'font-[inherit]';

  /// Composes the `<pre>` wrapper inline CSS — margin + padding
  /// shorthand (always emitted inline) plus the code-area size caps
  /// (emitted only when the caller set them).
  ///
  /// The caps land on `<pre>` because that is the scroll wrapper — the
  /// Flutter twin puts its `BoxConstraints` around the scroll views and
  /// inside the bordered surface, and `box-sizing: border-box` makes the
  /// padding count inside the cap on both sides. `overflow-y: auto`
  /// rides along with a height cap so the clamped area scrolls instead
  /// of spilling, matching the Flutter enclosing
  /// `SingleChildScrollView`.
  Styles buildPreInlineStyles() => .new(
    raw: {
      ...?codeTypography.inline,
      'margin': spaceCss(preMargin),
      'padding': padding,
      // The Flutter twin draws the code in the framework's `SelectableText`,
      // which lays it out the caret room wider than its glyphs — the cursor
      // width plus the framework's gap. That room sits after the code,
      // inside the padding, and scrolls with it; the end padding carries
      // it here. The caret room is the caret's geometry, not spacing, so it
      // stays put under density while the padding moves.
      'padding-inline-end':
          'calc(${spaceCss(paddingInsets.end)} + '
          '${pinnedLengthCss(caretRoom)})',
      'min-width': ?_remOrNull(minWidth),
      'max-width': ?_remOrNull(maxWidth),
      'min-height': ?_remOrNull(minHeight),
      'max-height': ?_remOrNull(maxHeight),
      if (maxHeight != null) 'overflow-y': 'auto',
    },
  );

  /// Composes the `<code>` element Tailwind className — typography
  /// role + inherit font.
  String buildCodeClassName() => '${codeTypography.className} font-[inherit]';

  /// Composes the `<code>` element inline CSS — any typography overlay a
  /// caller stated on [codeTypography], then the per-instance code
  /// text-style override on top of it (`null` when neither is present).
  Styles? buildCodeInlineStyles() {
    final raw = {
      ...?codeTypography.inline,
      ..._textStyleRaw(merged.codeTextStyle),
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes a single line row `<div>` Tailwind className — `flex`
  /// layout (used only when `showLineNumbers` is true).
  String buildLineRowClassName() => WebLayout.flex;

  /// Composes the line-number gutter `<span>` Tailwind className —
  /// inline-block + right-aligned + select-none, and the gutter's colour
  /// class (`text-on-surface-variant` by default; empty when a caller states
  /// a raw colour, which goes inline instead).
  ///
  /// The colour is the gutter's own token, opaque — Flutter resolves the
  /// same slot, so both platforms draw the numbers in one colour and neither
  /// derives it from the code colour.
  String buildLineNumberClassName() {
    final classList = [
      WebLayout.inlineBlock,
      'text-right',
      'select-none',
      if (lineNumberColor.className.isNotEmpty) lineNumberColor.className,
    ];
    return classList.join(' ');
  }

  /// Composes the line-number gutter `<span>` inline CSS — right margin and
  /// width are always emitted inline, a raw gutter colour joins them, and the
  /// optional `lineNumberTextStyle` non-colour overlay is layered on.
  Styles buildLineNumberInlineStyles() {
    return Styles(
      raw: {
        'margin-right': spaceCss(lineNumberMargin),
        // `ch` — one monospace digit per unit, so the gutter hugs the
        // widest number (Flutter intrinsic-width parity).
        'width': '${lineNumberDigits}ch',
        ...?lineNumberColor.inline,
        ..._textStyleRaw(merged.lineNumberTextStyle, withColor: false),
      },
    );
  }

  /// Composes the band layer inline CSS — from the top of the code, out over
  /// the `<pre>` padding on both sides.
  Styles buildBandLayerInlineStyles() => Styles(
    raw: {
      'top': '0',
      'left': 'calc(-1 * ${spaceCss(paddingInsets.left)})',
      'right': 'calc(-1 * ${spaceCss(paddingInsets.right)})',
    },
  );

  /// Composes a band row — one line box, in [band]'s colour when it is one.
  WebElementChrome buildBandRow(Emit? band) => WebElementChrome(
    className: band?.className ?? '',
    inlineStyles: Styles(raw: {'height': '1lh', ...?band?.inline}),
  );

  /// Composes the top-right action wrapper `<div>` Tailwind className —
  /// `absolute` + flex row so the action widgets + copy `Button` flow
  /// at the corner (mirrors the Flutter `Position` + `Row`).
  String buildActionWrapperClassName() =>
      '${WebLayout.absolute} ${WebLayout.flex} ${WebLayout.itemsCenter}';

  /// Composes the top-right action wrapper `<div>` inline CSS — the
  /// top / right corner offset (always emitted inline).
  ///
  /// Pinned: the offset positions the actions against the block's corner,
  /// which the Flutter twin leaves out of the density.
  Styles buildActionWrapperInlineStyles() => .new(
    raw: {
      'top': pinnedLengthCss(copyButtonOffset),
      'right': pinnedLengthCss(copyButtonOffset),
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedCodeSnippet(
    containerStyle: containerStyle,
    contentWrapper: WebElementChrome(
      className: buildContentWrapperClassName(),
      inlineStyles: buildContentWrapperInlineStyles(),
    ),
    pre: WebElementChrome(
      className: buildPreClassName(),
      inlineStyles: buildPreInlineStyles(),
    ),
    code: WebElementChrome(
      className: buildCodeClassName(),
      inlineStyles: buildCodeInlineStyles(),
    ),
    lineRow: WebElementChrome(className: buildLineRowClassName()),
    lineNumber: WebElementChrome(
      className: buildLineNumberClassName(),
      inlineStyles: buildLineNumberInlineStyles(),
    ),
    actionWrapper: WebElementChrome(
      className: buildActionWrapperClassName(),
      inlineStyles: buildActionWrapperInlineStyles(),
    ),
    copyButtonStyle: copyButtonStyle,
    iconStyle: iconStyle,
    actionGapStyle: actionGapStyle,
    syntax: syntax,
    bandHost: const WebElementChrome(
      className: WebLayout.relative,
      inlineStyles: Styles(raw: {'min-width': '100%', 'width': 'max-content'}),
    ),
    bandLayer: WebElementChrome(
      className: '${WebLayout.absolute} ${WebLayout.pointerEventsNone}',
      inlineStyles: buildBandLayerInlineStyles(),
    ),
    bandContent: const WebElementChrome(className: WebLayout.relative),
    bandRow: buildBandRow(null),
    lineBands: [
      for (final band in lineBandColors)
        if (band != null) buildBandRow(band) else null,
    ],
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (small pure functions, short signatures)
// ═══════════════════════════════════════════════════

/// Returns [px] as a `rem` length, or `null` when there is no value to
/// emit — used by the four code-area size caps, where "unset" must stay
/// distinguishable from a `0` cap.
String? _remOrNull(double? px) {
  if (px == null || !px.isFinite) return null;
  return '${px / kRemDivisor}rem';
}

/// Returns CSS overrides extracted from the given text style. When the
/// style is null, returns an empty map. [withColor] false leaves the colour
/// out for a caller that emits it through [emitColor].
///
/// Web EMIT is theme-free — a token colour emits its `var(--coui-X)`
/// reference via `.toValue()` and the browser resolves it at runtime
/// (no `scheme.resolve`, which is a no-op on Web).
Map<String, String> _textStyleRaw(
  CoreTextStyle? style, {
  bool withColor = true,
}) {
  if (style == null) return const {};
  return {
    if (style.fontSize != null)
      'font-size': '${style.fontSize! / kRemDivisor}rem',
    ...lineBoxCss(style),
    if (style.fontWeight != null) 'font-weight': '${style.fontWeight}',
    if (style.letterSpacing != null)
      'letter-spacing': '${style.letterSpacing}em',
    if (style.fontFamily != null)
      'font-family': CssVariableGenerator.fontFamilyCss(style.fontFamily!),
    if (withColor && style.color != null) 'color': style.color!.toValue(),
  };
}

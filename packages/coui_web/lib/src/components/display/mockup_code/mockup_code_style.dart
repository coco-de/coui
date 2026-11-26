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

/// Paint-ready chrome for Web `MockupCode`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // outer wrapper — w-full only
///   └─ OutlinedContainer(containerStyle: frameStyle)  // container chrome — composed, not hand-rolled
///        └─ body (<div>)                // content inset — inline
///             │                          //   four-side `padding`
///             └─ row (<div>) ×N          // single code-line row —
///                                       //   `flex bg-transparent` class
///                                       //   + inline bottom padding
///                  ├─ prefix (<span>)    // co_mockup_code renders only when CoreCodeLine.prefix != null
///                  └─ text (<span>)      // code content —
///                                       //   code-sm + default fg
///                                       //   colour class + optional
///                                       //   inline `color` override
/// ```
///
/// All slot chromes are non-null — `co_mockup_code` walks `lines` and
/// renders the `prefix` slot only when `CoreCodeLine.prefix` is set.
///
/// The outer container is a composed `OutlinedContainer`, not a
/// hand-rolled `<div>` (`core/style-contract.md`'s child-component-
/// composition rule), so its chrome is a single nested [frameStyle]
/// slot rather than `WebElementChrome` fields this resolver would have
/// to assemble — that composition also gets the control-shadow-at-rest
/// fallback for free.
class ResolvedMockupCode implements WebResolvedChrome {
  /// Creates a [ResolvedMockupCode].
  const ResolvedMockupCode({
    required this.root,
    required this.frameStyle,
    required this.body,
    required this.row,
    required this.prefix,
    required this.text,
    required this.toneText,
  });

  /// Paint-ready chrome for the outer wrapper `<div>` — `w-full` only.
  /// Carries no paint chrome of its own — that lives on [frameStyle].
  @override
  final WebElementChrome root;

  /// Nested [CoreOutlinedContainerStyle] for the outer container —
  /// raw-forwarded straight to `OutlinedContainer(containerStyle: …)`;
  /// that widget's own resolver owns border / radius / background /
  /// padding emit and the control-shadow-at-rest fallback (no
  /// className / inlineStyles assembly here). `borderColor` is forced
  /// transparent — `MockupCode` never drew a border of its own. It
  /// states no `padding`: the primitive's Web emit carries one value for
  /// all four sides, so the inset lives on [body].
  final CoreOutlinedContainerStyle frameStyle;

  /// Paint-ready chrome for the content wrapper `<div>` inside the
  /// frame — carries the four-side inset as inline `padding`. The
  /// `OutlinedContainer` Web emit writes a single value (the top side)
  /// for every side, so an asymmetric inset (vertical 10 / horizontal
  /// 16) can only render on this element; Flutter hands the same
  /// `CoreEdgeInsets` to its `OutlinedContainer`, which resolves each
  /// side.
  final WebElementChrome body;

  /// Paint-ready chrome for a single code-line `<div>` — `flex
  /// bg-transparent` className plus the inline bottom padding (line
  /// spacing).
  final WebElementChrome row;

  /// Paint-ready chrome for the line-number gutter `<span>` — inline
  /// block layout, code-sm typography, prefix colour token class
  /// (inline `color` on override), plus the inline gutter `width`.
  /// `co_mockup_code` skips this element when
  /// `CoreCodeLine.prefix == null`.
  final WebElementChrome prefix;

  /// Paint-ready chrome for the code text `<span>` — code-sm
  /// typography plus default foreground colour class (stripped when an
  /// inline `color` override is supplied). This is the `neutral` tone's
  /// chrome and the base every entry of [toneText] is built from; the
  /// widget reads [toneText] and picks the entry by `line.tone.index`.
  final WebElementChrome text;

  /// Paint-ready chrome for the code text `<span>` per line tone — one
  /// entry for every [CoreCodeLineTone], at index `tone.index`. A tone
  /// changes only the colour: each entry is [text]'s typography with the
  /// tone's colour emitted through the same class-XOR-inline decision (a
  /// token colour is a `text-<token>` class, a raw override goes inline),
  /// and `neutral` is [text] itself. `co_mockup_code` selects by `line.tone`.
  ///
  /// The list is built from `CoreCodeLineTone.values`, so `tone.index` is the
  /// position; the resolver test pins each tone's class at its own index.
  final List<WebElementChrome> toneText;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMockupCode] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.mockup.style (shared cross-variant)
///   → theme.coreComponentTheme.mockupCode.style
///   → widget.mockupCodeStyle
/// ```
ResolvedMockupCode resolveMockupCode(
  BuildContext context, {
  CoreMockupCodeStyle? mockupCodeStyle,
}) {
  final mkStyle = context.theme.coreComponentTheme?.mockup?.style;
  final codeTheme = context.theme.coreComponentTheme?.mockupCode;

  // ─── Merge chain (Stage 1 RESOLVE) ────────────────────
  final merged = resolveStyleChain(const CoreMockupCodeStyle(), [
    codeTheme?.style,
    mockupCodeStyle,
  ]);

  // ─── Stage 1 RESOLVE — Core values (local vars) ───────
  final borderRadiusCore =
      merged.borderRadius ??
      mkStyle?.borderRadius ??
      CoreMockupCodeStyle.defaultBorderRadius;
  final paddingCore = merged.padding ?? CoreMockupCodeStyle.defaultPadding;
  final lineSpacing =
      merged.lineSpacing ?? CoreMockupCodeStyle.defaultLineSpacing;
  final lineNumberWidth =
      merged.lineNumberWidth ?? CoreMockupCodeStyle.defaultLineNumberWidth;

  // ─── Composed OutlinedContainer surface (outer container) ──
  // The outer container is a composed `OutlinedContainer`, not a
  // hand-rolled `<div>` (`core/style-contract.md`'s child-component-
  // composition rule) — background / radius / padding stay `coui_core`
  // domain types, raw-forwarded so `OutlinedContainer`'s own resolver
  // runs the class-XOR-inline emit decision and the control-shadow-at-
  // rest fallback once. The shared cross-variant `CoreMockupTheme.style`
  // background is folded into the override slot before the
  // design-system default. `borderColor: transparent` collapses
  // `OutlinedContainer`'s default border to nothing — `MockupCode`
  // never drew a border of its own.
  //
  // No `padding` is stated on the frame: `OutlinedContainer`'s Web emit
  // writes ONE `padding` value (its top side) for all four sides, so the
  // asymmetric default inset (vertical 10 / horizontal 16) would render
  // as 10 all round. The inset is emitted on the content wrapper
  // instead (`buildBodyInlineStyles`) as a four-side declaration, the
  // way `CodeSnippet` pads its own `<pre>`. Flutter still forwards the
  // padding to its `OutlinedContainer`, which resolves each side.
  final frameStyle = CoreOutlinedContainerStyle(
    backgroundColor:
        merged.backgroundColor ??
        mkStyle?.backgroundColor ??
        CoreMockupCodeStyle.defaultBackgroundColor,
    borderColor: .transparent,
    borderRadius: borderRadiusCore,
  );

  // ─── Stage 2 EMIT — Web class XOR inline (theme-free) ──
  // Colour / typography route through the emit family — a single
  // class-XOR-inline decision per design value. Token-bound values
  // (the design-system default AND any token override) emit a Tailwind
  // class so they stay dark-mode reactive; only a raw override goes
  // inline. No `scheme.resolve` (a no-op on Web), no hand-rolled
  // `text-code-sm` role class.
  final textEmit = emitTypography(
    merged.textStyle,
    CoreMockupCodeStyle.defaultTextStyle,
  );
  final prefixEmit = emitTypography(
    merged.prefixTextStyle,
    CoreMockupCodeStyle.defaultPrefixTextStyle,
  );

  // A tone swaps only the colour: the tone slot's colour is laid over the
  // merged code text style before the emit decision, so the role / weight
  // / line box stay the text's own. `neutral` has no slot and reuses
  // [textEmit]. Indexed by `CoreCodeLineTone.index`.
  CoreColor? toneColorOf(CoreCodeLineTone tone) => switch (tone) {
    .neutral => null,
    .muted =>
      merged.mutedToneColor ?? CoreMockupCodeStyle.defaultMutedToneColor,
    .link => merged.linkToneColor ?? CoreMockupCodeStyle.defaultLinkToneColor,
    .success =>
      merged.successToneColor ?? CoreMockupCodeStyle.defaultSuccessToneColor,
    .warning =>
      merged.warningToneColor ?? CoreMockupCodeStyle.defaultWarningToneColor,
    .error =>
      merged.errorToneColor ?? CoreMockupCodeStyle.defaultErrorToneColor,
  };
  final toneTextEmit = [
    for (final tone in CoreCodeLineTone.values)
      switch (toneColorOf(tone)) {
        final toneColor? => emitTypography(
          (merged.textStyle ?? const CoreTextStyle()).merge(
            CoreTextStyle(color: toneColor),
          ),
          CoreMockupCodeStyle.defaultTextStyle,
        ),
        null => textEmit,
      },
  ];

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the outer wrapper `<div>` Tailwind className — `w-full`
  /// only. Carries no paint chrome of its own — that lives on
  /// [frameStyle].
  String buildRootClassName() => WebLayout.wFull;

  /// Composes the content wrapper `<div>` inline-CSS bundle — the
  /// resolved four-side inset. Logical longhands when the value is
  /// directional (a caller may state the inset as `start` / `end`; the
  /// `padding` shorthand is physical by construction), the one-line
  /// shorthand otherwise; each side goes through `spaceCss`, so it
  /// follows density the way the Flutter twin's `toGeometry()` does.
  Styles buildBodyInlineStyles() =>
      .new(raw: paddingCore.toLogicalDeclarations('padding'));

  /// Composes the single code-line `<div>` Tailwind className — `flex`
  /// layout plus the transparent background that lets the container
  /// fill show through. The bottom line spacing is emitted inline.
  String buildRowClassName() => '${WebLayout.flex} bg-transparent';

  /// Composes the single code-line `<div>` inline-CSS bundle — the
  /// resolved per-line bottom spacing (through `spaceCss` — `merged ??
  /// default` share this surface).
  Styles buildRowInlineStyles() =>
      .new(raw: {'padding-bottom': spaceCss(lineSpacing)});

  /// Composes the line-number gutter `<span>` Tailwind className —
  /// inline-block + shrink-0 plus the code-sm typography role /
  /// prefix colour classes from the emit family (token colour stays on a
  /// class; a raw override drops the colour class and goes inline). The
  /// gutter width is emitted inline.
  String buildPrefixClassName() {
    final classList = [
      WebLayout.inlineBlock,
      WebLayout.shrinkZero,
      prefixEmit.className,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the line-number gutter `<span>` inline-CSS bundle — the
  /// resolved gutter `width` (rem escape hatch — `merged ?? default`
  /// share this surface) plus any inline typography fragment (raw colour
  /// / scalar overlay only — token values stay on classes).
  Styles buildPrefixInlineStyles() {
    final raw = {
      'width': '${lineNumberWidth / kRemDivisor}rem',
      ...?prefixEmit.inline,
    };
    return .new(raw: raw);
  }

  /// Composes the code-text `<span>` Tailwind className — code-sm
  /// typography role / foreground colour classes from the emit family
  /// (token colour stays on a class; a raw override drops the colour
  /// class and goes inline).
  // 코드 라인은 줄바꿈하지 않는다 (코드 블록 semantics) — 넘치는
  // 부분은 composed `OutlinedContainer` 의 기본 clip(`.antiAlias` →
  // overflow-hidden) 이 잘라낸다. Flutter 쪽 `Text(softWrap: false)`
  // (기본 clip) 와 동일 동작.
  String buildTextClassName(Emit emit) => [
    emit.className,
    WebLayout.whitespaceNowrap,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the code-text `<span>` inline-CSS bundle — the inline
  /// typography fragment (raw colour / scalar overlay only — token
  /// values stay on classes). Returns `null` when nothing goes inline.
  Styles? buildTextInlineStyles(Emit emit) {
    final inline = emit.inline;
    if (inline == null || inline.isEmpty) return null;
    return Styles(raw: inline);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedMockupCode(
    root: WebElementChrome(className: buildRootClassName()),
    frameStyle: frameStyle,
    body: WebElementChrome(
      className: '',
      inlineStyles: buildBodyInlineStyles(),
    ),
    row: WebElementChrome(
      className: buildRowClassName(),
      inlineStyles: buildRowInlineStyles(),
    ),
    prefix: WebElementChrome(
      className: buildPrefixClassName(),
      inlineStyles: buildPrefixInlineStyles(),
    ),
    text: WebElementChrome(
      className: buildTextClassName(textEmit),
      inlineStyles: buildTextInlineStyles(textEmit),
    ),
    toneText: [
      for (final emit in toneTextEmit)
        WebElementChrome(
          className: buildTextClassName(emit),
          inlineStyles: buildTextInlineStyles(emit),
        ),
    ],
  );
}

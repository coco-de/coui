import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

// ═══════════════════════════════════════════════════
// ResolvedCodeSnippet
// ═══════════════════════════════════════════════════

/// Resolver output for [CodeSnippet].
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus static const default fallback,
/// theme typography resolution and `theme.scaling` applied.
class ResolvedCodeSnippet {
  /// Creates a [ResolvedCodeSnippet].
  const ResolvedCodeSnippet({
    required this.containerStyle,
    required this.contentPadding,
    required this.codeStyle,
    required this.lineNumberStyle,
    required this.lineNumberMargin,
    required this.preMargin,
    required this.copyButtonOffset,
    required this.codeAreaConstraints,
    required this.copyButtonStyle,
    required this.copyIconStyle,
    required this.actionGapStyle,
    required this.syntaxColors,
    required this.lineColors,
  });

  /// [CoreOutlinedContainerStyle] for the composed `OutlinedContainer`
  /// surface — `OutlinedContainer`'s contract input. Background /
  /// border / radius are merged from this component's own style and
  /// left as `coui_core` domain types so the receiving widget runs its
  /// own colour / radius resolution once — plus the surface-material
  /// wiring (glass blur / role fill) and the "no shadow of its own →
  /// take the active style's injected control-shadow" fallback a
  /// hand-drawn box never got (`core/style-contract.md` — 합성 =
  /// 재구현 금지).
  final CoreOutlinedContainerStyle containerStyle;

  /// Code area inner padding (already scaled).
  final EdgeInsets contentPadding;

  /// Rendered code text style.
  final TextStyle codeStyle;

  /// Line-number gutter text style.
  final TextStyle lineNumberStyle;

  /// Line-number gutter right margin (already scaled).
  final double lineNumberMargin;

  /// `<pre>` wrapper outer margin (already scaled).
  final double preMargin;

  /// Copy button corner offset — top + right (already scaled). Layout
  /// positioning of the button within its `Position` corner wrapper,
  /// not button chrome.
  final double copyButtonOffset;

  /// Size constraints for the code display area (already scaled), built
  /// from the `minWidth` / `maxWidth` / `minHeight` / `maxHeight` style
  /// fields. `null` when the caller set none of the four — an
  /// unconstrained code area, which is the design-system default.
  final BoxConstraints? codeAreaConstraints;

  /// Nested [CoreButtonStyle] for the copy affordance — raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`. Chained
  /// `defaultCopyButtonStyle ⊕ override`; `Button` resolves its own
  /// internals (size / radius / padding / foreground / transition) — not
  /// resolved here. On a solid role face it also carries the face's ink as
  /// the focus ring colour (`CoreCodeSnippetStyle.inkOnFace`).
  final CoreButtonStyle copyButtonStyle;

  /// Copy button glyph icon style — raw forward to `Icon` which runs
  /// its own scaling. Carries the size and, unless a caller states one or the
  /// face is a solid role fill ([CoreCodeSnippetStyle.inkOnFace]), no colour:
  /// the glyph follows the copy button's foreground through its states.
  final CoreIconStyle copyIconStyle;

  /// Resolved gap slot between sibling action widgets in the top-right
  /// area — the resolver absorbs the design-system default
  /// ([CoreCodeSnippetStyle.defaultActionGapStyle]) so this is non-null
  /// and carries a concrete `size`. Forwarded raw to
  /// `Gap(gapStyle: …)`; `Gap`'s own resolver applies scaling.
  final CoreGapStyle actionGapStyle;

  /// The colour each highlighted span role paints in, resolved against the
  /// active scheme — every [CoreSyntaxRole] except [CoreSyntaxRole.plain],
  /// which has no colour of its own and inherits [codeStyle]'s.
  ///
  /// Empty on a face the role colours are not certified on
  /// ([CoreSyntaxFaces.admits] is `false` for it): every span then inherits
  /// [codeStyle]'s colour, the snippet's own ink.
  ///
  /// Keyed by role rather than by span so the shared highlighter theme
  /// ([syntaxTheme]) stays independent of the palette: a brightness, brand
  /// or high-contrast change moves these colours and nothing else.
  final Map<CoreSyntaxRole, Color> syntaxColors;

  /// The band each line tone draws behind its line, resolved against the
  /// active scheme — only the tones that draw one
  /// ([CoreCodeSnippetStyle.lineColorFor]). A line whose tone has no entry
  /// draws nothing.
  final Map<CoreCodeLineTone, Color> lineColors;

  /// The highlighter theme every [CodeSnippet] shares.
  ///
  /// It names *roles*, not colours: each scope prefix of
  /// [CoreSyntaxScopes.roles] takes a sentinel foreground that stands for
  /// its [CoreSyntaxRole], and [syntaxColorOf] swaps the sentinel for the
  /// resolved colour when a span is painted. Nothing about it depends on the
  /// palette, so there is one instance for the process and a theme change
  /// needs no rebuild of it — the highlighted spans are converted on every
  /// build anyway.
  ///
  /// A theme built from resolved colours instead would have to be rebuilt
  /// and cached per palette, and every colour it states could be wrong for
  /// the next one. This one cannot be: a span the table does not name takes
  /// the [CoreSyntaxRole.plain] sentinel, never the highlighter's own black.
  static hl.HighlighterTheme get syntaxTheme => _sharedSyntaxTheme;

  /// The colour [span] paints in, or `null` when it inherits [codeStyle]'s
  /// colour (a plain span, one the highlighter left unstyled, or any span on
  /// a face that does not admit the role colours).
  ///
  /// A span the theme named carries its role's sentinel. The one span that
  /// does not is a bare bracket (`{ [ ( ) ] }` outside any scope), which the
  /// highlighter paints from a hard-coded rainbow of its own — recognised by
  /// having a style and no scope — and which reads as punctuation here.
  Color? syntaxColorOf(hl.TextSpan span) {
    final style = span.style;
    if (style == null || span.text == null) return null;
    final role = _roleOfSentinel(style.foreground.argb);
    if (role != null) return syntaxColors[role];
    if (span.scopes.isEmpty) return syntaxColors[CoreSyntaxRole.punctuation];
    return null;
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
// resolveCodeSnippet — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCodeSnippet] for the given [context].
ResolvedCodeSnippet resolveCodeSnippet(
  BuildContext context, {
  CoreCodeSnippetStyle? codeSnippetStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;

  final csTheme = theme.coreComponentTheme?.codeSnippet;

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

  // Foreground colour rides the nested `codeTextStyle.color` slot; the
  // design-system default lives on `defaultCodeTextStyle.color`. It is the
  // ink of the plain text and of every span the highlighter leaves
  // uncoloured — every span, on a face the role colours do not apply on; the
  // gutter states a colour of its own and the copy glyph follows its button.
  final fgColor = scheme
      .resolve(
        merged.codeTextStyle?.color ??
            CoreCodeSnippetStyle.defaultCodeTextStyle.color!,
      )
      .toValue();

  // Outer chrome composes the shared `OutlinedContainer` surface
  // primitive rather than a hand-drawn box, so background / border /
  // radius stay `coui_core` domain types and that primitive's own
  // resolver runs colour and radius resolution plus the surface
  // material wiring and the active style's injected control shadow
  // fallback exactly once.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: face,
    borderColor: merged.borderColor ?? CoreCodeSnippetStyle.defaultBorderColor,
    borderRadius:
        merged.borderRadius ?? CoreCodeSnippetStyle.defaultBorderRadius,
    borderWidth: merged.borderWidth ?? CoreCodeSnippetStyle.defaultBorderWidth,
  );

  final contentPadding =
      ((merged.padding ?? CoreCodeSnippetStyle.defaultPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;

  final lineNumberMargin =
      theme.geometry.space(
        merged.lineNumberMargin ?? CoreCodeSnippetStyle.defaultLineNumberMargin,
      ) *
      scaling;
  final preMargin =
      theme.geometry.space(
        merged.preMargin ?? CoreCodeSnippetStyle.defaultPreMargin,
      ) *
      scaling;
  final copyButtonOffset =
      (merged.copyButtonOffset ??
          CoreCodeSnippetStyle.defaultCopyButtonOffset) *
      scaling;
  // Code-area size caps — the four style fields have no design-system
  // default (unconstrained is the design), so each edge is scaled inside
  // its own null check to keep "no cap" distinguishable from a 0 cap.
  // `BoxConstraints` needs concrete bounds, so the unset edges fall back
  // to the framework's own unbounded sentinels (0 / infinity), and the
  // whole struct stays `null` when the caller set none of the four — the
  // widget then passes no constraints at all.
  final minWidth = merged.minWidth != null ? merged.minWidth! * scaling : null;
  final maxWidth = merged.maxWidth != null ? merged.maxWidth! * scaling : null;
  final minHeight = merged.minHeight != null
      ? merged.minHeight! * scaling
      : null;
  final maxHeight = merged.maxHeight != null
      ? merged.maxHeight! * scaling
      : null;
  final codeAreaConstraints =
      (minWidth == null &&
          maxWidth == null &&
          minHeight == null &&
          maxHeight == null)
      ? null
      : BoxConstraints(
          minWidth: minWidth ?? 0,
          maxWidth: maxWidth ?? .infinity,
          minHeight: minHeight ?? 0,
          maxHeight: maxHeight ?? .infinity,
        );
  // Nested CoreButtonStyle slot — chained (default ⊕ override) then
  // raw-forwarded to `Button(buttonStyle: …)`; the button resolves its
  // own internals (size / radius / padding / foreground / transition) —
  // `scheme.resolve` + `theme.scaling` happen inside Button, not here.
  final copyButtonStyle = CoreCodeSnippetStyle.defaultCopyButtonStyle.merge(
    merged.copyButtonStyle,
  );

  // Code text style — EMIT Stage 2 (Flutter). The default code role, the
  // caller's `codeTypography` and the per-instance `codeTextStyle` overlay
  // merge (composite: default ⊕ override, the Web `emitTypography` shape)
  // and materialise through the single `.toValue(theme:, color:)`
  // primitive. The default role is token-backed (`codeSm`), so it is read
  // off `theme.typography` — a project's own scale and text scaling reach
  // it — and its fixed 21px line box becomes `height = 21 / fontSize`
  // against the final size. The gutter below derives from this same style,
  // so code and numbers sit on the same rows. The `color:` override forces
  // the resolved foreground (`fgColor`) so the code text tracks the code
  // colour regardless of the role's own colour.
  final codeStyleCore = CoreCodeSnippetStyle.defaultCodeTypography
      .merge(merged.codeTypography)
      .merge(merged.codeTextStyle);
  final codeStyle = codeStyleCore.toValue(color: fgColor, theme: theme);

  // Line-number gutter style — the code style with the gutter's own
  // colour. The colour is stated, not derived: the default slot
  // (`onSurfaceVariant`) merged with any per-instance
  // `lineNumberTextStyle` (a solid role face's ink among them), resolved
  // through the scheme — so it does not follow a restated `codeTextStyle`
  // colour. Non-colour overlays merge at the Core level on top of the code
  // style.
  final lineNumberTextStyle = CoreCodeSnippetStyle.defaultLineNumberTextStyle
      .merge(merged.lineNumberTextStyle);
  final lineNumberStyleCore = codeStyleCore.merge(lineNumberTextStyle);
  final lineNumberColor = scheme.resolve(lineNumberTextStyle.color!).toValue();
  final lineNumberStyle = lineNumberStyleCore.toValue(
    color: lineNumberColor,
    theme: theme,
  );

  // Syntax colours — each role's token resolved once against the scheme, on a
  // face the role colours are certified on (`CoreSyntaxFaces`). Off it the map
  // is empty and every span inherits the code colour. `plain` has no token (it
  // inherits the code colour either way), so it is not here.
  final syntaxColors = {
    if (CoreSyntaxFaces.admits(face))
      for (final role in CoreSyntaxRole.values)
        if (role.token case final token?)
          role: scheme.resolve(CoreColor.token(token)).toValue(),
  };

  // Copy-icon slot (glyph) — design-system default (16 px, no colour of its
  // own) merged with any per-instance override (a solid role face's ink among
  // them), raw-forwarded to `Icon`. With no colour stated the glyph takes the
  // one `Button(variant: .plain)` hands its child (rest, hover, disabled);
  // `Icon`'s resolver resolves a stated colour + applies `theme.scaling`.
  final copyIconStyle = CoreCodeSnippetStyle.defaultCopyIconStyle.merge(
    merged.copyIconStyle,
  );

  // Raw forward — Gap's own resolver applies scaling.
  final actionGapStyle = CoreCodeSnippetStyle.defaultActionGapStyle.merge(
    merged.actionGapStyle,
  );

  // Line bands — each slot chained onto its default; Core says which one a
  // tone reads (`lineColorFor` — none for the tones that draw no band).
  final successLineColor =
      merged.successLineColor ?? CoreCodeSnippetStyle.defaultSuccessLineColor;
  final warningLineColor =
      merged.warningLineColor ?? CoreCodeSnippetStyle.defaultWarningLineColor;
  final errorLineColor =
      merged.errorLineColor ?? CoreCodeSnippetStyle.defaultErrorLineColor;
  final lineColors = {
    for (final tone in CoreCodeLineTone.values)
      if (CoreCodeSnippetStyle.lineColorFor(
            tone,
            success: successLineColor,
            warning: warningLineColor,
            error: errorLineColor,
          )
          case final color?)
        tone: scheme.resolve(color).toValue(),
  };

  return ResolvedCodeSnippet(
    containerStyle: containerStyle,
    contentPadding: contentPadding,
    codeStyle: codeStyle,
    lineNumberStyle: lineNumberStyle,
    lineNumberMargin: lineNumberMargin,
    preMargin: preMargin,
    copyButtonOffset: copyButtonOffset,
    codeAreaConstraints: codeAreaConstraints,
    copyButtonStyle: copyButtonStyle,
    copyIconStyle: copyIconStyle,
    actionGapStyle: actionGapStyle,
    syntaxColors: syntaxColors,
    lineColors: lineColors,
  );
}

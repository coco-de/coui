import 'dart:async';
import 'dart:math' show max;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/code_snippet/code_snippet_grammars.g.dart';
import 'package:coui_web/src/components/display/code_snippet/code_snippet_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

/// Unified cross-platform code snippet for CoUI Web.
///
/// Renders code on a quiet container face (`surfaceContainerLow`) with no
/// border, and syntax highlighting via `syntax_highlight_lite` (same engine as
/// Flutter) coloured from the scheme's syntax slots as CSS variable
/// references — so the page's brightness, brand and contrast repaint it with
/// no re-render. The grammar is the one [CoreCodeSnippetContract.grammarOf]
/// gives the [mode] — Dart, JSON, YAML or SQL, the grammars Flutter runs — and
/// a mode it gives none is shown as plain text. All chrome / dimensional /
/// nested text style overrides flow through the single [codeSnippetStyle]
/// slot — see [CoreCodeSnippetStyle] for the merge chain.
class CodeSnippet extends UiStatefulComponent
    implements CoreCodeSnippetContract<Component, CoreVoidCallback> {
  /// Creates a [CodeSnippet].
  const CodeSnippet({
    required this.code,
    required this.mode,
    super.key,
    this.showLineNumbers = false,
    this.lineTones = const {},
    this.showCopyButton = true,
    this.actions = const [],
    this.onCopy,
    this.codeSnippetStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  });

  @override
  final String code;

  @override
  final String mode;

  @override
  final bool showLineNumbers;

  @override
  final Map<int, CoreCodeLineTone> lineTones;

  @override
  final bool showCopyButton;

  @override
  final List<Component> actions;

  @override
  final CoreVoidCallback? onCopy;

  @override
  final CoreCodeSnippetStyle? codeSnippetStyle;

  /// Returns a copy of this component with the supplied non-null
  /// fields overridden.
  CodeSnippet copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    String? code,
    String? mode,
    bool? showLineNumbers,
    Map<int, CoreCodeLineTone>? lineTones,
    bool? showCopyButton,
    List<Component>? actions,
    CoreVoidCallback? onCopy,
    CoreCodeSnippetStyle? codeSnippetStyle,
  }) {
    return CodeSnippet(
      key: key ?? this.key,
      code: code ?? this.code,
      mode: mode ?? this.mode,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      lineTones: lineTones ?? this.lineTones,
      showCopyButton: showCopyButton ?? this.showCopyButton,
      actions: actions ?? this.actions,
      onCopy: onCopy ?? this.onCopy,
      codeSnippetStyle: codeSnippetStyle ?? this.codeSnippetStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  State<CodeSnippet> createState() => _CodeSnippetState();
}

/// Chain sugar for merging a [CoreCodeSnippetStyle] patch into
/// [CodeSnippet.codeSnippetStyle] without hand-reconstructing every
/// field. Mirrors the Flutter `CodeSnippet.withStyle` extension so
/// both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCodeSnippetStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreCodeSnippetStyle.borderRadius] and `.primary` sets
/// [CoreCodeSnippetStyle.backgroundColor] together with the colour that is
/// readable on it ([CoreCodeSnippetStyle.codeTextStyle] — `.primary` paints
/// `onPrimary` code). A face and its ink go together: the code colour
/// defaults to `onSurface`, which only reads on a surface tone. A semantic
/// layer that names these after component-specific intent (decided together
/// with design) is a follow-up once more components adopt this pattern.
///
/// A solid role face (`.primary` … `.outline`) is read by the resolver, not
/// by the getter: the line numbers, the copy glyph and the copy button's
/// focus ring take the face's ink (`CoreCodeSnippetStyle.inkOnFace`)
/// whichever way the face was chosen, and
/// syntax highlighting is off on it — it is not a face the role colours are
/// certified on (`CoreSyntaxFaces.admits`), so every span reads the code
/// colour. Because the glyph then states a colour, it keeps that ink through
/// hover instead of following the copy button's foreground. `.surface`,
/// `.surfaceContainer` and the default face keep the defaults for both.
/// Whichever colour getter comes last owns the face and the code colour, and
/// the line numbers and the glyph follow the face it leaves, so a chain such
/// as `.primary.surface` reads on the face it ends on.
///
/// ```dart
/// CodeSnippet(code: '...', mode: 'dart').radius4.primary
/// ```
extension CodeSnippetStyleChain on CodeSnippet {
  /// Sets the background paint and preserves the other style fields.
  CodeSnippet backgroundColor(CoreColor value) =>
      withStyle(CoreCodeSnippetStyle(backgroundColor: value));

  /// Returns a copy of this [CodeSnippet] with [patch] merged into
  /// [codeSnippetStyle] (patch fields win on conflict).
  CodeSnippet withStyle(CoreCodeSnippetStyle patch) => copyWith(
    codeSnippetStyle: (codeSnippetStyle ?? const CoreCodeSnippetStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  CodeSnippet get radius0 => withStyle(
    const CoreCodeSnippetStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  CodeSnippet get radius2 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  CodeSnippet get radius4 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  CodeSnippet get radius6 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  CodeSnippet get radius8 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  CodeSnippet get radius10 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  CodeSnippet get radius12 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  CodeSnippet get radius14 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  CodeSnippet get radius16 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  CodeSnippet get radius20 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  CodeSnippet get radius24 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  CodeSnippet get radius28 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  CodeSnippet get radius32 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  CodeSnippet get radius36 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  CodeSnippet get radius40 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  CodeSnippet get radius48 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  CodeSnippet get radius56 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  CodeSnippet get radius64 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  CodeSnippet get radius9999 => withStyle(
    const CoreCodeSnippetStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: primary` and its paired ink `onPrimary` as the code
  /// colour (`codeTextStyle.color`); the line numbers, the copy glyph and the
  /// copy button's focus ring take the same ink from the face itself
  /// (`CoreCodeSnippetStyle.inkOnFace`).
  CodeSnippet get primary => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onPrimary),
      ),
    ),
  );

  /// `backgroundColor: secondary` and its paired ink `onSecondary` as the code
  /// colour (`codeTextStyle.color`); the line numbers, the copy glyph and the
  /// copy button's focus ring take the same ink from the face itself
  /// (`CoreCodeSnippetStyle.inkOnFace`).
  CodeSnippet get secondary => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSecondary),
      ),
    ),
  );

  /// `backgroundColor: tertiary` and its paired ink `onTertiary` as the code
  /// colour (`codeTextStyle.color`); the line numbers, the copy glyph and the
  /// copy button's focus ring take the same ink from the face itself
  /// (`CoreCodeSnippetStyle.inkOnFace`).
  CodeSnippet get tertiary => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onTertiary),
      ),
    ),
  );

  /// `backgroundColor: surface` and its paired code colour `onSurface`
  /// (`codeTextStyle.color`).
  CodeSnippet get surface => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
  );

  /// `backgroundColor: surfaceContainer` and its paired code colour `onSurface`
  /// (`codeTextStyle.color`).
  CodeSnippet get surfaceContainer => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
  );

  /// `backgroundColor: error` and its paired ink `onError` as the code
  /// colour (`codeTextStyle.color`); the line numbers, the copy glyph and the
  /// copy button's focus ring take the same ink from the face itself
  /// (`CoreCodeSnippetStyle.inkOnFace`).
  CodeSnippet get error => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onError),
      ),
    ),
  );

  /// `backgroundColor: success` and its paired ink `onSuccess` as the code
  /// colour (`codeTextStyle.color`); the line numbers, the copy glyph and the
  /// copy button's focus ring take the same ink from the face itself
  /// (`CoreCodeSnippetStyle.inkOnFace`).
  CodeSnippet get success => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSuccess),
      ),
    ),
  );

  /// `backgroundColor: warning` and its paired ink `onWarning` as the code
  /// colour (`codeTextStyle.color`); the line numbers, the copy glyph and the
  /// copy button's focus ring take the same ink from the face itself
  /// (`CoreCodeSnippetStyle.inkOnFace`).
  CodeSnippet get warning => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onWarning),
      ),
    ),
  );

  /// `backgroundColor: info` and its paired ink `onInfo` as the code
  /// colour (`codeTextStyle.color`); the line numbers, the copy glyph and the
  /// copy button's focus ring take the same ink from the face itself
  /// (`CoreCodeSnippetStyle.inkOnFace`).
  CodeSnippet get info => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onInfo),
      ),
    ),
  );

  /// `backgroundColor: outline` and its paired ink `surface` as the code
  /// colour (`codeTextStyle.color`); the line numbers, the copy glyph and the
  /// copy button's focus ring take the same ink from the face itself
  /// (`CoreCodeSnippetStyle.inkOnFace`).
  ///
  /// `outline` has no `on` partner, so the ink reads `surface` — the
  /// colour this block's ink has always been on the mid-grey line colour.
  CodeSnippet get outline => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.surface),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`, with the code in `onSurface` —
  /// the page's ink, since the block shows the page through. The page behind
  /// is not known, so this is not a face the role colours are certified on
  /// (`CoreSyntaxFaces.admits`): syntax highlighting is off and every span
  /// reads the code colour.
  CodeSnippet get transparent => withStyle(
    const CoreCodeSnippetStyle(
      backgroundColor: .transparent,
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
  );
}

class _CodeSnippetState extends State<CodeSnippet> {
  /// One highlighter per grammar, made the first time a snippet asks for it.
  ///
  /// Shared by every snippet: a highlighter's theme names roles, not
  /// colours, so it does not depend on the page's brightness (the colours
  /// are CSS variable references the browser resolves).
  static var _highlighters = <String, hl.Highlighter>{};

  /// Whether the copy button currently shows its "copied" check-mark
  /// feedback (reverts after
  /// [CoreCodeSnippetContract.copiedFeedbackDuration]).
  bool _copied = false;
  Timer? _copiedResetTimer;

  /// The highlighter for the grammar [mode] runs, or `null` when the
  /// contract's table gives it none — that code is shown as plain text.
  ///
  /// Which grammar a mode runs is the contract's table
  /// ([CoreCodeSnippetContract.grammarOf]); Flutter reads the same one. The
  /// grammars themselves are the ones Flutter loads as assets, compiled in
  /// here because a Jaspr page has no asset bundle to load from.
  static hl.Highlighter? _highlighterFor(String mode) {
    final language = CoreCodeSnippetContract.grammarOf(mode);
    if (language == null) return null;

    final cached = _highlighters[language];
    if (cached != null) return cached;

    final grammar = codeSnippetGrammarSource(language);
    if (grammar == null) {
      // Dart — the highlighter embeds it. The registration is done by the
      // time the call returns; only its signature is asynchronous.
      unawaited(hl.Highlighter.initialize([language]));
    } else {
      hl.Highlighter.addLanguage(language, grammar);
    }

    final highlighter = hl.Highlighter(
      language: language,
      theme: ResolvedCodeSnippet.syntaxTheme,
    );
    _highlighters = {..._highlighters, language: highlighter};

    return highlighter;
  }

  static List<Component> _highlightCode(
    String code,
    String mode,
    ResolvedCodeSnippet resolved,
  ) {
    final highlighter = _highlighterFor(mode);
    if (highlighter == null) return [Component.text(code)];
    final root = highlighter.highlight(code);
    return _collectSpans(root, resolved);
  }

  /// Flattens a highlighted span tree to DOM. The colour comes from
  /// [ResolvedCodeSnippet.syntaxChromeOf] — the span carries a role, the
  /// resolver knows the token — so the emitter holds no palette of its own and
  /// no hex; bold / italic are read off the span as the theme states them.
  static List<Component> _collectSpans(
    hl.TextSpan node,
    ResolvedCodeSnippet resolved,
  ) {
    final chrome = resolved.syntaxChromeOf(node);
    final bold = node.style?.bold ?? false;
    final italic = node.style?.italic ?? false;
    return [
      if (node.text != null)
        if (chrome != null || bold || italic)
          span(
            [Component.text(node.text!)],
            classes: chrome?.className,
            styles: Styles(
              raw: {...?chrome?.inlineStyles?.properties},
              fontWeight: bold ? .bold : null,
              fontStyle: italic ? .italic : null,
            ),
          )
        else
          Component.text(node.text!),
      for (final child in node.children) ..._collectSpans(child, resolved),
    ];
  }

  static List<Component> _buildLinesWithNumbers(
    List<String> lines,
    List<Component> codeContent,
    ResolvedCodeSnippet resolved,
  ) {
    // Flutter 미러 — 번호는 왼쪽 거터 컬럼, 코드는 통째 하이라이트
    // 블록. 줄별로 쪼개 plain 텍스트로 렌더하면 신택스 하이라이트를
    // 잃는다(줄번호 ↔ 하이라이트가 양자택일이 되어 파리티 위반).
    return [
      div(
        [
          div(
            [
              for (var i = 0; i < lines.length; i++)
                div(
                  [
                    span(
                      [Component.text((i + 1).toString())],
                      classes: resolved.lineNumber.className,
                      styles: resolved.lineNumber.inlineStyles,
                    ),
                  ],
                ),
            ],
          ),
          div(codeContent),
        ],
        classes: resolved.lineRow.className,
      ),
    ];
  }

  /// [body] under the line bands [CodeSnippet.lineTones] asks for — or
  /// [body] alone when no line inside the code carries a band, the markup
  /// this snippet always had.
  ///
  /// The bands are a column of line-box rows behind the code, one per line
  /// up to the last band, so each band sits under its line without being
  /// placed by number. A band row says its tone in words to assistive
  /// technology (an `sr-only` label), the colour being for the eye.
  List<Component> _withLineBands(
    BuildContext context,
    ResolvedCodeSnippet resolved,
    int lineCount,
    List<Component> body,
  ) {
    final bands = <int, (CoreCodeLineTone, WebElementChrome)>{
      for (final MapEntry(key: line, value: tone)
          in component.lineTones.entries)
        if (line >= 1 && line <= lineCount)
          if (resolved.lineBands[tone.index] case final chrome?)
            line: (tone, chrome),
    };
    if (bands.isEmpty) return body;
    final localizations = CouiLocalizations.of(context);
    final last = bands.keys.reduce(max);
    return [
      div(
        [
          div(
            [
              for (var line = 1; line <= last; line++)
                if (bands[line] case (final tone, final chrome))
                  div(
                    [
                      span(
                        [
                          Component.text(switch (tone) {
                            .success =>
                              localizations.codeSnippetSuccessLineLabel(line),
                            .warning =>
                              localizations.codeSnippetWarningLineLabel(line),
                            _ => localizations.codeSnippetErrorLineLabel(line),
                          }),
                        ],
                        classes: WebLayout.srOnly,
                      ),
                    ],
                    classes: chrome.className,
                    styles: chrome.inlineStyles,
                  )
                else
                  div(
                    const [],
                    classes: resolved.bandRow.className,
                    styles: resolved.bandRow.inlineStyles,
                  ),
            ],
            classes: resolved.bandLayer.className,
            styles: resolved.bandLayer.inlineStyles,
          ),
          div(
            body,
            classes: resolved.bandContent.className,
            styles: resolved.bandContent.inlineStyles,
          ),
        ],
        classes: resolved.bandHost.className,
        styles: resolved.bandHost.inlineStyles,
      ),
    ];
  }

  @override
  void dispose() {
    _copiedResetTimer?.cancel();
    super.dispose();
  }

  void handleCopy() {
    writeTextToClipboard(component.code);
    component.onCopy?.call();
    // "Copied" feedback — swap the glyph to a check mark, reverting
    // after the shared feedback duration (re-copying restarts it).
    setState(() => _copied = true);
    _copiedResetTimer?.cancel();
    _copiedResetTimer = Timer(
      CoreCodeSnippetContract.copiedFeedbackDuration,
      () {
        if (mounted) setState(() => _copied = false);
      },
    );
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis. The outer
    // bordered box is composed from `OutlinedContainer` rather than a
    // hand-rolled `<div>` (`core/style-contract.md`'s child-component-
    // composition rule) — this component's own chrome (border / bg /
    // radius) flows through `resolved.containerStyle`, raw-forwarded
    // straight to the shared primitive. `co_code_snippet` reads the
    // remaining paint-ready strings straight from `resolved.<slot>`.
    final lines = component.code.split('\n');
    final resolved = resolveCodeSnippet(
      context,
      lineCount: lines.length,
      codeSnippetStyle: component.codeSnippetStyle,
    );
    final codeContent = _highlightCode(
      component.code,
      component.mode,
      resolved,
    );

    return OutlinedContainer(
      containerStyle: resolved.containerStyle,
      id: component.id,
      classes: component.classes,
      css: component.css,
      attributes: component.userAttributes,
      eventHandlers: component.eventHandlers,
      // `contentWrapper` carries the `relative` positioning context
      // `actionWrapper`'s `absolute` corner offset resolves against,
      // plus the typography role / foreground colour classes
      // `pre`/`code`/`lineNumber` inherit — one level inside the
      // composed chrome box rather than on it.
      child: div(
        [
          pre(
            [
              Component.element(
                tag: 'code',
                classes: resolved.code.className,
                styles: resolved.code.inlineStyles,
                children: _withLineBands(
                  context,
                  resolved,
                  lines.length,
                  component.showLineNumbers
                      ? _buildLinesWithNumbers(
                          lines,
                          codeContent,
                          resolved,
                        )
                      : codeContent,
                ),
              ),
            ],
            classes: resolved.pre.className,
            styles: resolved.pre.inlineStyles,
          ),
          if (component.showCopyButton || component.actions.isNotEmpty)
            Component.element(
              tag: 'div',
              classes: resolved.actionWrapper.className,
              styles: resolved.actionWrapper.inlineStyles,
              children: [
                for (var i = 0; i < component.actions.length; i++) ...[
                  if (i > 0) Gap(gapStyle: resolved.actionGapStyle),
                  component.actions[i],
                ],
                if (component.showCopyButton) ...[
                  if (component.actions.isNotEmpty)
                    Gap(gapStyle: resolved.actionGapStyle),
                  Button(
                    // Copies to the system clipboard (parity with
                    // Flutter `Clipboard.setData`), fires the
                    // caller's `onCopy`, and flips the glyph to a
                    // check mark for the shared feedback duration.
                    onPressed: handleCopy,
                    variant: .plain,
                    buttonStyle: resolved.copyButtonStyle,
                    attributes: {
                      'aria-label': CouiLocalizations.of(
                        context,
                      ).codeSnippetCopyLabel,
                    },
                    child: Icon(
                      _copied ? LucideIcons.check : LucideIcons.copy,
                      iconStyle: resolved.iconStyle,
                    ),
                  ),
                ],
              ],
            ),
        ],
        classes: resolved.contentWrapper.className,
        styles: resolved.contentWrapper.inlineStyles,
      ),
    );
  }
}

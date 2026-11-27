import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart' hide SelectableText;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart' show SelectableText;
import 'package:flutter/semantics.dart'
    show OrdinalSortKey, SemanticsProperties;
import 'package:flutter/services.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

/// Unified cross-platform code snippet with syntax highlighting
/// and clipboard copy functionality.
///
/// Sits on a quiet container face (`surfaceContainerLow`) with no border,
/// syntax highlighting coloured from the scheme's syntax slots (so it follows
/// the brightness, brand and contrast the page is in), and a copy button that
/// toggles to a check icon on copy. All chrome / dimensional / nested text
/// style overrides flow through the single [codeSnippetStyle] slot
/// (Epic #1415 option D).
///
/// Example:
/// ```dart
/// CodeSnippet(
///   code: "void main() {\n  print('Hello!');\n}",
///   mode: 'dart',
/// )
/// ```
class CodeSnippet extends StatefulWidget
    implements CoreCodeSnippetContract<Widget, VoidCallback> {
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
  final List<Widget> actions;

  @override
  final VoidCallback? onCopy;

  @override
  final CoreCodeSnippetStyle? codeSnippetStyle;

  /// Returns a copy of this [CodeSnippet] with the given fields
  /// replaced. All fields default to this instance's current value
  /// when omitted.
  CodeSnippet copyWith({
    Key? key,
    String? code,
    String? mode,
    bool? showLineNumbers,
    Map<int, CoreCodeLineTone>? lineTones,
    bool? showCopyButton,
    List<Widget>? actions,
    VoidCallback? onCopy,
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
    );
  }

  @override
  State<CodeSnippet> createState() => _CodeSnippetState();
}

/// Chain sugar for merging a [CoreCodeSnippetStyle] patch into
/// [CodeSnippet.codeSnippetStyle] without hand-reconstructing every
/// field. Mirrors the Web `CodeSnippet.withStyle` extension so both
/// platforms read identically.
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
  static Future<String?> _initializeLanguage(String mode) {
    // Which grammar a mode runs is the contract's table — Web reads the same.
    final language = CoreCodeSnippetContract.grammarOf(mode);
    if (language == null) {
      return Future.value();
    }
    if (_initializedLanguages.containsKey(language)) {
      return _initializedLanguages[language]!.then((_) => language);
    }
    final future = _loadLanguage(language);
    final updatedLanguages = Map.of(_initializedLanguages);
    updatedLanguages[language] = future;
    _initializedLanguages = updatedLanguages;
    return future.then((_) => language);
  }

  static Future<void> _loadLanguage(String mode) async {
    if (mode == 'dart') {
      await hl.Highlighter.initialize([mode]);
    } else {
      // Lite embeds Dart only; the other grammars are this package's
      // assets, registered with its pure-Dart parser. Web compiles the same
      // files in (`coui_web/tool/gen_code_snippet_grammars.dart`).
      final grammar = await rootBundle.loadString(
        'packages/coui_flutter/assets/syntax_grammars/$mode.json',
      );
      hl.Highlighter.addLanguage(mode, grammar);
    }
  }

  /// Converts a highlighted span to a painted one. The colour comes from
  /// [ResolvedCodeSnippet.syntaxColorOf] — the span carries a role, the
  /// resolver knows the scheme — so the converter holds no palette of its
  /// own; bold / italic / underline are read off the span as the theme
  /// states them.
  static TextSpan _toTextSpan(hl.TextSpan span, ResolvedCodeSnippet resolved) {
    final style = span.style;
    final color = resolved.syntaxColorOf(span);
    final bold = style?.bold ?? false;
    final italic = style?.italic ?? false;
    final underline = style?.underline ?? false;
    return TextSpan(
      text: span.text,
      style: color == null && !bold && !italic && !underline
          ? null
          : TextStyle(
              color: color,
              fontWeight: bold ? .bold : null,
              fontStyle: italic ? .italic : null,
              decoration: underline ? .underline : null,
            ),
      children: [
        for (final child in span.children) _toTextSpan(child, resolved),
      ],
    );
  }

  static var _initializedLanguages = <String, Future<void>>{};

  late Future<hl.Highlighter?> _highlighter;

  /// Whether the copy button currently shows its "copied" check-mark
  /// feedback (reverts after
  /// [CoreCodeSnippetContract.copiedFeedbackDuration]).
  bool _copied = false;
  Timer? _copiedResetTimer;

  @override
  void initState() {
    super.initState();
    _highlighter = _initializeHighlighter();
  }

  Future<hl.Highlighter?> _initializeHighlighter() async {
    final mode = widget.mode;
    final language = await _initializeLanguage(mode);
    if (language == null) return null;
    return hl.Highlighter(
      language: language,
      theme: ResolvedCodeSnippet.syntaxTheme,
    );
  }

  Widget _buildLineNumbers(
    int lineCount,
    TextStyle style,
    double margin,
  ) {
    final lines = <Widget>[];
    for (var i = 1; i <= lineCount; i++) {
      lines.add(Text('$i', style: style));
    }
    return Padding(
      padding: .only(right: margin),
      child: Column(
        crossAxisAlignment: .end,
        children: lines,
      ),
    );
  }

  /// The horizontal scroll that holds the code — and, when lines carry a
  /// tone, the bands behind them.
  ///
  /// With no band the tree is the one this snippet always had. With bands the
  /// padding moves inside the scroll and the content is at least as wide as
  /// the viewport, so a band runs from edge to edge — under the gutter, the
  /// code and the padding on both sides — and scrolls with its line.
  Widget _buildCodeScroll(
    BuildContext context,
    ResolvedCodeSnippet resolved,
    int lineCount,
    Widget codeArea,
  ) {
    final bands = _lineBands(context, resolved, lineCount);
    if (bands.isEmpty) {
      return SingleChildScrollView(
        scrollDirection: .horizontal,
        padding: resolved.contentPadding,
        child: codeArea,
      );
    }
    final defaultTextStyle = DefaultTextStyle.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: .horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: CustomPaint(
            painter: _CodeLineBandPainter(
              code: widget.code,
              // What `SelectableText` lays the code out with — the ambient
              // style under the code style, the ambient scaler and line
              // height behaviour — so a band sits on its line's own box.
              style: defaultTextStyle.style.merge(resolved.codeStyle),
              textScaler: MediaQuery.textScalerOf(context),
              textHeightBehavior: defaultTextStyle.textHeightBehavior,
              textDirection: Directionality.of(context),
              top: resolved.contentPadding.top,
              bands: bands,
            ),
            // The painter's line notes make this a semantics node of its own,
            // which would fold the gutter numbers into the code field's label;
            // the code keeps the nodes it has with no band, read after the
            // notes — the order the Web twin's markup gives.
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              sortKey: OrdinalSortKey(bands.length.toDouble()),
              child: Padding(
                padding: resolved.contentPadding,
                // The code keeps its own width, as it does with no band — a
                // stated minimum would widen the text by its caret margin and
                // make a short snippet scroll.
                child: Align(alignment: .topStart, child: codeArea),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The bands [CodeSnippet.lineTones] asks for — a line inside the code whose
  /// tone draws one — in line order, each with the words that say its tone.
  List<_CodeLineBand> _lineBands(
    BuildContext context,
    ResolvedCodeSnippet resolved,
    int lineCount,
  ) {
    if (widget.lineTones.isEmpty) return const [];
    final localizations = CoUILocalizations.of(context);
    final lines = widget.lineTones.keys.toList()..sort();
    return [
      for (final line in lines)
        if (line >= 1 && line <= lineCount)
          if (resolved.lineColors[widget.lineTones[line]!] case final color?)
            _CodeLineBand(
              index: line - 1,
              color: color,
              label: switch (widget.lineTones[line]!) {
                .success => localizations.codeSnippetSuccessLineLabel(line),
                .warning => localizations.codeSnippetWarningLineLabel(line),
                _ => localizations.codeSnippetErrorLineLabel(line),
              },
            ),
    ];
  }

  @override
  void dispose() {
    _copiedResetTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CodeSnippet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _highlighter = _initializeHighlighter();
    }
  }

  void handleCopy() {
    unawaited(
      Clipboard.setData(ClipboardData(text: widget.code)).then((_) {
        if (context.mounted) {
          widget.onCopy?.call();
        }
      }),
    );
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
  Widget build(BuildContext context) {
    final resolved = resolveCodeSnippet(
      context,
      codeSnippetStyle: widget.codeSnippetStyle,
    );

    // The region is a container boundary only — naming it would make the
    // reader announce the whole code block as "Copy code". The copy label
    // belongs on the copy button, which is where the Web twin puts it.
    return Semantics(
      container: true,
      child: Stacks(
        children: [
          OutlinedContainer(
            containerStyle: resolved.containerStyle,
            child: FutureBuilder(
              future: _highlighter,
              builder: (context, snapshot) {
                if (snapshot.connectionState != .done) {
                  // The caps apply while the highlighter is still loading too —
                  // Web enforces them from the first frame, so leaving this
                  // branch unconstrained would let the box overshoot its stated
                  // maximum for exactly as long as the future takes.
                  return Container(
                    constraints: resolved.codeAreaConstraints,
                    child: Padding(
                      padding: resolved.contentPadding,
                      child: Text(widget.code, style: resolved.codeStyle),
                    ),
                  );
                }
                final data = snapshot.data;
                final lines = widget.code.split('\n');

                TextSpan highlightedSpan(String code) {
                  final raw = data!.highlight(code);
                  return TextSpan(
                    style: resolved.codeStyle,
                    children: [
                      for (final child in raw.children)
                        _toTextSpan(child, resolved),
                    ],
                  );
                }

                final codeArea = widget.showLineNumbers
                    ? Row(
                        crossAxisAlignment: .start,
                        children: [
                          _buildLineNumbers(
                            lines.length,
                            resolved.lineNumberStyle,
                            resolved.lineNumberMargin,
                          ),
                          if (data == null)
                            SelectableText(
                              widget.code,
                              style: resolved.codeStyle,
                            )
                          else
                            SelectableText.rich(
                              highlightedSpan(widget.code),
                            ),
                        ],
                      )
                    : data == null
                    ? SelectableText(
                        widget.code,
                        style: resolved.codeStyle,
                      )
                    : SelectableText.rich(
                        highlightedSpan(widget.code),
                      );

                return Container(
                  constraints: resolved.codeAreaConstraints,
                  child: SingleChildScrollView(
                    child: _buildCodeScroll(
                      context,
                      resolved,
                      lines.length,
                      codeArea,
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.showCopyButton || widget.actions.isNotEmpty)
            Position(
              top: resolved.copyButtonOffset,
              right: resolved.copyButtonOffset,
              child: Row(
                mainAxisSize: .min,
                children: [
                  for (var i = 0; i < widget.actions.length; i++) ...[
                    if (i > 0) Gap(gapStyle: resolved.actionGapStyle),
                    widget.actions[i],
                  ],
                  if (widget.showCopyButton) ...[
                    if (widget.actions.isNotEmpty)
                      Gap(gapStyle: resolved.actionGapStyle),
                    // Icon-only — the label lives here, not on the region.
                    // Matches the Web twin, which puts the same string on the
                    // button's `aria-label`.
                    Semantics(
                      button: true,
                      label: CoUILocalizations.of(context).codeSnippetCopyLabel,
                      child: Button(
                        onPressed: handleCopy,
                        variant: .plain,
                        buttonStyle: resolved.copyButtonStyle,
                        child: Icon(
                          _copied ? LucideIcons.check : LucideIcons.copy,
                          iconStyle: resolved.copyIconStyle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One band behind a line — its 0-based line, its colour, and the words that
/// say its tone.
@immutable
class _CodeLineBand {
  const _CodeLineBand({
    required this.index,
    required this.color,
    required this.label,
  });

  final int index;
  final Color color;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is _CodeLineBand &&
      other.index == index &&
      other.color == color &&
      other.label == label;

  @override
  int get hashCode => Object.hash(index, color, label);
}

/// Paints the line bands of a [CodeSnippet] under its code and says each
/// band's tone to assistive technology at the band's place.
///
/// The code is one block of selectable text, so a line's box is read from
/// laying the same text out with the same style, scaler and line height
/// behaviour — every line, not a pitch multiplied out, so a line whose box
/// differs still gets its own band.
class _CodeLineBandPainter extends CustomPainter {
  _CodeLineBandPainter({
    required this.code,
    required this.style,
    required this.textScaler,
    required this.textHeightBehavior,
    required this.textDirection,
    required this.top,
    required this.bands,
  });

  final String code;
  final TextStyle style;
  final TextScaler textScaler;
  final TextHeightBehavior? textHeightBehavior;
  final TextDirection textDirection;

  /// Where the first line starts — the code area's top padding.
  final double top;
  final List<_CodeLineBand> bands;

  List<(Rect, _CodeLineBand)> _placed(Size size) {
    final painter = TextPainter(
      text: TextSpan(text: code, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      textHeightBehavior: textHeightBehavior,
      // `SelectableText`'s own strut — the code style as a floor under every
      // line.
      strutStyle: const StrutStyle().inheritFromTextStyle(style),
    )..layout();
    final metrics = painter.computeLineMetrics();
    painter.dispose();
    final tops = <double>[];
    var y = top;
    for (final line in metrics) {
      tops.add(y);
      y += line.height;
    }
    return [
      for (final band in bands)
        if (band.index < metrics.length)
          (
            Rect.fromLTWH(
              0,
              tops[band.index],
              size.width,
              metrics[band.index].height,
            ),
            band,
          ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final (rect, band) in _placed(size)) {
      canvas.drawRect(rect, Paint()..color = band.color);
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final (index, (rect, band)) in _placed(size).indexed)
          CustomPainterSemantics(
            rect: rect,
            properties: SemanticsProperties(
              label: band.label,
              textDirection: textDirection,
              // Line order, ahead of the code (sorted after every note).
              sortKey: OrdinalSortKey(index.toDouble()),
            ),
          ),
      ];

  @override
  bool shouldRepaint(_CodeLineBandPainter oldDelegate) =>
      oldDelegate.code != code ||
      oldDelegate.style != style ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.textHeightBehavior != textHeightBehavior ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.top != top ||
      !listEquals(oldDelegate.bands, bands);

  @override
  bool shouldRebuildSemantics(_CodeLineBandPainter oldDelegate) =>
      shouldRepaint(oldDelegate);
}

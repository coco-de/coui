/// Platform-independent contract for unified code snippet components.
///
/// Defines the interface that all CodeSnippet implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/code_snippet/code_snippet_style.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_code_line_tone.dart';
import 'package:coui_core/src/motion/duration_token.dart';

/// Contract for a unified code snippet component.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
/// - [Cb] - callback type
///   (Flutter `VoidCallback`, Web `CoreVoidCallback`).
///
/// Implementations should render a code display block with
/// syntax highlighting and an optional copy button.
abstract interface class CoreCodeSnippetContract<W, Cb> {
  /// How long the copy button shows its "copied" check-mark feedback
  /// before reverting to the copy glyph. Shared by both platforms so
  /// the feedback pace cannot silently diverge (behaviour default —
  /// not chrome, so it lives on the contract, not the style).
  static const Duration copiedFeedbackDuration = Duration(
    milliseconds: CoreDuration.ms2000,
  );

  /// The grammar a [mode] is painted with — `dart`, `json`, `yaml` or `sql` —
  /// or `null` when it names none.
  ///
  /// One table for both platforms: which spellings a mode accepts is not a
  /// platform's choice, and two copies of it are how one platform ends up
  /// painting a language the other shows plain.
  ///
  /// A mode with no entry is shown as plain text and never painted with a
  /// grammar picked for it: Dart's tokenizer reads the `//` of a URL in YAML
  /// as a comment, so a borrowed grammar colours the code wrong rather than
  /// not at all. JavaScript and TypeScript are the one borrowing this table
  /// makes — they are read with the Dart grammar, which reads their comments
  /// and quoted strings as they are written.
  static String? grammarOf(String mode) => switch (mode) {
    'dart' || 'javascript' || 'js' || 'ts' => 'dart',
    'json' => 'json',
    'yaml' || 'yml' => 'yaml',
    'sql' => 'sql',
    _ => null,
  };

  /// The source code content to display.
  String get code;

  /// The programming language mode for syntax highlighting.
  ///
  /// [grammarOf] says which grammar a mode runs; a mode it has no entry for
  /// is shown as plain text.
  String get mode;

  /// Whether to show line numbers.
  bool get showLineNumbers;

  /// What lines mean, keyed by their 1-based line number — the number the
  /// gutter shows. A `success`, `warning` or `error` line draws a band across
  /// the whole row, the gutter included
  /// ([CoreCodeSnippetStyle.lineColorFor]); the other tones draw none. A key
  /// outside the code's lines is ignored.
  ///
  /// The band is colour, so the tone is also said in words to assistive
  /// technology — "line 43: error" — in the snippet's reading order.
  Map<int, CoreCodeLineTone> get lineTones;

  /// Whether to show the copy button.
  bool get showCopyButton;

  /// Additional action widgets displayed in the top-right area.
  List<W> get actions;

  /// Callback invoked after code is copied to clipboard.
  Cb? get onCopy;

  /// Per-instance composite chrome / text style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreCodeSnippetStyle.defaultX)
  ///   → CoreCodeSnippetTheme.style
  ///   → widget.codeSnippetStyle
  /// ```
  CoreCodeSnippetStyle? get codeSnippetStyle;
}

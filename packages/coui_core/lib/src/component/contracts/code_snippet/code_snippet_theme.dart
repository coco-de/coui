import 'package:coui_core/src/component/contracts/code_snippet/code_snippet_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for code snippet components.
///
/// All chrome / nested text style overrides flow through the composite
/// [style] slot — there are no flat chrome fields (Epic #1543 / 7-6 (i)).
/// See [CoreCodeSnippetStyle] for the merge chain.
@immutable
class CoreCodeSnippetTheme {
  /// Creates a [CoreCodeSnippetTheme].
  const CoreCodeSnippetTheme({this.style});

  /// Project-wide composite style applied to every `CodeSnippet`.
  ///
  /// Resolved before any per-instance `widget.codeSnippetStyle`.
  final CoreCodeSnippetStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreCodeSnippetTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}

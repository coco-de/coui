// Adapted from Wonky Work's `wonky_rich_editor` (BSD-3-Clause, Copyright 2026
// The Wonky Work authors) — see NOTICE.

/// The block features a Markdown field supports.
library;

import 'package:coui_core/coui_core.dart' show CoreRichEditorImage;
import 'package:flutter/foundation.dart' show immutable;

/// Which block kinds a field turns into structure: blocks a
/// field does not support stay text. Paragraphs, lists, task lists and
/// inline styles are always supported. Fenced code blocks are not edited
/// as code: they are kept as literal Markdown
/// ([MarkdownNodeMetadata.raw]), like tables and HTML. An image that shares
/// its paragraph with other text is kept the same way.
@immutable
class MarkdownBlockFeatures {
  /// Creates a feature set.
  const MarkdownBlockFeatures({
    this.headings = true,
    this.quotes = true,
    this.rules = true,
    this.images = true,
  });

  /// Every block (posts).
  static const all = MarkdownBlockFeatures();

  /// Comments: no headings, quotes or rules. Images stay: a comment can
  /// carry a screenshot.
  static const comment = MarkdownBlockFeatures(
    headings: false,
    quotes: false,
    rules: false,
  );

  /// `#` headings (levels 1–6; the post renderer draws them at most at h3
  /// size).
  final bool headings;

  /// `>` quotes.
  final bool quotes;

  /// `---` horizontal rules.
  final bool rules;

  /// `![alt](url)` on a line of its own, drawn as an image block (an address
  /// [CoreRichEditorImage.normalizeSource] refuses stays literal text).
  final bool images;

  @override
  bool operator ==(Object other) =>
      other is MarkdownBlockFeatures &&
      other.headings == headings &&
      other.quotes == quotes &&
      other.rules == rules &&
      other.images == images;

  @override
  int get hashCode => Object.hash(headings, quotes, rules, images);
}

/// Node metadata keys of the codec. They live on the super_editor nodes the
/// codec creates and never reach the Markdown.
abstract final class MarkdownNodeMetadata {
  /// `true` on a block kept as literal Markdown (fenced code, tables,
  /// HTML, an image among other text, anything the editor cannot
  /// represent): a code-styled paragraph whose text is written back
  /// verbatim.
  static const raw = 'coui.richEditor.md.raw';

  /// The block's Markdown as it was read.
  static const source = 'coui.richEditor.md.source';

  /// The block's Markdown as the codec writes it, computed when it was
  /// read: while the block still serializes to it, [source] is written
  /// instead, so untouched blocks keep their exact text.
  static const canonical = 'coui.richEditor.md.canonical';

  /// The text between the previous block and this one as it was read.
  static const gap = 'coui.richEditor.md.gap';

  /// The id of the block before this one when it was read.
  static const previous = 'coui.richEditor.md.previous';

  /// The block kind when it was read (`p`, `h2`, `ul`, `ol`, `task`,
  /// `quote`, `raw`, `hr`, `img`).
  static const kind = 'coui.richEditor.md.kind';
}

// Adapted from Wonky Work's `wonky_rich_editor` (BSD-3-Clause, Copyright 2026
// The Wonky Work authors) — see NOTICE.

/// The block features a Markdown field supports.
library;

import 'package:coui_core/coui_core.dart' show CoreRichEditorImage;
import 'package:flutter/foundation.dart' show immutable;

/// Which block kinds a field turns into structure: blocks a
/// field does not support stay text. Paragraphs, lists, task lists and
/// inline styles are always supported. Fenced code blocks are not edited
/// as code: they are kept as literal Markdown, like tables and HTML. An image that shares
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

/// Unicode-aware heading-anchor slugs shared by every Markdown consumer.
///
/// `package:markdown`'s built-in `HeaderWithIdSyntax` /
/// `SetextHeaderWithIdSyntax` generate anchor ids via
/// `BlockSyntax.generateAnchorHash`, which strips anything outside
/// `[a-z0-9 _-]` — every non-Latin heading (Hangul, CJK, …) collapses to an
/// empty or near-empty id. On a Korean-language docs site that means the
/// `#` anchor next to a heading and every "On this page" link pointing at it
/// resolve to the same broken fragment for nearly every section.
///
/// These syntaxes swap in a Unicode-letter-aware slug instead, so both
/// `docs_site` (via `MarkdownParser(documentBuilder:)`) and `docs_app` (via
/// `buildDocsMarkdownDocument`) resolve headings to the same real anchor —
/// one slug rule, not two that can drift.
library;

import 'package:markdown/markdown.dart' as md;

/// Converts heading text into a URL-fragment-safe, Unicode-aware slug.
///
/// HTML5 ids may contain any non-whitespace character, so unlike
/// `BlockSyntax.generateAnchorHash` this keeps letters from any script
/// (`\p{L}`) and digits (`\p{N}`) instead of restricting to ASCII — Hangul
/// syllables are `\p{L}` like any other letter.
String slugifyHeadingText(String text) {
  final normalized = text.toLowerCase().trim();
  final withoutPunctuation = normalized.replaceAll(
    RegExp(r'[^\p{L}\p{N}\s_-]', unicode: true),
    '',
  );
  return withoutPunctuation.trim().replaceAll(RegExp(r'\s+'), '-');
}

/// Drop-in replacement for `BlockSyntax.generateAnchorHash` that slugs with
/// [slugifyHeadingText] instead of the ASCII-only upstream regex.
String _generateAnchorHash(md.Element element) => slugifyHeadingText(element.children!.first.textContent);

/// Same as `package:markdown`'s `HeaderWithIdSyntax`, but slugs the
/// generated id with [slugifyHeadingText].
class DocsHeaderWithIdSyntax extends md.HeaderSyntax {
  const DocsHeaderWithIdSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final element = super.parse(parser) as md.Element;
    if (element.children?.isNotEmpty ?? false) {
      element.generatedId = _generateAnchorHash(element);
    }
    return element;
  }
}

/// Setext-header counterpart of [DocsHeaderWithIdSyntax].
class DocsSetextHeaderWithIdSyntax extends md.SetextHeaderSyntax {
  const DocsSetextHeaderWithIdSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final element = super.parse(parser) as md.Element;
    element.generatedId = _generateAnchorHash(element);
    return element;
  }
}

/// `md.ExtensionSet.gitHubWeb`'s block syntaxes, with the two header
/// syntaxes swapped for [DocsHeaderWithIdSyntax] / [DocsSetextHeaderWithIdSyntax].
final List<md.BlockSyntax> docsHeadingAwareBlockSyntaxes = List<md.BlockSyntax>.unmodifiable(<md.BlockSyntax>[
  const md.FencedCodeBlockSyntax(),
  const DocsHeaderWithIdSyntax(),
  const DocsSetextHeaderWithIdSyntax(),
  const md.TableSyntax(),
  const md.UnorderedListWithCheckboxSyntax(),
  const md.OrderedListWithCheckboxSyntax(),
  const md.FootnoteDefSyntax(),
  const md.AlertBlockSyntax(),
]);

/// `md.ExtensionSet.gitHubWeb`'s inline syntaxes, unchanged — only heading
/// id generation needed a Unicode-aware replacement.
final List<md.InlineSyntax> docsHeadingAwareInlineSyntaxes = List<md.InlineSyntax>.unmodifiable(<md.InlineSyntax>[
  md.InlineHtmlSyntax(),
  md.StrikethroughSyntax(),
  md.EmojiSyntax(),
  md.ColorSwatchSyntax(),
  md.AutolinkExtensionSyntax(),
]);

/// [md.ExtensionSet.gitHubWeb] with Unicode-aware heading-anchor ids.
final md.ExtensionSet docsHeadingAwareExtensionSet = md.ExtensionSet(
  docsHeadingAwareBlockSyntaxes,
  docsHeadingAwareInlineSyntaxes,
);

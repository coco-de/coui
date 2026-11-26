@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/markdown/code_tag_block_syntax.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

/// Runs every content page through the exact pipeline `docs_site`'s
/// `MarkdownParser` uses — `package:markdown`'s document parse, then
/// `MarkdownParser.buildNodes`, which re-parses inline/block HTML text
/// through `package:html`'s tokenizer (`markdown_parser.dart`'s `md.Text`
/// branch calls `html.parseFragment`).
///
/// Why this exists: a `<!-- STYLE_TABLE:BEGIN … -->` marker that read
/// `` `dart run tool/generate_style_tables.dart --write` `` inline once
/// shipped to 28 real component docs. The literal `--` inside that HTML
/// comment body is a WHATWG parse error ("unexpected-char-in-comment"),
/// and `jaspr build`'s server-side render threw a 500 on every one of
/// those 28 pages — `dart analyze`/`dart test docs_core` (string-level
/// checks only) both stayed green throughout, and it was only caught by
/// actually running `jaspr build`, a multi-minute step nobody runs on
/// every change (`deploy.yaml` is `workflow_dispatch`-only — "expensive
/// on every merge"). This test exercises the same parser in milliseconds,
/// as a permanent regression gate against that whole failure class (any
/// future content — generated or hand-written — that embeds raw HTML
/// with a stray `--`, unterminated tag, or other WHATWG parse error).
void main() {
  final contentDir = Directory('content');
  if (!contentDir.existsSync()) return;

  final pages = contentDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      // `_templates`/`_data` are not routes — jaspr_content's loader does
      // not build pages from underscore-prefixed directories, so a parse
      // error there would never reach a live page. `docs_api_sync_test.dart`
      // draws the same line for the same reason.
      .where((f) => !f.path.contains('_templates') && !f.path.contains('_data'))
      .toList();

  test('at least one content page is checked (gate is not silently empty)', () {
    expect(pages, isNotEmpty);
  });

  test('every content page parses through MarkdownParser.buildNodes without throwing', () {
    final offenders = <String>[];
    for (final page in pages) {
      final source = page.readAsStringSync();
      // Frontmatter (--- ... ---) is stripped by jaspr_content's Page
      // loader before the body ever reaches MarkdownParser — leaving it
      // in would make every page's `---` delimiters look like malformed
      // input to this standalone check.
      final body = source.startsWith('---') ? source.replaceFirst(RegExp(r'^---.*?---\n', dotAll: true), '') : source;

      try {
        final document = md.Document(
          blockSyntaxes: kDocsBlockSyntaxes,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );
        MarkdownParser.buildNodes(document.parse(body));
      } on Object catch (e) {
        offenders.add('${page.path}: $e');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'These content pages fail to parse through the same pipeline '
          'jaspr build uses (jaspr build itself would 500 on them):\n  '
          '${offenders.join("\n  ")}',
    );
  });

  // A `<Code>` block that ends early or opens a stray tag does not throw —
  // it parses, and everything after it lands inside the code box. Two shapes
  // shipped that way with every test green: a blank line inside the block
  // (a blank line ends an HTML block, so the rest of the page is no longer
  // inside it) and a generic like `<Widget>` (read as an unclosed element
  // that swallows the following sections). The section contract test reads
  // the markdown source, so it saw every heading where it belonged.
  //
  // The site reads a `<Code>` block with its own syntax (`kDocsBlockSyntaxes`)
  // that hands the lines over as text, so both shapes are code now. A block
  // with no closing line is still an HTML block — the check still sees that.
  group('a <Code> block holds only its own text', () {
    test('blank lines and generics stay inside the code', () {
      const source =
          '<Code language="dart" title="t">\nfinal a = Select<String>();\n\nList<Widget> b = [];\n</Code>\n\n## After\n';
      expect(_swallowingCodeBlocks(source), isEmpty);
      expect(_codeTexts(source), ['final a = Select<String>();\n\nList<Widget> b = [];']);
    });

    test('a block that never closes is still caught', () {
      expect(
        _swallowingCodeBlocks('<Code language="dart" title="t">\nList<Widget>()\n\n## After\n'),
        isNotEmpty,
      );
    });

    test('no content page swallows anything into a <Code> block', () {
      final offenders = [
        for (final page in pages)
          for (final problem in _swallowingCodeBlocks(page.readAsStringSync())) '${page.path}: $problem',
      ];
      expect(
        offenders,
        isEmpty,
        reason:
            'Close every <Code> block with a </Code> line of its own:\n  '
            '${offenders.join("\n  ")}',
      );
    });
  });
}

/// The `<Code>` elements in [source] that hold anything but text, each named
/// by the first element they swallowed.
List<String> _swallowingCodeBlocks(String source) {
  final body = source.startsWith('---') ? source.replaceFirst(RegExp(r'^---.*?---\n', dotAll: true), '') : source;
  final document = md.Document(
    blockSyntaxes: kDocsBlockSyntaxes,
    extensionSet: md.ExtensionSet.gitHubWeb,
  );
  final problems = <String>[];
  void walk(List<Node> nodes) {
    for (final node in nodes) {
      if (node is! ElementNode) continue;
      final children = node.children ?? const <Node>[];
      if (node.tag == 'Code') {
        final swallowed = children.whereType<ElementNode>().firstOrNull;
        if (swallowed != null) problems.add('<Code> holds <${swallowed.tag}>');
      }
      walk(children);
    }
  }

  walk(MarkdownParser.buildNodes(document.parse(body)));
  return problems;
}

/// The text of each `<Code>` element in [source], as the site reads it.
List<String> _codeTexts(String source) {
  final document = md.Document(blockSyntaxes: kDocsBlockSyntaxes, extensionSet: md.ExtensionSet.gitHubWeb);
  final texts = <String>[];
  void walk(List<Node> nodes) {
    for (final node in nodes.whereType<ElementNode>()) {
      if (node.tag == 'Code')
        texts.add((node.children ?? const <Node>[]).map((child) => child.innerText).join().trim());
      walk(node.children ?? const []);
    }
  }

  walk(MarkdownParser.buildNodes(document.parse(source)));
  return texts;
}

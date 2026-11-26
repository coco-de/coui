/// Markdown ⇄ document codec for the Web `RichEditor`.
///
/// The editor keeps its document in the DOM, but nothing here touches the
/// DOM: both directions go through [RichEditorNode], a small tree the DOM
/// bridge reads the editing surface into. That keeps the codec plain Dart —
/// the server renders the first paint with it, and the round trip is tested
/// on the VM.
///
/// ```text
/// Markdown ──parseRichEditorMarkdown──▶ nodes ──renderRichEditorHtml──▶ HTML
/// DOM ──(bridge)──▶ nodes ──serializeRichEditorMarkdown──▶ Markdown
/// ```
library;

import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart' show immutable;
import 'package:markdown/markdown.dart' as md;

/// One node of the editor's document — an element or a run of text.
///
/// Tags are lower-case HTML tag names. A text node has [tag]
/// [RichEditorNode.textTag] and carries [text].
@immutable
class RichEditorNode {
  /// Creates an element node.
  const RichEditorNode(
    this.tag, {
    this.attributes = const {},
    this.children = const [],
  }) : text = null;

  /// Creates a text node.
  const RichEditorNode.text(String this.text)
    : tag = textTag,
      attributes = const {},
      children = const [];

  /// The [tag] of a text node.
  static const String textTag = '#text';

  /// The element's tag, or [textTag].
  final String tag;

  /// The element's attributes (`href`, `start`, `checked`, `class`, and an
  /// image's `src` and `alt`).
  final Map<String, String> attributes;

  /// The element's children.
  final List<RichEditorNode> children;

  /// The text of a text node; null for an element.
  final String? text;

  /// Whether this is a text node.
  bool get isText => tag == textTag;

  /// The text of this node and everything under it.
  String get textContent =>
      isText ? text! : children.map((child) => child.textContent).join();

  @override
  String toString() => isText ? '"$text"' : '<$tag $attributes>$children';
}

// ═══════════════════════════════════════════════════
// Markdown → nodes
// ═══════════════════════════════════════════════════

/// Tag names the editor keeps; anything else is unwrapped to its children.
const Set<String> _kKeptTags = {
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'ul',
  'ol',
  'li',
  'blockquote',
  'pre',
  'code',
  'hr',
  'br',
  'strong',
  'em',
  'del',
  'a',
  'img',
  'input',
};

/// The Markdown dialect the editor reads: CommonMark plus the GitHub
/// extensions it can edit — fenced code, task lists, strikethrough and bare
/// links. Tables and raw HTML are left out: a table has no editing surface
/// here, and raw HTML is shown as the text it is, never injected.
md.Document _document() => md.Document(
  extensionSet: md.ExtensionSet.none,
  blockSyntaxes: const [
    md.FencedCodeBlockSyntax(),
    md.UnorderedListWithCheckboxSyntax(),
    md.OrderedListWithCheckboxSyntax(),
  ],
  inlineSyntaxes: [md.StrikethroughSyntax(), md.AutolinkExtensionSyntax()],
  encodeHtml: false,
);

/// Parses [markdown] into the editor's document.
///
/// Links go through [CoreRichEditorContract.normalizeLink]: an unsafe target
/// (`javascript:` and the like) keeps its text and loses the link. Images go
/// through [CoreRichEditorImage.normalizeSource] the same way: one that may
/// be shown stays an `img`, an unsafe one becomes its alt text. An image
/// alone in its paragraph is the editor's image block. Soft line breaks
/// become spaces, the way they read.
List<RichEditorNode> parseRichEditorMarkdown(String markdown) {
  if (markdown.trim().isEmpty) return const [];
  final nodes = _document().parse(markdown.replaceAll('\r\n', '\n'));
  // A raw-HTML block parses to bare text; it is a paragraph of that text.
  final blocks = <RichEditorNode>[];
  for (final node in _convertAll(nodes, inPre: false)) {
    blocks.add(_isBlock(node) ? node : RichEditorNode('p', children: [node]));
  }
  return blocks;
}

List<RichEditorNode> _convertAll(List<md.Node> nodes, {required bool inPre}) =>
    [
      for (final node in nodes) ..._convert(node, inPre: inPre),
    ];

List<RichEditorNode> _convert(md.Node node, {required bool inPre}) {
  if (node is md.Text) {
    final text = inPre ? node.text : node.text.replaceAll('\n', ' ');
    return text.isEmpty ? const [] : [RichEditorNode.text(text)];
  }
  if (node is! md.Element) {
    final text = node.textContent;
    return text.isEmpty ? const [] : [RichEditorNode.text(text)];
  }
  final tag = node.tag;
  final children = node.children ?? const <md.Node>[];
  switch (tag) {
    case 'img':
      final alt = node.attributes['alt'] ?? '';
      final src = CoreRichEditorImage.normalizeSource(
        node.attributes['src'] ?? '',
      );
      if (src == null) {
        return alt.isEmpty ? const [] : [RichEditorNode.text(alt)];
      }
      return [
        RichEditorNode('img', attributes: {'src': src, 'alt': alt}),
      ];
    case 'a':
      final href = CoreRichEditorContract.normalizeLink(
        node.attributes['href'] ?? '',
      );
      final converted = _convertAll(children, inPre: inPre);
      if (href == null) return converted;
      return [
        RichEditorNode('a', attributes: {'href': href}, children: converted),
      ];
    case 'input':
      return [
        RichEditorNode(
          'input',
          attributes: {
            'type': 'checkbox',
            if (node.attributes.containsKey('checked')) 'checked': '',
          },
        ),
      ];
    case 'ol':
      final start = node.attributes['start'];
      return [
        RichEditorNode(
          'ol',
          attributes: {'start': ?start},
          children: _convertAll(children, inPre: inPre),
        ),
      ];
    case 'li':
      return [_convertListItem(children)];
    case 'pre':
      // The literal block's text, kept verbatim; a fence's info string
      // rides the inner `<code>`'s class.
      final code = children.whereType<md.Element>().firstOrNull;
      final language = code?.attributes['class'];
      return [
        RichEditorNode(
          'pre',
          children: [
            RichEditorNode(
              'code',
              attributes: {'class': ?language},
              children: [
                RichEditorNode.text(
                  node.textContent.replaceAll(_kTrailingNewline, ''),
                ),
              ],
            ),
          ],
        ),
      ];
  }
  final converted = _convertAll(children, inPre: inPre || tag == 'pre');
  if (!_kKeptTags.contains(tag)) return converted;
  return [RichEditorNode(tag, children: converted)];
}

final RegExp _kTrailingNewline = RegExp(r'\n$');

/// A list item, with a task's checkbox moved to its front and a lone
/// paragraph unwrapped — the shape the editing surface holds.
RichEditorNode _convertListItem(List<md.Node> children) {
  var converted = _convertAll(children, inPre: false);
  // A loose item's first paragraph carries the checkbox; lift it out.
  RichEditorNode? checkbox;
  final flattened = <RichEditorNode>[];
  for (final child in converted) {
    if (child.tag == 'input') {
      checkbox ??= child;
      continue;
    }
    if (child.tag == 'p' && child.children.firstOrNull?.tag == 'input') {
      checkbox ??= child.children.first;
      flattened.add(RichEditorNode('p', children: child.children.sublist(1)));
      continue;
    }
    flattened.add(child);
  }
  converted = flattened;
  final paragraphs = converted.where((child) => child.tag == 'p').length;
  if (paragraphs == 1 && converted.first.tag == 'p') {
    converted = [...converted.first.children, ...converted.skip(1)];
  }
  // A task's text starts after the space that follows `[ ]`.
  if (checkbox != null && converted.firstOrNull?.isText == true) {
    final first = converted.first.text!.replaceFirst(RegExp('^ '), '');
    converted = [
      if (first.isNotEmpty) RichEditorNode.text(first),
      ...converted.skip(1),
    ];
  }
  return RichEditorNode('li', children: [?checkbox, ...converted]);
}

// ═══════════════════════════════════════════════════
// nodes → HTML (the editing surface's markup)
// ═══════════════════════════════════════════════════

/// Void elements — written without a closing tag.
const Set<String> _kVoidTags = {'br', 'hr', 'img', 'input'};

/// Renders [nodes] as the editing surface's markup.
///
/// Every text and attribute value is HTML-escaped, and only the tags the
/// codec produces are written, so the markup carries no caller HTML. A
/// task's checkbox is not editable text (`contenteditable="false"`) and
/// takes no tab stop of its own — the editor's surface is the one stop. An
/// image whose `src` the editor would not show
/// ([CoreRichEditorImage.normalizeSource]) is written as its alt text.
String renderRichEditorHtml(List<RichEditorNode> nodes) {
  final buffer = StringBuffer();
  for (final node in nodes) {
    _renderNode(node, buffer);
  }
  return buffer.toString();
}

void _renderNode(RichEditorNode node, StringBuffer buffer) {
  if (node.isText) {
    buffer.write(escapeRichEditorHtml(node.text!));
    return;
  }
  if (node.tag == 'img') {
    final src = CoreRichEditorImage.normalizeSource(
      node.attributes['src'] ?? '',
    );
    final alt = node.attributes['alt'] ?? '';
    if (src == null) {
      buffer.write(escapeRichEditorHtml(alt));
      return;
    }
    buffer.write(
      '<img src="${escapeRichEditorHtml(src)}" '
      'alt="${escapeRichEditorHtml(alt)}">',
    );
    return;
  }
  final attributes = <String, String>{
    if (node.tag == 'input') ...{
      'type': 'checkbox',
      'contenteditable': 'false',
      'tabindex': '-1',
      if (node.attributes.containsKey('checked')) 'checked': '',
    } else
      ...node.attributes,
  };
  buffer.write('<${node.tag}');
  attributes.forEach((name, value) {
    buffer.write(' $name="${escapeRichEditorHtml(value)}"');
  });
  buffer.write('>');
  if (_kVoidTags.contains(node.tag)) return;
  for (final child in node.children) {
    _renderNode(child, buffer);
  }
  buffer.write('</${node.tag}>');
}

/// The addresses of the images [nodes] hold — the ones the editor would
/// show, which are the ones the Markdown keeps.
Set<String> richEditorImageUrls(List<RichEditorNode> nodes) {
  final urls = <String>{};
  void walk(List<RichEditorNode> level) {
    for (final node in level) {
      if (node.isText) continue;
      if (node.tag == 'img') {
        final src = CoreRichEditorImage.normalizeSource(
          node.attributes['src'] ?? '',
        );
        if (src != null) urls.add(src);
        continue;
      }
      walk(node.children);
    }
  }

  walk(nodes);
  return urls;
}

/// Escapes [text] for HTML text and attribute positions.
String escapeRichEditorHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// ═══════════════════════════════════════════════════
// nodes → Markdown
// ═══════════════════════════════════════════════════

/// Characters the editor's caret work leaves in the document (a zero-width
/// space that holds the caret outside a mark) — never part of the value.
const String _kCaretHolder = '​';

/// Tags that start a block.
const Set<String> _kBlockTags = {
  'p',
  'div',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'ul',
  'ol',
  'li',
  'blockquote',
  'pre',
  'hr',
  'section',
  'article',
  'header',
  'footer',
};

/// Serialises a document read from the editing surface to Markdown.
///
/// Normalises what browsers write into a `contenteditable`: a `<div>` line
/// is a paragraph, `<b>` / `<i>` / `<strike>` are the strong / emphasis /
/// strikethrough marks, styling `<span>`s are unwrapped, loose inline runs
/// at the top level are paragraphs, and a trailing `<br>` placeholder is
/// dropped. Plain text is escaped so it reads back as the same text.
String serializeRichEditorMarkdown(List<RichEditorNode> nodes) =>
    _serializeBlocks(nodes).join('\n\n');

/// Serialises a run of sibling nodes as blocks (one string per block,
/// possibly multi-line).
List<String> _serializeBlocks(List<RichEditorNode> nodes) {
  final blocks = <String>[];
  var inline = <RichEditorNode>[];
  void flushInline() {
    if (inline.isEmpty) return;
    final text = _serializeParagraph(inline);
    if (text.isNotEmpty) blocks.add(text);
    inline = [];
  }

  for (final node in nodes) {
    if (!_isBlock(node)) {
      inline.add(node);
      continue;
    }
    flushInline();
    blocks.addAll(_serializeBlock(node));
  }
  flushInline();
  return blocks;
}

bool _isBlock(RichEditorNode node) =>
    !node.isText && _kBlockTags.contains(node.tag);

List<String> _serializeBlock(RichEditorNode node) {
  switch (node.tag) {
    case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
      final text = _serializeInline(node.children, lineStart: false);
      if (text.isEmpty) return const [];
      final level = int.parse(node.tag.substring(1));
      return ['${'#' * level} ${text.replaceAll('\n', ' ')}'];
    case 'ul' || 'ol':
      final list = _serializeList(node);
      return list.isEmpty ? const [] : [list];
    case 'li':
      // A stray item outside a list reads as a bullet.
      final list = _serializeList(RichEditorNode('ul', children: [node]));
      return list.isEmpty ? const [] : [list];
    case 'blockquote':
      final inner = _serializeBlocks(node.children).join('\n\n');
      if (inner.isEmpty) return const [];
      return [
        inner
            .split('\n')
            .map((line) => line.isEmpty ? '>' : '> $line')
            .join('\n'),
      ];
    case 'pre':
      return [_serializeCodeBlock(node)];
    case 'hr':
      return const ['---'];
  }
  // p / div / section: a paragraph, unless it holds blocks of its own (a
  // browser wraps a pasted list in a `<div>`).
  if (node.children.any(_isBlock)) return _serializeBlocks(node.children);
  final text = _serializeParagraph(node.children);
  return text.isEmpty ? const [] : [text];
}

String _serializeParagraph(List<RichEditorNode> nodes) =>
    _serializeInline(nodes, lineStart: true);

String _serializeCodeBlock(RichEditorNode pre) {
  final code = pre.children.where((child) => child.tag == 'code').firstOrNull;
  final language = code?.attributes['class']?.replaceFirst('language-', '');
  final text = pre.textContent
      .replaceAll(_kCaretHolder, '')
      .replaceAll(' ', ' ')
      .replaceAll(_kTrailingNewline, '');
  final longest = RegExp('`+')
      .allMatches(text)
      .fold<int>(
        0,
        (max, match) =>
            match.group(0)!.length > max ? match.group(0)!.length : max,
      );
  final fence = '`' * (longest < 3 ? 3 : longest + 1);
  return '$fence${language ?? ''}\n$text\n$fence';
}

String _serializeList(RichEditorNode list) {
  final ordered = list.tag == 'ol';
  var number = int.tryParse(list.attributes['start'] ?? '') ?? 1;
  final lines = <String>[];
  for (final item in list.children) {
    if (item.isText && item.text!.trim().isEmpty) continue;
    final itemChildren = item.tag == 'li' ? item.children : [item];
    final checkbox = _findCheckbox(itemChildren);
    final marker = ordered ? '$number. ' : '- ';
    number++;
    final task = checkbox == null
        ? ''
        : checkbox.attributes.containsKey('checked')
        ? '[x] '
        : '[ ] ';
    final indent = ' ' * marker.length;
    final content = <RichEditorNode>[
      for (final child in itemChildren)
        if (child.tag != 'input') child,
    ];
    // The item's own text, then any nested blocks (a sub-list).
    final inline = <RichEditorNode>[];
    final nested = <RichEditorNode>[];
    for (final child in content) {
      if (nested.isEmpty && !_isBlock(child)) {
        inline.add(child);
      } else if (nested.isEmpty &&
          (child.tag == 'p' || child.tag == 'div') &&
          !child.children.any(_isBlock)) {
        if (inline.isNotEmpty) inline.add(const RichEditorNode('br'));
        inline.addAll(child.children);
      } else {
        nested.add(child);
      }
    }
    final text = _serializeInline(inline, lineStart: false);
    final head = '$marker$task$text'.trimRight();
    lines.add(head.split('\n').join('\n$indent'));
    for (final block in _serializeBlocks(nested)) {
      lines.add(
        block
            .split('\n')
            .map((line) => line.isEmpty ? line : '$indent$line')
            .join('\n'),
      );
    }
  }
  return lines.join('\n');
}

RichEditorNode? _findCheckbox(List<RichEditorNode> children) {
  for (final child in children) {
    if (child.tag == 'input' && child.attributes['type'] == 'checkbox') {
      return child;
    }
    if (child.isText &&
        child.text!.replaceAll(_kCaretHolder, '').trim().isEmpty) {
      continue;
    }
    // Only a leading checkbox makes an item a task.
    if (child.tag != 'p' && child.tag != 'span') return null;
    return _findCheckbox(child.children);
  }
  return null;
}

/// The mark a tag stands for, after normalising the browser's spellings.
String? _markOf(String tag) => switch (tag) {
  'strong' || 'b' => '**',
  'em' || 'i' => '*',
  'del' || 's' || 'strike' => '~~',
  _ => null,
};

/// Serialises inline content. [lineStart] is whether the content begins a
/// line, where `#`, `>`, `-` and `1.` would start a block.
String _serializeInline(List<RichEditorNode> nodes, {required bool lineStart}) {
  final merged = _mergeAdjacentMarks(_dropTrailingBreaks(nodes));
  final buffer = StringBuffer();
  _writeInline(merged, buffer, openMarks: const {});
  final text = buffer.toString();
  // A break at the very start or end carries nothing.
  final trimmed = text
      .replaceAll(RegExp(r'^(\\\n)+'), '')
      .replaceAll(RegExp(r'(\\\n)+$'), '');
  final collapsed = trimmed.trim().isEmpty ? '' : trimmed;
  if (!lineStart || collapsed.isEmpty) return collapsed;
  return collapsed.split('\n').map(_escapeLineStart).join('\n');
}

/// Drops `<br>` nodes at the end of [nodes] — the placeholder a browser
/// keeps in an empty or just-split line.
List<RichEditorNode> _dropTrailingBreaks(List<RichEditorNode> nodes) {
  var end = nodes.length;
  while (end > 0) {
    final node = nodes[end - 1];
    if (node.tag == 'br') {
      end--;
      continue;
    }
    if (node.isText && node.text!.replaceAll(_kCaretHolder, '').isEmpty) {
      end--;
      continue;
    }
    break;
  }
  return end == nodes.length ? nodes : nodes.sublist(0, end);
}

/// Joins `<b>a</b><b>b</b>` into one mark — written apart they would read
/// as `**a****b**`.
List<RichEditorNode> _mergeAdjacentMarks(List<RichEditorNode> nodes) {
  final result = <RichEditorNode>[];
  for (final node in nodes) {
    final previous = result.lastOrNull;
    final mark = node.isText ? null : _markOf(node.tag);
    if (previous != null &&
        mark != null &&
        !previous.isText &&
        _markOf(previous.tag) == mark) {
      result[result.length - 1] = RichEditorNode(
        previous.tag,
        children: [...previous.children, ...node.children],
      );
      continue;
    }
    result.add(node);
  }
  return result;
}

void _writeInline(
  List<RichEditorNode> nodes,
  StringBuffer buffer, {
  required Set<String> openMarks,
}) {
  for (final node in nodes) {
    if (node.isText) {
      buffer.write(escapeRichEditorMarkdown(_cleanText(node.text!)));
      continue;
    }
    final tag = node.tag;
    final mark = _markOf(tag);
    if (mark != null) {
      if (openMarks.contains(mark)) {
        // `<b>` inside `<b>` adds nothing.
        _writeInline(node.children, buffer, openMarks: openMarks);
        continue;
      }
      final inner = StringBuffer();
      _writeInline(
        _mergeAdjacentMarks(node.children),
        inner,
        openMarks: {...openMarks, mark},
      );
      buffer.write(_wrap(inner.toString(), mark, mark));
      continue;
    }
    switch (tag) {
      case 'code':
        buffer.write(_inlineCode(_cleanText(node.textContent)));
      case 'a':
        final href = CoreRichEditorContract.normalizeLink(
          node.attributes['href'] ?? '',
        );
        final inner = StringBuffer();
        _writeInline(node.children, inner, openMarks: openMarks);
        final label = inner.toString();
        if (href == null) {
          buffer.write(label);
        } else if (label == href ||
            'http://$label' == href ||
            'https://$label' == href ||
            'mailto:$label' == href) {
          // A bare link reads back as the same link (GFM autolink).
          buffer.write(label);
        } else if (label.trim().isEmpty) {
          buffer.write('<${href.replaceAll('>', '%3E')}>');
        } else {
          buffer.write('[$label](${_linkTarget(href)})');
        }
      case 'img':
        // An address the editor would not show is dropped, whatever put it
        // in the surface.
        final src = CoreRichEditorImage.normalizeSource(
          node.attributes['src'] ?? '',
        );
        if (src != null) {
          buffer.write(
            CoreRichEditorImage.markdown(
              alt: _cleanText(node.attributes['alt'] ?? ''),
              url: src,
            ),
          );
        }
      case 'br':
        buffer.write('\\\n');
      case 'input':
        // A checkbox is the task marker, written by the list.
        break;
      default:
        // `<span>`, `<font>`, `<u>` and anything else a browser or a paste
        // leaves behind: the text, without the styling.
        _writeInline(node.children, buffer, openMarks: openMarks);
    }
  }
}

String _cleanText(String text) => text
    .replaceAll(_kCaretHolder, '')
    .replaceAll(' ', ' ')
    .replaceAll('\n', ' ');

/// Wraps [inner] in a mark, keeping its outer whitespace outside the
/// markers (`** x**` would not read as strong).
String _wrap(String inner, String open, String close) {
  final match = RegExp(r'^(\s*)(.*?)(\s*)$', dotAll: true).firstMatch(inner)!;
  final core = match.group(2)!;
  if (core.isEmpty) return inner;
  return '${match.group(1)}$open$core$close${match.group(3)}';
}

String _inlineCode(String text) {
  if (text.isEmpty) return '';
  final longest = RegExp('`+')
      .allMatches(text)
      .fold<int>(
        0,
        (max, match) =>
            match.group(0)!.length > max ? match.group(0)!.length : max,
      );
  final fence = '`' * (longest + 1);
  final padded = text.startsWith('`') || text.endsWith('`') ? ' $text ' : text;
  return '$fence$padded$fence';
}

String _linkTarget(String href) {
  final escaped = href.replaceAll('(', '%28').replaceAll(')', '%29');
  return escaped.contains(' ')
      ? '<${escaped.replaceAll('>', '%3E')}>'
      : escaped;
}

/// Backslash-escapes the characters that would start Markdown syntax
/// inside a line of [text].
String escapeRichEditorMarkdown(String text) {
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (_kInlineSpecials.contains(char)) {
      buffer.write(r'\');
    } else if (char == '&' &&
        RegExp(
          r'^&(#\d+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);',
        ).hasMatch(text.substring(i))) {
      buffer.write(r'\');
    }
    buffer.write(char);
  }
  return buffer.toString();
}

const Set<String> _kInlineSpecials = {
  r'\',
  '*',
  '_',
  '`',
  '~',
  '[',
  ']',
  '<',
};

/// Escapes what would turn a line's start into a block marker.
String _escapeLineStart(String line) {
  final heading = RegExp(r'^(\s*)(#{1,6})(\s|$)').firstMatch(line);
  if (heading != null) {
    return line.replaceFirst('#', r'\#');
  }
  if (RegExp(r'^\s*>').hasMatch(line)) return line.replaceFirst('>', r'\>');
  if (RegExp(r'^\s*[-+](\s|$)').hasMatch(line)) {
    return line.replaceFirstMapped(RegExp('[-+]'), (m) => '\\${m[0]}');
  }
  final ordered = RegExp(r'^(\s*\d{1,9})([.)])(\s|$)').firstMatch(line);
  if (ordered != null) {
    return '${ordered[1]}\\${line.substring(ordered[1]!.length)}';
  }
  if (RegExp(r'^\s*(-\s*){3,}$|^\s*(=+|-+)\s*$').hasMatch(line)) {
    return line.replaceFirstMapped(RegExp('[-=]'), (m) => '\\${m[0]}');
  }
  return line;
}

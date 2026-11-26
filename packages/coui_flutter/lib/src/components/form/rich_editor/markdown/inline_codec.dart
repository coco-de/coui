// Adapted from Wonky Work's `wonky_rich_editor` (BSD-3-Clause, Copyright 2026
// The Wonky Work authors) — see NOTICE.

/// Inline Markdown ⇄ super_editor [AttributedText]: bold, italic,
/// strikethrough, inline code and links, and nothing else.
library;

import 'package:collection/collection.dart';
import 'package:coui_core/coui_core.dart'
    show CoreRichEditorContract, CoreRichEditorImage;
import 'package:coui_flutter/src/components/form/rich_editor/markdown/block_syntax.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:markdown/markdown.dart' as md;
import 'package:super_editor/super_editor.dart';

/// GitHub-flavoured Markdown as the editor reads it: fenced code, tables
/// and task lists for blocks; strikethrough and bare URLs inline. Inline
/// HTML is parsed (so it can be recognised and kept literal), never
/// rendered.
final md.ExtensionSet richEditorGfm = md.ExtensionSet(
  const <md.BlockSyntax>[
    md.FencedCodeBlockSyntax(),
    md.TableSyntax(),
    md.UnorderedListWithCheckboxSyntax(),
    md.OrderedListWithCheckboxSyntax(),
  ],
  <md.InlineSyntax>[
    md.InlineHtmlSyntax(),
    md.StrikethroughSyntax(),
    md.AutolinkExtensionSyntax(),
  ],
);

/// A run of uniformly formatted inline text.
@immutable
class InlineRun {
  /// Creates an [InlineRun].
  const InlineRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.code = false,
    this.link,
  });

  /// The text of the run.
  final String text;

  /// Whether the run is bold.
  final bool bold;

  /// Whether the run is italic.
  final bool italic;

  /// Whether the run is struck through.
  final bool strike;

  /// Whether the run is inline code.
  final bool code;

  /// The link target, or null.
  final String? link;

  /// Whether [other] has the same formatting (text aside).
  bool sameStyle(InlineRun other) =>
      bold == other.bold &&
      italic == other.italic &&
      strike == other.strike &&
      code == other.code &&
      link == other.link;

  /// A copy with the given fields replaced.
  InlineRun copyWith({
    String? text,
    bool? bold,
    bool? italic,
    bool? strike,
    bool? code,
    String? link,
  }) => InlineRun(
    text ?? this.text,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    strike: strike ?? this.strike,
    code: code ?? this.code,
    link: link ?? this.link,
  );

  /// Joins neighbouring runs of the same style and drops empty ones.
  static List<InlineRun> merge(Iterable<InlineRun> runs) {
    final out = <InlineRun>[];
    for (final r in runs) {
      if (r.text.isEmpty) continue;
      if (out.isNotEmpty && out.last.sameStyle(r)) {
        out[out.length - 1] = r.copyWith(text: out.last.text + r.text);
      } else {
        out.add(r);
      }
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is InlineRun && other.text == text && sameStyle(other);

  @override
  int get hashCode => Object.hash(text, bold, italic, strike, code, link);

  @override
  String toString() {
    final marks = [
      if (bold) 'b',
      if (italic) 'i',
      if (strike) 's',
      if (code) 'c',
      if (link != null) 'link=$link',
    ];
    return 'InlineRun(${marks.join(',')} "$text")';
  }
}

/// Reads and writes the inline content of one block.
///
/// Line breaks inside a block are `"\n"` in the node text (Shift+Enter) and
/// separate Markdown lines; every line is written on its own.
class InlineMarkdownCodec {
  /// Creates a codec, optionally parsing with [document].
  InlineMarkdownCodec({md.Document? document})
    : _document = document ?? newDocument();

  /// A Markdown document for parsing inline content.
  static md.Document newDocument() => md.Document(extensionSet: richEditorGfm);

  final md.Document _document;

  /// Kept for the block codec: brackets are always escaped here, so a text
  /// with link reference definitions cannot turn them into links.
  bool bareBrackets = true;

  // ------------------------------------------------------------------ read

  /// Parses inline [lines] (one block's content, without its markers).
  /// Lines become `"\n"` in the text.
  ///
  /// Returns null when the content holds something the editor cannot
  /// represent (images, raw HTML, unsafe links …): the caller keeps the
  /// block as literal text.
  AttributedText? read(List<String> lines) {
    if (lines.isEmpty) return AttributedText();
    final runs = <InlineRun>[];
    for (final (i, line) in lines.indexed) {
      if (i > 0) runs.add(const InlineRun('\n'));
      final parsed = _read(line);
      if (parsed == null) return null;
      runs.addAll(parsed);
    }
    return runsToText(InlineRun.merge(runs));
  }

  /// The image [lines] hold when they are exactly one image and nothing
  /// else — `![alt](url)`, `![alt](<url> "title")` or a reference-style
  /// `![alt][ref]` — as its alternative text and address, or null.
  ///
  /// The title is not kept (the block's source keeps it). An address
  /// [CoreRichEditorImage.normalizeSource] refuses gives null too, so the
  /// block stays literal text and nothing unsafe is ever loaded.
  ({String alt, String url})? readImage(List<String> lines) {
    if (lines.length != 1) return null;
    final nodes = _document.parseInline(lines.single.trim());
    if (nodes.length != 1) return null;
    final node = nodes.single;
    if (node is! md.Element || node.tag != 'img') return null;
    final src = node.attributes['src'];
    if (src == null) return null;
    final url = CoreRichEditorImage.normalizeSource(decodeEntities(src));
    if (url == null) return null;
    return (alt: decodeEntities(node.attributes['alt'] ?? ''), url: url);
  }

  List<InlineRun>? _read(String line) {
    final out = <InlineRun>[];
    bool walk(List<md.Node> nodes, InlineRun style) {
      for (final node in nodes) {
        if (node is md.Text) {
          out.add(style.copyWith(text: decodeEntities(node.text)));
          continue;
        }
        if (node is! md.Element) return false;
        final children = node.children ?? const <md.Node>[];
        switch (node.tag) {
          case 'strong':
            if (!walk(children, style.copyWith(bold: true))) return false;
          case 'em':
            if (!walk(children, style.copyWith(italic: true))) return false;
          case 'del':
            if (!walk(children, style.copyWith(strike: true))) return false;
          case 'code':
            out.add(
              style.copyWith(
                text: decodeEntities(node.textContent),
                code: true,
              ),
            );
          case 'a':
            final href = node.attributes['href'];
            final target = href == null
                ? null
                : normalizeLinkTarget(decodeEntities(href));
            if (target == null ||
                style.link != null ||
                node.attributes.containsKey('title')) {
              return false;
            }
            if (!walk(children, style.copyWith(link: target))) return false;
          default:
            // Images, inline HTML, hard breaks and anything else stay
            // literal.
            return false;
        }
      }
      return true;
    }

    if (!walk(_document.parseInline(line), const InlineRun(''))) return null;
    return InlineRun.merge(out);
  }

  // ----------------------------------------------------------------- write

  /// The Markdown lines of [text] (one per `"\n"`-separated line).
  List<String> writeLines(AttributedText text, {bool heading = false}) {
    final lines = <List<InlineRun>>[[]];
    for (final r in textToRuns(text)) {
      final parts = r.text.split('\n');
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) lines.add([]);
        if (parts[i].isNotEmpty) lines.last.add(r.copyWith(text: parts[i]));
      }
    }
    return [for (final l in lines) writeLine(l, heading: heading)];
  }

  /// One line of inline Markdown for [runs] (no `"\n"` in them).
  ///
  /// What is written reads back as the same runs: when an emphasis cannot
  /// be written so that it does (CommonMark's flanking rules refuse
  /// `a**(b)**c`), that emphasis is dropped rather than the text garbled.
  /// [heading] is accepted for the block codec; headings escape the same
  /// way as other lines.
  String writeLine(List<InlineRun> runs, {bool heading = false}) {
    var current = _normalize(runs);
    while (true) {
      final out = _write(current);
      if (const ListEquality<InlineRun>().equals(_read(out), current)) {
        return out;
      }
      final styled = current.indexWhere((r) => r.bold || r.italic || r.strike);
      if (styled < 0) return out;
      current = InlineRun.merge([
        for (final (i, r) in current.indexed)
          if (i == styled)
            r.copyWith(bold: false, italic: false, strike: false)
          else
            r,
      ]);
    }
  }

  static String _write(List<InlineRun> runs) {
    final b = StringBuffer();
    final open = <String>[];
    String? openLink;

    void closeAll() {
      open.reversed.forEach(b.write);
      open.clear();
      final link = openLink;
      if (link != null) {
        b.write('](${_destination(link)})');
        openLink = null;
      }
    }

    for (final (i, r) in runs.indexed) {
      final want = [if (r.strike) '~~', if (r.bold) '**', if (r.italic) '*'];
      if (r.link != openLink) {
        closeAll();
        if (r.link != null) {
          b.write('[');
          openLink = r.link;
        }
      } else {
        // Close down to the longest prefix both runs share.
        var keep = 0;
        while (keep < open.length &&
            keep < want.length &&
            open[keep] == want[keep]) {
          keep++;
        }
        open.sublist(keep).reversed.forEach(b.write);
        open.removeRange(keep, open.length);
      }
      for (final m in want.sublist(open.length)) {
        b.write(m);
        open.add(m);
      }
      b.write(r.code ? _code(r.text) : _escape(r.text, lineStart: i == 0));
    }
    closeAll();
    return b.toString();
  }

  static final _special = RegExp(r'[\\`*_~\[\]<>&!|]');
  static final _blockLead = RegExp('^[-+=#>]');
  static final _orderedLead = RegExp(r'^(\d{1,9})([.)])');

  static String _escape(String text, {required bool lineStart}) {
    var out = text.replaceAllMapped(_special, (m) => '\\${m[0]}');
    if (!lineStart) return out;
    // What would start a block (`# `, `- `, `1. `, `> `, `---` …) at the
    // start of a line is escaped at its first character.
    if (startsBlock(out) || _blockLead.hasMatch(out)) out = '\\$out';
    final ordered = _orderedLead.firstMatch(out);
    if (ordered != null) {
      out = '${ordered[1]}\\${out.substring(ordered[1]!.length)}';
    }
    return out;
  }

  static String _code(String text) {
    var ticks = 1;
    while (text.contains('`' * ticks)) {
      ticks++;
    }
    final fence = '`' * ticks;
    final pad =
        text.startsWith('`') ||
            text.endsWith('`') ||
            (text.startsWith(' ') && text.endsWith(' ') && text.trim() != '')
        ? ' '
        : '';
    return '$fence$pad$text$pad$fence';
  }

  static String _destination(String url) => url.contains(RegExp(r'[\s()<>]'))
      ? '<${url.replaceAll('>', '%3E')}>'
      : url;

  /// Merged runs as the reader produces them: inline code carries no other
  /// style, links are normalised (or dropped), emphasis never starts or
  /// ends on a space, and the line is trimmed.
  static List<InlineRun> _normalize(List<InlineRun> runs) {
    final split = <InlineRun>[];
    for (final raw in runs) {
      final r = InlineRun(
        raw.text,
        bold: raw.bold && !raw.code,
        italic: raw.italic && !raw.code,
        strike: raw.strike && !raw.code,
        code: raw.code,
        link: raw.link == null ? null : normalizeLinkTarget(raw.link!),
      );
      if (r.code || !(r.bold || r.italic || r.strike) || r.text.isEmpty) {
        split.add(r);
        continue;
      }
      final core = r.text.trim();
      final bare = r.copyWith(bold: false, italic: false, strike: false);
      if (core.isEmpty) {
        split.add(bare);
        continue;
      }
      final start = r.text.indexOf(core);
      final lead = r.text.substring(0, start);
      final trail = r.text.substring(start + core.length);
      if (lead.isNotEmpty) split.add(bare.copyWith(text: lead));
      split.add(r.copyWith(text: core));
      if (trail.isNotEmpty) split.add(bare.copyWith(text: trail));
    }
    var merged = InlineRun.merge(split);
    while (merged.isNotEmpty && !merged.first.code) {
      final t = merged.first.text.trimLeft();
      if (t.isNotEmpty) {
        merged[0] = merged.first.copyWith(text: t);
        break;
      }
      merged = merged.sublist(1);
    }
    while (merged.isNotEmpty && !merged.last.code) {
      final t = merged.last.text.trimRight();
      if (t.isNotEmpty) {
        merged[merged.length - 1] = merged.last.copyWith(text: t);
        break;
      }
      merged = merged.sublist(0, merged.length - 1);
    }
    return merged;
  }

  // ------------------------------------------------- runs ⇄ attributed text

  /// The runs of [text] (bold, italic, strikethrough, code and links; other
  /// attributions are not Markdown and are dropped).
  static List<InlineRun> textToRuns(AttributedText text) {
    final plain = text.toPlainText();
    if (plain.isEmpty) return const [];
    final runs = <InlineRun>[];
    for (final span in text.computeAttributionSpans()) {
      final a = span.attributions;
      final link = a.whereType<LinkAttribution>().firstOrNull;
      runs.add(
        InlineRun(
          plain.substring(span.start, span.end + 1),
          bold: a.contains(boldAttribution),
          italic: a.contains(italicsAttribution),
          strike: a.contains(strikethroughAttribution),
          code: a.contains(codeAttribution),
          link: link?.plainTextUri,
        ),
      );
    }
    return InlineRun.merge(runs);
  }

  /// [runs] as attributed text.
  static AttributedText runsToText(List<InlineRun> runs) {
    final text = AttributedText(runs.map((r) => r.text).join());
    var at = 0;
    for (final r in runs) {
      final end = at + r.text.length;
      if (r.text.isNotEmpty) {
        final range = SpanRange(at, end - 1);
        if (r.bold) text.addAttribution(boldAttribution, range);
        if (r.italic) text.addAttribution(italicsAttribution, range);
        if (r.strike) text.addAttribution(strikethroughAttribution, range);
        if (r.code) text.addAttribution(codeAttribution, range);
        if (r.link != null) {
          text.addAttribution(LinkAttribution(r.link!), range);
        }
      }
      at = end;
    }
    return text;
  }
}

final _entity = RegExp(
  r'&(?:(amp|lt|gt|quot|apos|nbsp)|#(\d{1,7})|#[xX]([0-9A-Fa-f]{1,6}));',
);

/// Decodes the HTML escapes `package:markdown` produces with
/// `encodeHtml: true`, plus numeric references.
String decodeEntities(String s) {
  if (!s.contains('&')) return s;
  return s.replaceAllMapped(_entity, (m) {
    final named = m[1];
    if (named != null) {
      return const {
        'amp': '&',
        'lt': '<',
        'gt': '>',
        'quot': '"',
        'apos': "'",
        'nbsp': ' ',
      }[named]!;
    }
    final code = m[2] != null ? int.parse(m[2]!) : int.parse(m[3]!, radix: 16);
    return code <= 0x10FFFF ? String.fromCharCode(code) : m[0]!;
  });
}

/// The link target the codec writes for [url] — see
/// [CoreRichEditorContract.normalizeLink].
String? normalizeLinkTarget(String url) =>
    CoreRichEditorContract.normalizeLink(url);

/// Whether [url] may be stored as a link.
bool isSafeLink(String url) =>
    CoreRichEditorContract.normalizeLink(url) == url.trim();

// Adapted from Wonky Work's wonky_rich_editor (BSD-3-Clause, Copyright 2026
// The Wonky Work authors) — see NOTICE.

import 'dart:convert';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart' show CoreRichEditorImage;
import 'package:coui_flutter/src/components/form/rich_editor/markdown/block_syntax.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/inline_codec.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/markdown_features.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;

/// Converts CoUI's Markdown value to and from Quill's document model.
class MarkdownDocumentCodec {
  const MarkdownDocumentCodec({this.features = MarkdownBlockFeatures.all});

  final MarkdownBlockFeatures features;

  static const imageType = 'coui-image';
  static const ruleType = 'coui-rule';

  /// Quill reserves LF for block boundaries. A Unicode line separator
  /// retains soft breaks inside paragraphs, list items and literals.
  static const softBreak = '\u2028';

  static final _sources = Expando<_SourceBlock>();
  static final _ids = Expando<String>();
  static int _nextId = 0;

  static Iterable<quill.Line> lines(quill.Document document) sync* {
    for (final node in document.root.children) {
      if (node is quill.Line) yield node;
      if (node is quill.Block) yield* node.children.whereType<quill.Line>();
    }
  }

  static String createId() => 'coui-rich-editor-${++_nextId}';
  static String lineId(quill.Line line) => _ids[line] ??= createId();

  static Map<String, dynamic> image(String id, String url, String alt) => {
    imageType: jsonEncode({'id': id, 'url': url, 'alt': alt}),
  };

  static ({String id, String url, String alt})? imageData(Object? insert) {
    if (insert is! Map || insert[imageType] is! String) return null;
    final data =
        jsonDecode(insert[imageType] as String) as Map<String, dynamic>;
    return (
      id: data['id'] as String,
      url: data['url'] as String,
      alt: data['alt'] as String,
    );
  }

  static String kindOf(quill.Line line) => _readLine(line.toDelta()).kind;

  static bool isPlain(quill.Line line) => kindOf(line) == 'p';

  static int indentOf(quill.Line line) =>
      (line.toDelta().last.attributes?[quill.Attribute.indent.key] as int?) ??
      0;

  static Delta runDelta(Iterable<InlineRun> runs) {
    final delta = Delta();
    for (final run in runs) {
      if (run.text.isEmpty) continue;
      final style = <String, dynamic>{
        if (run.bold) quill.Attribute.bold.key: true,
        if (run.italic) quill.Attribute.italic.key: true,
        if (run.strike) quill.Attribute.strikeThrough.key: true,
        if (run.code) quill.Attribute.inlineCode.key: true,
        if (run.link != null) quill.Attribute.link.key: run.link,
      };
      delta.insert(
        run.text.replaceAll('\n', softBreak),
        style.isEmpty ? null : style,
      );
    }
    return delta;
  }

  quill.Document decode(String markdown) {
    final input = markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final inputLines = input.split('\n');
    final mdDoc = md.Document(extensionSet: richEditorGfm);
    final definitions = inputLines.where(linkDefinitionLine.hasMatch).toList();
    if (definitions.isNotEmpty) mdDoc.parseLines(definitions);
    final inline = InlineMarkdownCodec(document: mdDoc)
      ..bareBrackets = definitions.isEmpty;
    final scanned = _Scanner(inputLines, features).scan();
    final blocks = <_EditorBlock>[];
    final original = <String>[];
    final gaps = <String?>[];
    var previousEnd = 0;

    for (final block in scanned) {
      final source = inputLines.sublist(block.start, block.end).join('\n');
      blocks.add(_readBlock(block, inline, source));
      original.add(source);
      final between = inputLines.sublist(previousEnd, block.start);
      gaps.add(
        blocks.length == 1
            ? null
            : '\n${between.map((line) => '$line\n').join()}',
      );
      previousEnd = block.end;
    }
    if (blocks.isEmpty || blocks.last.embed != null) {
      blocks.add(const _EditorBlock('p'));
      original.add('');
      gaps.add(null);
    }

    final delta = Delta();
    for (final block in blocks) {
      final embed = block.embed;
      if (embed != null) delta.insert(embed);
      for (final operation in runDelta(block.runs).toList()) {
        delta.push(operation);
      }
      final attrs = <String, dynamic>{
        if (block.kind.startsWith('h') && block.kind != 'hr')
          quill.Attribute.header.key: int.parse(block.kind.substring(1)),
        if (block.kind == 'quote') quill.Attribute.blockQuote.key: true,
        if (block.kind == 'raw') quill.Attribute.codeBlock.key: true,
        if (_listKinds.contains(block.kind))
          quill.Attribute.list.key: switch (block.kind) {
            'ul' => 'bullet',
            'ol' => 'ordered',
            _ => block.checked ? 'checked' : 'unchecked',
          },
        if (block.indent != 0) quill.Attribute.indent.key: block.indent,
      };
      delta.insert('\n', attrs.isEmpty ? null : attrs);
    }

    final document = quill.Document.fromDelta(delta);
    final encoder = _Encoder(blocks);
    quill.Line? previous;
    for (final (index, line) in lines(document).indexed) {
      final block = blocks[index];
      _sources[line] = _SourceBlock(
        original[index],
        encoder.next(block),
        block.kind,
        gaps[index],
        previous == null ? null : lineId(previous),
      );
      previous = line;
    }
    return document;
  }

  /// Transfers exact source fragments after an external document replacement.
  void preserveSources(quill.Document from, quill.Document to) {
    final destination = lines(to).iterator;
    for (final origin in lines(from)) {
      if (!destination.moveNext()) return;
      final dest = destination.current;
      _ids[dest] = lineId(origin);
      final source = _sources[origin];
      if (source != null) _sources[dest] = source;
    }
  }

  String encode(quill.Document document, {int? start, int? end}) {
    final blocks = <(quill.Line, _EditorBlock, bool)>[];
    for (final line in lines(document)) {
      final offset = line.documentOffset;
      final lineEnd = offset + line.length - 1;
      if (end != null && offset >= end || start != null && lineEnd < start) {
        continue;
      }
      final from = math.max(0, (start ?? offset) - offset);
      final to = math.min(line.length - 1, (end ?? lineEnd) - offset);
      final whole = from == 0 && to == line.length - 1;
      final data = line.toDelta();
      blocks.add((
        line,
        whole
            ? _readLine(data)
            : _readLine(
                data.slice(from, to)..insert('\n', data.last.attributes),
              ),
        whole,
      ));
    }
    final encoder = _Encoder(blocks.map((entry) => entry.$2));
    final output = StringBuffer();
    quill.Line? previous;
    _EditorBlock? previousBlock;

    // Inside a single line the clipboard carries only the selected text.
    if (start != null && blocks.length == 1 && !blocks.single.$3) {
      final selected = blocks.single.$2;
      return selected.kind == 'raw'
          ? selected.text
          : encoder.inline.writeLines(selected.runs).join('\n');
    }

    for (final (line, block, whole) in blocks) {
      final canonical = encoder.next(block);
      if (canonical == null) continue;
      final source = whole ? _sources[line] : null;
      if (previous != null) {
        final keepsGap =
            source?.previousId == lineId(previous) &&
            source?.kind == block.kind &&
            _sources[previous]?.kind == previousBlock!.kind;
        output.write(
          keepsGap && source?.gap != null
              ? source!.gap
              : _defaultGap(previousBlock!.kind, block.kind),
        );
      }
      output.write(
        source?.canonical == canonical && source?.kind == block.kind
            ? source!.text
            : canonical,
      );
      previous = line;
      previousBlock = block;
    }
    return output.toString().trimRight();
  }

  static const _listKinds = {'ul', 'ol', 'task'};

  static String _defaultGap(String before, String after) {
    if (_listKinds.contains(before) && _listKinds.contains(after)) return '\n';
    if (before == 'quote' && after == 'quote') return '\n>\n';
    return '\n\n';
  }

  _EditorBlock _readBlock(
    _Block block,
    InlineMarkdownCodec inline,
    String original,
  ) {
    if (block.kind == _K.paragraph && features.images) {
      final found = inline.readImage(block.content);
      if (found != null) {
        return _EditorBlock(
          'img',
          embed: image(createId(), found.url, found.alt),
        );
      }
    }
    if (block.kind == _K.rule) {
      return const _EditorBlock('hr', embed: {ruleType: 'rule'});
    }
    final text = block.kind == _K.raw ? null : inline.read(block.content);
    if (text == null) return _EditorBlock('raw', runs: [InlineRun(original)]);
    final kind = switch (block.kind) {
      _K.paragraph => 'p',
      _K.heading => 'h${block.level}',
      _K.quote => 'quote',
      _K.bullet => 'ul',
      _K.ordered => 'ol',
      _K.task => 'task',
      _ => 'raw',
    };
    return _EditorBlock(
      kind,
      runs: text,
      indent: _listKinds.contains(kind) ? block.level : 0,
      checked: block.checked,
    );
  }

  static _EditorBlock _readLine(Delta data) {
    final lineEnd = data.last;
    final operations = data
        .slice(
          0,
          data.toList().fold<int>(0, (length, op) => length + op.length!) - 1,
        )
        .toList();
    final attrs = lineEnd.attributes ?? const <String, dynamic>{};
    final first = operations.firstOrNull?.data;
    if (first is Map) {
      if (first.containsKey(imageType)) {
        return _EditorBlock('img', embed: Map<String, dynamic>.from(first));
      }
      if (first.containsKey(ruleType)) {
        return const _EditorBlock('hr', embed: {ruleType: 'rule'});
      }
    }
    final list = attrs[quill.Attribute.list.key];
    final heading = attrs[quill.Attribute.header.key];
    final kind = switch (list) {
      'ordered' => 'ol',
      'bullet' => 'ul',
      'checked' || 'unchecked' => 'task',
      _ when attrs[quill.Attribute.codeBlock.key] == true => 'raw',
      _ when attrs[quill.Attribute.blockQuote.key] == true => 'quote',
      _ when heading is int => 'h$heading',
      _ => 'p',
    };
    return _EditorBlock(
      kind,
      runs: [
        for (final op in operations)
          if (op.data case final String text)
            InlineRun(
              text.replaceAll(softBreak, '\n'),
              bold: op.attributes?[quill.Attribute.bold.key] == true,
              italic: op.attributes?[quill.Attribute.italic.key] == true,
              strike: op.attributes?[quill.Attribute.strikeThrough.key] == true,
              code: op.attributes?[quill.Attribute.inlineCode.key] == true,
              link: op.attributes?[quill.Attribute.link.key] as String?,
            ),
      ],
      indent: attrs[quill.Attribute.indent.key] as int? ?? 0,
      checked: list == 'checked',
    );
  }
}

class _EditorBlock {
  const _EditorBlock(
    this.kind, {
    this.runs = const [],
    this.indent = 0,
    this.checked = false,
    this.embed,
  });

  final String kind;
  final List<InlineRun> runs;
  final int indent;
  final bool checked;
  final Map<String, dynamic>? embed;

  String get text => runs.map((run) => run.text).join();
}

class _SourceBlock {
  const _SourceBlock(
    this.text,
    this.canonical,
    this.kind,
    this.gap,
    this.previousId,
  );

  final String text;
  final String? canonical;
  final String kind;
  final String? gap;
  final String? previousId;
}

/// Writes one block at a time, accounting for list numbering and indentation.
class _Encoder {
  _Encoder(Iterable<_EditorBlock> blocks)
    : inline = InlineMarkdownCodec()
        ..bareBrackets = !blocks.any(
          (block) =>
              block.kind == 'raw' &&
              block.text.split('\n').any(linkDefinitionLine.hasMatch),
        );

  final InlineMarkdownCodec inline;
  final _columns = <int>[];
  final _numbers = <int>[];

  String? next(_EditorBlock block) {
    final kind = block.kind;
    if (MarkdownDocumentCodec._listKinds.contains(kind)) return _item(block);
    if (kind != 'raw') _columns.clear();
    _numbers.clear();
    switch (kind) {
      case 'hr':
        return '---';
      case 'img':
        final image = MarkdownDocumentCodec.imageData(block.embed)!;
        return CoreRichEditorImage.markdown(alt: image.alt, url: image.url);
      case 'raw':
        return block.text.trim().isEmpty ? null : block.text;
      case 'quote':
        final lines = inline.writeLines(block.runs);
        if (lines.every((line) => line.isEmpty)) return null;
        return [for (final line in lines) '> $line'.trimRight()].join('\n');
      case 'p':
        final text = inline.writeLines(block.runs).join('\n').trim();
        return text.isEmpty ? null : text;
    }
    final level = int.parse(kind.substring(1));
    final text = inline.writeLine(
      [
        for (final run in block.runs)
          run.copyWith(text: run.text.replaceAll('\n', ' ')),
      ],
      heading: true,
    );
    return text.isEmpty ? null : '${'#' * level} $text';
  }

  String _item(_EditorBlock block) {
    final level = math.min(block.indent, _columns.length);
    _columns.length = level;
    final pad = level == 0 ? 0 : _columns.last;
    final String marker;
    if (block.kind == 'task') {
      marker = block.checked ? '- [x] ' : '- [ ] ';
      _columns.add(pad + 2);
      _numbers.clear();
    } else {
      while (_numbers.length <= level) {
        _numbers.add(0);
      }
      _numbers.length = level + 1;
      if (block.kind == 'ol') {
        _numbers[level]++;
        marker = '${_numbers[level]}. ';
      } else {
        _numbers[level] = 0;
        marker = '- ';
      }
      _columns.add(pad + marker.length);
    }
    final lines = inline
        .writeLines(block.runs)
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return '${' ' * pad}$marker';
    final continuation = ' ' * _columns.last;
    return [
      '${' ' * pad}$marker${lines.first}',
      for (final line in lines.skip(1)) '$continuation$line',
    ].join('\n');
  }
}

// ------------------------------------------------------------------ scanning

enum _K { paragraph, heading, bullet, ordered, task, quote, raw, rule }

class _Block {
  _Block(
    this.kind,
    this.start,
    this.end, {
    this.level = 0,
    this.checked = false,
    this.content = const [],
  });

  final _K kind;

  /// Source lines `[start, end)`.
  final int start;
  final int end;

  /// Heading level, or list level (0 = top).
  final int level;
  final bool checked;

  /// Inline content lines.
  final List<String> content;
}

/// The line-based block scanner (see [startsBlock] for the patterns).
class _Scanner {
  _Scanner(this.lines, this.features);

  final List<String> lines;
  final MarkdownBlockFeatures features;

  /// Content columns of the open list items (CommonMark nesting: an item
  /// indented to at least its predecessor's content column is its child).
  final _stack = <int>[];

  bool _blank(int k) => lines[k].trim().isEmpty;

  static String _leading(String line) =>
      RegExp(r'^\s*').firstMatch(line)!.group(0)!;

  List<_Block> scan() {
    final out = <_Block>[];
    final n = lines.length;
    var i = 0;
    while (i < n) {
      final line = lines[i];
      if (_blank(i)) {
        i++;
        continue;
      }

      // Fenced code is kept literally, fences included: the editor has no
      // code blocks.
      final f = fenceOpen.firstMatch(line);
      if (f != null &&
          !(f.group(2)!.startsWith('`') && f.group(3)!.contains('`'))) {
        final fence = f.group(2)!;
        final close = RegExp(
          '^\\s*${RegExp.escape(fence[0])}{${fence.length},}\\s*\$',
        );
        var j = i + 1;
        while (j < n && !close.hasMatch(lines[j])) {
          j++;
        }
        final end = j < n ? j + 1 : n;
        _stack.clear();
        out.add(_Block(_K.raw, i, end));
        i = end;
        continue;
      }

      // Indented code, link reference definitions, tables and HTML are
      // kept literally.
      if (_stack.isEmpty && indentedCodeLine.hasMatch(line)) {
        var j = i + 1;
        while (j < n && (_blank(j) || indentedCodeLine.hasMatch(lines[j]))) {
          j++;
        }
        while (j > i + 1 && _blank(j - 1)) {
          j--;
        }
        out.add(_Block(_K.raw, i, j));
        i = j;
        continue;
      }
      if (linkDefinitionLine.hasMatch(line)) {
        var j = i + 1;
        while (j < n && linkDefinitionLine.hasMatch(lines[j])) {
          j++;
        }
        _stack.clear();
        out.add(_Block(_K.raw, i, j));
        i = j;
        continue;
      }
      if (tableLine.hasMatch(line)) {
        var j = i + 1;
        while (j < n && tableLine.hasMatch(lines[j])) {
          j++;
        }
        _stack.clear();
        out.add(_Block(_K.raw, i, j));
        i = j;
        continue;
      }
      if (htmlLine.hasMatch(line)) {
        var j = i + 1;
        while (j < n && !_blank(j)) {
          j++;
        }
        _stack.clear();
        out.add(_Block(_K.raw, i, j));
        i = j;
        continue;
      }

      final h = features.headings ? headingLine.firstMatch(line) : null;
      if (h != null) {
        var content = h.group(2)!;
        // A closing sequence (`## Title ##`) is not content.
        content = content.replaceFirst(RegExp(r'(^|[ \t]+)#+$'), '');
        _stack.clear();
        out.add(
          _Block(
            _K.heading,
            i,
            i + 1,
            level: h.group(1)!.length,
            content: [content.trim()],
          ),
        );
        i++;
        continue;
      }
      if (features.rules && ruleLine.hasMatch(line)) {
        _stack.clear();
        out.add(_Block(_K.rule, i, i + 1));
        i++;
        continue;
      }

      final item = _item(i);
      if (item != null) {
        out.add(item);
        i = item.end;
        continue;
      }

      if (features.quotes && quoteLine.hasMatch(line)) {
        var j = i;
        while (j < n && quoteLine.hasMatch(lines[j])) {
          j++;
        }
        _stack.clear();
        final inner = [
          for (var k = i; k < j; k++)
            lines[k].replaceFirst(RegExp(r'^\s*>\s?'), ''),
        ];
        // Blocks inside a quote are not supported: kept literally.
        if (inner.any((l) => l.trim().isNotEmpty && startsBlock(l))) {
          out.add(_Block(_K.raw, i, j));
        } else {
          // A blank `>` line separates the quote's paragraphs.
          var s = 0;
          for (var k = 0; k <= inner.length; k++) {
            if (k == inner.length || inner[k].trim().isEmpty) {
              if (k > s) {
                out.add(
                  _Block(
                    _K.quote,
                    i + s,
                    i + k,
                    content: [for (final l in inner.sublist(s, k)) l.trim()],
                  ),
                );
              }
              s = k + 1;
            }
          }
        }
        i = j;
        continue;
      }

      // A paragraph: lines up to a blank line or a line starting a block.
      var j = i;
      final content = <String>[];
      while (j < n && !_blank(j)) {
        if (j > i && _interrupts(lines[j])) break;
        content.add(lines[j].trim());
        j++;
      }
      _stack.clear();
      out.add(_Block(_K.paragraph, i, j, content: content));
      i = j;
    }
    return out;
  }

  bool _interrupts(String line) =>
      fenceOpen.hasMatch(line) ||
      (features.headings && headingLine.hasMatch(line)) ||
      (features.rules && ruleLine.hasMatch(line)) ||
      bulletLine.hasMatch(line) ||
      orderedLine.hasMatch(line) ||
      (features.quotes && quoteLine.hasMatch(line)) ||
      tableLine.hasMatch(line) ||
      htmlLine.hasMatch(line);

  /// A list item at line [i] (with its continuation lines), or null.
  _Block? _item(int i) {
    final line = lines[i];
    final b = bulletLine.firstMatch(line);
    final o = b == null ? orderedLine.firstMatch(line) : null;
    if (b == null && o == null) return null;
    final m = (b ?? o)!;
    final indent = indentWidth(m.group(1)!);
    final marker = b != null ? 1 : m.group(2)!.length + 1;
    final spaces = (b != null ? m.group(3) : m.group(4))!.length;
    final column = indent + marker + (spaces > 4 ? 1 : spaces);
    while (_stack.isNotEmpty && indent < _stack.last) {
      _stack.removeLast();
    }
    final level = math.min(_stack.length, 8);
    _stack.add(column);
    final rest = (b != null ? m.group(4) : m.group(5))!;
    var first = rest.trim();
    var kind = b != null ? _K.bullet : _K.ordered;
    var checked = false;
    if (b != null) {
      final t = taskBox.firstMatch(rest);
      if (t != null) {
        kind = _K.task;
        checked = t.group(1) != ' ';
        first = t.group(2)!.trim();
      }
    }
    // Continuation lines: indented to the content column, no blank line
    // before, not a block of their own.
    var j = i + 1;
    final content = [first];
    while (j < lines.length &&
        !_blank(j) &&
        indentWidth(_leading(lines[j])) >= column &&
        !startsBlock(lines[j])) {
      content.add(lines[j].trim());
      j++;
    }
    // A block inside an item (`- > quote`, `- # title`) is not supported.
    if (first.isNotEmpty && startsBlock(first)) {
      return _Block(_K.raw, i, j, level: level);
    }
    return _Block(kind, i, j, level: level, checked: checked, content: content);
  }
}

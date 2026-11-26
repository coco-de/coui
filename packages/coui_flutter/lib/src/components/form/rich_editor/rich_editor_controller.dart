// Adapted from Wonky Work's wonky_rich_editor (BSD-3-Clause, Copyright 2026
// The Wonky Work authors) — see NOTICE.

import 'dart:math' as math;

import 'package:coui_core/coui_core.dart' show CoreRichEditorImage;
import 'package:coui_flutter/src/components/form/rich_editor/markdown/inline_codec.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/markdown_document_codec.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/markdown_features.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';

/// Inline styles of the toolbar.
enum InlineFormat {
  /// Bold text.
  bold,

  /// Italic text.
  italic,

  /// Struck-through text.
  strikethrough,

  /// Inline code.
  code,
}

/// Block kinds of the toolbar.
enum BlockFormat {
  /// A plain paragraph.
  paragraph,

  /// A level-1 heading.
  heading1,

  /// A level-2 heading.
  heading2,

  /// A level-3 heading.
  heading3,

  /// A bulleted list item.
  bulletList,

  /// A numbered list item.
  numberedList,

  /// A checklist item.
  taskList,

  /// A quote.
  quote,
}

/// The editable Markdown value, selection, and formatting of a RichEditor.
///
/// Input and history are handled by the editor. The controller retains the
/// original Markdown until a document change and preserves the source of
/// untouched blocks when another block is edited.
class RichEditorController extends ChangeNotifier {
  RichEditorController({
    String markdown = '',
    MarkdownBlockFeatures features = MarkdownBlockFeatures.all,
  }) : _features = features,
       _source = markdown {
    editor = quill.QuillController(
      document: codec.decode(markdown),
      selection: const TextSelection.collapsed(offset: 0),
      keepStyleOnNewLine: false,
      onReplaceText: _handleAllowInput,
      onSelectionChanged: (_) => _hasSelection = true,
    )..addListener(_editorChanged);
    _observed = document.toDelta();
  }

  late final quill.QuillController editor;
  quill.Document get document => editor.document;

  MarkdownBlockFeatures _features;
  MarkdownBlockFeatures get features => _features;
  set features(MarkdownBlockFeatures value) {
    if (value == _features) return;
    final before = markdown;
    _features = value;
    _replace(before);
  }

  MarkdownDocumentCodec get codec => MarkdownDocumentCodec(features: _features);

  bool get readOnly => editor.readOnly;
  set readOnly(bool value) => editor.readOnly = value;
  int? maxLength;

  String _source;
  String? _cache;
  bool _edited = false;
  bool _hasSelection = false;
  bool _updating = false;
  bool _nativeInput = false;
  late Delta _observed;
  int _replacements = 0;

  /// Counts external values, independently of edits and undo.
  int get replacements => _replacements;

  String get markdown =>
      _edited ? (_cache ??= codec.encode(document)) : _source;
  set markdown(String value) {
    if (value != markdown) _replace(value);
  }

  int get length => markdown.length;
  bool get isEmpty => markdown.trim().isEmpty;

  void _replace(String value) {
    final parsed = codec.decode(value);
    final next = parsed.toDelta();
    _updating = true;
    try {
      _replacements++;
      _apply(
        _observed.diff(next),
        TextSelection.collapsed(offset: parsed.length - 1),
      );
      codec.preserveSources(parsed, document);
      _source = value;
      _cache = null;
      _edited = false;
    } finally {
      parsed.close();
      _updating = false;
    }
    notifyListeners();
  }

  bool _handleAllowInput(int index, int removed, Object? inserted) {
    if (readOnly) return false;
    if (inserted is String && inserted.isNotEmpty) {
      final limit = maxLength;
      if (limit != null && length >= limit && removed == 0) return false;
      _nativeInput = true;
    }
    return true;
  }

  void _editorChanged() {
    final updated = document.toDelta();
    final changed = updated != _observed;
    _observed = updated;
    if (changed) {
      _edited = true;
      _cache = null;
    }
    final autoformat = changed && _nativeInput && !_updating;
    _nativeInput = false;
    if (_updating) return;
    if (autoformat && _autoformat()) return;
    notifyListeners();
  }

  void _apply(Delta change, TextSelection selected) {
    _hasSelection = true;
    change.trim();
    if (change.isNotEmpty) {
      // Toolbar, clipboard, and embed operations each get a history step.
      document.history.lastRecorded = 0;
      document.compose(change, quill.ChangeSource.local);
      document.history.lastRecorded = 0;
    }
    final last = document.length - 1;
    editor.updateSelection(
      selected.copyWith(
        baseOffset: selected.baseOffset.clamp(0, last),
        extentOffset: selected.extentOffset.clamp(0, last),
      ),
      quill.ChangeSource.local,
    );
  }

  bool get canUndo => editor.hasUndo;
  bool get canRedo => editor.hasRedo;
  void undo() {
    if (!readOnly) editor.undo();
  }

  void redo() {
    if (!readOnly) editor.redo();
  }

  TextSelection? get selection => _hasSelection ? editor.selection : null;

  void setSelection(TextSelection value) {
    final last = document.length - 1;
    _apply(
      Delta(),
      value.copyWith(
        baseOffset: value.baseOffset.clamp(0, last),
        extentOffset: value.extentOffset.clamp(0, last),
      ),
    );
  }

  void moveCaretToEnd() =>
      setSelection(TextSelection.collapsed(offset: document.length - 1));
  void selectAll() => setSelection(
    TextSelection(baseOffset: 0, extentOffset: document.length - 1),
  );

  quill.Line? _lineAt(int offset) =>
      document.queryChild(offset).node as quill.Line?;
  quill.Line? get _caretLine {
    final current = selection;
    return current == null ? null : _lineAt(current.extentOffset);
  }

  String? get selectedLineId {
    final line = _caretLine;
    return line == null ? null : MarkdownDocumentCodec.lineId(line);
  }

  Iterable<quill.Line> get _selectedLines sync* {
    final selected = selection;
    if (selected == null) return;
    if (selected.isCollapsed) {
      final line = _caretLine;
      if (line != null) yield line;
      return;
    }
    for (final line in MarkdownDocumentCodec.lines(document)) {
      final start = line.documentOffset;
      if (start >= selected.end) break;
      if (start + line.length > selected.start) yield line;
    }
  }

  bool get inLiteralBlock {
    final line = _caretLine;
    return line != null && MarkdownDocumentCodec.kindOf(line) == 'raw';
  }

  bool get hasSelectedText {
    final selected = selection;
    if (selected == null || selected.isCollapsed) return false;
    return _selectedLines.any(
      (line) =>
          !line.hasEmbed &&
          math.min(selected.end, line.documentOffset + line.length - 1) >
              math.max(selected.start, line.documentOffset),
    );
  }

  static quill.Attribute<bool> _attribute(InlineFormat format) =>
      switch (format) {
        InlineFormat.bold => quill.Attribute.bold,
        InlineFormat.italic => quill.Attribute.italic,
        InlineFormat.strikethrough => quill.Attribute.strikeThrough,
        InlineFormat.code => quill.Attribute.inlineCode,
      };

  bool get canFormatInline =>
      !readOnly &&
      _selectedLines.any(
        (line) => !line.hasEmbed && MarkdownDocumentCodec.kindOf(line) != 'raw',
      );

  Iterable<({int start, int end, Map<String, dynamic> attrs})> _inlineRanges(
    TextSelection selected, {
    bool excludeCode = false,
  }) sync* {
    for (final line in _selectedLines) {
      if (line.hasEmbed || MarkdownDocumentCodec.kindOf(line) == 'raw') {
        continue;
      }
      var cursor = line.documentOffset;
      final limit = cursor + line.length - 1;
      for (final op in line.toDelta().toList()) {
        final end = cursor + op.length!;
        final start = math.max(selected.start, cursor);
        final last = math.min(math.min(selected.end, end), limit);
        final attributes = op.attributes ?? const <String, dynamic>{};
        if (last > start &&
            (!excludeCode ||
                attributes[quill.Attribute.inlineCode.key] != true)) {
          yield (start: start, end: last, attrs: attributes);
        }
        cursor = end;
      }
    }
  }

  bool isActive(InlineFormat format) {
    final current = selection;
    if (current == null) return false;
    final attribute = _attribute(format).key;
    if (current.isCollapsed) {
      return editor.getSelectionStyle().attributes[attribute]?.value == true;
    }
    final ranges = _inlineRanges(
      current,
      excludeCode: format != InlineFormat.code,
    ).toList();
    return ranges.isNotEmpty &&
        ranges.every((run) => run.attrs[attribute] == true);
  }

  void toggleInline(InlineFormat format) {
    if (!canFormatInline) return;
    final current = selection!;
    final attribute = _attribute(format);
    final remove = isActive(format);
    final key = attribute.key;
    if (current.isCollapsed) {
      var style = editor.toggledStyle.put(
        quill.Attribute<bool?>(key, attribute.scope, remove ? null : true),
      );
      if (format == InlineFormat.code && !remove) {
        for (final other in [
          quill.Attribute.bold,
          quill.Attribute.italic,
          quill.Attribute.strikeThrough,
        ]) {
          style = style.put(
            quill.Attribute<bool?>(other.key, other.scope, null),
          );
        }
      }
      editor.forceToggledStyle(style);
      return;
    }
    final diff = Delta();
    var end = 0;
    for (final range in _inlineRanges(
      current,
      excludeCode: format != InlineFormat.code,
    )) {
      diff.retain(range.start - end);
      diff.retain(range.end - range.start, {
        key: remove ? null : true,
        if (format == InlineFormat.code && !remove) ...{
          quill.Attribute.bold.key: null,
          quill.Attribute.italic.key: null,
          quill.Attribute.strikeThrough.key: null,
        },
      });
      end = range.end;
    }
    _apply(diff, current);
  }

  BlockFormat? get blockFormat {
    final line = _caretLine;
    return line == null ? null : _formatOf(line);
  }

  static BlockFormat? _formatOf(quill.Line line) =>
      switch (MarkdownDocumentCodec.kindOf(line)) {
        'p' => BlockFormat.paragraph,
        'h1' => BlockFormat.heading1,
        'h2' => BlockFormat.heading2,
        'h3' || 'h4' || 'h5' || 'h6' => BlockFormat.heading3,
        'ul' => BlockFormat.bulletList,
        'ol' => BlockFormat.numberedList,
        'task' => BlockFormat.taskList,
        'quote' => BlockFormat.quote,
        _ => null,
      };

  bool canFormatBlock(BlockFormat format) {
    if (readOnly || selection == null) return false;
    return switch (format) {
      BlockFormat.heading1 ||
      BlockFormat.heading2 ||
      BlockFormat.heading3 => _features.headings,
      BlockFormat.quote => _features.quotes,
      _ => true,
    };
  }

  static bool _isList(BlockFormat? format) =>
      format == BlockFormat.bulletList ||
      format == BlockFormat.numberedList ||
      format == BlockFormat.taskList;

  static Map<String, dynamic> _blockAttributes(
    BlockFormat format, {
    int indent = 0,
  }) => {
    quill.Attribute.header.key: switch (format) {
      BlockFormat.heading1 => 1,
      BlockFormat.heading2 => 2,
      BlockFormat.heading3 => 3,
      _ => null,
    },
    quill.Attribute.list.key: switch (format) {
      BlockFormat.bulletList => 'bullet',
      BlockFormat.numberedList => 'ordered',
      BlockFormat.taskList => 'unchecked',
      _ => null,
    },
    quill.Attribute.indent.key: _isList(format) && indent > 0 ? indent : null,
    quill.Attribute.blockQuote.key: format == BlockFormat.quote ? true : null,
  };

  void toggleBlock(BlockFormat format) {
    if (!canFormatBlock(format)) return;
    final lines = _selectedLines
        .where((line) => _formatOf(line) != null)
        .toList();
    if (lines.isEmpty) return;
    final target = lines.every((line) => _formatOf(line) == format)
        ? BlockFormat.paragraph
        : format;
    final diff = Delta();
    var end = 0;
    for (final line in lines) {
      final at = line.documentOffset + line.length - 1;
      diff.retain(at - end);
      diff.retain(
        1,
        _blockAttributes(target, indent: MarkdownDocumentCodec.indentOf(line)),
      );
      end = at + 1;
    }
    _apply(diff, selection!);
  }

  bool indentItems({bool outdent = false}) {
    if (readOnly) return false;
    final items = _selectedLines
        .where((line) => _isList(_formatOf(line)))
        .toList();
    if (items.isEmpty) return false;
    final diff = Delta();
    var end = 0;
    for (final line in items) {
      final indent = MarkdownDocumentCodec.indentOf(line);
      final previous = line.documentOffset > 0
          ? _lineAt(line.documentOffset - 1)
          : null;
      final maxIndent = previous == null || !_isList(_formatOf(previous))
          ? 0
          : MarkdownDocumentCodec.indentOf(previous) + 1;
      final updated = outdent
          ? math.max(0, indent - 1)
          : math.min(indent + 1, maxIndent);
      if (updated == indent) continue;
      final at = line.documentOffset + line.length - 1;
      diff.retain(at - end);
      diff.retain(1, {
        quill.Attribute.indent.key: updated == 0 ? null : updated,
      });
      end = at + 1;
    }
    _apply(diff, selection!);
    return true;
  }

  ({int start, int end, String url})? _linkAt(int offset) {
    final line = _lineAt(offset);
    if (line == null) return null;
    final key = quill.Attribute.link.key;
    var start = line.documentOffset;
    final links = <({int start, int end, String url})>[];
    for (final op in line.toDelta().toList()) {
      final end = start + op.length!;
      final url = op.attributes?[key];
      if (url is String) {
        final last = links.lastOrNull;
        if (last != null && last.url == url && last.end == start) {
          links[links.length - 1] = (start: last.start, end: end, url: url);
        } else {
          links.add((start: start, end: end, url: url));
        }
      }
      start = end;
    }
    return links
        .where((link) => link.start <= offset && offset <= link.end)
        .firstOrNull;
  }

  String? get link {
    final current = selection;
    return current == null ? null : _linkAt(current.start)?.url;
  }

  bool get canLink => canFormatInline;

  void setLink(String? url) {
    if (!canLink) return;
    final target = url == null ? null : normalizeLinkTarget(url);
    if (url != null && target == null) return;
    final current = selection!;
    var start = current.start;
    var end = current.end;
    final key = quill.Attribute.link.key;
    if (current.isCollapsed) {
      final existing = _linkAt(start);
      if (existing != null) {
        start = existing.start;
        end = existing.end;
      } else {
        if (target == null) return;
        final label = url!.trim();
        final change = Delta()
          ..retain(start)
          ..insert(label, {key: target});
        _apply(change, TextSelection.collapsed(offset: start + label.length));
        return;
      }
    }
    final diff = Delta();
    var last = 0;
    for (final range in _inlineRanges(
      TextSelection(baseOffset: start, extentOffset: end),
    )) {
      diff.retain(range.start - last);
      diff.retain(range.end - range.start, {key: target});
      last = range.end;
    }
    _apply(diff, current);
  }

  Set<String> get imageUrls => {
    for (final op in document.toDelta().toList())
      if (MarkdownDocumentCodec.imageData(op.data) case final image?) image.url,
  };

  int get embedCount => MarkdownDocumentCodec.lines(
    document,
  ).where((line) => line.hasEmbed).length;

  String? insertImage({
    required String url,
    String alt = '',
    String? afterNodeId,
  }) {
    if (readOnly) return null;
    final source = CoreRichEditorImage.normalizeSource(url);
    if (source == null) return null;
    final lines = MarkdownDocumentCodec.lines(document).toList();
    final index = afterNodeId == null
        ? -1
        : lines.indexWhere(
            (line) => MarkdownDocumentCodec.lineId(line) == afterNodeId,
          );
    final anchor = index < 0 ? lines.last : lines[index];
    final follower = index >= 0 && index < lines.length - 1
        ? lines[index + 1]
        : null;
    final id = MarkdownDocumentCodec.createId();
    final image = MarkdownDocumentCodec.image(id, source, alt);
    final emptyAnchor =
        anchor.length == 1 && MarkdownDocumentCodec.isPlain(anchor);
    final emptyFollower =
        follower != null &&
        follower.length == 1 &&
        MarkdownDocumentCodec.isPlain(follower);
    final diff = Delta();
    final int cursor;
    if (emptyAnchor) {
      final at = anchor.documentOffset;
      diff.retain(at);
      diff.insert(image);
      diff.insert('\n');
      if (emptyFollower) diff.delete(1);
      cursor = at + 2;
    } else if (follower != null) {
      final at = follower.documentOffset;
      diff.retain(at);
      diff.insert(image);
      diff.insert(emptyFollower ? '\n' : '\n\n');
      cursor = at + 2;
    } else {
      final at = anchor.documentOffset + anchor.length - 1;
      diff.retain(at);
      diff.insert('\n', anchor.toDelta().last.attributes);
      diff.insert(image);
      diff.insert('\n');
      final oldStyle = anchor.toDelta().last.attributes;
      if (oldStyle != null) {
        diff.retain(1, {for (final key in oldStyle.keys) key: null});
      }
      cursor = at + 3;
    }
    _apply(diff, TextSelection.collapsed(offset: cursor));
    return id;
  }

  String? get selectedMarkdown {
    final current = selection;
    if (current == null || current.isCollapsed) return null;
    final value = codec.encode(
      document,
      start: current.start,
      end: current.end,
    );
    return value.isEmpty ? null : value;
  }

  bool deleteSelection() {
    final current = selection;
    if (readOnly || current == null || current.isCollapsed) return false;
    editor.replaceText(
      current.start,
      current.end - current.start,
      '',
      TextSelection.collapsed(offset: current.start),
    );
    return true;
  }

  bool replaceText(String nodeId, int start, int end, String replacement) {
    if (readOnly) return false;
    final line = MarkdownDocumentCodec.lines(
      document,
    ).where((line) => MarkdownDocumentCodec.lineId(line) == nodeId).firstOrNull;
    if (line == null ||
        line.hasEmbed ||
        start < 0 ||
        start > end ||
        end >= line.length) {
      return false;
    }
    final offset = line.documentOffset + start;
    final style = document.collectStyle(offset, 1).toJson();
    final change = Delta()..retain(offset);
    if (replacement.isNotEmpty) {
      change.insert(
        replacement.replaceAll('\n', MarkdownDocumentCodec.softBreak),
        {
          for (final entry in (style ?? const <String, dynamic>{}).entries)
            if (quill.Attribute.inlineKeys.contains(entry.key))
              entry.key: entry.value,
        },
      );
    }
    if (end > start) change.delete(end - start);
    _apply(
      change,
      TextSelection.collapsed(offset: offset + replacement.length),
    );
    return true;
  }

  bool paste(String text, {bool plain = false}) {
    final current = selection;
    if (readOnly || current == null || text.isEmpty) return false;
    final max = maxLength;
    if (max != null && length + text.length > max) return false;
    final url = text.trim();
    if (!plain &&
        !current.isCollapsed &&
        !url.contains(RegExp(r'\s')) &&
        isSafeLink(url)) {
      setLink(url);
      return true;
    }
    if (plain || inLiteralBlock) {
      final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final value = inLiteralBlock
          ? normalized.replaceAll('\n', MarkdownDocumentCodec.softBreak)
          : normalized
                .split(RegExp(r'\n\s*\n'))
                .where((paragraph) => paragraph.trim().isNotEmpty)
                .map(
                  (paragraph) => paragraph.replaceAll(
                    '\n',
                    MarkdownDocumentCodec.softBreak,
                  ),
                )
                .join('\n');
      if (value.isEmpty) return false;
      final change = Delta()
        ..retain(current.start)
        ..insert(value)
        ..delete(current.end - current.start);
      _apply(
        change,
        TextSelection.collapsed(offset: current.start + value.length),
      );
      return true;
    }

    final fragment = codec.decode(text);
    try {
      final lines = MarkdownDocumentCodec.lines(fragment);
      final structured =
          lines.length > 1 || !MarkdownDocumentCodec.isPlain(lines.first);
      if (!structured) {
        final data = fragment.toDelta().slice(0, fragment.length - 1);
        final change = Delta()..retain(current.start);
        for (final op in data.toList()) {
          change.push(op);
        }
        change.delete(current.end - current.start);
        _apply(
          change,
          TextSelection.collapsed(offset: current.start + fragment.length - 1),
        );
        return true;
      }
      final at = current.start;
      final line = _lineAt(at)!;
      final preceding = at > line.documentOffset;
      final change = Delta()..retain(at);
      if (preceding) change.insert('\n', line.toDelta().last.attributes);
      final fragmentData = fragment.toDelta();
      final last = lines.last;
      final trailing = last.length == 1 && MarkdownDocumentCodec.isPlain(last);
      final fragmentLength = fragment.length - (trailing ? 1 : 0);
      for (final op in fragmentData.slice(0, fragmentLength).toList()) {
        change.push(op);
      }
      change.delete(current.end - current.start);
      _apply(
        change,
        TextSelection.collapsed(
          offset: at + fragmentLength + (preceding ? 1 : 0),
        ),
      );
      return true;
    } finally {
      fragment.close();
    }
  }

  /// Inserts a soft line break or a tab in a literal block.
  bool insertLiteral(String text) {
    final current = selection;
    if (readOnly || current == null) return false;
    final change = Delta()
      ..retain(current.start)
      ..insert(text)
      ..delete(current.end - current.start);
    _apply(
      change,
      TextSelection.collapsed(offset: current.start + text.length),
    );
    return true;
  }

  bool insertRule() {
    final current = selection;
    final line = _caretLine;
    if (!features.rules ||
        readOnly ||
        current == null ||
        !current.isCollapsed ||
        line == null ||
        !MarkdownDocumentCodec.isPlain(line) ||
        current.start != line.documentOffset + line.length - 1) {
      return false;
    }
    if (!_rulePrefix.hasMatch(line.toPlainText().trimRight())) return false;
    _replaceWithRule(line);
    return true;
  }

  void _replaceWithRule(quill.Line line) {
    final start = line.documentOffset;
    final change = Delta()
      ..retain(start)
      ..insert({MarkdownDocumentCodec.ruleType: 'rule'})
      ..insert('\n')
      ..delete(line.length - 1);
    _apply(change, TextSelection.collapsed(offset: start + 2));
  }

  bool _autoformat() {
    final current = selection;
    final line = _caretLine;
    if (current == null ||
        !current.isCollapsed ||
        line == null ||
        line.hasEmbed ||
        inLiteralBlock) {
      return false;
    }
    final position = current.start - line.documentOffset;
    if (position <= 0) return false;
    final prefix = line.toPlainText().substring(0, position);
    final paragraph = MarkdownDocumentCodec.isPlain(line);
    if (paragraph &&
        features.rules &&
        position == line.length - 1 &&
        prefix.endsWith(' ') &&
        _rulePrefix.hasMatch(prefix.trimRight())) {
      _replaceWithRule(line);
      return true;
    }
    final attributes = _prefixAttributes(prefix, line, paragraph: paragraph);
    if (attributes != null) {
      final start = line.documentOffset;
      final change = Delta()
        ..retain(start)
        ..delete(position)
        ..retain(line.length - position - 1)
        ..retain(1, attributes);
      _apply(change, TextSelection.collapsed(offset: start));
      return true;
    }
    final lineStart = prefix.lastIndexOf(MarkdownDocumentCodec.softBreak) + 1;
    final candidate = _inlineSuffix.firstMatch(prefix.substring(lineStart));
    if (candidate == null) return false;
    final relativeStart = lineStart + candidate.start;
    final start = line.documentOffset + relativeStart;
    final previous = relativeStart == 0 ? null : prefix[relativeStart - 1];
    if (previous == candidate.group(0)![0] ||
        document
                .collectStyle(start, 1)
                .attributes[quill.Attribute.inlineCode.key]
                ?.value ==
            true) {
      return false;
    }
    final source = candidate.group(0)!;
    final runs = InlineMarkdownCodec().read([source]);
    if (runs == null ||
        runs.every(
          (run) =>
              !run.bold &&
              !run.italic &&
              !run.strike &&
              !run.code &&
              run.link == null,
        )) {
      return false;
    }
    final change = Delta()..retain(start);
    for (final op in MarkdownDocumentCodec.runDelta(runs).toList()) {
      change.push(op);
    }
    change.delete(source.length);
    final end =
        start + runs.fold<int>(0, (length, run) => length + run.text.length);
    _apply(change, TextSelection.collapsed(offset: end));
    return true;
  }

  static final _inlineSuffix = RegExp(
    r'(?:\*\*[^*\n]+\*\*|__[^_\n]+__|\*[^*\n]+\*|_[^_\n]+_|~~[^~\n]+~~|`[^`\n]+`|\[[^\]\n]+\]\([^)\n]+\))$',
  );

  static final _headingPrefix = RegExp(r'^(#{1,6}) $');
  static final _orderedPrefix = RegExp(r'^\d{1,9}[.)] $');
  static final _taskPrefix = RegExp(r'^(- )?\[( |x|X)?\] $');
  static final _rulePrefix = RegExp(r'^(---|\*\*\*|___)$');

  Map<String, dynamic>? _prefixAttributes(
    String prefix,
    quill.Line line, {
    required bool paragraph,
  }) {
    final list = _isList(_formatOf(line));
    final heading = _headingPrefix.firstMatch(prefix);
    if (features.headings && (paragraph || list) && heading != null) {
      return _blockAttributes(BlockFormat.paragraph)
        ..[quill.Attribute.header.key] = heading.group(1)!.length;
    }

    final task = _taskPrefix.firstMatch(prefix);
    if ((paragraph || list) && task != null) {
      return _blockAttributes(
          BlockFormat.taskList,
          indent: MarkdownDocumentCodec.indentOf(line),
        )
        ..[quill.Attribute.list.key] = task.group(2)?.toLowerCase() == 'x'
            ? 'checked'
            : 'unchecked';
    }
    if (!paragraph) return null;

    final format = switch (prefix) {
      '- ' || '* ' || '+ ' => BlockFormat.bulletList,
      '> ' when features.quotes => BlockFormat.quote,
      _ when _orderedPrefix.hasMatch(prefix) => BlockFormat.numberedList,
      _ => null,
    };
    return format == null ? null : _blockAttributes(format);
  }

  @override
  void dispose() {
    editor.removeListener(_editorChanged);
    editor.dispose();
    super.dispose();
  }
}

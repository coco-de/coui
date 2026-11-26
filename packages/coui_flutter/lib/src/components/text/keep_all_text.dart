/// How the `.keepAll` chain redraws the `Text` it wraps — the Flutter
/// transport of CSS `word-break: keep-all`.
///
/// Flutter's line breaker has no keep-all mode, so the wrapped `Text` is
/// drawn from [CoreKeepAll]'s display string instead: the same text with a
/// U+2060 WORD JOINER at every break opportunity keep-all removes. The
/// joiners are a drawing detail only — the original string stays what is
/// announced (`semanticsLabel`) and, under a selection area, what is
/// copied.
///
/// Package-internal: not exported from the barrel.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:collection/collection.dart' show lowerBound;
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart'
    show SelectedContent, SelectedContentRange;

/// [child] as keep-all draws it.
///
/// Only an exact `Text` is redrawn — its `data`, or every `TextSpan` text
/// of `Text.rich`. A `Text` subclass keeps its own build, and any other
/// widget (`SelectableText`, an editable field, a layout of several
/// texts) passes through unchanged: an editable or selectable string must
/// not gain characters its user did not type.
Widget keepAllContent(BuildContext context, Widget child) {
  if (child is! Text || child.runtimeType != Text) return child;

  final drawing = _KeepAllDrawing.of(child);
  if (drawing == null) return child;

  // Under a selection area the joiners would reach the clipboard; the
  // container below maps the selection back to the original string.
  if (SelectionContainer.maybeOf(context) == null) return drawing.text;

  return _KeepAllSelection(drawing: drawing);
}

/// The `Text` keep-all draws, and where its display string differs from
/// the original.
@immutable
class _KeepAllDrawing {
  const _KeepAllDrawing({
    required this.text,
    required this.joinerIndices,
    required this.displayLength,
  });

  /// The redrawn `Text`.
  final Text text;

  /// Indices in the display string that hold an inserted joiner,
  /// ascending.
  final List<int> joinerIndices;

  /// Length of the display string — the paragraph's whole selectable
  /// content when only text is inside it.
  final int displayLength;

  /// The drawing for [text], or `null` when keep-all changes nothing.
  static _KeepAllDrawing? of(Text text) {
    final data = text.data;
    if (data != null) return _plain(text, data);

    final span = text.textSpan;

    return span == null ? null : _rich(text, span);
  }

  static _KeepAllDrawing? _plain(Text text, String data) {
    final offsets = CoreKeepAll.joinOffsets(data);
    if (offsets.isEmpty) return null;
    final joinerIndices = _displayIndices(offsets);

    return _KeepAllDrawing(
      text: _redraw(
        text,
        textSpan: _KeepAllTextSpan(
          text: CoreKeepAll.joinAt(data, offsets),
          joinerIndices: joinerIndices,
        ),
        semanticsLabel: text.semanticsLabel ?? data,
      ),
      joinerIndices: joinerIndices,
      displayLength: data.length + offsets.length,
    );
  }

  /// A rich text is joined as one string — a word split across two spans
  /// (a bolded syllable) still holds together — and each joiner lands in
  /// the span holding the letter before it. A span whose text changed
  /// announces its original text; the other spans are untouched.
  static _KeepAllDrawing? _rich(Text text, InlineSpan root) {
    final source = StringBuffer();
    final pieces = <(int, int)>[];
    _flatten(root, source, pieces);

    final flat = source.toString();
    final offsets = CoreKeepAll.joinOffsets(flat);
    if (offsets.isEmpty) return null;

    final localOffsets = [for (final _ in pieces) <int>[]];
    var piece = 0;
    for (final offset in offsets) {
      // The piece holding the letter before the joiner: start < offset <=
      // end. Pieces and offsets both ascend, so the scan only moves on.
      while (piece < pieces.length &&
          !(pieces[piece].$1 < offset && offset <= pieces[piece].$2)) {
        piece += 1;
      }
      if (piece == pieces.length) break;
      localOffsets[piece].add(offset - pieces[piece].$1);
    }

    var visited = 0;
    InlineSpan rebuild(InlineSpan span) {
      if (span.runtimeType != TextSpan) return span;
      final textSpan = span as TextSpan;
      final local = localOffsets[visited];
      visited += 1;

      final children = textSpan.children;
      final rebuiltChildren = children?.map(rebuild).toList();
      final childrenChanged =
          rebuiltChildren != null &&
          !rebuiltChildren.indexed.every(
            (entry) => identical(entry.$2, children![entry.$1]),
          );
      if (local.isEmpty && !childrenChanged) return textSpan;

      final spanText = textSpan.text;

      return _KeepAllTextSpan(
        joinerIndices: _displayIndices(local),
        text: local.isEmpty || spanText == null
            ? spanText
            : CoreKeepAll.joinAt(spanText, local),
        children: rebuiltChildren,
        style: textSpan.style,
        recognizer: textSpan.recognizer,
        mouseCursor: textSpan.mouseCursor,
        onEnter: textSpan.onEnter,
        onExit: textSpan.onExit,
        semanticsLabel: local.isEmpty
            ? textSpan.semanticsLabel
            : textSpan.semanticsLabel ?? spanText,
        semanticsIdentifier: textSpan.semanticsIdentifier,
        locale: textSpan.locale,
        spellOut: textSpan.spellOut,
      );
    }

    return _KeepAllDrawing(
      text: _redraw(text, textSpan: rebuild(root)),
      joinerIndices: _displayIndices(offsets),
      displayLength: flat.length + offsets.length,
    );
  }

  /// Writes the text [span] draws into [source] in paint order and records
  /// each `TextSpan`'s own text range in [pieces] — in the order
  /// [_rich]'s rebuild visits them.
  ///
  /// Anything that is not exactly a `TextSpan` (a `WidgetSpan`, a span
  /// subclass) is opaque: one object-replacement character that no word
  /// joins across, and nothing inside it is touched.
  static void _flatten(
    InlineSpan span,
    StringBuffer source,
    List<(int, int)> pieces,
  ) {
    if (span.runtimeType != TextSpan) {
      source.writeCharCode(PlaceholderSpan.placeholderCodeUnit);

      return;
    }
    final textSpan = span as TextSpan;
    final start = source.length;
    source.write(textSpan.text ?? '');
    pieces.add((start, source.length));
    for (final child in textSpan.children ?? const <InlineSpan>[]) {
      _flatten(child, source, pieces);
    }
  }

  /// Source offsets → the indices the joiners occupy in the display
  /// string: each one is pushed right by the joiners before it.
  static List<int> _displayIndices(List<int> offsets) => [
    for (final (index, offset) in offsets.indexed) offset + index,
  ];

  /// [text] with its content replaced and every other property kept.
  static Text _redraw(
    Text text, {
    required InlineSpan textSpan,
    String? semanticsLabel,
  }) {
    final label = semanticsLabel ?? text.semanticsLabel;

    return Text.rich(
      textSpan,
      key: text.key,
      style: text.style,
      strutStyle: text.strutStyle,
      textAlign: text.textAlign,
      textDirection: text.textDirection,
      locale: text.locale,
      softWrap: text.softWrap,
      overflow: text.overflow,
      // Preserve the caller's scale through the deprecated parameter too.
      // ignore: deprecated_member_use
      textScaleFactor: text.textScaleFactor,
      textScaler: text.textScaler,
      maxLines: text.maxLines,
      semanticsLabel: label,
      semanticsIdentifier: text.semanticsIdentifier,
      textWidthBasis: text.textWidthBasis,
      textHeightBehavior: text.textHeightBehavior,
      selectionColor: text.selectionColor,
    );
  }
}

/// Paints only inserted joiners with zero tracking. Giving the invisible
/// control the surrounding letter spacing changes the word's advance.
///
/// The span tree remains intact for recognizers, semantics and selection;
/// temporary paint spans do not split or duplicate that metadata.
class _KeepAllTextSpan extends TextSpan {
  _KeepAllTextSpan({
    required List<int> joinerIndices,
    super.text,
    super.style,
    super.recognizer,
    super.mouseCursor,
    super.onEnter,
    super.onExit,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.locale,
    super.spellOut,
    super.children,
  }) : _joinerIndices = List<int>.unmodifiable(joinerIndices);

  final List<int> _joinerIndices;

  @override
  void build(
    ui.ParagraphBuilder builder, {
    TextScaler textScaler = TextScaler.noScaling,
    List<PlaceholderDimensions>? dimensions,
  }) {
    if (_joinerIndices.isEmpty) {
      super.build(builder, textScaler: textScaler, dimensions: dimensions);
      return;
    }
    assert(debugAssertIsValid(), 'Invalid keep-all text span.');
    final hasStyle = style != null;
    if (hasStyle) {
      builder.pushStyle(style!.getTextStyle(textScaler: textScaler));
    }
    final value = text!;
    var start = 0;
    for (final index in _joinerIndices) {
      TextSpan(
        text: value.substring(start, index),
      ).build(builder, textScaler: textScaler, dimensions: dimensions);
      // Zero belongs to the inserted control, never the caller's glyphs.
      const TextSpan(
        text: CoreKeepAll.wordJoiner,
        style: TextStyle(letterSpacing: 0),
      ).build(builder, textScaler: textScaler, dimensions: dimensions);
      start = index + CoreKeepAll.wordJoiner.length;
    }
    TextSpan(
      text: value.substring(start),
    ).build(builder, textScaler: textScaler, dimensions: dimensions);
    for (final child in children ?? const <InlineSpan>[]) {
      child.build(builder, textScaler: textScaler, dimensions: dimensions);
    }
    if (hasStyle) builder.pop();
  }

  @override
  RenderComparison compareTo(InlineSpan other) =>
      other is _KeepAllTextSpan &&
          listEquals(_joinerIndices, other._joinerIndices)
      ? super.compareTo(other)
      : RenderComparison.layout;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _KeepAllTextSpan &&
          super == other &&
          listEquals(_joinerIndices, other._joinerIndices);

  @override
  int get hashCode =>
      Object.hash(super.hashCode, Object.hashAll(_joinerIndices));
}

/// A selection container around the redrawn `Text` that reports the
/// original string — what is copied, and the offsets a selection listener
/// reads — instead of the display string with its joiners.
class _KeepAllSelection extends StatefulWidget {
  const _KeepAllSelection({required this.drawing});

  final _KeepAllDrawing drawing;

  @override
  State<_KeepAllSelection> createState() => _KeepAllSelectionState();
}

class _KeepAllSelectionState extends State<_KeepAllSelection> {
  final _delegate = _KeepAllSelectionDelegate();

  @override
  void initState() {
    super.initState();
    _delegate.drawing = widget.drawing;
  }

  @override
  void didUpdateWidget(_KeepAllSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _delegate.drawing = widget.drawing;
  }

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionContainer(delegate: _delegate, child: widget.drawing.text);
  }
}

/// Maps the redrawn paragraph's selection back to the original string.
///
/// When the paragraph holds only text, its selectable content is exactly
/// the display string, so a display offset becomes a source offset by
/// counting the joiners before it — and only the joiners keep-all
/// inserted are dropped from a copy. A paragraph with widgets inside it
/// flattens their content into its own, which breaks that count; there
/// every word joiner is dropped from a copy, and offsets are passed
/// through as drawn.
class _KeepAllSelectionDelegate extends StaticSelectionContainerDelegate {
  _KeepAllDrawing? drawing;

  bool get _mapsExactly {
    final drawing = this.drawing;

    return drawing != null && super.contentLength == drawing.displayLength;
  }

  List<int> get _joiners => drawing!.joinerIndices;

  /// The number of inserted joiners before [displayOffset], subtracted.
  int _toSource(int displayOffset) =>
      displayOffset - lowerBound(_joiners, displayOffset);

  @override
  int get contentLength => _mapsExactly
      ? drawing!.displayLength - _joiners.length
      : super.contentLength;

  @override
  SelectedContentRange? getSelection() {
    final range = super.getSelection();
    if (range == null || !_mapsExactly) return range;

    return SelectedContentRange(
      startOffset: _toSource(range.startOffset),
      endOffset: _toSource(range.endOffset),
    );
  }

  @override
  SelectedContent? getSelectedContent() {
    final content = super.getSelectedContent();
    if (content == null) return null;

    final selected = content.plainText;
    final range = super.getSelection();
    if (range != null && _mapsExactly) {
      final start = math.min(range.startOffset, range.endOffset);
      final end = math.max(range.startOffset, range.endOffset);
      if (end - start == selected.length) {
        return SelectedContent(plainText: _withoutInserted(selected, start));
      }
    }

    return SelectedContent(
      plainText: selected.replaceAll(CoreKeepAll.wordJoiner, ''),
    );
  }

  /// [selected] — the display string from [start] — without the joiners
  /// keep-all inserted. A joiner the original string carried stays.
  String _withoutInserted(String selected, int start) {
    final buffer = StringBuffer();
    var next = lowerBound(_joiners, start);
    for (var i = 0; i < selected.length; i += 1) {
      if (next < _joiners.length && _joiners[next] == start + i) {
        next += 1;
        continue;
      }
      buffer.writeCharCode(selected.codeUnitAt(i));
    }

    return buffer.toString();
  }
}

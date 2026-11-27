import 'package:coui_flutter/coui_flutter.dart';

/// 코드 변경 사항을 라인 단위로 표시하는 viewer 컴포넌트 (Flutter).
///
/// Web `CodeDiff` 와 동일한 API/렌더링.
///
/// ```dart
/// CodeDiff(
///   lines: [
///     CoreCodeDiffLine(text: 'same', type: CoreCodeDiffLineType.unchanged),
///     CoreCodeDiffLine(text: 'old',  type: CoreCodeDiffLineType.removed),
///     CoreCodeDiffLine(text: 'new',  type: CoreCodeDiffLineType.added),
///   ],
/// )
/// ```
class CodeDiff extends StatelessWidget implements CoreCodeDiffContract {
  /// Creates a [CodeDiff].
  const CodeDiff({
    required this.lines,
    super.key,
    this.showLineNumbers = true,
    this.onLineTap,
    this.codeDiffStyle,
  });

  @override
  final List<CoreCodeDiffLine> lines;

  @override
  final bool showLineNumbers;

  @override
  final ValueChanged<CoreCodeDiffLine>? onLineTap;

  @override
  final CoreCodeDiffStyle? codeDiffStyle;

  /// Returns a copy of this [CodeDiff] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  CodeDiff copyWith({
    Key? key,
    List<CoreCodeDiffLine>? lines,
    bool? showLineNumbers,
    ValueChanged<CoreCodeDiffLine>? onLineTap,
    CoreCodeDiffStyle? codeDiffStyle,
  }) {
    return CodeDiff(
      key: key ?? this.key,
      lines: lines ?? this.lines,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      onLineTap: onLineTap ?? this.onLineTap,
      codeDiffStyle: codeDiffStyle ?? this.codeDiffStyle,
    );
  }

  String _resolvePrefix(CoreCodeDiffLineType type) => switch (type) {
    .added => '+ ',
    .removed => '- ',
    .unchanged => '  ',
  };

  // Select among resolved values only — the colours are final, opaque and
  // already theme-resolved. A band row is a solid face, never a tint.
  Color _resolveBackgroundColor(
    CoreCodeDiffLineType type,
    ResolvedCodeDiff resolved,
  ) => switch (type) {
    .added => resolved.addedBackgroundColor,
    .removed => resolved.removedBackgroundColor,
    .unchanged => Colors.transparent,
  };

  // The `+ ` / `- ` prefix wears the ink of the band it sits on; an
  // unchanged row has no band, so its (blank) prefix keeps the body ink.
  Color _resolvePrefixColor(
    CoreCodeDiffLineType type,
    ResolvedCodeDiff resolved,
  ) => switch (type) {
    .added => resolved.addedForegroundColor,
    .removed => resolved.removedForegroundColor,
    .unchanged => resolved.unchangedTextColor,
  };

  // The gutter number: the band's ink on a band, the subdued gutter colour
  // on a plain row. The subdued colour is never drawn on a band.
  Color _resolveLineNumberColor(
    CoreCodeDiffLineType type,
    ResolvedCodeDiff resolved,
  ) => switch (type) {
    .added => resolved.addedForegroundColor,
    .removed => resolved.removedForegroundColor,
    .unchanged => resolved.lineNumberColor,
  };

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCodeDiff(context, codeDiffStyle: codeDiffStyle);

    final linePadding = resolved.linePadding;
    final lineNumberPadding = resolved.lineNumberPadding;

    return OutlinedContainer(
      containerStyle: resolved.containerStyle,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          for (final line in lines)
            _buildRow(
              line: line,
              resolved: resolved,
              linePadding: linePadding,
              lineNumberPadding: lineNumberPadding,
            ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required CoreCodeDiffLine line,
    required ResolvedCodeDiff resolved,
    required EdgeInsets linePadding,
    required EdgeInsetsGeometry lineNumberPadding,
  }) {
    final row = Container(
      padding: linePadding,
      color: _resolveBackgroundColor(line.type, resolved),
      child: Row(
        // First-line aligned: the gutter number and the prefix stay on the
        // first 21px line of a text that wraps, as the Web row does.
        crossAxisAlignment: .start,
        children: [
          if (showLineNumbers && line.lineNumber != null)
            SizedBox(
              width: resolved.lineNumberWidth,
              child: Padding(
                padding: lineNumberPadding,
                child: Text(
                  '${line.lineNumber}',
                  style: resolved.gutterTextStyle.copyWith(
                    color: _resolveLineNumberColor(line.type, resolved),
                  ),
                  // End edge, not `.right`: the number hugs the gap beside
                  // the prefix in either reading direction.
                  textAlign: .end,
                ),
              ),
            ),
          Text(
            _resolvePrefix(line.type),
            style: resolved.bodyTextStyle.copyWith(
              color: _resolvePrefixColor(line.type, resolved),
              fontWeight: resolved.prefixFontWeight,
            ),
          ),
          Expanded(
            child: Text(
              line.text,
              // The code keeps the body ink on every row: a band recolours
              // the prefix and the number, never the text.
              style: resolved.bodyTextStyle.copyWith(
                color: resolved.unchangedTextColor,
              ),
            ),
          ),
        ],
      ),
    );
    final onTap = onLineTap;
    if (onTap == null) {
      return row;
    }
    return Clickable(
      onPressed: () => onTap(line),
      child: row,
    );
  }
}

/// Chain sugar for merging a [CoreCodeDiffStyle] patch into
/// [CodeDiff.codeDiffStyle] without hand-reconstructing every field.
/// Mirrors the Web `CodeDiff.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCodeDiffStyle.merge` right-side-wins semantics).
extension CodeDiffStyleChain on CodeDiff {
  /// Sets the border width in logical pixels.
  CodeDiff borderWidth(double value) =>
      withStyle(CoreCodeDiffStyle(borderWidth: value));

  /// Returns a copy of this [CodeDiff] with [patch] merged into
  /// [codeDiffStyle] (patch fields win on conflict).
  CodeDiff withStyle(CoreCodeDiffStyle patch) => copyWith(
    codeDiffStyle: (codeDiffStyle ?? const CoreCodeDiffStyle()).merge(patch),
  );
}

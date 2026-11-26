import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/code_diff/code_diff_style.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified line-by-line code diff viewer for CoUI Web.
///
/// Per Epic #1302 every chrome / dimensional / nested-text-style
/// override flows through the single [codeDiffStyle] (a
/// [CoreCodeDiffStyle]). Behavioural fields ([lines],
/// [showLineNumbers]) stay flat on the component.
///
/// ```text
/// design system default for codeDiff
///   → CoreCodeDiffTheme.style                  // 프로젝트 공통
///   → component.codeDiffStyle                  // 인스턴스별
/// ```
///
/// Mirrors Flutter `CodeDiff` in API and DOM structure.
class CodeDiff extends UiComponent implements CoreCodeDiffContract {
  /// Creates a [CodeDiff].
  const CodeDiff({
    required this.lines,
    super.key,
    this.showLineNumbers = true,
    this.onLineTap,
    this.codeDiffStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<CoreCodeDiffLine> lines;

  @override
  final bool showLineNumbers;

  @override
  final CoreValueChanged<CoreCodeDiffLine>? onLineTap;

  @override
  final CoreCodeDiffStyle? codeDiffStyle;

  @override
  CodeDiff copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<CoreCodeDiffLine>? lines,
    bool? showLineNumbers,
    CoreValueChanged<CoreCodeDiffLine>? onLineTap,
    CoreCodeDiffStyle? codeDiffStyle,
  }) {
    return CodeDiff(
      key: key ?? this.key,
      lines: lines ?? this.lines,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      onLineTap: onLineTap ?? this.onLineTap,
      codeDiffStyle: codeDiffStyle ?? this.codeDiffStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveCodeDiff(
      context,
      lines: lines,
      codeDiffStyle: codeDiffStyle,
    );

    // The outer bordered box is composed from `OutlinedContainer` rather
    // than a hand-rolled `<div>` (`core/style-contract.md`'s child-
    // component-composition rule) — this component's own chrome
    // (border / bg / radius) flows through `resolved.containerStyle`,
    // raw-forwarded straight to the shared primitive. Caller-supplied
    // id / classes / css / attributes / event handlers land on that
    // same composed root, mirroring the passthrough every other
    // `UiComponent` root gives them.
    return OutlinedContainer(
      containerStyle: resolved.containerStyle,
      id: id,
      classes: classes,
      css: css,
      attributes: userAttributes,
      eventHandlers: eventHandlers,
      child: div(
        [
          for (var i = 0; i < lines.length; i++)
            _buildRow(line: lines[i], row: resolved.rows[i]),
        ],
        classes: resolved.rowsWrapper.className,
        styles: resolved.rowsWrapper.inlineStyles,
      ),
    );
  }

  Component _buildRow({
    required CoreCodeDiffLine line,
    required ResolvedCodeDiffRow row,
  }) {
    final rowBody = div(
      [
        if (showLineNumbers && line.lineNumber != null)
          div(
            [Component.text('${line.lineNumber}')],
            classes: row.lineNumber.className,
            styles: row.lineNumber.inlineStyles,
          ),
        span(
          [Component.text(_resolvePrefix(line.type))],
          classes: row.prefix.className,
          styles: row.prefix.inlineStyles,
        ),
        div(
          [Component.text(line.text)],
          classes: row.text.className,
          styles: row.text.inlineStyles,
        ),
      ],
      classes: row.root.className,
      styles: row.root.inlineStyles,
    );
    final onTap = onLineTap;
    if (onTap == null) {
      return rowBody;
    }
    return Clickable(
      onPressed: () => onTap(line),
      child: rowBody,
    );
  }

  String _resolvePrefix(CoreCodeDiffLineType type) => switch (type) {
    .added => '+ ',
    .removed => '- ',
    .unchanged => '  ',
  };
}

/// Chain sugar mirroring the Flutter `CodeDiff.withStyle` extension —
/// merges a [CoreCodeDiffStyle] patch into [CodeDiff.codeDiffStyle] via
/// the existing [CodeDiff.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCodeDiffStyle.merge` right-side-wins semantics).
extension CodeDiffStyleChain on CodeDiff {
  /// Returns a copy of this [CodeDiff] with [patch] merged into
  /// [codeDiffStyle] (patch fields win on conflict).
  CodeDiff withStyle(CoreCodeDiffStyle patch) => copyWith(
    codeDiffStyle: (codeDiffStyle ?? const CoreCodeDiffStyle()).merge(patch),
  );
}

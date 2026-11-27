import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/layout/step_item/step_item_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

const _kDivTag = 'div';

/// One row of a step list for CoUI Web — a status glyph, the step's title
/// on one line, and an optional note pinned to the end of the row.
///
/// The row `Steps` stacks with `variant: CoreStepsVariant.list`, public so
/// a page can place rows one by one. Not `Stepper`'s step — that one
/// (`CoreStepItem`) is an input flow; this row only reports where a step
/// stands.
///
/// ```dart
/// StepItem(
///   title: 'Build',
///   status: CoreStepStatus.done,
///   trailing: '1m 12s',
/// )
/// ```
///
/// The glyph is the [status]'s own (`CoreStepStatus.glyph`); its colour,
/// the title's and the trailing note's are the status row of
/// `CoreStepItemStyle.defaultsByStatus`. The title takes the space left
/// and ends with an ellipsis; the trailing note keeps its width at the end
/// of the row (the start in a right-to-left page). The row fills the width
/// it is given.
///
/// A row on its own announces nothing beyond its text; inside a list
/// `Steps` marks it as a list entry through `attributes`.
///
/// All paint resolution is delegated to [resolveStepItem].
class StepItem extends UiComponent implements CoreStepItemContract {
  /// Creates a [StepItem].
  const StepItem({
    required this.title,
    this.status = CoreStepStatus.defaultStatus,
    this.trailing,
    this.stepItemStyle,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _kDivTag,
  });

  @override
  final String title;

  @override
  final CoreStepStatus status;

  @override
  final String? trailing;

  @override
  final CoreStepItemStyle? stepItemStyle;

  @override
  StepItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? title,
    CoreStepStatus? status,
    String? trailing,
    CoreStepItemStyle? stepItemStyle,
    Key? key,
  }) {
    return StepItem(
      key: key ?? this.key,
      title: title ?? this.title,
      status: status ?? this.status,
      trailing: trailing ?? this.trailing,
      stepItemStyle: stepItemStyle ?? this.stepItemStyle,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveStepItem(
      context,
      status: status,
      stepItemStyle: stepItemStyle,
    );
    final note = trailing;

    return Component.element(
      tag: tag,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
      children: [
        Icon(status.glyph, iconStyle: resolved.iconStyle),
        Gap(gapStyle: resolved.iconTitleGapStyle),
        span(
          [Text(title)],
          classes: resolved.title.className,
          styles: resolved.title.inlineStyles,
        ),
        if (note != null) ...[
          Gap(gapStyle: resolved.titleTrailingGapStyle),
          span(
            [Text(note)],
            classes: resolved.trailing.className,
            styles: resolved.trailing.inlineStyles,
          ),
        ],
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `StepItem.withStyle` extension —
/// merges a [CoreStepItemStyle] patch into [StepItem.stepItemStyle] via
/// the existing [StepItem.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStepItemStyle.merge` right-side-wins semantics).
extension StepItemStyleChain on StepItem {
  /// Sets the content padding.
  StepItem contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreStepItemStyle(padding: value));

  /// Returns a copy of this [StepItem] with [patch] merged into
  /// [stepItemStyle] (patch fields win on conflict).
  StepItem withStyle(CoreStepItemStyle patch) => copyWith(
    stepItemStyle: (stepItemStyle ?? const CoreStepItemStyle()).merge(patch),
  );
}

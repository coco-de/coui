import 'package:coui_flutter/coui_flutter.dart';

/// One row of a step list — a status glyph, the step's title on one line,
/// and an optional note pinned to the end of the row.
///
/// The row [Steps] stacks with `variant: CoreStepsVariant.list`, public so
/// a screen can place rows one by one. Not `Stepper`'s step — that one
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
/// of the row (the start in a right-to-left locale). The row fills the
/// width it is given.
///
/// A row on its own announces nothing beyond its text; inside a list
/// [Steps] marks it as a list entry.
///
/// `StepItem` is render-only — every colour / size / gap is pre-resolved
/// by [resolveStepItem] into a [ResolvedStepItem].
class StepItem extends StatelessWidget implements CoreStepItemContract {
  /// Creates a [StepItem].
  const StepItem({
    required this.title,
    this.status = CoreStepStatus.defaultStatus,
    this.trailing,
    this.stepItemStyle,
    super.key,
  });

  @override
  final String title;

  @override
  final CoreStepStatus status;

  @override
  final String? trailing;

  @override
  final CoreStepItemStyle? stepItemStyle;

  /// Returns a copy of this [StepItem] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  StepItem copyWith({
    Key? key,
    String? title,
    CoreStepStatus? status,
    String? trailing,
    CoreStepItemStyle? stepItemStyle,
  }) {
    return StepItem(
      key: key ?? this.key,
      title: title ?? this.title,
      status: status ?? this.status,
      trailing: trailing ?? this.trailing,
      stepItemStyle: stepItemStyle ?? this.stepItemStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveStepItem(
      context,
      status: status,
      stepItemStyle: stepItemStyle,
    );
    final note = trailing;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      child: Padding(
        padding: resolved.padding,
        child: Row(
          children: [
            Icon(status.glyph, iconStyle: resolved.iconStyle),
            Gap(gapStyle: resolved.iconTitleGapStyle),
            Expanded(
              child: Text(
                title, // one line — the row's height is the row's own
                maxLines: 1,
                overflow: .ellipsis,
                style: resolved.titleTextStyle,
              ),
            ),
            if (note != null) ...[
              Gap(gapStyle: resolved.titleTrailingGapStyle),
              Text(
                note,
                maxLines: 1,
                style: resolved.trailingTextStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreStepItemStyle] patch into
/// [StepItem.stepItemStyle] without hand-reconstructing every field.
/// Mirrors the Web `StepItem.withStyle` extension so both platforms read
/// identically.
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

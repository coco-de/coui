/// Cross-platform contract for `StepItem`.
library;

import 'package:coui_core/src/component/contracts/step_item/step_item_style.dart';
import 'package:coui_core/src/component/contracts/steps/step_status.dart';

/// One row of a step list — a status glyph, the step's title on one line,
/// and an optional note pinned to the end of the row.
///
/// The row `Steps(variant: CoreStepsVariant.list)` stacks, public on its
/// own so a screen can place rows one by one (and so the Figma `StepItem`
/// set maps 1:1 to a widget).
///
/// Not `Stepper`'s step: `CoreStepItem` is the data class of `Stepper`, an
/// input flow the user moves through. This row only reports where a step
/// stands.
///
/// Anatomy, start to end: `[ glyph ] [ title … ] [ trailing ]`. The glyph
/// is the [status]'s ([CoreStepStatus.glyph]); its colour, the title's and
/// the trailing note's come from the status row in
/// [CoreStepItemStyle.defaultsByStatus]. The title takes the space left
/// and ends with an ellipsis rather than wrap; the trailing note keeps its
/// own width at the end.
///
/// Chrome flows through the single [stepItemStyle] slot; everything else
/// here is data (the title and the note) or semantic (the status).
abstract interface class CoreStepItemContract {
  /// The step's name. One line — a longer title is cut with an ellipsis.
  String get title;

  /// Where the step stands. Picks the glyph and the colours.
  CoreStepStatus get status;

  /// A short note at the end of the row — a duration, a count, a reason.
  /// `null` draws nothing there.
  String? get trailing;

  /// Per-instance chrome override.
  ///
  /// ```text
  /// CoreStepItemStyle.default* + defaultsByStatus[status]
  ///   → CoreStepItemTheme.style
  ///   → CoreStepItemTheme.statusStyles[status]
  ///   → stepItemStyle
  /// ```
  CoreStepItemStyle? get stepItemStyle;
}

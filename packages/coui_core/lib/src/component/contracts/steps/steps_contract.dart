/// Platform-independent contract for unified steps components.
library;

import 'package:coui_core/src/component/contracts/steps/step_status.dart';
import 'package:coui_core/src/component/contracts/steps/steps_style.dart';
import 'package:coui_core/src/component/contracts/steps/steps_variant.dart';

/// Data for a single step in a steps progression.
///
/// Not the same class as `CoreStepItem` — that one is `Stepper`'s step (an
/// input flow the user moves through); this one is a step `Steps` reports.
class CoreStepData {
  /// Creates a [CoreStepData].
  const CoreStepData({
    required this.title,
    this.description,
    this.status,
    this.trailing,
  });

  /// Title text for this step.
  final String title;

  /// Optional description text. Drawn under the title by
  /// [CoreStepsVariant.numbered]; [CoreStepsVariant.list] rows have one
  /// line and do not draw it.
  final String? description;

  /// Where this step stands. `null` → placed by its index against
  /// `CoreStepsContract.currentStep` (see [CoreStepStatus.effective]).
  final CoreStepStatus? status;

  /// A short note pinned to the end of the row — a duration, a count, a
  /// reason. Drawn by [CoreStepsVariant.list] only.
  final String? trailing;
}

/// Contract for a unified steps component.
///
/// Displays a sequence of steps — numbered indicators joined by connectors
/// ([CoreStepsVariant.numbered]) or a list of status rows
/// ([CoreStepsVariant.list]).
abstract interface class CoreStepsContract {
  /// Step data items.
  List<CoreStepData> get items;

  /// Current active step index (0-based). Places every item that states no
  /// `status` of its own.
  int get currentStep;

  /// Whether to render vertically. Read by [CoreStepsVariant.numbered];
  /// [CoreStepsVariant.list] is always vertical.
  bool get vertical;

  /// Which layout the steps take.
  CoreStepsVariant get variant;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreStepsTheme.style
  ///   → CoreStepsTheme.variantStyles[variant]
  ///   → widget.stepsStyle
  /// ```
  CoreStepsStyle? get stepsStyle;
}

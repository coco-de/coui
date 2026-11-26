/// Platform-independent contract for unified stepper components.
///
/// Defines the interface that all Stepper implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/stepper/stepper_style.dart';

/// A single step within a stepper component.
///
/// Represents one stage in a multi-step process with
/// a label and optional description.
///
/// `Stepper`'s step — an input flow the user moves through. Not the row of
/// `Steps(variant: list)`, which is `StepItem` (`CoreStepItemContract`) and
/// only reports where a step stands.
class CoreStepItem {
  /// Creates a [CoreStepItem].
  const CoreStepItem({
    required this.label,
    this.description,
  });

  /// The text label displayed for this step.
  final String label;

  /// An optional description providing additional detail.
  final String? description;
}

/// Orientation for stepper layout.
enum CoreStepperOrientation {
  /// Horizontal layout.
  horizontal,

  /// Vertical layout.
  vertical,
}

/// Contract for a unified stepper component.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [stepperStyle] field — see [CoreStepperStyle] for the
/// merge chain.
abstract interface class CoreStepperContract {
  /// The list of steps to display.
  List<CoreStepItem> get steps;

  /// The index of the currently active step.
  int get currentStep;

  /// Layout orientation.
  CoreStepperOrientation get orientation;

  /// Called when the active step changes.
  ///
  /// Receives the index of the newly selected step.
  CoreValueChanged<int>? get onStepChanged;

  /// Whether the stepper is enabled.
  ///
  /// `null` follows [onStepChanged]: a stepper that navigates is enabled, one
  /// that cannot is drawn disabled. A disabled stepper keeps its structure —
  /// every circle, line and word stays — and takes the disabled colours of
  /// [CoreStepperStyle] instead; it is not dimmed.
  bool? get enabled;

  /// Per-instance stepper chrome / dimensional / slot style.
  CoreStepperStyle? get stepperStyle;
}

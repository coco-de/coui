// ignore_for_file: avoid-using-non-ascii-symbols

import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A stepper component for multi-step processes.
///
/// Example:
/// ```dart
/// Stepper(
///   currentStep: 0,
///   steps: [
///     Step(label: 'Step 1', content: text('Content 1')),
///     Step(label: 'Step 2', content: text('Content 2')),
///   ],
/// )
/// ```
class Stepper extends UiComponent {
  /// Parameters:
  /// - [steps]: List of steps
  /// - [currentStep]: Currently active step index
  /// - [orientation]: Layout orientation
  const Stepper({
    super.key,
    required this.steps,
    this.currentStep = 0,
    this.orientation = StepperOrientation.vertical,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// List of steps.
  final List<Step> steps;

  /// Currently active step index.
  final int currentStep;

  /// Layout orientation.
  final StepperOrientation orientation;

  /// Creates a Stepper component.
  ///
  /// Checkmark icon character code (U+2713 - ✓).
  static const _kCheckIconCode = 0x2713;

  static const _divValue = 'div';

  /// Checkmark icon character.
  static String get _kCheckIcon => String.fromCharCode(_kCheckIconCode);

  @override
  Stepper copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Step>? steps,
    int? currentStep,

    StepperOrientation? orientation,
    Key? key,
  }) {
    return Stepper(
      key: key ?? this.key,
      steps: steps ?? this.steps,
      currentStep: currentStep ?? this.currentStep,
      orientation: orientation ?? this.orientation,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final stepComponents = <Component>[];

    for (int i = 0; i < steps.length; i += 1) {
      final step = steps[i];
      final isActive = i == currentStep;
      final isCompleted = i < currentStep;

      stepComponents.add(
        div(
          children: [
            // Step indicator
            div(
              children: [
                div(
                  child: text(isCompleted ? _kCheckIcon : (i + 1).toString()),
                  classes: _buildStepIndicatorClasses(isActive, isCompleted),
                ),
                if (i < steps.length - 1 &&
                    orientation == StepperOrientation.vertical)
                  div(
                    classes: 'w-px h-8 bg-border',
                  ),
              ],
              classes: orientation == StepperOrientation.vertical
                  ? 'flex flex-col items-center'
                  : 'flex items-center gap-2',
            ),
            // Step content
            div(
              children: [
                div(
                  child: text(step.label),
                  classes: 'font-medium',
                ),
                if (step.description != null)
                  div(
                    child: text(step.description),
                    classes: 'text-sm text-muted-foreground',
                  ),
                if (isActive && step.content != null)
                  div(
                    child: step.content,
                    classes: 'mt-4',
                  ),
              ],
              classes: 'flex-1',
            ),
          ],
          classes: orientation == StepperOrientation.vertical
              ? 'flex gap-4'
              : 'flex flex-col items-center gap-2',
        ),
      );

      if (i < steps.length - 1 &&
          orientation == StepperOrientation.horizontal) {
        stepComponents.add(
          div(
            classes: 'flex-1 h-px bg-border self-center',
          ),
        );
      }
    }

    return div(
      children: stepComponents,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => orientation == StepperOrientation.vertical
      ? 'flex flex-col gap-4'
      : 'flex gap-4';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  static String _buildStepIndicatorClasses(bool isActive, bool isCompleted) {
    const base =
        'flex items-center justify-center w-8 h-8 rounded-full border-2 text-sm font-medium';
    final state = isCompleted
        ? 'bg-primary text-primary-foreground border-primary'
        : isActive
        ? 'border-primary text-primary'
        : 'border-muted text-muted-foreground';

    return '$base $state';
  }
}

/// A step in a Stepper.
class Step {
  /// Creates a Step.
  const Step({
    required this.label,
    this.description,
    this.content,
  });

  /// Step label.
  final String label;

  /// Optional step description.
  final String? description;

  /// Optional step content.
  final Component? content;
}

/// Stepper orientation options.
enum StepperOrientation {
  /// Vertical layout.
  vertical,

  /// Horizontal layout.
  horizontal,
}

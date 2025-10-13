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
  /// Creates a Stepper component.
  ///
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

  static const _divValue = 'div';

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
          classes: orientation == StepperOrientation.vertical
              ? 'flex gap-4'
              : 'flex flex-col items-center gap-2',
          children: [
            // Step indicator
            div(
              classes: orientation == StepperOrientation.vertical
                  ? 'flex flex-col items-center'
                  : 'flex items-center gap-2',
              children: [
                div(
                  classes: _buildStepIndicatorClasses(isActive, isCompleted),
                  child: text(isCompleted ? '\u2713' : (i + 1).toString()),
                ),
                if (i < steps.length - 1 &&
                    orientation == StepperOrientation.vertical)
                  div(
                    classes: 'w-px h-8 bg-border',
                  ),
              ],
            ),
            // Step content
            div(
              classes: 'flex-1',
              children: [
                div(
                  classes: 'font-medium',
                  child: text(step.label),
                ),
                if (step.description != null)
                  div(
                    classes: 'text-sm text-muted-foreground',
                    child: text(step.description!),
                  ),
                if (isActive && step.content != null)
                  div(
                    classes: 'mt-4',
                    child: step.content!,
                  ),
              ],
            ),
          ],
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
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: stepComponents,
    );
  }

  @override
  String get baseClass => orientation == StepperOrientation.vertical
      ? 'flex flex-col gap-4'
      : 'flex gap-4';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
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

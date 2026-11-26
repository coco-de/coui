import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'stepper.stories.g.dart';

const _kDefaultStepCount = 4;
const _kStepperWidth = 600.0;

/// Interactive demo host for [Stepper] stories.
class StepperDemo extends StatefulWidget {
  /// Creates a [StepperDemo].
  const StepperDemo({
    super.key,
    this.stepCount = _kDefaultStepCount,
    this.initialStep = 0,
    this.orientation = CoreStepperOrientation.horizontal,
  });

  /// Number of generated steps.
  final int stepCount;

  /// Initially active step index.
  final int initialStep;

  /// Layout orientation of the stepper.
  final CoreStepperOrientation orientation;

  @override
  State<StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<StepperDemo> {
  // deferred init must read widget.
  late int _currentStep = widget.initialStep;

  @override
  void didUpdateWidget(StepperDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStep != widget.initialStep) {
      _currentStep = widget.initialStep;
    }
  }

  void handleStepChanged(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = List.generate(
      widget.stepCount,
      (idx) => CoreStepItem(
        label: 'Step ${idx + 1}',
        description: 'Description ${idx + 1}',
      ),
    );

    return Center(
      child: SizedBox(
        width: _kStepperWidth,
        child: Stepper(
          steps: steps,
          currentStep: _currentStep,
          orientation: widget.orientation,
          onStepChanged: handleStepChanged,
        ),
      ),
    );
  }
}

/// Navigation metadata for the Stepper component.
const kComponentMeta = ComponentMeta(name: 'Stepper', path: 'layout');

/// Story metadata for [StepperDemo].
const kMeta = Meta(StepperDemo.new);

/// Horizontal stepper with editable knobs.
final $Default = _Story();

/// Vertical stepper layout.
final $Vertical = _Story(
  args: _Args(
    orientation: EnumArg(
      CoreStepperOrientation.vertical,
      values: CoreStepperOrientation.values,
    ),
  ),
);

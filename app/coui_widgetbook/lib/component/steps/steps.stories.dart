import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'steps.stories.g.dart';

const _kDefaultStepCount = 4;

// `failedStep` knob value meaning no step is marked failed.
const _kNoFailedStep = -1;

// The list variant fills the width it is given, so the harness hands it a
// bounded one the way a card would.
const _kListWidth = 280.0;

/// Demo host for [Steps] stories.
class StepsDemo extends StatelessWidget {
  /// Creates a [StepsDemo].
  const StepsDemo({
    super.key,
    this.stepCount = _kDefaultStepCount,
    this.currentStep = 1,
    this.vertical = true,
    this.variant = CoreStepsVariant.defaultVariant,
    this.failedStep = _kNoFailedStep,
    this.showTrailing = true,
  });

  /// Number of generated steps.
  final int stepCount;

  /// Currently active step index.
  final int currentStep;

  /// Whether the steps stack vertically. Read by the numbered variant only —
  /// the list is always vertical.
  final bool vertical;

  /// Which layout the steps take — numbered indicators or a list of rows.
  final CoreStepsVariant variant;

  /// Index of the step marked failed, or -1 for none. The other steps are
  /// placed by [currentStep].
  final int failedStep;

  /// Whether each step carries a trailing note — drawn by the list variant
  /// only.
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      stepCount,
      (idx) => CoreStepData(
        title: 'Step ${idx + 1}',
        description: 'Step ${idx + 1} description',
        status: idx == failedStep ? CoreStepStatus.failed : null,
        trailing: showTrailing ? '${(idx + 1) * 12}s' : null,
      ),
    );

    final steps = Steps(
      items: items,
      currentStep: currentStep,
      vertical: vertical,
      variant: variant,
    );

    return Padding(
      padding: const .all(CoreSpace.space16),
      child: variant == CoreStepsVariant.list
          ? SizedBox(width: _kListWidth, child: steps)
          : steps,
    );
  }
}

/// Navigation metadata for the Steps component.
const kComponentMeta = ComponentMeta(name: 'Steps', path: 'layout');

/// Story metadata for [StepsDemo].
const kMeta = Meta(StepsDemo.new);

/// Vertical steps with editable knobs.
final $Default = _Story();

/// Horizontal steps layout.
final $Horizontal = _Story(
  args: _Args(vertical: BoolArg(false)),
);

/// Status rows stacked as a list — each step is a `StepItem` with a glyph, a
/// one-line name and a note pinned to the end.
final $List = _Story(
  args: _Args(
    variant: EnumArg(CoreStepsVariant.list, values: CoreStepsVariant.values),
  ),
);

/// A step that ran and stopped — set on the second step; the others stay
/// placed by the current step.
final $Failed = _Story(
  args: _Args(failedStep: IntArg(1), currentStep: IntArg(1)),
);

/// The failed step in the list variant — a `circle-x` row with the reason in
/// the error family's text ink.
final $ListFailed = _Story(
  name: 'List Failed',
  args: _Args(
    variant: EnumArg(CoreStepsVariant.list, values: CoreStepsVariant.values),
    failedStep: IntArg(2),
  ),
);

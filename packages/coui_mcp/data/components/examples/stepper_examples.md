# Stepper Examples

This document contains example code for the stepper component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)
- [Example 5: Example 5](#example-5)
- [Example 6: Example 6](#example-6)

## Example 1

**Basic Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class StepperExample1 extends StatefulWidget {
  const StepperExample1({super.key});

  @override
  State<StepperExample1> createState() => _StepperExample1State();
}

class _StepperExample1State extends State<StepperExample1> {
  final StepperController controller = StepperController();

  @override
  Widget build(BuildContext context) {
    return Stepper(
      controller: controller,
      direction: Axis.vertical,
      steps: [
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(child: Text(t.docs.common.prev)),
                PrimaryButton(
                  child: Text(t.docs.common.next),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 1, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_1),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(
                  child: Text(t.docs.common.prev),
                  onPressed: () {
                    controller.previousStep();
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.common.next),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 2, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_2),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(
                  child: Text(t.docs.common.prev),
                  onPressed: () {
                    controller.previousStep();
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.common.finish),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 3, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_3),
        ),
      ],
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class StepperExample2 extends StatefulWidget {
  const StepperExample2({super.key});

  @override
  State<StepperExample2> createState() => _StepperExample2State();
}

class _StepperExample2State extends State<StepperExample2> {
  final StepperController controller = StepperController();

  @override
  Widget build(BuildContext context) {
    return Stepper(
      controller: controller,
      direction: Axis.horizontal,
      steps: [
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(child: Text(t.docs.common.prev)),
                PrimaryButton(
                  child: Text(t.docs.common.next),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 1, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_1),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(
                  child: Text(t.docs.common.prev),
                  onPressed: () {
                    controller.previousStep();
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.common.next),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 2, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_2),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(
                  child: Text(t.docs.common.prev),
                  onPressed: () {
                    controller.previousStep();
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.common.finish),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 3, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_3),
        ),
      ],
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class StepperExample3 extends StatefulWidget {
  const StepperExample3({super.key});

  @override
  State<StepperExample3> createState() => _StepperExample3State();
}

class _StepperExample3State extends State<StepperExample3> {
  final StepperController controller = StepperController(
    currentStep: 1,
    stepStates: {1: StepState.failed},
  );

  @override
  Widget build(BuildContext context) {
    return Stepper(
      controller: controller,
      direction: Axis.horizontal,
      steps: [
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(child: Text(t.docs.common.prev)),
                PrimaryButton(child: Text(t.docs.common.next)),
              ],
              child: const NumberedContainer(index: 1, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_1),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(child: Text(t.docs.common.prev)),
                PrimaryButton(child: Text(t.docs.common.next)),
              ],
              child: const NumberedContainer(index: 2, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_2),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(child: Text(t.docs.common.prev)),
                PrimaryButton(child: Text(t.docs.common.finish)),
              ],
              child: const NumberedContainer(index: 3, height: 200),
            );
          },
          title: Text(t.docs.components.stepper.step_3),
        ),
      ],
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class StepperExample4 extends StatefulWidget {
  const StepperExample4({super.key});

  @override
  State<StepperExample4> createState() => _StepperExample4State();
}

class _StepperExample4State extends State<StepperExample4> {
  final StepperController controller = StepperController();

  @override
  Widget build(BuildContext context) {
    return Stepper(
      controller: controller,
      direction: Axis.vertical,
      steps: [
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(child: Text(t.docs.common.prev)),
                PrimaryButton(
                  child: Text(t.docs.common.next),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 1, height: 200),
            );
          },
          icon: StepNumber(
            onPressed: () {
              controller.jumpToStep(0);
            },
          ),
          title: Text(t.docs.components.stepper.step_1),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(
                  child: Text(t.docs.common.prev),
                  onPressed: () {
                    controller.previousStep();
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.common.next),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 2, height: 200),
            );
          },
          icon: StepNumber(
            onPressed: () {
              controller.jumpToStep(1);
            },
          ),
          title: Text(t.docs.components.stepper.step_2),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(
                  child: Text(t.docs.common.prev),
                  onPressed: () {
                    controller.previousStep();
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.common.finish),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 3, height: 200),
            );
          },
          icon: StepNumber(
            onPressed: () {
              controller.jumpToStep(2);
            },
          ),
          title: Text(t.docs.components.stepper.step_3),
        ),
      ],
    );
  }
}

```

## Example 5

**Example 5**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class StepperExample5 extends StatefulWidget {
  const StepperExample5({super.key});

  @override
  State<StepperExample5> createState() => _StepperExample5State();
}

class _StepperExample5State extends State<StepperExample5> {
  final StepperController controller = StepperController();

  @override
  Widget build(BuildContext context) {
    return Stepper(
      controller: controller,
      direction: Axis.horizontal,
      steps: [
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(child: Text(t.docs.common.prev)),
                PrimaryButton(
                  child: Text(t.docs.common.next),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 1, height: 200),
            );
          },
          icon: const StepNumber(icon: Icon(Icons.person)),
          title: Text(t.docs.components.stepper.step_1),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(
                  child: Text(t.docs.common.prev),
                  onPressed: () {
                    controller.previousStep();
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.common.next),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 2, height: 200),
            );
          },
          icon: const StepNumber(icon: Icon(Icons.house_outlined)),
          title: Text(t.docs.components.stepper.step_2),
        ),
        Step(
          contentBuilder: (context) {
            return StepContainer(
              actions: [
                SecondaryButton(
                  child: Text(t.docs.common.prev),
                  onPressed: () {
                    controller.previousStep();
                  },
                ),
                PrimaryButton(
                  child: Text(t.docs.common.finish),
                  onPressed: () {
                    controller.nextStep();
                  },
                ),
              ],
              child: const NumberedContainer(index: 3, height: 200),
            );
          },
          icon: const StepNumber(icon: Icon(Icons.work_outline)),
          title: Text(t.docs.components.stepper.step_3),
        ),
      ],
    );
  }
}

```

## Example 6

**Example 6**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class StepperExample6 extends StatefulWidget {
  const StepperExample6({super.key});

  @override
  State<StepperExample6> createState() => _StepperExample6State();
}

class _StepperExample6State extends State<StepperExample6> {
  static const List<StepVariant> _variants = [
    StepVariant.circle,
    StepVariant.circleAlt,
    StepVariant.line,
  ];
  final StepperController controller = StepperController();
  int _currentVariant = 0;
  int _currentStepSize = 0;
  Axis direction = Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final List<String> variantNames = [
      t.docs.components.stepper.circle,
      t.docs.components.stepper.circle_alt,
      t.docs.components.stepper.line,
    ];
    const List<StepSize> stepSizes = StepSize.values;
    final List<String> stepSizeNames = [
      t.docs.components.stepper.small,
      t.docs.components.stepper.medium,
      t.docs.components.stepper.large,
    ];

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runAlignment: WrapAlignment.center,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Toggle(
              onChanged: (value) {
                if (value) {
                  setState(() {
                    direction = Axis.horizontal;
                  });
                } else {
                  setState(() {
                    direction = Axis.vertical;
                  });
                }
              },
              trailing: Text(t.docs.components.stepper.horizontal),
              value: direction == Axis.horizontal,
            ),
            Toggle(
              onChanged: (value) {
                if (value) {
                  setState(() {
                    direction = Axis.vertical;
                  });
                } else {
                  setState(() {
                    direction = Axis.horizontal;
                  });
                }
              },
              trailing: Text(t.docs.components.stepper.vertical),
              value: direction == Axis.vertical,
            ),
            const VerticalDivider().sized(height: 16),
            for (var i = 0; i < _variants.length; i++)
              Toggle(
                onChanged: (value) {
                  setState(() {
                    _currentVariant = i;
                  });
                },
                trailing: Text(variantNames[i]),
                value: _currentVariant == i,
              ),
            const VerticalDivider().sized(height: 16),
            for (var i = 0; i < stepSizes.length; i++)
              Toggle(
                onChanged: (value) {
                  setState(() {
                    _currentStepSize = i;
                  });
                },
                trailing: Text(stepSizeNames[i]),
                value: _currentStepSize == i,
              ),
            const VerticalDivider().sized(height: 16),
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Toggle(
                  onChanged: (value) {
                    if (value) {
                      controller.setStatus(1, StepState.failed);
                    } else {
                      controller.setStatus(1, null);
                    }
                  },
                  trailing: Text(t.docs.components.stepper.toggle_error),
                  value: controller.value.stepStates[1] == StepState.failed,
                );
              },
            ),
          ],
        ),
        const Gap(size: 16),
        Stepper(
          controller: controller,
          direction: direction,
          size: stepSizes[_currentStepSize],
          steps: [
            Step(
              contentBuilder: (context) {
                return StepContainer(
                  actions: [
                    SecondaryButton(child: Text(t.docs.common.prev)),
                    PrimaryButton(
                      child: Text(t.docs.common.next),
                      onPressed: () {
                        controller.nextStep();
                      },
                    ),
                  ],
                  child: const NumberedContainer(index: 1, height: 200),
                );
              },
              title: Text(t.docs.components.stepper.step_1),
            ),
            Step(
              contentBuilder: (context) {
                return StepContainer(
                  actions: [
                    SecondaryButton(
                      child: Text(t.docs.common.prev),
                      onPressed: () {
                        controller.previousStep();
                      },
                    ),
                    PrimaryButton(
                      child: Text(t.docs.common.next),
                      onPressed: () {
                        controller.nextStep();
                      },
                    ),
                  ],
                  child: const NumberedContainer(index: 2, height: 200),
                );
              },
              title: StepTitle(
                subtitle: Text(t.docs.components.stepper.optional_step),
                title: Text(t.docs.components.stepper.step_2),
              ),
            ),
            Step(
              contentBuilder: (context) {
                return StepContainer(
                  actions: [
                    SecondaryButton(
                      child: Text(t.docs.common.prev),
                      onPressed: () {
                        controller.previousStep();
                      },
                    ),
                    PrimaryButton(
                      child: Text(t.docs.common.finish),
                      onPressed: () {
                        controller.nextStep();
                      },
                    ),
                  ],
                  child: const NumberedContainer(index: 3, height: 200),
                );
              },
              title: Text(t.docs.components.stepper.step_3),
            ),
          ],
          variant: _variants[_currentVariant],
        ),
      ],
    );
  }
}

```


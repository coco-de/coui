# Resizable Examples

This document contains example code for the resizable component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)
- [Example 5: Example 5](#example-5)
- [Example 6: Example 6](#example-6)
- [Example 7: Example 7](#example-7)

## Example 1

**Basic Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ResizableExample1 extends StatefulWidget {
  const ResizableExample1({super.key});

  @override
  State<ResizableExample1> createState() => _ResizableExample1State();
}

class _ResizableExample1State extends State<ResizableExample1> {
  @override
  Widget build(BuildContext context) {
    return const OutlinedContainer(
      clipBehavior: Clip.antiAlias,
      child: ResizablePanel.horizontal(
        children: [
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 0, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 1, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 120,
            child: NumberedContainer(index: 2, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 3, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 4, height: 200, fill: false),
          ),
        ],
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ResizableExample2 extends StatefulWidget {
  const ResizableExample2({super.key});

  @override
  State<ResizableExample2> createState() => _ResizableExample2State();
}

class _ResizableExample2State extends State<ResizableExample2> {
  @override
  Widget build(BuildContext context) {
    return const OutlinedContainer(
      clipBehavior: Clip.antiAlias,
      child: ResizablePanel.vertical(
        children: [
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 0, width: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 120,
            child: NumberedContainer(index: 1, width: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 2, width: 200, fill: false),
          ),
        ],
      ),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ResizableExample3 extends StatefulWidget {
  const ResizableExample3({super.key});

  @override
  State<ResizableExample3> createState() => _ResizableExample3State();
}

class _ResizableExample3State extends State<ResizableExample3> {
  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      clipBehavior: Clip.antiAlias,
      child: ResizablePanel.horizontal(
        children: const [
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 0, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 1, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 120,
            child: NumberedContainer(index: 2, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 3, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 80,
            child: NumberedContainer(index: 4, height: 200, fill: false),
          ),
        ],
        draggerBuilder: (context) {
          return const HorizontalResizableDragger();
        },
      ),
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ResizableExample4 extends StatefulWidget {
  const ResizableExample4({super.key});

  @override
  State<ResizableExample4> createState() => _ResizableExample4State();
}

class _ResizableExample4State extends State<ResizableExample4> {
  final AbsoluteResizablePaneController controller1 =
      AbsoluteResizablePaneController(80);
  final AbsoluteResizablePaneController controller2 =
      AbsoluteResizablePaneController(80);
  final AbsoluteResizablePaneController controller3 =
      AbsoluteResizablePaneController(120);
  final AbsoluteResizablePaneController controller4 =
      AbsoluteResizablePaneController(80);
  final AbsoluteResizablePaneController controller5 =
      AbsoluteResizablePaneController(80);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedContainer(
          clipBehavior: Clip.antiAlias,
          child: ResizablePanel.horizontal(
            children: [
              ResizablePane.controlled(
                controller: controller1,
                child: const NumberedContainer(
                  index: 0,
                  height: 200,
                  fill: false,
                ),
              ),
              ResizablePane.controlled(
                controller: controller2,
                child: const NumberedContainer(
                  index: 1,
                  height: 200,
                  fill: false,
                ),
              ),
              ResizablePane.controlled(
                controller: controller3,
                maxSize: 200,
                child: const NumberedContainer(
                  index: 2,
                  height: 200,
                  fill: false,
                ),
              ),
              ResizablePane.controlled(
                controller: controller4,
                child: const NumberedContainer(
                  index: 3,
                  height: 200,
                  fill: false,
                ),
              ),
              ResizablePane.controlled(
                collapsedSize: 20,
                controller: controller5,
                minSize: 80,
                child: const NumberedContainer(
                  index: 4,
                  height: 200,
                  fill: false,
                ),
              ),
            ],
          ),
        ),
        const Gap(size: 48),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            PrimaryButton(
              child: const Text('Reset'),
              onPressed: () {
                controller1.size = 80;
                controller2.size = 80;
                controller3.size = 120;
                controller4.size = 80;
                controller5.size = 80;
              },
            ),
            PrimaryButton(
              child: const Text('Expand Panel 2'),
              onPressed: () {
                controller3.tryExpandSize(20);
              },
            ),
            PrimaryButton(
              child: const Text('Shrink Panel 2'),
              onPressed: () {
                controller3.tryExpandSize(-20);
              },
            ),
            PrimaryButton(
              child: const Text('Expand Panel 1'),
              onPressed: () {
                controller2.tryExpandSize(20);
              },
            ),
            PrimaryButton(
              child: const Text('Shrink Panel 1'),
              onPressed: () {
                controller2.tryExpandSize(-20);
              },
            ),
            PrimaryButton(
              child: const Text('Expand Panel 4'),
              onPressed: () {
                controller5.tryExpandSize(20);
              },
            ),
            PrimaryButton(
              child: const Text('Shrink Panel 4'),
              onPressed: () {
                controller5.tryExpandSize(-20);
              },
            ),
            PrimaryButton(
              child: const Text('Collapse Panel 4'),
              onPressed: () {
                controller5.tryCollapse();
              },
            ),
            PrimaryButton(
              child: const Text('Expand Panel 4'),
              onPressed: () {
                controller5.tryExpand();
              },
            ),
          ],
        ),
      ],
    );
  }
}

```

## Example 5

**Example 5**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class ResizableExample5 extends StatefulWidget {
  const ResizableExample5({super.key});

  @override
  State<ResizableExample5> createState() => _ResizableExample5State();
}

class _ResizableExample5State extends State<ResizableExample5> {
  final ResizablePaneController controller = AbsoluteResizablePaneController(
    120,
  );
  final ResizablePaneController controller2 = AbsoluteResizablePaneController(
    120,
  );
  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      clipBehavior: Clip.antiAlias,
      child: ResizablePanel.horizontal(
        children: [
          ResizablePane.controlled(
            collapsedSize: 40,
            controller: controller,
            minSize: 100,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                if (controller.collapsed) {
                  return Container(
                    alignment: Alignment.center,
                    height: 200,
                    child: const RotatedBox(
                      quarterTurns: -1,
                      child: Text('Collapsed'),
                    ),
                  );
                }
                return Container(
                  alignment: Alignment.center,
                  height: 200,
                  child: const Text('Expanded'),
                );
              },
            ),
          ),
          ResizablePane(
            initialSize: 300,
            child: Container(
              alignment: Alignment.center,
              height: 200,
              child: const Text('Resizable'),
            ),
          ),
          ResizablePane.controlled(
            collapsedSize: 40,
            controller: controller2,
            minSize: 100,
            child: AnimatedBuilder(
              animation: controller2,
              builder: (context, child) {
                if (controller2.collapsed) {
                  return Container(
                    alignment: Alignment.center,
                    height: 200,
                    child: const RotatedBox(
                      quarterTurns: -1,
                      child: Text('Collapsed'),
                    ),
                  );
                }
                return Container(
                  alignment: Alignment.center,
                  height: 200,
                  child: const Text('Expanded'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

```

## Example 6

**Example 6**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ResizableExample6 extends StatefulWidget {
  const ResizableExample6({super.key});

  @override
  State<ResizableExample6> createState() => _ResizableExample6State();
}

class _ResizableExample6State extends State<ResizableExample6> {
  @override
  Widget build(BuildContext context) {
    return const OutlinedContainer(
      clipBehavior: Clip.antiAlias,
      child: ResizablePanel.horizontal(
        children: [
          ResizablePane(
            initialSize: 100,
            minSize: 40,
            child: NumberedContainer(index: 0, height: 200, fill: false),
          ),
          ResizablePane(
            initialSize: 300,
            minSize: 100,
            child: ResizablePanel.vertical(
              children: [
                ResizablePane(
                  initialSize: 80,
                  minSize: 40,
                  child: NumberedContainer(index: 1, fill: false),
                ),
                ResizablePane(
                  initialSize: 120,
                  minSize: 40,
                  child: ResizablePanel.horizontal(
                    children: [
                      ResizablePane.flex(
                        child: NumberedContainer(index: 2, fill: false),
                      ),
                      ResizablePane.flex(
                        child: NumberedContainer(index: 3, fill: false),
                      ),
                      ResizablePane.flex(
                        child: NumberedContainer(index: 4, fill: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ResizablePane(
            initialSize: 100,
            minSize: 40,
            child: NumberedContainer(index: 5, height: 200, fill: false),
          ),
        ],
      ),
    );
  }
}

```

## Example 7

**Example 7**

```dart
import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

class ResizableExample7 extends StatefulWidget {
  const ResizableExample7({super.key});

  @override
  State<ResizableExample7> createState() => _ResizableExample7State();
}

class _ResizableExample7State extends State<ResizableExample7> {
  final List<Color> _items = List.generate(2, (index) => _generateColor());

  static Color _generateColor() {
    Random random = Random();
    return HSVColor.fromAHSV(
      1.0,
      random.nextInt(360).toDouble(),
      0.8,
      0.8,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          ResizablePanel.vertical(
            children: [
              for (int i = 0; i < _items.length; i++)
                ResizablePane(
                  initialSize: 200,
                  key: ValueKey(_items[i].toARGB32()),
                  minSize: 100,
                  child: Container(
                    color: _items[i],
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            child: const Text('Insert Before'),
                            onPressed: () {
                              setState(() {
                                _items.insert(i, _generateColor());
                              });
                            },
                          ),
                          TextButton(
                            child: const Text('Remove'),
                            onPressed: () {
                              setState(() {
                                _items.removeAt(i);
                              });
                            },
                          ),
                          TextButton(
                            child: const Text('Insert After'),
                            onPressed: () {
                              setState(() {
                                _items.insert(i + 1, _generateColor());
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          PrimaryButton(
            child: const Text('Add'),
            onPressed: () {
              setState(() {
                _items.add(_generateColor());
              });
            },
          ),
        ],
      ),
    );
  }
}

```


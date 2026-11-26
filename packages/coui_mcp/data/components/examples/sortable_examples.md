# Sortable Examples

This document contains example code for the sortable component.

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
import 'package:coui_flutter/coui_flutter.dart';

class SortableExample1 extends StatefulWidget {
  const SortableExample1({super.key});

  @override
  State<SortableExample1> createState() => _SortableExample1State();
}

class _SortableExample1State extends State<SortableExample1> {
  List<SortableData<String>> invited = [
    const SortableData('James'),
    const SortableData('John'),
    const SortableData('Robert'),
    const SortableData('Michael'),
    const SortableData('William'),
  ];
  List<SortableData<String>> reserved = [
    const SortableData('David'),
    const SortableData('Richard'),
    const SortableData('Joseph'),
    const SortableData('Thomas'),
    const SortableData('Charles'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: SortableLayer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: SortableDropFallback<String>(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < invited.length; i++)
                        Sortable<String>(
                          data: invited[i],
                          onAcceptBottom: (value) {
                            setState(() {
                              swapItemInLists(
                                [invited, reserved],
                                value,
                                invited,
                                i + 1,
                              );
                            });
                          },
                          onAcceptTop: (value) {
                            setState(() {
                              swapItemInLists(
                                [invited, reserved],
                                value,
                                invited,
                                i,
                              );
                            });
                          },
                          child: OutlinedContainer(
                            padding: const EdgeInsets.all(12),
                            child: Center(child: Text(invited[i].data)),
                          ),
                        ),
                    ],
                  ),
                  onAccept: (value) {
                    setState(() {
                      swapItemInLists(
                        [invited, reserved],
                        value,
                        invited,
                        invited.length,
                      );
                    });
                  },
                ),
              ),
            ),
            gap(12),
            Expanded(
              child: Card(
                child: SortableDropFallback<String>(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < reserved.length; i++)
                        Sortable<String>(
                          data: reserved[i],
                          onAcceptBottom: (value) {
                            setState(() {
                              swapItemInLists(
                                [invited, reserved],
                                value,
                                reserved,
                                i + 1,
                              );
                            });
                          },
                          onAcceptTop: (value) {
                            setState(() {
                              swapItemInLists(
                                [invited, reserved],
                                value,
                                reserved,
                                i,
                              );
                            });
                          },
                          child: OutlinedContainer(
                            padding: const EdgeInsets.all(12),
                            child: Center(child: Text(reserved[i].data)),
                          ),
                        ),
                    ],
                  ),
                  onAccept: (value) {
                    setState(() {
                      swapItemInLists(
                        [invited, reserved],
                        value,
                        reserved,
                        reserved.length,
                      );
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class SortableExample2 extends StatefulWidget {
  const SortableExample2({super.key});

  @override
  State<SortableExample2> createState() => _SortableExample2State();
}

class _SortableExample2State extends State<SortableExample2> {
  List<SortableData<String>> names = [
    const SortableData('James'),
    const SortableData('John'),
    const SortableData('Robert'),
    const SortableData('Michael'),
    const SortableData('William'),
  ];

  @override
  Widget build(BuildContext context) {
    return SortableLayer(
      lock: true,
      child: SortableDropFallback<int>(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < names.length; i++)
              Sortable<String>(
                data: names[i],
                key: ValueKey(i),
                onAcceptBottom: (value) {
                  setState(() {
                    names.swapItem(value, i + 1);
                  });
                },
                onAcceptTop: (value) {
                  setState(() {
                    names.swapItem(value, i);
                  });
                },
                child: OutlinedContainer(
                  padding: const EdgeInsets.all(12),
                  child: Center(child: Text(names[i].data)),
                ),
              ),
          ],
        ),
        onAccept: (value) {
          setState(() {
            names.add(names.removeAt(value.data));
          });
        },
      ),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class SortableExample3 extends StatefulWidget {
  const SortableExample3({super.key});

  @override
  State<SortableExample3> createState() => _SortableExample3State();
}

class _SortableExample3State extends State<SortableExample3> {
  List<SortableData<String>> names = [
    const SortableData('James'),
    const SortableData('John'),
    const SortableData('Robert'),
    const SortableData('Michael'),
    const SortableData('William'),
  ];

  @override
  Widget build(BuildContext context) {
    return SortableLayer(
      lock: true,
      child: SortableDropFallback<int>(
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < names.length; i++)
                Sortable<String>(
                  data: names[i],
                  key: ValueKey(i),
                  onAcceptLeft: (value) {
                    setState(() {
                      names.swapItem(value, i);
                    });
                  },
                  onAcceptRight: (value) {
                    setState(() {
                      names.swapItem(value, i + 1);
                    });
                  },
                  child: OutlinedContainer(
                    padding: const EdgeInsets.all(12),
                    width: 100,
                    child: Center(child: Text(names[i].data)),
                  ),
                ),
            ],
          ),
        ),
        onAccept: (value) {
          setState(() {
            names.add(names.removeAt(value.data));
          });
        },
      ),
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class SortableExample4 extends StatefulWidget {
  const SortableExample4({super.key});

  @override
  State<SortableExample4> createState() => _SortableExample4State();
}

class _SortableExample4State extends State<SortableExample4> {
  List<SortableData<String>> names = [
    const SortableData('James'),
    const SortableData('John'),
    const SortableData('Robert'),
    const SortableData('Michael'),
    const SortableData('William'),
    const SortableData('David'),
    const SortableData('Richard'),
    const SortableData('Joseph'),
    const SortableData('Thomas'),
    const SortableData('Charles'),
    const SortableData('Daniel'),
    const SortableData('Matthew'),
    const SortableData('Anthony'),
    const SortableData('Donald'),
    const SortableData('Mark'),
    const SortableData('Paul'),
    const SortableData('Steven'),
    const SortableData('Andrew'),
    const SortableData('Kenneth'),
  ];

  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: SortableLayer(
        lock: true,
        child: SortableDropFallback<int>(
          child: ScrollableSortableLayer(
            controller: controller,
            child: ListView.builder(
              controller: controller,
              itemBuilder: (context, i) {
                return Sortable<String>(
                  data: names[i],
                  key: ValueKey(i),
                  onAcceptBottom: (value) {
                    setState(() {
                      names.swapItem(value, i + 1);
                    });
                  },
                  onAcceptTop: (value) {
                    setState(() {
                      names.swapItem(value, i);
                    });
                  },
                  child: OutlinedContainer(
                    padding: const EdgeInsets.all(12),
                    child: Center(child: Text(names[i].data)),
                  ),
                );
              },
              itemCount: names.length,
            ),
          ),
          onAccept: (value) {
            setState(() {
              names.add(names.removeAt(value.data));
            });
          },
        ),
      ),
    );
  }
}

```

## Example 5

**Example 5**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class SortableExample5 extends StatefulWidget {
  const SortableExample5({super.key});

  @override
  State<SortableExample5> createState() => _SortableExample5State();
}

class _SortableExample5State extends State<SortableExample5> {
  List<SortableData<String>> names = [
    const SortableData('James'),
    const SortableData('John'),
    const SortableData('Robert'),
    const SortableData('Michael'),
    const SortableData('William'),
  ];

  @override
  Widget build(BuildContext context) {
    return SortableLayer(
      lock: true,
      child: SortableDropFallback<int>(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < names.length; i++)
              Sortable<String>(
                data: names[i],
                // we only want user to drag the item from the handle,
                // so we disable the drag on the item itself
                enabled: false,
                key: ValueKey(i),
                onAcceptBottom: (value) {
                  setState(() {
                    names.swapItem(value, i + 1);
                  });
                },
                onAcceptTop: (value) {
                  setState(() {
                    names.swapItem(value, i);
                  });
                },
                child: OutlinedContainer(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SortableDragHandle(child: Icon(Icons.drag_handle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(names[i].data)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        onAccept: (value) {
          setState(() {
            names.add(names.removeAt(value.data));
          });
        },
      ),
    );
  }
}

```

## Example 6

**Example 6**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class SortableExample6 extends StatefulWidget {
  const SortableExample6({super.key});

  @override
  State<SortableExample6> createState() => _SortableExample6State();
}

class _SortableExample6State extends State<SortableExample6> {
  late List<SortableData<String>> names;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    names = [
      const SortableData('James'),
      const SortableData('John'),
      const SortableData('Robert'),
      const SortableData('Michael'),
      const SortableData('William'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SortableLayer(
      child: Builder(
        // this builder is needed to access the context of the SortableLayer
        builder: (context) {
          return SortableDropFallback<int>(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  child: const Text('Reset'),
                  onPressed: () {
                    setState(() {
                      _reset();
                    });
                  },
                ),
                for (int i = 0; i < names.length; i++)
                  Sortable<String>(
                    data: names[i],
                    // we only want user to drag the item from the handle,
                    // so we disable the drag on the item itself
                    enabled: false,
                    key: ValueKey(i),
                    onAcceptBottom: (value) {
                      setState(() {
                        names.swapItem(value, i + 1);
                      });
                    },
                    onAcceptTop: (value) {
                      setState(() {
                        names.swapItem(value, i);
                      });
                    },
                    onDropFailed: () {
                      // Remove the item from the list if the drop failed
                      setState(() {
                        var removed = names.removeAt(i);
                        SortableLayer.ensureAndDismissDrop(context, removed);
                        // Dismissing drop will prevent the SortableLayer from
                        // animating the item back to its original position
                      });
                    },
                    child: OutlinedContainer(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const SortableDragHandle(
                            child: Icon(Icons.drag_handle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(names[i].data)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            onAccept: (value) {
              setState(() {
                names.add(names.removeAt(value.data));
              });
            },
          );
        },
      ),
    );
  }
}

```


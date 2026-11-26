# Calendar Examples

This document contains example code for the calendar component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class CalendarExample1 extends StatefulWidget {
  const CalendarExample1({super.key});

  @override
  State<CalendarExample1> createState() => _CalendarExample1State();
}

class _CalendarExample1State extends State<CalendarExample1> {
  CalendarValue? _value;
  CalendarView _view = CalendarView.now();
  @override
  Widget build(BuildContext context) {
    CoUILocalizations localizations = CoUILocalizations.of(context);
    return Card(
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.previous;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_back).iconXSmall(),
                ),
                Text(
                  '${localizations.getMonth(_view.month)} ${_view.year}',
                ).sm().md().center().expanded(),
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.next;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_forward).iconXSmall(),
                ),
              ],
            ),
            const Gap(size: 16),
            Calendar(
              onChanged: (value) {
                setState(() {
                  _value = value;
                });
              },
              selectionMode: CalendarSelectionMode.range,
              value: _value,
              view: _view,
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

class CalendarExample2 extends StatefulWidget {
  const CalendarExample2({super.key});

  @override
  State<CalendarExample2> createState() => _CalendarExample2State();
}

class _CalendarExample2State extends State<CalendarExample2> {
  CalendarValue? _value;
  CalendarView _view = CalendarView.now();
  @override
  Widget build(BuildContext context) {
    CoUILocalizations localizations = CoUILocalizations.of(context);
    return Card(
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.previous;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_back).iconXSmall(),
                ),
                Text(
                  '${localizations.getMonth(_view.month)} ${_view.year}',
                ).sm().md().center().expanded(),
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.next;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_forward).iconXSmall(),
                ),
              ],
            ),
            const Gap(size: 16),
            Calendar(
              now: DateTime.now(),
              onChanged: (value) {
                setState(() {
                  _value = value;
                });
              },
              selectionMode: CalendarSelectionMode.single,
              value: _value,
              view: _view,
            ),
          ],
        ),
      ),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class CalendarExample3 extends StatefulWidget {
  const CalendarExample3({super.key});

  @override
  State<CalendarExample3> createState() => _CalendarExample3State();
}

class _CalendarExample3State extends State<CalendarExample3> {
  CalendarValue? _value;
  CalendarView _view = CalendarView.now();
  @override
  Widget build(BuildContext context) {
    CoUILocalizations localizations = CoUILocalizations.of(context);
    return Card(
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.previous;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_back).iconXSmall(),
                ),
                Text(
                  '${localizations.getMonth(_view.month)} ${_view.year}',
                ).sm().md().center().expanded(),
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.next;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_forward).iconXSmall(),
                ),
              ],
            ),
            const Gap(size: 16),
            Calendar(
              onChanged: (value) {
                setState(() {
                  _value = value;
                });
              },
              selectionMode: CalendarSelectionMode.multi,
              value: _value,
              view: _view,
            ),
          ],
        ),
      ),
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class CalendarExample4 extends StatefulWidget {
  const CalendarExample4({super.key});

  @override
  State<CalendarExample4> createState() => _CalendarExample4State();
}

class _CalendarExample4State extends State<CalendarExample4> {
  CalendarValue? _value;
  CalendarView _view = CalendarView.now();
  @override
  Widget build(BuildContext context) {
    CoUILocalizations localizations = CoUILocalizations.of(context);
    return Card(
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.previous;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_back).iconXSmall(),
                ),
                Text(
                  '${localizations.getMonth(_view.month)} ${_view.year}',
                ).sm().md().center().expanded(),
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.next;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_forward).iconXSmall(),
                ),
              ],
            ),
            const Gap(size: 16),
            Calendar(
              now: DateTime.now(),
              onChanged: (value) {
                setState(() {
                  _value = value;
                });
              },
              selectionMode: CalendarSelectionMode.none,
              value: _value,
              view: _view,
            ),
          ],
        ),
      ),
    );
  }
}

```


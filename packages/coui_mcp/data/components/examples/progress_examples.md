# Progress Examples

This document contains example code for the progress component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ProgressExample1 extends StatefulWidget {
  const ProgressExample1({super.key});

  @override
  State<ProgressExample1> createState() => _ProgressExample1State();
}

class _ProgressExample1State extends State<ProgressExample1> {
  double _progress = 0.0;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 400,
          child: Progress(max: 100, min: 0, progress: _progress.clamp(0, 100)),
        ),
        const Gap(size: 16),
        Row(
          children: [
            DestructiveButton(
              child: Text(t.docs.common.reset),
              onPressed: () {
                setState(() {
                  _progress = 0;
                });
              },
            ),
            const Gap(size: 16),
            PrimaryButton(
              child: Text(t.docs.components.circular_progress.decrease_by_10),
              onPressed: () {
                if (_progress > 0) {
                  setState(() {
                    _progress -= 10;
                  });
                }
              },
            ),
            const Gap(size: 16),
            PrimaryButton(
              child: Text(t.docs.components.circular_progress.increase_by_10),
              onPressed: () {
                if (_progress < 100) {
                  setState(() {
                    _progress += 10;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

```


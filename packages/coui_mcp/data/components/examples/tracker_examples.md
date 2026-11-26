# Tracker Examples

This document contains example code for the tracker component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class TrackerExample1 extends StatefulWidget {
  const TrackerExample1({super.key});

  @override
  State<TrackerExample1> createState() => _TrackerExample1State();
}

class _TrackerExample1State extends State<TrackerExample1> {
  @override
  Widget build(BuildContext context) {
    List<TrackerData> data = [];
    for (int i = 0; i < 80; i++) {
      data.add(
        TrackerData(
          level: TrackerLevel.fine,
          tooltip: Text(t.docs.components.tracker.tracker_fine),
        ),
      );
    }
    data[40] = data[35] = TrackerData(
      level: TrackerLevel.warning,
      tooltip: Text(t.docs.components.tracker.tracker_warning),
    );
    data[60] = data[68] = data[72] = TrackerData(
      level: TrackerLevel.critical,
      tooltip: Text(t.docs.components.tracker.tracker_critical),
    );
    for (int i = 8; i < 16; i++) {
      data[i] = TrackerData(
        level: TrackerLevel.unknown,
        tooltip: Text(t.docs.components.tracker.tracker_unknown),
      );
    }
    return Tracker(data: data);
  }
}

```


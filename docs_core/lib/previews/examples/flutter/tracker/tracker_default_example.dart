import 'package:coui_flutter/coui_flutter.dart';

class TrackerDefaultExample extends StatefulWidget {
  const TrackerDefaultExample({super.key});

  @override
  State<TrackerDefaultExample> createState() => _TrackerDefaultExampleState();
}

class _TrackerDefaultExampleState extends State<TrackerDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return Tracker(
      segments: [
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.warning),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.critical),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.unknown),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.warning),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
      ],
    );
  }
}

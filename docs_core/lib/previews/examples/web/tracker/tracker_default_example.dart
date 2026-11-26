import 'package:coui_web/coui_web.dart';

class TrackerDefaultExample extends StatefulComponent {
  const TrackerDefaultExample({super.key});

  @override
  State<TrackerDefaultExample> createState() => _TrackerDefaultExampleState();
}

class _TrackerDefaultExampleState extends State<TrackerDefaultExample> {
  @override
  Component build(BuildContext context) {
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

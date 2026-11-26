import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreTrackerStyle] slot without constructing the widget
/// from scratch.
class TrackerChainExample extends StatefulWidget {
  const TrackerChainExample({super.key});

  @override
  State<TrackerChainExample> createState() => _TrackerChainExampleState();
}

class _TrackerChainExampleState extends State<TrackerChainExample> {
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
    ).withStyle(
      const CoreTrackerStyle(
        itemHeight: CoreSpace.space48,
        itemSpacing: CoreSpace.space4,
        endRadius: CoreRadius.radius8,
      ),
    );
  }
}

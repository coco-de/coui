/// Returns a Flutter code snippet string for the Tracker component.
String trackerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class TrackerChainExample extends StatefulWidget {
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
}''',
    _ =>
      '''
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
}''',
  };
}

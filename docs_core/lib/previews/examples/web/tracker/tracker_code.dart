/// Returns a Web code snippet string for the Tracker component.
String trackerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class TrackerChainExample extends StatefulComponent {
  const TrackerChainExample({super.key});

  @override
  State<TrackerChainExample> createState() => _TrackerChainExampleState();
}

class _TrackerChainExampleState extends State<TrackerChainExample> {
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
        CoreTrackerSegment(status: CoreTrackerStatus.fine, tooltip: '정상'),
        CoreTrackerSegment(status: CoreTrackerStatus.warning, tooltip: '느림'),
        CoreTrackerSegment(status: CoreTrackerStatus.critical, tooltip: '중단'),
      ],
    );
  }
}''',
  };
}

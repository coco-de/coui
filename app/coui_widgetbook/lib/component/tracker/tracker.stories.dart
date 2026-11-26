import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'tracker.stories.g.dart';

/// Default preview width for the tracker.
const _kTrackerWidth = 400.0;

/// Knob input for [Tracker] stories.
class TrackerInput {
  /// Creates a [TrackerInput].
  const TrackerInput({this.width = _kTrackerWidth});

  /// Horizontal size of the tracker preview.
  final double width;
}

/// Navigation metadata for the Tracker component.
const kComponentMeta = ComponentMeta(name: 'Tracker', path: 'display');

/// Story metadata for [Tracker].
const kMeta = Meta(Tracker.new, argsType: TrackerInput.new);

/// Default builder mapping [TrackerInput] args to a [Tracker].
final TrackerDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: args.width,
    child: child,
  ),
  builder: (context, args) => const Tracker(
    segments: [
      CoreTrackerSegment(
        status: .fine,
        tooltip: 'System OK',
      ),
      CoreTrackerSegment(
        status: .fine,
        tooltip: 'System OK',
      ),
      CoreTrackerSegment(
        status: .warning,
        tooltip: 'High Load',
      ),
      CoreTrackerSegment(
        status: .fine,
        tooltip: 'System OK',
      ),
      CoreTrackerSegment(
        status: .critical,
        tooltip: 'System Down',
      ),
      CoreTrackerSegment(
        status: .fine,
        tooltip: 'System OK',
      ),
      CoreTrackerSegment(
        status: .warning,
        tooltip: 'Memory Warning',
      ),
    ],
  ),
);

/// Tracker with mixed segment statuses.
final $Default = _Story();

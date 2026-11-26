import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'timeline.stories.g.dart';

const _kDefaultItemCount = 5;
const _kTimelineWidth = 600.0;
const _kStartHour = 9;

/// Knob input for [Timeline] stories.
class TimelineInput {
  /// Creates a [TimelineInput].
  const TimelineInput({this.itemCount = _kDefaultItemCount});

  /// Number of generated timeline items.
  final int itemCount;
}

/// Navigation metadata for the Timeline component.
const kComponentMeta = ComponentMeta(name: 'Timeline', path: 'display');

/// Story metadata for [Timeline].
const kMeta = Meta(Timeline.new, argsType: TimelineInput.new);

/// Default builder mapping [TimelineInput] args to a [Timeline].
final TimelineDefaults defaults = _Defaults(
  setup: (context, child, args) =>
      SizedBox(width: _kTimelineWidth, child: child),
  builder: (context, args) => Timeline(
    items: List.generate(
      args.itemCount,
      (idx) => CoreTimelineItem(
        title: 'Event ${idx + 1}',
        description: 'Description for event ${idx + 1}',
        timestamp: '${_kStartHour + idx}:00 AM',
      ),
    ),
  ),
);

/// Timeline with a generated item list.
final $Default = _Story();

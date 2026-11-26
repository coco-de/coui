import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'status.stories.g.dart';

/// Navigation metadata for the Status component.
const kComponentMeta = ComponentMeta(name: 'Status', path: 'display');

/// Story metadata for [Status].
const kMeta = Meta(Status.new);

/// Success status dot with editable knobs.
final $Default = _Story(
  args: _Args(
    color: EnumArg(CoreStatusColor.success, values: CoreStatusColor.values),
    size: EnumArg(CoreStatusSize.lg, values: CoreStatusSize.values),
    semanticLabel: NullableStringArg('Online'),
  ),
);

/// Neutral status color.
final $Neutral = _Story(
  args: _Args(
    color: EnumArg(CoreStatusColor.neutral, values: CoreStatusColor.values),
    size: EnumArg(CoreStatusSize.lg, values: CoreStatusSize.values),
  ),
);

/// Primary status color.
final $Primary = _Story(
  args: _Args(
    color: EnumArg(CoreStatusColor.primary, values: CoreStatusColor.values),
    size: EnumArg(CoreStatusSize.lg, values: CoreStatusSize.values),
  ),
);

/// Secondary status color.
final $Secondary = _Story(
  args: _Args(
    color: EnumArg(CoreStatusColor.secondary, values: CoreStatusColor.values),
    size: EnumArg(CoreStatusSize.lg, values: CoreStatusSize.values),
  ),
);

/// Tertiary status color.
final $Tertiary = _Story(
  args: _Args(
    color: EnumArg(CoreStatusColor.tertiary, values: CoreStatusColor.values),
    size: EnumArg(CoreStatusSize.lg, values: CoreStatusSize.values),
  ),
);

/// Info status color.
final $Info = _Story(
  args: _Args(
    color: EnumArg(CoreStatusColor.info, values: CoreStatusColor.values),
    size: EnumArg(CoreStatusSize.lg, values: CoreStatusSize.values),
  ),
);

/// Warning status color.
final $Warning = _Story(
  args: _Args(
    color: EnumArg(CoreStatusColor.warning, values: CoreStatusColor.values),
    size: EnumArg(CoreStatusSize.lg, values: CoreStatusSize.values),
  ),
);

/// Error status color.
final $Error = _Story(
  args: _Args(
    color: EnumArg(CoreStatusColor.error, values: CoreStatusColor.values),
    size: EnumArg(CoreStatusSize.lg, values: CoreStatusSize.values),
  ),
);

/// Pulse opt-in (default stories stay still).
class StatusPulseDemo extends StatelessWidget {
  /// Creates a [StatusPulseDemo].
  const StatusPulseDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Status(
      color: CoreStatusColor.info,
      size: CoreStatusSize.lg,
      animated: true,
      semanticLabel: 'Running',
    );
  }
}

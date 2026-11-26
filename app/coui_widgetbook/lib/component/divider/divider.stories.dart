import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'divider.stories.g.dart';

// Divider widgetbook constants.
const _kThicknessDefault = 1.0;
const _kVerticalDividerHeight = 50.0;

/// Knob input for [Divider] stories.
class DividerInput {
  /// Creates a [DividerInput].
  const DividerInput({
    this.orientation = CoreDividerOrientation.horizontal,
    this.thickness = _kThicknessDefault,
  });

  /// Divider orientation.
  final CoreDividerOrientation orientation;

  /// Line thickness in logical pixels.
  final double thickness;
}

/// Navigation metadata for the Divider component.
const kComponentMeta = ComponentMeta(name: 'Divider', path: 'display');

/// Story metadata for [Divider].
const kMeta = Meta(Divider.new, argsType: DividerInput.new);

/// Default builder mapping [DividerInput] args to a [Divider], wrapped
/// in sibling content matching the orientation.
final DividerDefaults defaults = _Defaults(
  setup: (context, child, args) => args.orientation == .vertical
      ? Row(
          mainAxisAlignment: .center,
          children: [
            const Text('Left'),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            SizedBox(height: _kVerticalDividerHeight, child: child),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            const Text('Right'),
          ],
        )
      : Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Content Above'),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            child,
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            const Text('Content Below'),
          ],
        ),
  builder: (context, args) => Divider(
    orientation: args.orientation,
    dividerStyle: CoreDividerStyle(thickness: args.thickness),
  ),
);

/// Horizontal divider between stacked content.
final $Default = _Story();

/// Vertical divider between inline content.
final $Vertical = _Story(
  name: 'Vertical Divider',
  args: _Args(
    orientation: EnumArg(
      CoreDividerOrientation.vertical,
      values: CoreDividerOrientation.values,
    ),
  ),
);

import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'frame.stories.g.dart';

/// Interactive demo host for [Frame] stories.
///
/// Renders a [Frame] with icon + label children and knob-controlled
/// direction, border, border style, and shadow elevation.
class FrameDemo extends StatelessWidget {
  /// Creates a [FrameDemo].
  const FrameDemo({
    super.key,
    this.direction = CoreFrameDirection.row,
    this.showBorder = true,
    this.borderStyle = CoreFrameBorderStyle.solid,
    this.elevation = CoreFrameElevation.none,
  });

  /// Layout direction of the frame children.
  final CoreFrameDirection direction;

  /// Whether the frame draws a border.
  final bool showBorder;

  /// Border style used when [showBorder] is enabled.
  final CoreFrameBorderStyle borderStyle;

  /// Shadow elevation preset.
  final CoreFrameElevation elevation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = switch (direction) {
      .row || .rowReverse => CoreSpace.space12,
      .column || .columnReverse || .wrap => CoreSpace.space8,
    };
    final borderWidth = switch (borderStyle) {
      .dashed || .dotted => CoreStrokeWidth.stroke2,
      .solid || .none => CoreStrokeWidth.stroke1,
    };

    return Frame(
      direction: direction,
      gap: gap,
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
      backgroundColor: colorScheme.surfaceContainer,
      borderColor: showBorder ? colorScheme.outlineVariant : null,
      borderWidth: showBorder ? borderWidth : null,
      borderStyle: showBorder ? borderStyle : null,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      elevation: elevation,
      children: const [
        Icon(
          LucideIcons.frame,
          iconStyle: CoreIconStyle(size: CoreSpace.space24),
        ),
        Text('Frame primitive'),
      ],
    );
  }
}

/// Navigation metadata for the Frame component.
const kComponentMeta = ComponentMeta(name: 'Frame', path: 'layout');

/// Story metadata for [FrameDemo].
const kMeta = Meta(FrameDemo.new);

/// Row frame with solid border and editable knobs.
final $Default = _Story();

/// Frame with a dashed (or dotted) painted border.
final $DashedBorder = _Story(
  name: 'Dashed Border',
  args: _Args(
    borderStyle: EnumArg(
      CoreFrameBorderStyle.dashed,
      values: CoreFrameBorderStyle.values,
    ),
  ),
);

/// Borderless frame with a shadow elevation preset.
final $ElevatedShadow = _Story(
  name: 'Elevated Shadow',
  args: _Args(
    showBorder: BoolArg(false),
    elevation: EnumArg(
      CoreFrameElevation.medium,
      values: CoreFrameElevation.values,
    ),
  ),
);

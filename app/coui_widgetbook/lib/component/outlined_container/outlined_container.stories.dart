import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'outlined_container.stories.g.dart';

const _kContainerSize = 200.0;

/// Knob input for [OutlinedContainer] stories.
class OutlinedContainerInput {
  /// Creates an [OutlinedContainerInput].
  const OutlinedContainerInput({
    this.borderRadius = CoreRadius.radius8,
    this.borderWidth = 1.0,
    this.padding = CoreSpace.space16,
    this.borderStyle = CoreOutlinedContainerBorderStyle.solid,
    this.coloredBorder = false,
    this.destructiveBorder = false,
  });

  /// Corner radius of the container in logical pixels.
  final double borderRadius;

  /// Border stroke width in logical pixels.
  final double borderWidth;

  /// Inner padding in logical pixels.
  final double padding;

  /// Border stroke style.
  final CoreOutlinedContainerBorderStyle borderStyle;

  /// Whether the border uses a theme accent color.
  final bool coloredBorder;

  /// Whether the colored border uses the destructive (error) color.
  final bool destructiveBorder;
}

/// Navigation metadata for the OutlinedContainer component.
const kComponentMeta = ComponentMeta(name: 'OutlinedContainer', path: 'infra');

/// Story metadata for [OutlinedContainer].
const kMeta = Meta(
  OutlinedContainer.new,
  argsType: OutlinedContainerInput.new,
);

/// Default builder mapping [OutlinedContainerInput] args to an
/// [OutlinedContainer].
final OutlinedContainerDefaults defaults = _Defaults(
  builder: (context, args) {
    final theme = Theme.of(context);
    final borderColor = args.coloredBorder
        ? args.destructiveBorder
              ? theme.colorScheme.error
              : theme.colorScheme.primary
        : null;

    return OutlinedContainer(
      containerStyle: CoreOutlinedContainerStyle(
        borderColor: borderColor,
        borderRadius: CoreBorderRadius.all(args.borderRadius),
        borderWidth: args.borderWidth,
        borderStyle: args.borderStyle,
        padding: CoreEdgeInsets.all(args.padding),
      ),
      child: const SizedBox.square(
        dimension: _kContainerSize,
        child: Center(
          child: Text('Content inside outlined container'),
        ),
      ),
    );
  },
);

/// Solid outlined container with editable chrome knobs.
final $Default = _Story();

/// Dashed border style.
final $Dashed = _Story(
  args: _Args(
    borderStyle: EnumArg(
      CoreOutlinedContainerBorderStyle.dashed,
      values: CoreOutlinedContainerBorderStyle.values,
    ),
  ),
);

/// Theme-colored border (primary, or error when destructive).
final $ColoredBorder = _Story(
  name: 'Colored Border',
  args: _Args(
    borderWidth: DoubleArg(2),
    coloredBorder: BoolArg(true),
  ),
);

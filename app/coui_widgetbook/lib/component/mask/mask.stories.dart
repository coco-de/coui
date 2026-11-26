import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'mask.stories.g.dart';

/// Knob input for [Mask] stories.
class MaskInput {
  /// Creates a [MaskInput].
  const MaskInput({
    this.shape = CoreMaskShape.squircle,
    this.half = CoreMaskHalf.none,
  });

  /// Mask clip shape.
  final CoreMaskShape shape;

  /// Half-crop applied to the shape.
  final CoreMaskHalf half;
}

/// Navigation metadata for the Mask component.
const kComponentMeta = ComponentMeta(name: 'Mask', path: 'layout');

/// Story metadata for [Mask].
const kMeta = Meta(Mask.new, argsType: MaskInput.new);

/// Default builder mapping [MaskInput] args to a [Mask].
final MaskDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox.square(
    dimension: CoreSize.size64,
    child: child,
  ),
  builder: (context, args) => Mask(
    shape: args.shape,
    half: args.half,
    child: Container(
      color: Theme.of(context).colorScheme.primary.toValue(),
    ),
  ),
);

/// Squircle mask with editable knobs.
final $Default = _Story();

/// Circle shape.
final $Circle = _Story(
  args: _Args(
    shape: EnumArg(CoreMaskShape.circle, values: CoreMaskShape.values),
  ),
);

/// Heart shape.
final $Heart = _Story(
  args: _Args(
    shape: EnumArg(CoreMaskShape.heart, values: CoreMaskShape.values),
  ),
);

/// Hexagon shape.
final $Hexagon = _Story(
  args: _Args(
    shape: EnumArg(CoreMaskShape.hexagon, values: CoreMaskShape.values),
  ),
);

/// Star shape.
final $Star = _Story(
  args: _Args(
    shape: EnumArg(CoreMaskShape.star, values: CoreMaskShape.values),
  ),
);

/// Triangle shape.
final $Triangle = _Story(
  args: _Args(
    shape: EnumArg(CoreMaskShape.triangle, values: CoreMaskShape.values),
  ),
);

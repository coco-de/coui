import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'dot_indicator.stories.g.dart';

// DotIndicator widgetbook constants.
const _kDefaultLength = 5;
const _kDefaultIndex = 2;

/// Knob input for [DotIndicator] stories.
class DotIndicatorInput {
  /// Creates a [DotIndicatorInput].
  const DotIndicatorInput({
    this.length = _kDefaultLength,
    this.index = _kDefaultIndex,
    this.direction = CoreAxis.horizontal,
    this.size = CoreDotIndicatorSize.defaultSize,
  });

  /// Total number of dots.
  final int length;

  /// Active dot index (clamped to the valid range).
  final int index;

  /// Layout direction of the dots.
  final CoreAxis direction;

  /// Dot diameter + spacing rung.
  final CoreDotIndicatorSize size;
}

/// Navigation metadata for the DotIndicator component.
const kComponentMeta = ComponentMeta(name: 'DotIndicator', path: 'display');

/// Story metadata for [DotIndicator].
const kMeta = Meta(DotIndicator.new, argsType: DotIndicatorInput.new);

/// Default builder mapping [DotIndicatorInput] args to a [DotIndicator],
/// with a page label below the dots.
final DotIndicatorDefaults defaults = _Defaults(
  setup: (context, child, args) => Center(
    child: Column(
      mainAxisAlignment: .center,
      spacing: CoreSpace.space16,
      children: [
        child,
        Text('Page ${args.index + 1} of ${args.length}'),
      ],
    ),
  ),
  builder: (context, args) => DotIndicator(
    index: args.index.clamp(0, args.length - 1),
    length: args.length,
    direction: args.direction,
    size: args.size,
  ),
);

/// Default horizontal dot indicator with editable knobs.
final $Default = _Story();

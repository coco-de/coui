import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'hidden.stories.g.dart';

const _kBoxWidth = 200.0;
const _kBoxHeight = 100.0;

/// Knob input for [Hidden] stories.
class HiddenInput {
  /// Creates a [HiddenInput].
  const HiddenInput({
    this.hidden = false,
    this.direction = CoreHiddenDirection.horizontal,
  });

  /// Whether the child is collapsed.
  final bool hidden;

  /// Axis along which the child collapses.
  final CoreHiddenDirection direction;
}

/// Navigation metadata for the Hidden component.
const kComponentMeta = ComponentMeta(name: 'Hidden', path: 'layout');

/// Story metadata for [Hidden].
const kMeta = Meta(Hidden.new, argsType: HiddenInput.new);

/// Default builder mapping [HiddenInput] args to a [Hidden].
final HiddenDefaults defaults = _Defaults(
  builder: (context, args) {
    final colorScheme = Theme.of(context).colorScheme;

    return Hidden(
      hidden: args.hidden,
      direction: args.direction,
      child: SizedBox(
        width: _kBoxWidth,
        height: _kBoxHeight,
        child: ColoredBox(
          color: colorScheme.primary.toValue(),
          child: Center(child: const Text('I am visible!').onPrimary),
        ),
      ),
    );
  },
);

/// Visible box — toggle the hidden knob to collapse it.
final $Default = _Story();

/// Box collapsed along the horizontal axis.
final $Collapsed = _Story(
  args: _Args(hidden: BoolArg(true)),
);

import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'swap.stories.g.dart';

/// Interactive demo host for [Swap] stories.
class SwapDemo extends StatefulWidget {
  /// Creates a [SwapDemo].
  const SwapDemo({
    super.key,
    this.animation = CoreSwapAnimation.none,
    this.showCounter = false,
  });

  /// Swap transition animation.
  final CoreSwapAnimation animation;

  /// Whether text contents and a toggle counter are shown
  /// instead of the sun / moon icons.
  final bool showCounter;

  @override
  State<SwapDemo> createState() => _SwapDemoState();
}

class _SwapDemoState extends State<SwapDemo> {
  bool _checked = false;
  int _toggleCount = 0;

  void handleToggle(bool value) {
    setState(() {
      _checked = value;
      _toggleCount += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.showCounter
        ? Column(
            mainAxisSize: .min,
            spacing: CoreSpace.space16,
            children: [
              Swap(
                animation: widget.animation,
                checked: _checked,
                offContent: const Text('OFF'),
                onContent: const Text('ON'),
                onToggle: handleToggle,
              ),
              Text('Toggled $_toggleCount times').medium(),
            ],
          )
        : Swap(
            animation: widget.animation,
            checked: _checked,
            offContent: const Icon(
              LucideIcons.moon,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            onContent: const Icon(
              LucideIcons.sun,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            onToggle: handleToggle,
          );
  }
}

/// Navigation metadata for the Swap component.
const kComponentMeta = ComponentMeta(name: 'Swap', path: 'display');

/// Story metadata for [SwapDemo].
const kMeta = Meta(SwapDemo.new);

/// Icon swap with editable knobs.
final $Default = _Story();

/// Flip-animated text swap with a toggle counter.
final $ToggleCounter = _Story(
  name: 'Toggle Counter',
  args: _Args(
    animation: EnumArg(
      CoreSwapAnimation.flip,
      values: CoreSwapAnimation.values,
    ),
    showCounter: BoolArg(true),
  ),
);

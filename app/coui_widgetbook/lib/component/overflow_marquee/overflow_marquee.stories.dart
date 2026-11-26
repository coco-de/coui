import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'overflow_marquee.stories.g.dart';

const _kMarqueeWidth = 200.0;

/// Knob input for [OverflowMarquee] stories.
class OverflowMarqueeInput {
  /// Creates an [OverflowMarqueeInput].
  const OverflowMarqueeInput({
    this.text = 'This is a very long text that will scroll when it overflows',
    this.direction = CoreAxis.horizontal,
    this.pauseOnHover = false,
  });

  /// Text content that overflows and scrolls.
  final String text;

  /// Scroll direction of the marquee.
  final CoreAxis direction;

  /// Whether scrolling pauses while hovered.
  final bool pauseOnHover;
}

/// Navigation metadata for the OverflowMarquee component.
const kComponentMeta = ComponentMeta(name: 'OverflowMarquee', path: 'layout');

/// Story metadata for [OverflowMarquee].
const kMeta = Meta(OverflowMarquee.new, argsType: OverflowMarqueeInput.new);

/// Default builder mapping [OverflowMarqueeInput] args to an
/// [OverflowMarquee] constrained to a fixed width.
final OverflowMarqueeDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: _kMarqueeWidth,
    child: child,
  ),
  builder: (context, args) => OverflowMarquee(
    direction: args.direction,
    pauseOnHover: args.pauseOnHover,
    child: Text(args.text),
  ),
);

/// Horizontal marquee scrolling overflowing text.
final $Default = _Story();

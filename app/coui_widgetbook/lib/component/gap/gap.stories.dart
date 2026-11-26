import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'gap.stories.g.dart';

const _kBoxSize = 60.0;

/// Interactive demo host for [Gap] stories.
///
/// Renders two boxes separated by a [Gap] whose size and axis are
/// knob-controlled.
class GapDemo extends StatelessWidget {
  /// Creates a [GapDemo].
  const GapDemo({
    super.key,
    this.size = CoreSpace.space16,
    this.vertical = true,
  });

  /// Gap size in logical pixels.
  final double size;

  /// Whether the boxes are laid out vertically.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final children = [
      _DemoBox(label: 'Box 1', color: colorScheme.primary),
      Gap(gapStyle: CoreGapStyle(size: size)),
      _DemoBox(label: 'Box 2', color: colorScheme.secondary),
    ];

    return vertical
        ? Column(mainAxisSize: .min, children: children)
        : Row(mainAxisSize: .min, children: children);
  }
}

class _DemoBox extends StatelessWidget {
  const _DemoBox({required this.label, required this.color});

  final String label;
  final CoreColor color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _kBoxSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.toValue(),
          borderRadius: const .all(
            .circular(CoreRadius.radius8),
          ),
        ),
        child: Center(child: Text(label).onPrimary),
      ),
    );
  }
}

/// Navigation metadata for the Gap component.
const kComponentMeta = ComponentMeta(name: 'Gap', path: 'layout');

/// Story metadata for [GapDemo].
const kMeta = Meta(GapDemo.new);

/// Vertical gap with an editable size knob.
final $Default = _Story();

/// Small predefined gap (`CoreSpace.space8`).
final $Small = _Story(
  args: _Args(size: DoubleArg(CoreSpace.space8)),
);

/// Large predefined gap (`CoreSpace.space32`).
final $Large = _Story(
  args: _Args(size: DoubleArg(CoreSpace.space32)),
);

/// Extra-large predefined gap (`CoreSpace.space64`).
final $ExtraLarge = _Story(
  name: 'Extra Large',
  args: _Args(size: DoubleArg(CoreSpace.space64)),
);

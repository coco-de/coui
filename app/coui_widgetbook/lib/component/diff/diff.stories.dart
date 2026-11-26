import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'diff.stories.g.dart';

// Diff widgetbook constants.
const _kFrameWidth = 320.0;
const _kPositionGap = 12.0;
const _kPercentMultiplier = 100;

/// Interactive demo host for [Diff] stories.
class DiffDemo extends StatefulWidget {
  /// Creates a [DiffDemo].
  const DiffDemo({
    super.key,
    this.interactive = true,
    this.initialPosition = CoreDiffStyle.defaultInitialPosition,
    this.showPositionLabel = false,
    this.showLabels = false,
  });

  /// Whether the resizer handle can be dragged.
  final bool interactive;

  /// Initial resizer position (0.0 - 1.0).
  final double initialPosition;

  /// Whether the live resizer position is shown below the diff.
  final bool showPositionLabel;

  /// Whether the `beforeLabel` / `afterLabel` chips are drawn over the
  /// frame's top corners.
  final bool showLabels;

  @override
  State<DiffDemo> createState() => _DiffDemoState();
}

class _DiffDemoState extends State<DiffDemo> {
  // deferred init must read widget.
  late double _position = widget.initialPosition;

  void handlePositionChanged(double position) {
    setState(() => _position = position);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final beforeText = const Text('Before').titleLarge.onPrimary;
    final afterText = const Text('After').titleLarge.onSecondary;

    return Column(
      mainAxisSize: .min,
      spacing: _kPositionGap,
      children: [
        SizedBox(
          width: _kFrameWidth,
          child: Diff(
            beforeLabel: widget.showLabels ? const Text('Before') : null,
            afterLabel: widget.showLabels ? const Text('After') : null,
            before: ColoredBox(
              color: colorScheme.primary.toValue(),
              child: Center(child: beforeText),
            ),
            after: ColoredBox(
              color: colorScheme.secondary.toValue(),
              child: Center(child: afterText),
            ),
            onPositionChanged: handlePositionChanged,
            interactive: widget.interactive,
            ariaLabel: 'Filled vs surface comparison',
            diffStyle: CoreDiffStyle(initialPosition: widget.initialPosition),
          ),
        ),
        if (widget.showPositionLabel)
          Text(
            'Position: ${(_position * _kPercentMultiplier).round()}%',
          ).bodyMedium,
      ],
    );
  }
}

/// Navigation metadata for the Diff component.
const kComponentMeta = ComponentMeta(name: 'Diff', path: 'display');

/// Story metadata for [DiffDemo].
const kMeta = Meta(DiffDemo.new);

/// Default before/after comparison with editable knobs.
final $Default = _Story();

/// Draggable diff tracking the live resizer position.
final $Interactive = _Story(
  args: _Args(showPositionLabel: BoolArg(true)),
);

/// Before / after chips drawn over the frame's top corners.
final $Labeled = _Story(
  args: _Args(showLabels: BoolArg(true)),
);

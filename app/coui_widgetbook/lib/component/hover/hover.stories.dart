import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'hover.stories.g.dart';

const _kHoverAlpha = 0.1;

/// Interactive demo host for [Hover] stories.
///
/// Tracks hover state internally and animates the container chrome
/// between idle and hovered colors.
class HoverDemo extends StatefulWidget {
  /// Creates a [HoverDemo].
  const HoverDemo({
    super.key,
    this.label = 'Hover over me',
    this.hoveredLabel = 'Hovered!',
  });

  /// Label shown while the pointer is outside the area.
  final String label;

  /// Label shown while the pointer hovers the area.
  final String hoveredLabel;

  @override
  State<HoverDemo> createState() => _HoverDemoState();
}

class _HoverDemoState extends State<HoverDemo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = (_isHovered ? colorScheme.primary : colorScheme.outline)
        .toValue();

    return Hover(
      onHover: (hovered) => setState(() => _isHovered = hovered),
      child: AnimatedContainer(
        padding: const .all(CoreSpace.space16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: _kHoverAlpha),
          border: Border.all(color: accent),
          borderRadius: const .all(
            .circular(CoreRadius.radius8),
          ),
        ),
        duration: const Duration(milliseconds: CoreDuration.ms200),
        child: Text(_isHovered ? widget.hoveredLabel : widget.label),
      ),
    );
  }
}

/// Navigation metadata for the Hover component.
const kComponentMeta = ComponentMeta(name: 'Hover', path: 'control');

/// Story metadata for [HoverDemo].
const kMeta = Meta(HoverDemo.new);

/// Hover area with animated chrome feedback.
final $Default = _Story();
